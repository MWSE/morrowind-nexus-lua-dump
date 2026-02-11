local self = require('openmw.self')

local function onActivated(actor)
    if actor then
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
