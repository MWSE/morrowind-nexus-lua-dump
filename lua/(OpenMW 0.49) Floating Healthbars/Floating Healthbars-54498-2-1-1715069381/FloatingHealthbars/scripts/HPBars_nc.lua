local AI = require('openmw.interfaces').AI
local self = require("openmw.self")
local nearby = require('openmw.nearby')
local core = require('openmw.core')
local types = require('openmw.types')
local Player = types.Player

local nextUpdate = 0
local function cb(p)
	if p.target and Player.objectIsInstance(p.target)
	and (p.type == "Follow" or p.type == "Combat") 
	then
		--print(self,p.type)
		p.target:sendEvent("FHB_AI_update",{id = self.id, package = p.type})
	end
end
local function onUpdate()
	local now = core.getRealTime()
	if now > nextUpdate then
		nextUpdate = now + 0.3+math.random()/5
		AI.forEachPackage(cb)
	end
	--print(AI.getActivePackage().type)
	--print(AI.getActivePackage().target)
	--print(AI.getActivePackage().sideWithTarget)
	--print(self.id)
	--for a,b in pairs(nearby.players) do
	--	b:sendEvent("AI_update","WARNow returned to restocking?")
	--end
end
return {
	engineHandlers = {
		onUpdate = onUpdate
	},
}
