-- If you want to change the "out of water" key or the "backed position" key, look at the bottom of this script...


local self = require("openmw.self")
local types = require("openmw.types")
local Actor = types.Actor
local dynamicStats = Actor.stats.dynamic
local baseType = types.Player.baseType
local selfRecord = baseType.record(self)
local height = baseType.races.record(selfRecord.race).height
local core = require("openmw.core")
local util = require("openmw.util")
local trans = util.transform
--local nearby = require('openmw.nearby')
local ui = require('openmw.ui')

local stdSize = 124
local realTime
local timeTrig = -1
local timeTrigB
local backedPosition
local backedCell

--local raceSizes = {
--	["argonian"] = 1.03,
--	["breton"] = 1,
--	["dark elf"] = 1,
--	["high elf"] = 1.1,
--	["imperial"] = 1,
--	["khajiit"] = 1,
--	["nord"] = 1.06,
--	["orc"] = 1.05,
--	["redguard"] = 1.02,
--	["wood elf"] = 0.9,
--}

--local femaleSizes = {
--	["argonian"] = 1,
--	["breton"] = 0.95,
--	["dark elf"] = 1,
--	["high elf"] = 1.1,
--	["imperial"] = 1,
--	["khajiit"] = 0.95,
--	["nord"] = 1.06,
--	["orc"] = 1.05,
--	["redguard"] = 1,
--	["wood elf"] = 1,
--}

local size
if selfRecord.isMale == true then
	size = stdSize * height.male
else
	size = stdSize * height.female
end


local function waterCheck()

	local Cell = self.cell
	local Position = self.position
	local posZ = Position.z
	local finalSize = size * self.scale
	
	if posZ < Cell.waterLevel - finalSize then return end -- PC doesn't jump if he's under the surface

	-- We save the position before the jump, in case of a stuck pb after the jump
	backedPosition = Position
	backedCell = Cell
	timeTrigB = realTime + 30
	
	local fromActorSpace = trans.move(Position) * trans.rotateZ(self.rotation:getYaw()) -- y axis -> actor front
	local newPosition = fromActorSpace * util.vector3(0, finalSize * 0.25, finalSize * 0.9) -- move up + size*0.9, move front + size*0.25
	dynamicStats.fatigue(self).current = dynamicStats.fatigue(self).current - 20 -- jumping out of water cause fatigue loss...
	
	--testPosition = nearby.findNearestNavMeshPosition(newPosition, {
	--searchAreaHalfExtents = util.vector3(100, 100, 100),
		--includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
	--})
		
	
	core.sendGlobalEvent('Move', {
		actor = self,
		cell = Cell.name,
		position = newPosition,
	})
	
end

return {
    engineHandlers = {
        onKeyPress = function(key)
			-- if cell has changed we reset the "backed position" functionality
			if timeTrigB and self.cell ~= backedCell then
				timeTrigB = nil
			end
			-- If you want to change the "out of water key", change "e" below with the key of your choice
            if key.symbol == 'e' and Actor.isSwimming(self) and Actor.canMove(self) then
				realTime = core.getRealTime()
				if realTime > timeTrig then
					timeTrig = realTime + 4
					waterCheck()
				end
            -- If you want to change the "backed position key", change "p" below with the key of your choice
            elseif key.symbol == 'p' and timeTrigB then
				if core.getRealTime() < timeTrigB then
					core.sendGlobalEvent('Move', {
						actor = self,
						cell = backedCell.name,
						position = backedPosition,
					})
				end
				timeTrigB = nil
            end
        end,
        onActive = function()
			timeTrigB = nil
		end,
    }
}
