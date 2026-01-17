local ai = require("openmw.interfaces").AI
local core = require("openmw.core")
local self = require("openmw.self")

local AI = ai and ai.getActivePackage() or {}

local function removeCheck()
	--	print("NPCWANDER FORCE REMOVE")
	local valid
	if self.isActive(self) and AI.type == "Wander" then
		valid = true
	--	if AI.distance == 0 and (target.position - self.position):length() > 300 then
	--	end
	end
	if not valid then
		core.sendGlobalEvent("dynRemoveScript",
			{ object = self, script = "scripts/DynamicActors/npcDialogAI.lua" })
	end
end

removeCheck()


local types = require("openmw.types")
local util = require("openmw.util")

local target, canWander


local function onUpdate(dt)
	if dt <= 0 then		return			end
	if not target then	return			end
	if core.sound.isSayActive(self) then
--		print("STOP SOUND")
		core.sound.stopSay(self)
	end
	if AI.distance == 0 then	return		end

        local dPos = target.position - self.position
	if dPos:length() < 300 then
		local dVec = util.vector2(dPos.x, dPos.y):rotate(self.rotation:getYaw())
		local dYaw = math.atan2(dVec.x, dVec.y)
		if math.abs(dYaw) < math.rad(80) then
			if canWander then
				self.controls.yawChange = math.pi
				canWander = false
			else
			        self.controls.movement = 0
			        self.controls.sideMovement = 0
			        self.controls.yawChange = 0
			end
		end
	end
end


return {
	engineHandlers = {
		onUpdate = onUpdate,
		onInit = function(e)	target = e	removeCheck()		end,
		onInactive = removeCheck
	},
}
