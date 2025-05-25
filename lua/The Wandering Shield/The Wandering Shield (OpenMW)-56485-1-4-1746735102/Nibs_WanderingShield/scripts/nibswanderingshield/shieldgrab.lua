local self = require('openmw.self')
local core = require('openmw.core')

-- Sends an Event to the Global script when Spellbreaker is Activated (grabbed)
return {
    engineHandlers = {
        onActivated = function(actor)
            core.sendGlobalEvent('ShieldGrabbed', { object = self })
        end
    }
}