local commands = require('commands')
local log = require "log"

local lifecycle_handler = {}

function lifecycle_handler.init(driver, device)
  --device.thread:call_on_schedule(
  --  config.SCHEDULE_PERIOD,
  --  function ()
  --    return commands.refresh(nil, device)
  --  end,
  --  'Refresh schedule')
  log.debug('mpd device init')
  commands.refresh(nil, device)
end

function lifecycle_handler.doConfigure(driver, device)
  log.debug('mpd device do configure')
end

function lifecycle_handler.added(driver, device)
  --commands.refresh(nil, device)
  log.debug('mpd device added')
end

function lifecycle_handler.removed(driver, device)
  -- Remove Schedules created under
  -- device.thread to avoid unnecessary
  -- CPU processing.
  --for timer in pairs(device.thread.timers) do
  --  device.thread:cancel_timer(timer)
  --end
  log.debug('mpd device removed')
end

return lifecycle_handler
