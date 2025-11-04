local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')

local function onActivated(actor)
    actor:sendEvent("readBook", {
        book = self
    })
end

return {
    engineHandlers = {
        onActivated = onActivated,
    }
}
