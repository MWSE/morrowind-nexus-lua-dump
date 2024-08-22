local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local self = require('openmw.self')
local types = require('openmw.types')
local camera = require('openmw.camera')
local input = require('openmw.input')
local core = require('openmw.core')
local storage = require('openmw.storage')
local util = require('openmw.util')
local I = require("openmw.interfaces")
local HarvestedCorpses = storage.playerSection("IsHarvested")
HarvestedCorpses:setLifeTime(storage.LIFE_TIME.Temporary)

local function RayCast(key)

	if key.symbol == 'x' then
	local faced = nearby.castRenderingRay(camera.getPosition(), camera.getPosition() + camera.viewportToWorldVector(util.vector2(0.5, 0.5))* 8192, {ignorePlayer = true})

		if faced.hitObject then
			if types.NPC.objectIsInstance(faced.hitObject) == true then
				if types.Actor.isDead(faced.hitObject) == true then
					if (self.position - faced.hitObject.position):length() < 205 then
						if HarvestedCorpses:get(faced.hitObject.id) == faced.hitObject.id then
							ui.showMessage('This corpse was harvested!')
							return
						end
						if types.Player.quests(self)["KSN_SorkvildTeacher"].stage == 100 then
						ui.showMessage('You harvest a corpse!')
						core.sendGlobalEvent("HarvestCorpse", faced.hitObject)
						HarvestedCorpses:set(faced.hitObject.id, faced.hitObject.id)
						I.UI.addMode('Container', {target = faced.hitObject})
						end
					end
				end
			end
		end


	end

	
	if key.code == input.KEY.LeftAlt and I.UI.getMode() == "Container" and types.Player.quests(self)["MG_Sharn_Necro"].stage == 10 then
		local faced = nearby.castRenderingRay(camera.getPosition(), camera.getPosition() + camera.viewportToWorldVector(util.vector2(0.5, 0.5))* 8192, {ignorePlayer = true})
			if faced.hitObject then 
				if types.NPC.objectIsInstance(faced.hitObject) then
					if types.Actor.isDead(faced.hitObject) then
						if HarvestedCorpses:get(faced.hitObject.id) == faced.hitObject.id then
							ui.showMessage("You can't reanimate corpse that was harvested!")
							return
						end
					core.sendGlobalEvent("SpawnProp", "KSN_Zombie_Summon_PROP")
					core.sendGlobalEvent("RemoveCorpse", faced.hitObject)
					end
				end
			end
	end

end


return { engineHandlers = {onKeyPress = RayCast} }
