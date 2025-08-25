
local self = require("openmw.self")
local types = require("openmw.types")
local Actor = types.Actor
local ActorSpells = Actor.activeSpells(self)
local fatigue = Actor.stats.dynamic.fatigue(self)
local baseType = types.Player.baseType
local selfRecord = baseType.record(self)
local height = baseType.races.record(selfRecord.race).height
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local input = require('openmw.input')


-- If you want to change the "out of water" key ('e' by default (default "jump" key))
-- it's here:
local OutOfWaterKey = 'e'

-- If you want to change the "out of water" button (for game controller) ('Y Button' by default (default "jump" key))
-- it's here:
local OutOfWaterButton = input.CONTROLLER_BUTTON.Y
-- the list of authorized buttons can be found here:
-- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_input.html##(CONTROLLER_BUTTON)


-- A Levitate effect is applied to simulate the "get out water".
-- If you want to change the speed of the Levitate effect (so the
-- distance travelled), you can choose between ll_fly1, ll_fly2, ll_fly5,
-- ll_fly10, ll_fly20, ll_fly50, ll_fly100, and ll_fly200.
-- Note that the more you reduce this speed, the more it will be
-- difficult (and perhaps impossible) to the Player Character to get out
-- water (especially if he is slow).
-- ll_fly20 is the recommended effect for the PC.
local LevitateSpell = "ll_fly20"

-- If you don't want the Archimedes' Principle applied to PC
-- (PC slowly goes up to water surface), set it to 0:
local ArchimedesPrinciple = 1


local Position
local newPosition
local backedPosition
local finalSize
local Cell
local posX
local posY
local posZ
local quit
local keyOk = 1

-- We determine the PC size
local stdSize = 124
local size
if selfRecord.isMale == true then
	size = stdSize * height.male
else
	size = stdSize * height.female
end


-- Main function (to get out water)
local function waterCheck()

	if quit then
		quit = nil
		keyOk = 1
		return
	end

	async:newUnsavableSimulationTimer(0.25, waterCheck)

	Position = self.position
	finalSize = size * self.scale
	local tryToExitWater = ActorSpells:isSpellActive(LevitateSpell)
	if tryToExitWater and (backedPosition == nil or (Position - backedPosition):length() > finalSize) then -- if PC went all the way with the try (to exit water), we stop the try.
		backedPosition = nil
        for _, spell in pairs(ActorSpells) do
            if spell.id == LevitateSpell then
                ActorSpells:remove(spell.activeSpellId)
                break
            end
        end
        quit = 1
		return
	elseif tryToExitWater then -- if the try is in progress, we will stop the try in the next cycle.
		fatigue.current = fatigue.current - 10 -- try to get out of water cause fatigue loss...
		backedPosition = nil
		return
	end
	
	-- Here we know that he's not trying to exit water

	Cell = self.cell
	posZ = Position.z
	if Actor.canMove(self) and posZ > Cell.waterLevel - finalSize then -- (PC is valid and near the surface)
		if backedPosition == nil then -- if this is a new situation, we save the start position, and we wait a little bit (return) (to determine the movement speed).
			backedPosition = Position
			return
		elseif (Position - backedPosition):length() > finalSize / 100 then -- if PC has done a move too important since the start position save, it means that he isn't ready to get out water now (PC must not move (in the water) to try to get out water).
			backedPosition = nil
			quit = 1
			return
		end
		
		-- Now we now that he's ready to get out water.
		
		-- so, first, we try to "give" him a "jump" equal to his size x 0.5
		posX = Position.x
		posY = Position.y
		newPosition = util.vector3(posX,
									posY,
									posZ + finalSize * 1.5) -- first we test if there is enough space (jump + height of the body, so 0.5 + 1)

		if not nearby.castRay(Position, newPosition, {ignore=self}).hit then -- if no collision, we can do the "jump"

			newPosition = util.vector3(posX,
										posY,
										posZ + finalSize * 0.5)
			core.sendGlobalEvent('ll_ActorsOverObstacles_Move', {
				actor = self,
				cell = Cell.name,
				position = newPosition,
			})
			fatigue.current = fatigue.current - 10 -- try to get out of water cause fatigue loss...
			
		else -- (not enough space) so we try a mini jump...
			newPosition = util.vector3(posX,
										posY,
										posZ + finalSize + 12)
		
			if not nearby.castRay(Position, newPosition, {ignore=self}).hit then -- space test for the move
				newPosition = util.vector3(posX,
											posY,
											posZ + 7) -- the mini jump
				core.sendGlobalEvent('ll_ActorsOverObstacles_Move', {
					actor = self,
					cell = Cell.name,
					position = newPosition,
				})
			else -- no space
				backedPosition = nil
				quit = 1
				return
			end
		end
		-- and we give him a flying capacity also to simulate an exit from the water.
		ActorSpells:add({id = LevitateSpell, effects = { 0 }, ignoreResistances = true, ignoreSpellAbsorption = true, ignoreReflect = true})
	end
end


local function waterCheckUnderwater()

	async:newUnsavableSimulationTimer(1.3 + math.random() * 0.2, waterCheckUnderwater) -- (we try every 1.3-1.5 seconds)

	if not Actor.isSwimming(self) then -- if actor isn't in the water, we have nothing to do now.
		return
	end
	
	Position = self.position
	finalSize = size * self.scale
	Cell = self.cell
	posZ = Position.z
	if posZ <= Cell.waterLevel - finalSize then -- if he's underwater,
	-- we bring him up a bit to the water surface to simulate the Archimedes' principle
	
		-- A PC can be stuck in collision when teleported, so we check this before the little move
		posX = Position.x
		posY = Position.y
		newPosition = util.vector3(posX,
									posY,
									posZ + finalSize + 10) -- space needed for the move
		if nearby.castRay(Position, newPosition, {ignore=self}).hit then -- if collision, we can't do the move
			return
		end
		
		newPosition = util.vector3(posX,
									posY,
									posZ + 3.5) -- to be coherent with other actors (+7 in 2 cycles)
	
		core.sendGlobalEvent('ll_ActorsOverObstacles_Move', {
			actor = self,
			cell = Cell.name,
			position = newPosition,
		})
	end
end


return {
    engineHandlers = {
        onKeyPress = function(key)
			-- If player press the OutOfWaterKey...
            if key.symbol == OutOfWaterKey and Actor.isSwimming(self) and Actor.canMove(self) and keyOk then
				keyOk = nil
				waterCheck()
            end
        end,
        onControllerButtonPress = function(id)
			-- If player press the OutOfWaterButton...
            if id == OutOfWaterButton and Actor.isSwimming(self) and Actor.canMove(self) and keyOk then
				keyOk = nil
				waterCheck()
            end
        end,
        onActive = function()
			if ArchimedesPrinciple == 1 then
				async:newUnsavableSimulationTimer(1, waterCheckUnderwater)
			end
		end,
    }
}
