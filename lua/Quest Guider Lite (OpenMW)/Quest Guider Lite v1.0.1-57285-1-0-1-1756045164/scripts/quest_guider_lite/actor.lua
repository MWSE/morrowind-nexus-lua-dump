local core = require('openmw.core')
local self = require('openmw.self')

return {
    eventHandlers = {
        Died = function()
            core.sendGlobalEvent("QGL:registerActorDeath", {object = self})
        end
    },
}