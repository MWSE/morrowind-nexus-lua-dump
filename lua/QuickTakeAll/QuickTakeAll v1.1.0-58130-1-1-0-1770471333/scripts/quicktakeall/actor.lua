local self = require('openmw.self')
local types = require('openmw.types')

local function onActivated(actor)
    -- Only send event if this actor is dead (corpse looting)
    if actor and types.Actor.isDead(self.object) then
        actor:sendEvent('ContainerActivated', {
            object = self.object,
            isCorpse = true,
        })
    end
end

return {
    engineHandlers = {
        onActivated = onActivated,
    },
}
