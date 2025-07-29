
local self = require("openmw.self")
local types = require("openmw.types")
local Actor = types.Actor
local ActorSpells = Actor.activeSpells(self)
local fatigue = Actor.stats.dynamic.fatigue(self)
local selfRecord = types.NPC.record(self)
local height = types.NPC.races.record(selfRecord.race).height
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require('openmw.nearby')


-- A Levitate effect is applied to simulate the "get out water".
-- If you want to change the speed of the Levitate effect (so the
-- distance travelled), you can choose between ll_fly1, ll_fly2, ll_fly5,
-- ll_fly10, ll_fly20, ll_fly50, ll_fly100, and ll_fly200.
-- Note that the more you reduce this speed, the more it will be
-- difficult (and perhaps impossible) to some slow NPCs to get out water.
-- ll_fly50 is the recommended effect for NPCs.
local LevitateSpell = "ll_fly50"

local fly = selfRecord.canFly

local stdSize = 124
local newPosition
local backedPosition
local ArchiPush = 20

local size
if selfRecord.isMale == true then
	size = stdSize * height.male
else
	size = stdSize * height.female
end


local function waterCheck()

	async:newUnsavableSimulationTimer(1.3 + math.random() * 0.2, waterCheck) -- (we check every 1.3-1.5 seconds)
	
	local Position = self.position
	local finalSize = size * self.scale
	local tryToExitWater = ActorSpells:isSpellActive(LevitateSpell)
	local substantialMove
	local minimalMove
	if backedPosition then
		substantialMove = (Position - backedPosition):length() > finalSize
		minimalMove = (Position - backedPosition):length() > 4
	end
	if tryToExitWater and (backedPosition == nil or substantialMove) then -- if he went all the way with the try (to exit water), we stop the try.
		backedPosition = nil
        for _, spell in pairs(ActorSpells) do
            if spell.id == LevitateSpell then
                ActorSpells:remove(spell.activeSpellId)
                break
            end
        end
		return
	elseif tryToExitWater then -- if the try is in progress, we will stop the try in the next cycle.
		fatigue.current = fatigue.current - 5 -- try to get out of water cause fatigue loss...
		backedPosition = nil
		return
	end
	
	-- Here we know that he's not trying to exit water

	if not Actor.isSwimming(self) then -- if actor isn't in the water, we have nothing to do now.
		return
	end
		
	local Cell = self.cell
	local posZ = Position.z
	if not fly and Actor.canMove(self) and posZ > Cell.waterLevel - finalSize then -- (actor is valid and near the surface)
		if backedPosition == nil then -- if this is a new situation, we save the start position, and we wait a little bit (return).
			backedPosition = Position
			return
		elseif not minimalMove or substantialMove then -- if he hasn't move, or has done a substantial move since the start position save, it means that he doesn't need to get out water now.
			backedPosition = nil
			return
		end
		
		-- Now we now that he needs to get out water.

		-- so we give him a flying capacity to simulate an exit from the water.
		ActorSpells:add({id = LevitateSpell, effects = { 0 }, ignoreResistances = true, ignoreSpellAbsorption = true, ignoreReflect = true})

		fatigue.current = fatigue.current - 5 -- try to get out of water cause fatigue loss...

	elseif posZ <= Cell.waterLevel - finalSize then -- if he's underwater,
	-- we bring him up a bit to the water surface to simulate the Archimedes' principle

		-- An actor who can't move can be stuck in collision, so we check this before the little move
		newPosition = util.vector3(Position.x,
									Position.y,
									posZ + finalSize + 20) -- space needed for the move
		if not Actor.canMove(self) and nearby.castRay(Position, newPosition, {ignore=self}).hit then -- if collision, we can't do the move
			return
		end
		
		newPosition = util.vector3(Position.x,
									Position.y,
									posZ + ArchiPush) -- moves of "20" can also un-block some situations...
	
		core.sendGlobalEvent('ll_Actors_Out_Of_Water_Move', {
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
end

return {
    engineHandlers = {
        onActive = async:newUnsavableSimulationTimer(1, waterCheck),
    }
}
