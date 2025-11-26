local core = require('openmw.core')
local self = require('openmw.self')


local function onInactive()
    core.sendGlobalEvent("QuestGuiderLite:ObjectInactive", self)
end


return {
    engineHandlers = {
        onInactive = onInactive,
    },
    eventHandlers = {
        Died = function()
            core.sendGlobalEvent("QGL:registerActorDeath", {object = self})
        end
    },
}