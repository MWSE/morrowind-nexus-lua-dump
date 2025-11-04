local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')

local function onActivated(actor)
    --print('scribo: book activated from world')

	local inventory = false

    actor:sendEvent("ProcessingItem", {
        book = self,
        inventory = inventory,
    })
end

return {
    engineHandlers = {
        onActivated = onActivated,
    }
}
