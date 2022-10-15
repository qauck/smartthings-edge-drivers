local capabilities = require('st.capabilities')
local log = require('log')
local cosock = require "cosock"
local http = cosock.asyncify "socket.http"
local ltn12 = require('ltn12')
local mpd_cap = capabilities['locketcenter12781.mpd']
local track_title_cap = capabilities['locketcenter12781.tracktitle']
local track_album_cap = capabilities['locketcenter12781.trackalbum']
local track_artist_cap = capabilities['locketcenter12781.trackartist']
local track_progress_cap = capabilities['locketcenter12781.trackProgress']
local device_network_id_cap = capabilities['locketcenter12781.deviceNetworkId']

local command_handler = {}

local function send_lan_command(ip, cmd)
    local dest_url = 'http://' .. ip .. '/command?cmd=' .. cmd
    local res_body = {}

    local _, code = http.request({
        method = 'GET',
        url = dest_url,
        sink = ltn12.sink.table(res_body),
        headers = {
        } })

    local resp = table.concat(res_body);
    log.debug(resp)

    if code == 200 then
        return true, resp
    end
    return false, resp
end

local function parseResponse(response, field)
    local idx = string.find(response, field .. ':', 1, true)

    if idx ~= nil then
        local len = string.len(field) + 2
        local endIdx = string.find(response, "\n", idx + len)
        if endIdx ~= nil then
            return string.sub(response, idx + len, endIdx - 1)
        end
    end
    return nil
end

local function updateAttributes(data, device)
    local state = parseResponse(data, 'state')
    if state ~= nil then
        device:emit_event(mpd_cap.status(state))
        if state == 'play' then
            device:emit_event(capabilities.switch.switch.on())
        else
            device:emit_event(capabilities.switch.switch.off())
        end
    end

    local random = parseResponse(data, 'random')
    if random == '1' then
        device:emit_event(mpd_cap.modeRandom('on'))
    elseif random == '0' then
        device:emit_event(mpd_cap.modeRandom('off'))
    end

    local rpt = parseResponse(data, 'repeat')
    if rpt == '1' then
        device:emit_event(mpd_cap.modeRepeat('on'))
    elseif rpt == '0' then
        device:emit_event(mpd_cap.modeRepeat('off'))
    end

    local single = parseResponse(data, 'single')
    if single == '1' then
        device:emit_event(mpd_cap.modeSingle('on'))
    elseif single == '0' then
        device:emit_event(mpd_cap.modeSingle('off'))
    end

    local title = parseResponse(data, 'Title')
    if title ~= nil then
        device:emit_event(track_title_cap.trackTitle(title))
    else
        local file = parseResponse(data, 'file')
        if file ~= nil then
            local idx = string.reverse(file):find('/', 1, true)
            if idx ~= nil then
                title = string.sub(file, string.len(file) - idx + 2)
                device:emit_event(track_title_cap.trackTitle(title))
            end
        end
    end

    local album = parseResponse(data, 'Album')
    if album ~= nil then
        device:emit_event(track_album_cap.trackAlbum(album))
    end

    local artist = parseResponse(data, 'Artist')
    if artist ~= nil then
        device:emit_event(track_artist_cap.trackArtist(artist))
    end

    if state ~= nil then
        local elapsed = parseResponse(data, 'elapsed')
        if elapsed ~= nil then
            device:emit_event(track_progress_cap.trackProgress(elapsed .. ' s'))
        else
            device:emit_event(track_progress_cap.trackProgress('N/A'))
        end
    end

    local songPos = parseResponse(data, 'song')
    if songPos ~= nil then
        local success, songData = send_lan_command(device.device_network_id, 'playlistinfo%20' .. songPos)
        if success then
            log.debug('Query song info succeeded: ' .. songPos)
            updateAttributes(songData, device)
        else
            log.error('Set status failed: ' .. status)
        end
    end

end

function command_handler.refresh(_, device)
    local success, data = send_lan_command(device.device_network_id, 'status')
    if success then
        device:online()
        device:emit_event(device_network_id_cap.deviceNetworkId(device.device_network_id))
        updateAttributes(data, device)
    else
        log.error('Failed to poll device state')
        device:offline()
    end
end

function command_handler.setStatus(_, device, command)
    local status = command.args.status
    local success = send_lan_command(device.device_network_id, status)
    if success then
        log.debug('Set status succeeded: ' .. status)
        command_handler.refresh(_, device)
    else
        log.error('Set status failed: ' .. status)
    end
end

return command_handler
