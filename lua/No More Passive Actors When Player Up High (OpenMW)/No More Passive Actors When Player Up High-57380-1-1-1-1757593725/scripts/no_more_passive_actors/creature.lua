local self = require("openmw.self")
local I = require("openmw.interfaces")
local ai = I.AI
local types = require("openmw.types")
local Actor = types.Actor
local async = require("openmw.async")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local util = require("openmw.util")

local playerPosition
local testPosition
local speedBoost
local fightBoost
local memCombat
local Stats = Actor.stats
local Speed = Stats.attributes.speed(self)
local baseSpeed = Speed.base
local StatsAI = Stats.ai
local Fight = StatsAI.fight(self)
local Hello = StatsAI.hello(self)
local activeTarget
local player = nearby.players[1]
local counter = 0


local function onSave()
    return {
        SB = speedBoost,
        FB = fightBoost,
        MC = memCombat,
    }
end

local function onLoad(data)
	if data then
		speedBoost = data.SB
		fightBoost = data.FB
		memCombat = data.MC
	end
end


local function targetPlayer()
    activeTarget = ai.getActiveTarget("Combat")
    if activeTarget and activeTarget.type == types.Player then
		return true
	end
end


local function playerLow()
	playerPosition = player.position
	-- if player isn't very high relative to me then return true.
	if playerPosition.z - self.position.z < 130 then return true end
	testPosition = util.vector3(playerPosition.x, playerPosition.y, playerPosition.z - 130)
	if nearby.castRay(playerPosition, testPosition, {collisionType=nearby.COLLISION_TYPE.HeightMap}).hit then
		return true -- if player isn't very high relative to the ground, then return true. 
	end
end


local function fightBoostFct()
	if not fightBoost then
		Fight.modifier = Fight.modifier + 1000 -- so i will stay "angry" against the player
		Hello.modifier = Hello.modifier - 1000 -- so i won't talk to the player
		fightBoost = true -- Memorization
		core.sendGlobalEvent('ll_NoMorePassiveActors_Dialogue', {
			actor = self,
			desactivate = true, -- so the player won't be able to talk with me
		})
	end
end


local function fightUnBoostFct()
	if fightBoost then
		Fight.modifier = Fight.modifier - 1000
		Hello.modifier = Hello.modifier + 1000
		fightBoost = nil
		core.sendGlobalEvent('ll_NoMorePassiveActors_Dialogue', {
			actor = self,
			desactivate = false,
		})
	end
end


local function noMorePassiveActors()

    if types.Creature.record(self).canFly or Actor.isDead(self) then -- Flying creatures and dead creatures are excluded from this mod
        return
    end
--if self.recordId ~= "xxx" and self.recordId == "yyy" then return end

	async:newUnsavableSimulationTimer(0.75, noMorePassiveActors) -- Check every 0.75 s

	if not Actor.isInActorsProcessingRange(self) then return end -- The actor must be in the processing range
	
	if speedBoost then -- If we have boosted his speed, it's time to unboost...
		Speed.modifier = Speed.modifier - baseSpeed
		speedBoost = nil
	end

	if memCombat then -- If the actor was in combat against the player...
		if not targetPlayer() then --If he's not in combat against the player anymore...
			counter = 0
			if not playerLow() then -- If player is up high
				fightBoostFct() -- the actor will stay angry against the player when player will come back down
				return
			else -- (player low)
				memCombat = nil
				return
			end
		elseif playerLow() then -- If player isn't very up high
			counter = 0
			fightUnBoostFct() -- We undo our modifications to let the Morrowind engine takes over
			return
		end -- if (targetPlayer() + player up high), we continue...
	elseif targetPlayer() then
		memCombat = true
		if playerLow() then
			counter = 0
			fightUnBoostFct()
			return
		end -- if (targetPlayer() + player high), we continue...
	else -- (no memCombat, no targetPlayer())
		counter = 0
		return
	end
	
	-- If actor can't move, or actor is moving, or is hidding because of the Take Cover mod, then we don't continue
    if not Actor.canMove(self) or Actor.getCurrentSpeed(self) > 0 or (I.TakeCover and I.TakeCover.isHidden()) then
		counter = 0
        return
    end

-- Here we know that the actor doesn't move (and he's targeting the player, and player is up high)

	counter = counter + 1
	if counter < 6 then return end -- We wait a few seconds before going on
	counter = 0
	
	ai.removePackages("Combat") -- Actors stops to be immobile, he comes back to his normal behavior
	fightBoostFct()
	Speed.modifier = Speed.modifier + baseSpeed -- We speed him a little bit to simulate an alert state
	speedBoost = true -- Memorization

end


return {
    engineHandlers = {
		onLoad = onLoad,
		onSave = onSave,
        onActive = async:newUnsavableSimulationTimer(0.5 + math.random() * 0.5, noMorePassiveActors),
    }
}
