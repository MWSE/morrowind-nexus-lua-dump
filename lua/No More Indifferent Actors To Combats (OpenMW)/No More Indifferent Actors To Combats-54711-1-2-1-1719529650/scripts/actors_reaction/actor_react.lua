local util = require("openmw.util")
local types = require("openmw.types")
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
local startPosition, startPositionV3
local actorSpeed = types.Actor.stats.attributes.speed(self).base

local function onSave()
    return {
        T = target_,
        GB = goBack,
        GoiB = goingBack,
        NP = newPos,
        SP = startPosition,
        SPV3 = startPositionV3
    }
end

local function onLoad(data)
	if data then
		target_ = data.T
		goBack = data.GB
		goingBack = data.GoiB
		newPos = data.NP
		startPosition = data.SP
		startPositionV3 = data.SPV3
    
	-- correction for old mod versions "corrupted" save 
		if data.T == nil then
			if data.SP == nil then
				startPosition = self.position
				startPositionV3 = util.vector3(self.position.x, self.position.y, self.position.z)
			end
			if types.Actor.stats.ai.hello(self).modifier < -500 then
				target_ = self
			end
		elseif types.Actor.stats.ai.hello(self).modifier < -1500 then
			types.Actor.stats.ai.hello(self).modifier = types.Actor.stats.ai.hello(self).modifier + 1000
			types.Actor.stats.attributes.speed(self).modifier = types.Actor.stats.attributes.speed(self).modifier - actorSpeed
		end
	elseif types.Actor.stats.ai.hello(self).modifier < -500 then
		target_ = self
		startPosition = self.position
		startPositionV3 = util.vector3(self.position.x, self.position.y, self.position.z)
	end
end

local function resetTarget()
	if goBack then -- (if actor is going back, i let him 10 more seconds...)
		goBack = nil
		newPos = nil
	else
		target_ = nil
		ai.removePackages("Travel")
		types.Actor.stats.ai.hello(self).modifier = types.Actor.stats.ai.hello(self).modifier + 1000
		types.Actor.stats.attributes.speed(self).modifier = types.Actor.stats.attributes.speed(self).modifier - actorSpeed
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
		
			if blacklistedActors[self.recordId]
			 or e.aggr.id == self.id or e.vict.id == self.id or types.Actor.isDead(self)
			 or (ai.getActivePackage() ~= nil and ai.getActivePackage().type ~= "Wander"	-- if actor has no active package
			  and ai.getActivePackage().type ~= "Unknown"									-- or "Unknown" or "Wander"
			  and (ai.getActivePackage().type ~= "Travel" or target_ == nil))				-- or this mod "Travel"
			 or goingBack == 1 then															-- or actor isn't going back, then ok, else return
					return
			end
			
			combatDist = (self.position - e.aggr.position):length()
			victDist = (self.position - e.vict.position):length()
			if victDist < combatDist then
				combatDist = victDist
				preTarget = e.vict
			else
				preTarget = e.aggr
			end
			if combatDist > 1638 
			 or (target_ and e.aggr ~= target_ and e.vict ~= target_ -- "or if there is another fight
			  and combatDist + 500 > (self.position - target_.position):length()) then -- but it is not enough close
																	--to change my business with the first one, then..."
					return
			end
			-- Now we know that this actor checks all the conditions, and is going to be moved by this mod
			
			if target_ == nil then
				-- an actor don't say hello next to a combat:
				types.Actor.stats.ai.hello(self).modifier = types.Actor.stats.ai.hello(self).modifier - 1000
				-- walking (Travel) x 2 to simulate the alarming situation:
				types.Actor.stats.attributes.speed(self).modifier = types.Actor.stats.attributes.speed(self).modifier + actorSpeed
				if newPos == nil then
					startPosition = self.position
					startPositionV3 = util.vector3(self.position.x, self.position.y, self.position.z)
					newPos = 1
				end
			end
			
			target_ = preTarget

			if (self.position - startPosition):length() > 4000 then -- "if actor has moved too far, then..."
				goBack, goingBack = 1, 1
				targetPos = startPositionV3
			elseif combatDist > 500 then
				targetPos = util.vector3(target_.position.x, target_.position.y, target_.position.z)
			else -- "i'm too close from the fight, so..."
				targetPos = util.vector3(2 * self.position.x - target_.position.x, -- "...i'm going to
										2 * self.position.y - target_.position.y, -- walk away from
										2 * self.position.z - target_.position.z) -- the target/fight"
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
