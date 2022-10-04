local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local log = require "log"
local discovery = require("discovery")
local lifecycles = require('lifecycles')
local commands = require("commands")
local mpd_cap = capabilities['locketcenter12781.mpd']
local track_title_cap = capabilities['locketcenter12781.tracktitle']
local track_album_cap = capabilities['locketcenter12781.trackalbum']
local track_artist_cap = capabilities['locketcenter12781.trackartist']
local track_progress_cap = capabilities['locketcenter12781.trackProgress']
local device_network_id_cap = capabilities['locketcenter12781.deviceNetworkId']

local function handle_on(driver, device, command)
    commands.setStatus(_, device, { args = { status = 'play' } })
end

local function handle_off(driver, device, command)
    commands.setStatus(_, device, { args = { status = 'stop' } })
end

local mpd_driver = Driver("MPD Driver", {
    discovery = discovery.start,
    lifecycle_handlers = lifecycles,
    supported_capabilities = {
        mpd_cap,
        track_title_cap,
        track_album_cap,
        track_artist_cap,
        track_progress_cap,
        device_network_id_cap,
        capabilities.switch,
        capabilities.refresh
    },
    capability_handlers = {
        [capabilities.switch.ID] = {
            [capabilities.switch.commands.on.NAME] = handle_on,
            [capabilities.switch.commands.off.NAME] = handle_off
        },
        [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = commands.refresh
        },
        [mpd_cap.ID] = {
            [mpd_cap.commands.setStatus.NAME] = commands.setStatus,
            [mpd_cap.commands.setVolume.NAME] = commands.setVolume,
            [mpd_cap.commands.setModeRandom.NAME] = commands.setModeRandom,
            [mpd_cap.commands.setModeRepeat.NAME] = commands.setModeRepeat,
            [mpd_cap.commands.setModeSingle.NAME] = commands.setModeSingle
        }
    }
}
)

mpd_driver:run()
