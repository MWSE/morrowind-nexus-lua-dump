local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local anim = require('openmw.animation')
local types = require("openmw.types")
local AI = require('openmw.interfaces').AI
local core = require('openmw.core')
local nextUpdate = 0
-- local hasDied = false
-- local deaths = {
-- ["death1"] = true,
-- ["death2"] = true,
-- ["death3"] = true,
-- ["death4"] = true,
-- }
-- 
-- local function soultrapVFX()
--	 anim.addVfx(self, types.Static.records["VFX_Soul_Trap"].model)
-- end
-- 
-- I.AnimationController.addTextKeyHandler('', function(groupname, key) --self start/stop, touch start/stop, target start/stop
-- 	if deaths[groupname] and not hasDied and types.Actor.isDead(self) then
-- 		print(self.recordId.." died")
-- 		for _, player in pairs(nearby.players) do
-- 			player:sendEvent("Roguelite_actorDied", self)
-- 		end
-- 		hasDied = true
-- 	end
-- end)




local function aiCheck(p)
	--print(self,p.type,p.target)
	if p
	and p.type == "Follow"
	and p.target
	and types.Player.objectIsInstance(p.target)
	then
		companion = p.target
	end
end



local function onInactive()
	if companion and not types.Actor.isDead(self) and companion.cell ~= self.cell then
		core.sendGlobalEvent("PMM_catchUpTeleport", {self, companion})
	else
		core.sendGlobalEvent("PMM_unhookObject", self)
	end
end


local function onUpdate()
	local now = core.getRealTime()
	if now > nextUpdate then
		companion = nil
		AI.forEachPackage(aiCheck)
		nextUpdate = now + 0.3+math.random()/5
	end
end



return {
	engineHandlers = {
		onUpdate = onUpdate,
		onInactive = onInactive,
	},
	--eventHandlers = {
	--	Died = function()
	--		print(self, "died")
	--	end
	--}
}
