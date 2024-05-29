-- Note: all Ids must be in _lowercase_

local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local async = require("openmw.async")

local core = require("openmw.core")
local nearby = require("openmw.nearby")

local aux_util = require("openmw_aux.util")

local old_API = core.API_REVISION < 59


-- For old OpenMW 0.49 versions (API < 59 (< april 2024)):
-- Preset fight value for wildlife creatures that we cannot check in live:
-------------------------------------------------------------------------
local oldAPIcreatures_fightV = {
	["alit_blighted"] = 90, -- Morrowind: 90, More Passive Wildlife mod: 90
	["alit_diseased"] = 90, -- Morrowind: 90, More Passive Wildlife mod: 85
	["cliff racer_blighted"] = 90, -- Morrowind: 90
	["cliff racer_diseased"] = 90, -- Morrowind: 90
	["kagouti_blighted"] = 90, -- Morrowind: 90, More Passive Wildlife mod: 90
	["kagouti_diseased"] = 90, -- Morrowind: 90, More Passive Wildlife mod: 85
	["kwama forager blighted"] = 85, -- Morrowind: 85, More Passive Wildlife mod: 90
	["kwama warrior blighted"] = 90, -- Morrowind: 90, More Passive Wildlife mod: 90
	["kwama warrior shurdan"] = 90, -- Morrowind: 90
	["kwama worker blighted"] = 90, -- Morrowind: 90, More Passive Wildlife mod: 90
	["kwama worker diseased"] = 50, -- Morrowind: 50
	["mudcrab-diseased"] = 83, -- Morrowind: 83, More Passive Wildlife mod: 81
	["netch_betty_ranched"] = 30, -- Morrowind: 30
	["netch_bull_ranched"] = 30, -- Morrowind: 30
	["nix-hound blighted"] = 90, -- Morrowind: 90, More Passive Wildlife mod: 90
	["rat_blighted"] = 85, -- Morrowind: 85, More Passive Wildlife mod: 90
	["rat_diseased"] = 85, -- Morrowind: 85, More Passive Wildlife mod: 85
	["rat_plague"] = 85, -- Morrowind: 85
	["rat_plague_hall1"] = 85, -- Morrowind: 85
	["rat_plague_hall1a"] = 85, -- Morrowind: 85
	["scrib blighted"] = 50, -- Morrowind: 50, More Passive Wildlife mod: 95
	["scrib diseased"] = 50, -- Morrowind: 50
	["shalk_blighted"] = 90, -- Morrowind: 90
	["shalk_diseased"] = 90, -- Morrowind: 90
-----------------------------------------------------------------------
	["alit"] = "fight_tokens",
	["bm_bear_black"] = "fight_tokens",
	["bm_bear_brown"] = "fight_tokens",
	["bm_frost_boar"] = "fight_tokens",
	["bm_wolf_grey"] = "fight_tokens",
	["bm_wolf_grey_lvl_1"] = "fight_tokens",
	["bm_wolf_red"] = "fight_tokens",
	["cliff racer"] = "fight_tokens",
	["dreugh"] = "fight_tokens",
	["guar"] = "fight_tokens",
	["guar_feral"] = "fight_tokens",
	["guar_pack"] = "fight_tokens",
	["kagouti"] = "fight_tokens",
	["kagouti_mating"] = "fight_tokens",
	["kwama forager"] = "fight_tokens",
	["kwama warrior"] = "fight_tokens",
	["kwama worker"] = "fight_tokens",
	["kwama worker entrance"] = "fight_tokens",
	["mudcrab"] = "fight_tokens",
	["mudcrab_hrmudcrabnest"] = "fight_tokens",
	["netch_betty"] = "fight_tokens",
	["netch_bull"] = "fight_tokens",
	["nix-hound"] = "fight_tokens",
	["rat"] = "fight_tokens",
	["rat_cave_fgrh"] = "fight_tokens",
	["rat_cave_fgt"] = "fight_tokens",
	["scrib"] = "fight_tokens",
	["shalk"] = "fight_tokens",
	["slaughterfish"] = "fight_tokens",
	["slaughterfish_small"] = "fight_tokens",
}

-- For new OpenMW 0.49 versions (API >= 59 (>= april 2024)):
local newAPIcreatures_fightV = {
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

-- Blacklist example for NPCs not to be attacked.
-- Change and add as you want.
-- To activate the blacklist, see my explanation below in the code.
local NPCsBlacklist = {
	["fargoth"] = true,
	["vodunius nuccius"] = true,
	-- ...
}
	
local wildlife
local fightV
local nearestNPC, distToNPC


local function wildlifeAtk()

	if wildlife == "no" then return end
	
	async:newUnsavableSimulationTimer(3, wildlifeAtk)

	if types.Actor.stats.dynamic.health(self).current < 1
	  or (ai.getActivePackage() ~= nil and ai.getActivePackage().type ~= "Wander" and ai.getActivePackage().type ~= "Unknown") then
		return
	end
	
  if old_API then

	fightV = oldAPIcreatures_fightV[self.recordId]
	
	if fightV == "fight_tokens" then
		fightV = types.Actor.inventory(self):countOf("ll_fight_token")
	elseif fightV == nil then
		wildlife = "no"
		return
	end
	
  else

	if newAPIcreatures_fightV[self.recordId] then
		fightV = types.Actor.stats.ai.fight(self).modified
	else
		wildlife = "no"
		return
	end

  end


	-- Find the nearest alive NPC
	nearestNPC, distToNPC = aux_util.findMinScore(
		nearby.actors,
		function(actor)
			return actor.type == types.NPC and types.Actor.isDead(actor) == false and (self.position - actor.position):length()
		end)
	
	-- Optionnal NPCs blacklist.
	-- To activate the blacklist, remove "--" from the begining of the next line.
	-- if NPCsBlacklist[nearestNPC.recordId] then return end
	
	if distToNPC and distToNPC < (fightV - 80) * 200 then
           ai.startPackage({
               type = "Combat",
               target = nearestNPC,
               cancelOther = false
           })
	end

--print("*****************************")
--print("crea:")
--print(self)
--print("distToNPC:")
--print(distToNPC)
--print("fightV:")
--print(fightV)

  return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave
    }
  }
end

async:newUnsavableSimulationTimer(1, wildlifeAtk)
