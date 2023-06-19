--[[

Mod: Welcome To Vvardenfell
Author: Pharis

--]]

local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")

local isDead = false

local function onUpdate()
	if (not isDead) and (types.Actor.stats.dynamic.health(self).current <= 0) then
		isDead = true
		core.sendGlobalEvent(
			"PharisRecursiveCreaturesOnCreatureDeath",
			{
				object = self.object,
				deathPosition = self.position,
				deathRotation = self.rotation
			}
		)
	end
end

return {
	engineHandlers = {
		onUpdate = onUpdate
	}
}
