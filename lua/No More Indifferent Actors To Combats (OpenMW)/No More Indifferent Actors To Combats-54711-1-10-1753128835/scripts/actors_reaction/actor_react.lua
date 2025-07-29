local util = require("openmw.util")
local types = require("openmw.types")
local Actor = types.Actor
local nearby = require("openmw.nearby")
local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local async = require("openmw.async")


-- Distance max to be alerted by a combat: If there is a combat at a distance < alertDistMax, the actor is alerted (so he's going to travel towards the combat)
local alertDistMax = 1638

-- Distance to combat for the actors: each "non-fighter" tries to keep this distance between him and the fighters.
local actorsDistance = 500

-- Maximum move for an actor: if the distance between his starting point and his actual position is more than maxMove, he comes back to his starting point
local maxMove = 4000

-- Blacklist to exclude some actors from the scope of this mod.
-- By default i put the common wildlife creatures.
-- You can modify this list as you want (you must use the ID of the actor, in lowercase).
local blacklistedActors = {
	["alit"] = true,
	["alit_blighted"] = true,
	["alit_diseased"] = true,
	["bm_bear_black"] = true,
	["bm_bear_brown"] = true,
	["bm_frost_boar"] = true,
	["bm_wolf_grey"] = true,
	["bm_wolf_grey_lvl_1"] = true,
	["bm_wolf_red"] = true,
	["cliff racer"] = true,
	["cliff racer_blighted"] = true,
	["cliff racer_diseased"] = true,
	["dreugh"] = true,
	["guar"] = true,
	["guar_feral"] = true,
	["guar_pack"] = true,
	["kagouti"] = true,
	["kagouti_mating"] = true,
	["kagouti_blighted"] = true,
	["kagouti_diseased"] = true,
	["kwama forager"] = true,
	["kwama forager blighted"] = true,
	["kwama warrior"] = true,
	["kwama warrior blighted"] = true,
	["kwama warrior shurdan"] = true,
	["kwama worker"] = true,
	["kwama worker entrance"] = true,
	["kwama worker blighted"] = true,
	["kwama worker diseased"] = true,
	["mudcrab"] = true,
	["mudcrab-diseased"] = true,
	["mudcrab_hrmudcrabnest"] = true,
	["netch_betty"] = true,
	["netch_betty_ranched"] = true,
	["netch_bull"] = true,
	["netch_bull_ranched"] = true,
	["nix-hound"] = true,
	["nix-hound blighted"] = true,
	["rat"] = true,
	["rat_cave_fgrh"] = true,
	["rat_cave_fgt"] = true,
	["rat_blighted"] = true,
	["rat_diseased"] = true,
	["rat_plague"] = true,
	["rat_plague_hall1"] = true,
	["rat_plague_hall1a"] = true,
	["scrib"] = true,
	["scrib blighted"] = true,
	["scrib diseased"] = true,
	["shalk"] = true,
	["shalk_blighted"] = true,
	["shalk_diseased"] = true,
	["slaughterfish"] = true,
	["slaughterfish_small"] = true,
}


local targetDist
local combatDist
local preTarget
local target_
local startCell
local startPosition
local myPosition
local myPositionHigh

local opponent
local opponent_position
local combat_position

local destPosHigh
local destPos

local goBack, goingBack
local newPos

local baptism

local Stats = Actor.stats
local Hello = Stats.ai.hello(self)
local Speed = Stats.attributes.speed(self)
local baseSpeed = Speed.base

local function onSave()
    return {
        T = target_,
        GB = goBack,
        GoiB = goingBack,
        NP = newPos,
        SP = startPosition,
        SC = startCell,
    }
end

local function onLoad(data)
	if data then
		target_ = data.T
		goBack = data.GB
		goingBack = data.GoiB
		newPos = data.NP
		startPosition = data.SP
		startCell = data.SC

	-- correction for old mod versions "corrupted" save 
		if data.T == nil then
			if data.SP == nil then
				startPosition = self.position
			end
			if Hello.modifier < -500 then
				target_ = self
			end
		elseif Hello.modifier < -1500 then
			Hello.modifier = Hello.modifier + 1000
			Speed.modifier = Speed.modifier - baseSpeed
		end
	elseif Hello.modifier < -500 then
		target_ = self
		startPosition = self.position
	end
	
	-- Init for the new startCell variable
	if not startCell and startPosition then
		startCell = self.cell.name
	end
end

local function resetTarget()
	if goBack then -- (if "goBack" order, we start a travel toward the start position (to be sure to retrieve the start position at the end of combat))
		goBack = nil
		--newPos = nil
		activePackage = ai.getActivePackage()
		if activePackage and activePackage.type == "Travel" then
			ai.startPackage({
				type = 'Travel',
				destPosition = startPosition,
				cancelOther = false,
			})
		else -- but if the AI package has changed (!= Travel), we are in the unknown, so we reinit the actor status
			target_ = nil
			ai.removePackages("Travel")
			Hello.modifier = Hello.modifier + 1000
			Speed.modifier = Speed.modifier - baseSpeed
			goingBack = nil
		end
	else -- (it is time to reinit the actor status)
		target_ = nil
		ai.removePackages("Travel")
		Hello.modifier = Hello.modifier + 1000
		Speed.modifier = Speed.modifier - baseSpeed
		goingBack = nil
	end
end

local function TargetTest()
	if target_ then
		local delay = 9 + math.random() * 2
		async:newUnsavableSimulationTimer(delay, resetTarget) -- every 10s we check for a "return back" or a "reinit"
		async:newUnsavableSimulationTimer(delay + 0.1, TargetTest)
	else
		async:newUnsavableSimulationTimer(1, TargetTest)
	end
end

async:newUnsavableSimulationTimer(1, TargetTest)


return {
    engineHandlers = {
		onLoad = onLoad,
		onSave = onSave
    },
    eventHandlers = {
        combat_detected = function(e)
		
			local Aggr = e.aggr
			local Vict = e.vict
			local activePackage = ai.getActivePackage()
			if blacklistedActors[self.recordId]
			 or Aggr.id == self.id or Vict.id == self.id or not Actor.canMove(self)
			 or (activePackage ~= nil and activePackage.type ~= "Wander"
			  and activePackage.type ~= "Unknown"
			  and (activePackage.type ~= "Travel" or target_ == nil)) -- ("or actor has active package other than "Wander", "Unknown" or this mod "Travel" ")
			 or goingBack == 1 -- or actor is going back
			 or not Actor.isInActorsProcessingRange(Vict) then -- or defensor isn't in the scene (aggressor is treated below...)
				return
			end
			
			myPosition = self.position
			targetDist = (myPosition - Aggr.position):length() -- distance to the aggressor
			local victimReady = Actor.getStance(Vict)
			-- Prevention of an undesirable situation
			-- (don't react around the victim if aggressor isn't around...):
			if targetDist > alertDistMax and ((Vict.type ~= types.Player and victimReady == 0) or (Vict.type == types.Player and (Aggr.position - Vict.position):length() > 1638)) then
				return
			end
			
			victDist = (myPosition - Vict.position):length()
			if victDist < targetDist then
				targetDist = victDist
				preTarget = Vict
				opponent = Aggr
			else
				preTarget = Aggr
				opponent = Vict
			end
			if targetDist > alertDistMax -- this targetDist variable is the distance to the nearest of the 2 opponents
			 or (target_ and Aggr ~= target_ and Vict ~= target_ -- "or if this is another fight
			  and targetDist > (myPosition - target_.position):length()) then -- but it is not enough close
																	--to change my business with the first one, then..."
					return
			end
			-- Now we know that this actor checks all the conditions, and is going to be moved by this mod

			if target_ == nil then
				-- an actor don't say hello next to a combat:
				Hello.modifier = Hello.modifier - 1000
				-- walking (Travel) x 2 to simulate the alarming situation:
				Speed.modifier = Speed.modifier + baseSpeed
				if not startCell or startCell ~= self.cell.name then -- init of the start position
					startPosition = myPosition
					--newPos = 1
					startCell = self.cell.name
				end
			end
			
			target_ = preTarget
			local target_position = target_.position

			if startPosition == nil then -- correction for old mod versions "corrupted" save
			    startPosition = myPosition
			    --newPos = 1
			end
			
			if (myPosition - startPosition):length() > maxMove then -- "if actor has moved too far, then..."
				goBack, goingBack = 1, 1 -- goBack order + startposition travel is going to begin...
				destPos = startPosition
				
			elseif targetDist > actorsDistance + 200 then -- "Since i'm not close to the target/fight, i'm going in his direction"...
				destPos = target_position
				baptism = nil
				goBack = 1 -- goBack order (for later) to be sure to retrieve the start position at the end of combat

			elseif targetDist > actorsDistance and baptism then -- "Since i'm close to the target/fight, but not too much, and since i had my "baptism of the fire", i stay around"...
				
				--myPositionCenteredFct()
				destPos = myPosition
				goBack = 1 -- goBack order (for later) to be sure to retrieve the start position at the end of combat
				
			else -- "i'm too close to the fight, so i'm going to try to move away"...

				baptism = true -- (baptism of the fire... - We want a "baptism" for the actor...)
			
				opponent_position = opponent.position
				
				-- The center of the combat
				combat_position = util.vector3((target_position.x + opponent_position.x) / 2,
											(target_position.y + opponent_position.y) / 2,
											(target_position.z + opponent_position.z) / 2)
				--combatDist = (combat_position - myPosition):length()
				
				destPos = util.vector3(2 * myPosition.x - combat_position.x, -- "...i'm going to
										2 * myPosition.y - combat_position.y, -- walk away from
										2 * myPosition.z - combat_position.z) -- the combat"
				
				-- Is there a NavMesh Position near?...
				destPos = nearby.findNearestNavMeshPosition(destPos, {
						agentBounds = Actor.getPathfindingAgentBounds(self),
					})
				
				-- If yes, ...
				if destPos then
				
					-- test if this navmesh position isn't behind a wall (for example)

					myPositionHigh = util.vector3(myPosition.x, myPosition.y, myPosition.z + 100)

					destPosHigh = util.vector3(destPos.x, 
											destPos.y,
											destPos.z + 100)
					-- If no impact, it's ok...
					if not nearby.castRay(myPositionHigh, destPosHigh, {
						ignore=self,
						collisionType=nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door,
					}).hit then -- it's ok.
						goBack = 1 -- goBack order (for later) to be sure to retrieve the start position at the end of combat
					end
				else
					destPos = myPosition
					goBack = 1 -- goBack order (for later) to be sure to retrieve the start position at the end of combat
				end
			end
			
			ai.startPackage({
				type = 'Travel',
				destPosition = destPos,
				cancelOther = false,
			})
        end
    }
}
