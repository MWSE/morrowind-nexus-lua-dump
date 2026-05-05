local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')

local function onActivated(actor)
    
	local inventory = false

    core.sendGlobalEvent("hrCollectConteiners", { container = self })
end

return {
    engineHandlers = {
        onActivated = onActivated,
    }
}
