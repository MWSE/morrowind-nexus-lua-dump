
local self = require("openmw.self")
local types = require("openmw.types")
local selfRecord = types.NPC.record(self)

local Actor = types.Actor
local ActorSpells = Actor.activeSpells(self)
local fatigue = Actor.stats.dynamic.fatigue(self)
local height = types.NPC.races.record(selfRecord.race).height
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
-- Note that below 50 it will be impossible to some slow NPCs to get out
-- water.
-- ll_fly50 is the recommended effect for NPCs.
local LevitateSpell = "ll_fly50"

-- Blacklist to exclude some NPCs from the obstacles overcoming (they won't "jump", and they won't get out water. But they still rise to the surface (if underwater)).
-- (If you edit, write the ID of the NPC in lowercase, like the example below)
local blacklist = {
	--["fargoth"] = true,          -- Example. (To activate, remove the "--" at the begining of the line)
	--["vodunius nuccius"] = true,
}

-- If you want less frequent "jumps", rise the "pauseCycles" value below
-- 0 (default): NPCs will "jump" (if all conditions are met) every 3s (approx)
-- 1: NPCs will "jump" (if all conditions are met) every 4s (approx)
-- 2: NPCs will "jump" (if all conditions are met) every 5.5s (approx)
-- 3: NPCs will "jump" (if all conditions are met) every 7s (approx)
-- ...
-- 10: NPCs will "jump" (if all conditions are met) every 17s (approx)
-- ...
local pauseCycles = 0


local stdSize = 124
local testPosition
local newPosition
local backedPosition
local ArchiPush = -10
local coverDist
local walkSpeed
local testX, testY, testZ, destX, destY, destZ
local jumpTests = {1, 2, 3, 4, 5, 6, 7, 8}
local safe
local random7_7 = {7, -7}
local lastEffortToGetOutWater
local pause = pauseCycles

local size
if selfRecord.isMale == true then
	size = stdSize * height.male
else
	size = stdSize * height.female
end


-- We remove the levitation effect we had given to the NPC
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

	-- (If the NPC has our levitate effect on him, it means that he's finishing his try to get out water (or it's a residual bug and we must remove this effect))	
	if ActorSpells:isSpellActive(LevitateSpell) then -- He has the levitate effect, so it's time to remove it.
		backedPosition = nil
		stopLevit()
		return
	end
	
	local canMove = Actor.canMove(self)
	local isSwimming = Actor.isSwimming(self)
	if not isSwimming and canMove and not blacklist[recordId] then
	-- Section for NPCs that aren't in water ----------------------------------
	---------------------------------------------------------------------------
	
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
			backedPosition = nil
			if coverDist > Actor.getWalkSpeed(self) / 3 or (coverDist == 0 and Actor.getCurrentSpeed(self) == 0) then -- if he has done a "big" move since the start position save, or if he is stationary, it means that he's not in the conditions to "jump".
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
	
			if not nearby.castRay(Position, testPosition, {collisionType=nearby.COLLISION_TYPE.Default + nearby.COLLISION_TYPE.VisualOnly, ignore=self}).hit then -- if no collision, we can do the "jump"
			
				newPosition = fromActorSpace * util.vector3(destX, destY, destZ)
				
				if result < 5 then -- if it's a jump on the side, we check he's not going to fall lower
					testPosition = fromActorSpace * util.vector3(destX, destY, -2)
					safe = nearby.castRay(newPosition, testPosition, {ignore=self}).hit -- if there's a collision, it's ok: there's going to have a ground not lower than the actual
				end
				
				if result > 4 or safe then -- if all is ok, we can do the "jump"

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

		async:newUnsavableSimulationTimer(0.5, stopLevit) -- Only 0.5s of levitate capacity
	
	
	elseif isSwimming then

		if canMove and posZ > Cell.waterLevel - finalSize and not blacklist[recordId] then
		-- Section for NPCs that are at the water surface--------------------------
		---------------------------------------------------------------------------

			if backedPosition == nil then -- if this is a new situation, we save the start position, and we wait a little bit (return) (to determine the movement speed).
				backedPosition = Position
				return
			else
				coverDist = (Position - backedPosition):length()
				backedPosition = nil
				if coverDist < 4 or coverDist > finalSize then -- if he hasn't done a sufficient move, or has done a "big" move, since the start position save, it means that he's not in the conditions to get out water now.
					return
				end
			end

			-- We give him a levitate capacity to start the out of water simulation.
			ActorSpells:add({id = LevitateSpell, effects = { 0 }, ignoreResistances = true, ignoreSpellAbsorption = true, ignoreReflect = true})
	
			fatigue.current = fatigue.current - 3 -- try to get out of water cause fatigue loss...
			
			lastEffortToGetOutWater = true -- After the levitation there will be a last effort to get out of water (teleportation) (To get out water, it works better in this order)
			
		
		elseif posZ <= Cell.waterLevel - finalSize then
		-- Section for NPCs that are underwater--------------------------
		-----------------------------------------------------------------
		
		-- we bring him up a bit to the water surface to simulate the Archimedes' principle
		-- and also to un-block some situations...

			backedPosition = nil

			-- An actor who can't move can be stuck in collision, so we check this before the little move
			if not canMove then
				testPosition = util.vector3(posX,
											posY,
											posZ + finalSize + 21) -- space needed for a "move of 17"
				if  nearby.castRay(Position, testPosition, {collisionType=nearby.COLLISION_TYPE.Default + nearby.COLLISION_TYPE.VisualOnly, ignore=self}).hit then -- if collision, we can't do the move
					return
				end
			-- For the actors who can move, we check if we stop the Archimedes' Principle or not
			elseif ArchiPush == -10 then
				testPosition = util.vector3(posX,
											posY,
											posZ + finalSize + 12) -- little space above?...
				if nearby.castRay(Position, testPosition, {collisionType=nearby.COLLISION_TYPE.Default + nearby.COLLISION_TYPE.VisualOnly, ignore=self}).hit then -- if no little space above, we stop the Archimedes' Principle 
					ArchiPush = -17
				end
			end
			
			newPosition = util.vector3(posX,
										posY,
										posZ + ArchiPush) -- moves of "17" can also un-block some situations...
		
			core.sendGlobalEvent('ll_ActorsOverObstacles_Move', {
				actor = self,
				cell = Cell.name,
				position = newPosition,
			})
			
			-- As there is a stuck risk with multiple "17" moves, we alternate with a negative one to have a move of "7" in 2 cycles (17 - 10). This suppress a stuck risk.
			if ArchiPush ~= 17 then
				ArchiPush = 17
			else
				ArchiPush = -10
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
