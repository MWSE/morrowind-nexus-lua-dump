
local self = require("openmw.self")
local types = require("openmw.types")
local selfRecord = types.Creature.record(self)
local canFly = selfRecord.canFly
-- We exclude from this mod the creature that aren't biped and who can't walk and who can't fly
-- (So kwama queens and fishes are excluded, for example)
if not selfRecord.canWalk and not selfRecord.isBiped and not canFly then return end

local Actor = types.Actor
local ActorSpells = Actor.activeSpells(self)
local fatigue = Actor.stats.dynamic.fatigue(self)
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require('openmw.nearby')
local AI = require('openmw.interfaces').AI
local trans = util.transform
local recordId = self.recordId


-- A Levitate effect is applied to simulate a part of the "jumps", and a
-- part of the "out of the water" feature.
-- If you want to change the speed of the Levitate effect (so the
-- distance travelled), you can choose between ll_fly1, ll_fly2, ll_fly5,
-- ll_fly10, ll_fly20, ll_fly50, ll_fly100, and ll_fly200.
-- Note that below 50 it will be impossible to some slow creatures
-- (Ascended Sleeper, for example) to get out water.
-- ll_fly50 is the recommended effect for creatures.
local LevitateSpell = "ll_fly50"

-- Blacklist to exclude some creatures from the obstacles overcoming (they won't "jump", and they won't get out water. But they still rise to the surface (if underwater)).
-- (If you edit, write the name of the creature NIF file, and/or the creature ID, in lowercase, like the default below)
local blacklist = {
	-- Blacklisting by NIF file
	["sphere_centurions.nif"] = true, -- Centurion Spheres aren't designed to "jump" or to get out water
	["spherearcher.nif"] = true, -- Centurion Archers aren't designed to "jump" or to get out water
	-- Blacklisting by ID
	["corprus_stalker_fgcs"] = true, -- Berwen corprus stalker can't jump over the box
}

-- If you want less frequent "jumps", rise the "pauseCycles" value below
-- 0 (default): creatures will "jump" (if all conditions are met) every 3s (approx)
-- 1: creatures will "jump" (if all conditions are met) every 4s (approx)
-- 2: creatures will "jump" (if all conditions are met) every 5.5s (approx)
-- 3: creatures will "jump" (if all conditions are met) every 7s (approx)
-- ...
-- 10: creatures will "jump" (if all conditions are met) every 17s (approx)
-- ...
local pauseCycles = 0


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
	--["babelfish.nif"] = ?, -- Excluded from this mod because they aren't biped, they dont walk and they don't fly
	["bear_black_larger.nif"] = 1.54,
	["bear_blond_larger.nif"] = 1.03,
	["bear_brown_larger.nif"] = 1.54,
	["bonelord.nif"] = 1.16,
	["bonewalker.nif"] = 1.11,
	["byagram.nif"] = 0.44, -- theoriticaly 0.88, but Yagrum isn't agile. With a value divided by 2, Yagrum won't jump far... And a reduction like this exclude him from the "out of water" possibility.
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
	--["dreugh.nif"] = ?, -- Excluded from this mod because they aren't biped, they dont walk and they don't fly
	["durzog.nif"] = 0.84,
	["durzog_collar.nif"] = 0.84,
	["duskyalit.nif"] = 0.94,
	["dwarvenspecter.nif"] = 1,
	["fabricant.nif"] = 1,
	["fabricant_hulking.nif"] = 0.88,
	["fabricant_imperfect.nif"] = 2.04,
	["frostgiant.nif"] = 1.98,
	["g_centurionspider.nif"] = 0.61,
	["goblin01.nif"] = 0.84,
	["goblin02.nif"] = 0.82,
	["goblin03.nif"] = 1.23,
	["golden saint.nif"] = 1,
	["greatbonewalker.nif"] = 1.08,
	["guar.nif"] = 1.20,
	["guar_white.nif"] = 1.20,
	["guar_withpack.nif"] = 1.20,
	--["heart_akulakhan.nif"] = ?, -- Excluded from this mod because it isn't biped, it doesn't walk and it don't fly
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
	--["slaughterfish.nif"] = ?, -- Excluded from this mod because they aren't biped, they dont walk and they don't fly
	["sphere_centurions.nif"] = 1.17,
	["spherearcher.nif"] = 1.17,
	["spriggan.nif"] = 1.01,
	["steam_centurions.nif"] = 1.08,
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



local stdSize = 124
local testPosition
local newPosition
local backedPosition
local ArchiPush = 20
local coverDist
local walkSpeed
local testX, testY, testZ, destX, destY, destZ
local jumpTests = {1, 2, 3, 4, 5, 6, 7, 8}
local safe
local random7_7 = {7, -7}
local lastEffortToGetOutWater
local pause = pauseCycles

local size
local Model = string.match(selfRecord.model, '.*[/\\](.+%.[nN][iI][fF])')
if Model == nil then Model = "no_model" end -- theoriticaly impossible case
Model = Model:lower()

-- We determine the size of the creature
size = creatureSizes[Model]
if size == nil then -- we don't know this creature
	size = 1.1 -- If we don't know the creature we take the size of a high elf
	size = size * stdSize
else
	size = size * stdSize
	local nifScale = NIFscales[self.recordId]
	if nifScale then size = size * nifScale end
end


-- We remove the levitation effect we had given to the creature
local function stopLevit()
	for _, spell in pairs(ActorSpells) do
		if spell.id == LevitateSpell then
			ActorSpells:remove(spell.activeSpellId)
			break
		end
	end
end


local function obstacleCheck()

	async:newUnsavableSimulationTimer(1.3 + math.random() * 0.2, obstacleCheck) -- (we check every 1.3-1.5 seconds)

	if not Actor.isInActorsProcessingRange(self) then return end
	
	if pause > 0 then
		pause = pause -1
		return
	end
	
	local finalSize = size * self.scale
	local Position = self.position
	local posZ = Position.z
	local posY = Position.y
	local posX = Position.x
	local Cell = self.cell

	-- If we have to finish the "get out water" try, we make a little teleportation to simulate this
	if lastEffortToGetOutWater then
		lastEffortToGetOutWater = nil

		testPosition = util.vector3(posX, posY, posZ + finalSize * 1.5) -- Test position to check if there is enough space
			
		if not nearby.castRay(Position, testPosition, {ignore=self}).hit then -- if no collision, we can do the "last effort" (teleportation)
			newPosition = util.vector3(posX, posY, posZ + finalSize * 0.5)
			
			-- We send a teleportation order
			core.sendGlobalEvent('ll_ActorsOverObstacles_Move', {
				actor = self,
				cell = Cell.name,
				position = newPosition,
			})
			fatigue.current = fatigue.current - 3 -- try to get out of water cause fatigue loss...
		end
	end

	-- (If the creature has our levitate effect on him, it means that he's finishing his try to get out water (or it's a residual bug and we must remove this effect))
	if ActorSpells:isSpellActive(LevitateSpell) then -- He has the levitate effect, so it's time to remove it.
		backedPosition = nil
		stopLevit()
		return
	end
	
	local canMove = Actor.canMove(self)
	local isSwimming = Actor.isSwimming(self)
	if not isSwimming and canMove and not blacklist[Model] and not blacklist[recordId] then
	-- Section for creatures that aren't in water ----------------------------------
	--------------------------------------------------------------------------------
	
		local activePackage = AI.getActivePackage()
		if not activePackage or activePackage.type == "Wander" then
			backedPosition = nil
			return
		end
	
		if backedPosition == nil then -- if this is a new situation, we save the start position, and we wait a little bit (return) (to determine the movement speed).
			backedPosition = Position
			return
		else
			coverDist = (Position - backedPosition):length()
			if coverDist > Actor.getWalkSpeed(self) / 3 or (coverDist == 0 and Actor.getCurrentSpeed(self) == 0) then -- if he has done a "big" move since the start position save, or if he is stationary, it means that he's not in the conditions to "jump".
				backedPosition = nil
				return
			end
		end
		
		-- Now we now that he needs to "jump" (to overcome a potential obstacle). So he will try a "jump" between 5 differents "jumps" (up, up and right, up and left, right, left)
		local random7 = random7_7[math.random(1, 2)]
		local finalSize50 = finalSize * 0.5
		local finalSize36 = finalSize * 0.36
		local finalSize25 = finalSize * 0.25
		while true do
			local case = math.random(#jumpTests)
			local result = jumpTests[case]
			if result > 4 then -- up
				testX, testY, testZ = random7, 7, finalSize + finalSize50
				destX, destY, destZ = random7, 7, finalSize50
			elseif result == 1 then -- up and right
				testX, testY, testZ = finalSize50 + finalSize36, 7, finalSize + finalSize36
				destX, destY, destZ = finalSize36, 7, finalSize36
			elseif result == 2 then -- up and left
				testX, testY, testZ = -finalSize50 - finalSize36, 7, finalSize + finalSize36
				destX, destY, destZ = -finalSize36, 7, finalSize36
			elseif result == 3 then -- right
				testX, testY, testZ = finalSize, 7, 7
				destX, destY, destZ = finalSize50, 7, 7
			else -- (result == 4) -- left
				testX, testY, testZ = -finalSize, 7, 7
				destX, destY, destZ = -finalSize50, 7, 7
			end
	
			local fromActorSpace = trans.move(Position) * trans.rotateZ(self.rotation:getYaw()) -- xyz axis are now relatives to actor
			testPosition = fromActorSpace * util.vector3(testX, testY, testZ) -- first we test if there is enough space
	
			if not nearby.castRay(Position, testPosition, {ignore=self}).hit then -- if no collision, we can do the "jump"
			
				newPosition = fromActorSpace * util.vector3(destX, destY, destZ)
				
				if result < 5 and not canFly then -- if it's a jump on the side, we check he's not going to fall lower
					testPosition = fromActorSpace * util.vector3(destX, destY, -2)
					safe = nearby.castRay(newPosition, testPosition, {ignore=self}).hit -- if there's a collision, it's ok: there's going to have a ground not lower than the actual
				end
				
				if result > 4 or safe or canFly then -- if all is ok, we can do the "jump"

					core.sendGlobalEvent('ll_ActorsOverObstacles_Move', {
						actor = self,
						cell = Cell.name,
						position = newPosition,
					})
					fatigue.current = fatigue.current - 3 -- the jump cause fatigue loss...
					
					result = nil
					jumpTests = {1, 2, 3, 4, 5, 6, 7, 8}
					pause = pauseCycles -- the number of "pause" cycles before another jump (default: 0)
					break
				end
			end
			if result then
				if #jumpTests == 1 or jumpTests[1] == 5 then -- if it was the last try (all failed),
					-- we do a "micro jump" (to try to unblock a possible blocked situation)
					newPosition = fromActorSpace * util.vector3(-random7, 7, 7)
					core.sendGlobalEvent('ll_ActorsOverObstacles_Move', {
						actor = self,
						cell = Cell.name,
						position = newPosition,
					})
					jumpTests = {1, 2, 3, 4, 5, 6, 7, 8}
					break
				-- else, we remove the failed try (to try another one)
				elseif result > 4 then
					for i = 1, 4 do
						table.remove(jumpTests)
					end
				else
					table.remove(jumpTests, case)
				end
			end
		end

		-- After the "jump" phase, we give him a levitate capacity to finish the simulation and the possibility to overcome an obstacle.
		ActorSpells:add({id = LevitateSpell, effects = { 0 }, ignoreResistances = true, ignoreSpellAbsorption = true, ignoreReflect = true})
		
		fatigue.current = fatigue.current - 3 -- try to overcome an obstacle cause fatigue loss...

		backedPosition = nil
		async:newUnsavableSimulationTimer(0.5, stopLevit) -- Only 0.5s of levitate capacity

	elseif isSwimming then

		if not canFly and canMove and posZ > Cell.waterLevel - finalSize and not blacklist[Model] and not blacklist[recordId] then
		-- Section for creatures that are at the water surface--------------------------
		--------------------------------------------------------------------------------

			if backedPosition == nil then -- if this is a new situation, we save the start position, and we wait a little bit (return) (to determine the movement speed).
				backedPosition = Position
				return
			else
				coverDist = (Position - backedPosition):length()
				if coverDist < 4 or coverDist > finalSize then -- if he hasn't done a sufficient move, or has done a "big" move, since the start position save, it means that he's not in the conditions to get out water now.
					backedPosition = nil
					return
				end
			end

			-- We give him a levitate capacity to start the out of water simulation.
			ActorSpells:add({id = LevitateSpell, effects = { 0 }, ignoreResistances = true, ignoreSpellAbsorption = true, ignoreReflect = true})
	
			fatigue.current = fatigue.current - 3 -- try to get out of water cause fatigue loss...
			backedPosition = nil
			
			lastEffortToGetOutWater = true -- After the levitation there will be a last effort to get out of water (teleportation) (To get out water, it works better in this order)
			
		
		elseif posZ <= Cell.waterLevel - finalSize then
		-- Section for creatures that are underwater--------------------------
		----------------------------------------------------------------------
		
		-- we bring him up a bit to the water surface to simulate the Archimedes' principle
		-- and also to un-block some situations...

			-- An actor who can't move can be stuck in collision, so we check this before the little move
			testPosition = util.vector3(posX,
										posY,
										posZ + finalSize + 20) -- space needed for the move
			if not canMove and nearby.castRay(Position, testPosition, {ignore=self}).hit then -- if collision, we can't do the move
				backedPosition = nil
				return
			end
			
			newPosition = util.vector3(posX,
										posY,
										posZ + ArchiPush) -- moves of "20" can also un-block some situations...
		
			core.sendGlobalEvent('ll_ActorsOverObstacles_Move', {
				actor = self,
				cell = Cell.name,
				position = newPosition,
			})
			
			-- As there is a stuck risk with multiple "20" moves, we alternate with a negative one to have a move of "7" in 2 cycles (20 - 13). This suppress the stuck risk.
			if ArchiPush ~= -13 then
				ArchiPush = -13
			else
				ArchiPush = 20
			end
		end
	else
		backedPosition = nil
		return	
	end

end


return {
    engineHandlers = {
        onActive = async:newUnsavableSimulationTimer(0.5 + math.random() * 1.4, obstacleCheck),
    }
}
