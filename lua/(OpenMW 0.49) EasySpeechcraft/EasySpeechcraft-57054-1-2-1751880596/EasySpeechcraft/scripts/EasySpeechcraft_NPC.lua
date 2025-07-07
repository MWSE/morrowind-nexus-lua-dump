
local types = require('openmw.types')
local self = require('openmw.self')


--local function onActivated(actor)
--end

local function setDisposition(data)
	local player = data[1]
	local value = data[2]
	
	types.NPC.setBaseDisposition(self, player, value)
	--print("NPC: disposition to ",player,value)
end

return { 
	engineHandlers = { 
		--onActivated = onActivated,
	},
	eventHandlers = { 
		EasySpeechcraft_setDisposition = setDisposition
	}
}