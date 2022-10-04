local disco = {}
local mdns = require('mdns')
local log = require "log"

function disco.start(driver, opts, cons)
    local res = mdns.query("_mpd._tcp")
    if (res) then
        for k,v in pairs(res) do
            log.debug('===== Found MPD device: '..k)
            for k1,v1 in pairs(v) do
                -- print all fields
                log.debug('=====   '..k1..': '..v1)
            end

            if v.ipv4 ~=nil and v.name ~=nil then
                -- try create device
                log.debug('===== Try creating MPD device: '..v.ipv4)
                local metadata = {
                    type = "LAN",
                    device_network_id = v.ipv4,
                    label = v.name,
                    profile = "mpd.v1",
                    manufacturer = "RuneAudio",
                    model = "RuneAudio RaspberryPi",
                    vendor_provided_label = "org.uguess.smartthings.mpd"
                }
                driver:try_create_device(metadata)
                log.debug('===== MPD device creation done: '..v.ipv4)
            else
                log.debug('===== Not a valid MPD device.')
            end
        end
    else
        log.debug('===== No MPD device found.')
    end
end

return disco