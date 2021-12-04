local self = require('openmw.self')
local core = require('openmw.core')

local function onOffAi(data)
if data.enable then
self:enableAI(true)
else
self:stopCombat()
self:enableAI(false)
end
end


return {
    engineHandlers = {
        onInactive = function()
			if self.cell.name ~= "Mournhold" then
			core.sendGlobalEvent('warpToPlayer')
			end
        end,
    },

	eventHandlers = {
		onOffAi = onOffAi,
	}
}

