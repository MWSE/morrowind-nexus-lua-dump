local core = require'openmw.core'
local input = require'openmw.input'
local self = require'openmw.self'

local commonKeys = require'scripts.styxd.stackmaster.commonKeys'
local events = require'scripts.styxd.stackmaster.events'

local M = {}

M.eventHandlers = {}

M.eventHandlers[events.PlayerActivatedStack.eventName] = function(eventData)
    -- Do not try to override activation in any kind of menu context.
    -- I don't know if there's currently a better way to detect it.
    if core.isWorldPaused() then
        return
    end

    if input.getBooleanActionValue(commonKeys.actions.DumpAll) then
        events.ReturnStack.sendEvent{
            player = self.object,
            stackInfoProps = eventData.stackInfoProps,
            keepOneItem = false
        }
    elseif input.getBooleanActionValue(commonKeys.actions.PickOne) then
        events.ReturnStack.sendEvent{
            player = self.object,
            stackInfoProps = eventData.stackInfoProps,
            keepOneItem = true
        }
    end
end

return M
