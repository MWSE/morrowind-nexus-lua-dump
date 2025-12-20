local self=require('openmw.self')
local types = require('openmw.types')

local function activateBardStand(actor)
	if self.recordId=="cst_bard_stand" then  --write here your activator record id
		if self.recordId == 'cst_bard_stand' and actor.type == types.Player then
			actor:sendEvent('BC_ToggleUI')
		end
	end
end


return {
	engineHandlers = {	onActivated=activateBardStand
	}
}