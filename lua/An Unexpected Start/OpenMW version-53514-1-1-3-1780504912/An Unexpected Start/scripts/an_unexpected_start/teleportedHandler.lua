local core = require('openmw.core')
local self = require('openmw.self')

local function onTeleported()
    core.sendGlobalEvent("usbd_objectTeleported", {reference = self})
end

return {
    engineHandlers = {
        onTeleported = onTeleported,
    },
}