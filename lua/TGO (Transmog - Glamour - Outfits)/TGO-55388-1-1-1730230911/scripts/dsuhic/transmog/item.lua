local self = require('openmw.self')
local types = require('openmw.types')

local function onActivated(actor)
    if actor.type == types.Player then
        actor:sendEvent("transmogItemSelected", self)
    end
end

return {
    engineHandlers = {
        onActivated = onActivated,
    },
}
