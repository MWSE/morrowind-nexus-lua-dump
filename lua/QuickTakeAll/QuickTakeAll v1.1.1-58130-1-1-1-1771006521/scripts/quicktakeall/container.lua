local self = require('openmw.self')
local types = require('openmw.types')

local function onActivated(actor)
    -- Only notify if the container actually opens (not locked)
    if actor and not types.Lockable.isLocked(self) then
        actor:sendEvent('ContainerActivated', {
            object = self.object,
            isCorpse = false,
        })
    end
end

return {
    engineHandlers = {
        onActivated = onActivated,
    },
}
