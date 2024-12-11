
local self = require("openmw.self")
local types = require("openmw.types")
local Actor = types.Actor
local dynamicStats = Actor.stats.dynamic
local selfRecord = types.Creature.record(self)
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local trans = util.transform
--local nearby = require('openmw.nearby')

local biped = selfRecord.isBiped
local walk = selfRecord.canWalk

local stdSize = 124
local newPosition

local creatureSizes = {
	["almelexia.nif"] = 1,
	["almelexia_warrior.nif"] = 0.99,
	["ancestorghost.nif"] = 1,
	["ascendedsleeper.nif"] = 1.07,
	["ashghoul.nif"] = 1.08,
	["ashslave.nif"] = 1.04,
	["ashvampire.nif"] = 1.2,
	["ashzombie.nif"] = 1.03,
	["atronach_fire.nif"] = 1.17,
	["atronach_frost.nif"] = 1.31,
	["atronach_storm.nif"] = 1.31,
	["babelfish.nif"] = 0, -- Exclusively aquatic life must not be affected by this mod
	["bear_black_larger.nif"] = 1.54,
	["bear_blond_larger.nif"] = 1.03,
	["bear_brown_larger.nif"] = 1.54,
	["bonelord.nif"] = 1.16,
	["bonewalker.nif"] = 1.11,
	["byagram.nif"] = 0.77, -- theoriticaly 0.88, but Yagrum can't jump out of water
	["cavemudcrab.nif"] = 0.61,
	["clannfear.nif"] = 1,
	["clannfear_daddy.nif"] = 1.44,
	["cliffracer.nif"] = 2.21,
	["corprus_stalker.nif"] = 1.03,
	["cr_draugr.nif"] = 1.15,
	["daedroth.nif"] = 1,
	["dagothr.nif"] = 1.40,
	["draugrlord.nif"] = 1.15,
	["dremora.nif"] = 1,
	["dreugh.nif"] = 0, -- Exclusively aquatic life must not be affected by this mod
	["durzog.nif"] = 0.84,
	["durzog_collar.nif"] = 0.84,
	["duskyalit.nif"] = 0.94,
	["dwarvenspecter.nif"] = 1,
	["fabricant.nif"] = 0, -- theoriticaly 1, but this mod doesn't give them (mechanical creatures) ability to move up in water
	["fabricant_hulking.nif"] = 0, -- theoriticaly 0.88, but this mod doesn't give them (mechanical creatures) ability to move up in water
	["fabricant_imperfect.nif"] = 0, -- theoriticaly 2.04, but this mod doesn't give them (mechanical creatures) ability to move up in water
	["frostgiant.nif"] = 1.98,
	["g_centurionspider.nif"] = 0, -- this mod doesn't give them (mechanical creatures) ability to move up in water
	["goblin01.nif"] = 0.84,
	["goblin02.nif"] = 0.82,
	["goblin03.nif"] = 1.23,
	["golden saint.nif"] = 1,
	["greatbonewalker.nif"] = 1.08,
	["guar.nif"] = 1.20,
	["guar_white.nif"] = 1.20,
	["guar_withpack.nif"] = 1.20,
	["heart_akulakhan.nif"] = 0, -- the Heart don't move in water
	["hircine.nif"] = 0.98,
	["hircine_bear_larger.nif"] = 2.06,
	["hircinewolf.nif"] = 1.07,
	["horker.nif"] = 0.4,
	["horker_larger.nif"] = 0.89,
	["hunger.nif"] = 0.85,
	["ice troll.nif"] = 1.26,
	["iceminion.nif"] = 0.60,
	["iceminion2.nif"] = 0.60,
	["icemraider.nif"] = 0.57,
	["kwama forager.nif"] = 0.43,
	["kwama queen.nif"] = 1.28,
	["kwama warior.nif"] = 1.15,
	["kwama worker.nif"] = 0.72,
	["lame_corprus.nif"] = 0.92,
	["leastkagouti.nif"] = 1.20,
	["liche.nif"] = 1,
	["liche_king.nif"] = 1,
	["lordvivec.nif"] = 1.01,
	["minescrib.nif"] = 0.32,
	["mount.nif"] = 0.57,
	["netch_betty.nif"] = 1.63,
	["netch_bull.nif"] = 3.07,
	["nixhound.nif"] = 0.87,
	["packrat.nif"] = 0.46,
	["raven.nif"] = 0.5,
	["rust rat.nif"] = 0.45,
	["scamp_fetch.nif"] = 0.85,
	["shalk.nif"] = 0.37,
	["skeleton.nif"] = 1,
	["slaughterfish.nif"] = 0, -- Exclusively aquatic life must not be affected by this mod
	["sphere_centurions.nif"] = 0, -- this mod doesn't give them (mechanical creatures) ability to move up in water
	["spherearcher.nif"] = 0, -- this mod doesn't give them (mechanical creatures) ability to move up in water
	["spriggan.nif"] = 1.01,
	["steam_centurions.nif"] = 0, -- this mod doesn't give them (mechanical creatures) ability to move up in water
	["swimmer.nif"] = 1.62,
	["udyrfrykte.nif"] = 0.93,
	["undeadwolf_2.nif"] = 0.63,
	["wingedtwilight.nif"] = 0.99,
	["wolf_black.nif"] = 0.63,
	["wolf_red.nif"] = 0.63,
	["wolf_white.nif"] = 0.88,
	["skinnpc.nif"] = 1,
}

local NIFscales = {
	["ancestor_ghost_greater"] = 1.3,
	["bm_bear_black_fat"] = 1.55 / 1.5,
	["bm_bear_snow_unique"] = 1.7,
	["bm_bear_spr_unique"] = 1.2,
	["bonewalker_weak"] = 0.8,
	["ogrim titan"] = 1.3,
	["ogrim titan_velas"] = 1.25,
	["dremora_lord_khash_uni"] = 1.25,
	["fabricant_hulking_c_l"] = 1.3,
	["goblin_officeruni"] = 1 / 1.5,
	["bm_hircine"] = 1.5,
	["bm_hircine2"] = 1.9,
	["bm_icetroll_fg_uni"] = 1.2,
	["netch_giant_unique"] = 1.25,
	["dead rat"] = 0.5,
	["rat_diseased"] = 0.5,
	["rat_plague"] = 0.5,
	["rat_plague_hall1"] = 0.5,
	["rat_plague_hall1a"] = 0.5,
	["rat_plague_hall2"] = 0.5,
	["rat_rerlas"] = 0.5,
	["bm_skeleton_pirate_capt"] = 1.2,
	["skeleton nord "] = 1.1, -- the final space is needed
	["skeleton nord_2"] = 1.1,
	["skeleton_stahl_uni"] = 1.1,
	["centurion_steam_a_c"] = 1.2,
	["centurion_steam_advance"] = 1.2,
	["centurion_steam_c_l"] = 1.5,
}

local size
local Model = string.match(selfRecord.model, '.*\\(.+)')
if Model == nil then Model = "no_model" end -- theoriticaly impossible case

Model = Model:lower()
size = creatureSizes[Model]
if size == nil then -- we don't know this creature
	if selfRecord.canSwim and not walk and not biped and not selfRecord.canFly then
		size = 0 -- we don't deal with pure aquatic life 
	else
		size = 1.1 -- If we don't know the creature we take the size of a high elf
		size = size * stdSize
	end
else
	size = size * stdSize
	local nifScale = NIFscales[self.recordId]
	if nifScale then size = size * nifScale end
end
		

local function waterCheck()

	async:newUnsavableSimulationTimer(3 + math.random() * 2, waterCheck) -- (we try every 3-5 seconds)

	if not Actor.isSwimming(self) or size == 0 then
		return
	end
	
	local Cell = self.cell
	local Position = self.position
	local posZ = Position.z
	local finalSize = size * self.scale
	
	if (walk or biped) and Actor.canMove(self) and posZ > Cell.waterLevel - finalSize then -- (actor is near the surface)

		local fromActorSpace = trans.move(Position) * trans.rotateZ(self.rotation:getYaw()) -- y axis -> actor front
		newPosition = fromActorSpace * util.vector3(0, finalSize * 0.25, finalSize * 0.9) -- move up + size*0.9, move front + size*0.25
		dynamicStats.fatigue(self).current = dynamicStats.fatigue(self).current - 5 -- jumping out of water cause fatigue loss...

		--testPosition = nearby.findNearestNavMeshPosition(newPosition, {
		--searchAreaHalfExtents = util.vector3(100, 100, 100),
			--includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
		--})

	else -- (actor is below the surface)
		newPosition = util.vector3(Position.x,
									Position.y,
									posZ + 20)
	end
	
	core.sendGlobalEvent('Move', {
		actor = self,
		cell = Cell.name,
		position = newPosition,
	})
	
end

return {
    engineHandlers = {
        onActive = async:newUnsavableSimulationTimer(3 + math.random() * 2, waterCheck),
    }
}
