local util = require("openmw.util")
local types = require("openmw.types")
local Actor = types.Actor
local nearby = require("openmw.nearby")
local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local self = require("openmw.self")
local ai = require("openmw.interfaces").AI

local async = require("openmw.async")

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

local combatDist
local preTarget
local target_
local targetPos
local goBack, goingBack
local newPos
local startPosition
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
    }
end

local function onLoad(data)
	if data then
		target_ = data.T
		goBack = data.GB
		goingBack = data.GoiB
		newPos = data.NP
		startPosition = data.SP
    
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
end

local function resetTarget()
	if goBack then -- (if actor is going back, i let him 10 more seconds...)
		goBack = nil
		newPos = nil
	else
		target_ = nil
		ai.removePackages("Travel")
		Hello.modifier = Hello.modifier + 1000
		Speed.modifier = Speed.modifier - baseSpeed
		goingBack = nil
	end
end

local function TargetTest()
	if target_ then
		async:newUnsavableSimulationTimer(10, resetTarget) -- every 10s i remove this mod Travel package
		async:newUnsavableSimulationTimer(10.1, TargetTest)
	else
		async:newUnsavableSimulationTimer(1, TargetTest)
	end
end

--local function print_()
--	if self.recordId == "fargoth"
--	 or self.recordId == "indrele rathryon"
--	  or self.recordId == "vodunius nuccius"
--	   or self.recordId == "eldafire"
--	    or self.recordId == "teleri helvi"
--	     or self.recordId == "darvame hleran"
--	     or self.recordId == "maurrie aurmine"
--	      or self.recordId == "imperial guard" then
--		print(self.recordId)
--		if ai.getActivePackage() then
--			print(ai.getActivePackage())
--			print(ai.getActivePackage().type)
--		end
--	end
--	async:newUnsavableSimulationTimer(1, print_)
--end

async:newUnsavableSimulationTimer(1, TargetTest)
--async:newUnsavableSimulationTimer(1, print_)

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
			
			local myPosition = self.position
			combatDist = (myPosition - Aggr.position):length() -- distance to the aggressor
			-- Prevention of an undesirable situation
			-- (actor reacts next to the victim despite the fact aggressor is not around):
			if combatDist > 1638 then return end
			
			victDist = (myPosition - Vict.position):length()
			if victDist < combatDist then
				combatDist = victDist
				preTarget = Vict
			else
				preTarget = Aggr
			end
			if combatDist > 1638 -- this combatDist variable is the distance to the nearest of the 2 opponents
			 or (target_ and Aggr ~= target_ and Vict ~= target_ -- "or if this is another fight
			  and combatDist + 500 > (myPosition - target_.position):length()) then -- but it is not enough close
																	--to change my business with the first one, then..."
					return
			end
			-- Now we know that this actor checks all the conditions, and is going to be moved by this mod

			if target_ == nil then
				-- an actor don't say hello next to a combat:
				Hello.modifier = Hello.modifier - 1000
				-- walking (Travel) x 2 to simulate the alarming situation:
				Speed.modifier = Speed.modifier + baseSpeed
				if newPos == nil then
					startPosition = myPosition
					newPos = 1
				end
			end
			
			target_ = preTarget
			local target_position = target_.position

			if startPosition == nil then -- correction for old mod versions "corrupted" save
			    startPosition = myPosition
			    newPos = 1
			end
			if (myPosition - startPosition):length() > 4000 then -- "if actor has moved too far, then..."
				goBack, goingBack = 1, 1
				targetPos = startPosition
			elseif combatDist > 500 then
				targetPos = target_position
			else -- "i'm too close from the fight, so..."
				targetPos = util.vector3(2 * myPosition.x - target_position.x, -- "...i'm going to
										2 * myPosition.y - target_position.y, -- walk away from
										2 * myPosition.z - target_position.z) -- the target/fight"
				
				local status, path = nearby.findPath(myPosition, targetPos) -- data of the theorical path
				if status ~= nearby.FIND_PATH_STATUS.Success then -- if path isn't valid
					targetPos = myPosition -- then this actor stay where he is
				end
			end
			
			ai.startPackage({
				type = 'Travel',
				destPosition = targetPos,
				cancelOther = false,
				--isRepeat = true
			})
        end
    }
}
