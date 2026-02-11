local ai = require("openmw.interfaces").AI
local core = require("openmw.core")
local self = require("openmw.self")

local AI = ai and ai.getActivePackage() or {}
local noWander = true

local function removeCheck()
--	print("NPCWANDER FORCE REMOVE")
	if self:isActive() and AI.type == "Wander" then
	--	if AI.distance == 0 and (target.position - self.position):length() > 300 then
	--	end
		if AI.distance and AI.distance > 0 then
			noWander = false
		end
	else
		core.sendGlobalEvent("dynRemoveScript",
			{ object = self, script = "scripts/DynamicActors/npcDialogAI.lua" })
		return true
	end
end

if removeCheck() then		return		end


local types = require("openmw.types")
local util = require("openmw.util")
local target, freezeControls

-- Bards of Bardenfell bugfix
local isSayActive = types.Actor.stats.ai.hello(self).modified ~= 0 and core.sound.isSayActive


local function onUpdate(dt)
	if dt <= 0 or not target then	return		end
	if isSayActive and isSayActive(self) then
--		print("STOP SOUND")
		core.sound.stopSay(self)
	end
	if noWander then	return			end

        local delta = target.position - self.position
	if delta:length() < 300 then
		local dVec = delta.xy:rotate(self.rotation:getYaw())
		local dYaw = math.atan2(dVec.x, dVec.y)
		if math.abs(dYaw) < math.rad(80) then
			if freezeControls then
			        self.controls.movement = 0
			        self.controls.sideMovement = 0
			        self.controls.yawChange = 0
			else
				self.controls.yawChange = math.pi
				freezeControls = true
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
