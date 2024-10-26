-- If you want to change the "out of water key", look at the bottom of this script...


local self = require("openmw.self")
local types = require("openmw.types")
local Actor = types.Actor
local selfRecord = types.Player.baseType.record(self)
local height = types.Player.baseType.races.record(selfRecord.race).height
local core = require("openmw.core")
local util = require("openmw.util")
local trans = util.transform
--local nearby = require('openmw.nearby')
local ui = require('openmw.ui')

local stdSize = 124
local timeTrig = -1

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

	if not Actor.isSwimming(self) then
		return
	end
	
	local Cell = self.cell
	local Position = self.position
	local posZ = Position.z
	local finalSize = size * self.scale
	local newPosition
	
	if Actor.canMove(self) and posZ > Cell.waterLevel - finalSize then

		local fromActorSpace = trans.move(Position) * trans.rotateZ(self.rotation:getYaw()) -- y axis -> actor front
		newPosition = fromActorSpace * util.vector3(0, finalSize * 0.25, finalSize * 0.9) -- move up + size*0.9, move front + size*0.25

		--testPosition = nearby.findNearestNavMeshPosition(newPosition, {
		--searchAreaHalfExtents = util.vector3(100, 100, 100),
			--includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
		--})
		
	else
		return
	end
	
	core.sendGlobalEvent('Move', {
		actor = self,
		cell = Cell.name,
		position = newPosition,
	})
	
end

return {
    engineHandlers = {
        onKeyPress = function(key)
			-- If you want to change the "out of water key", change "e" below with the key of your choice
            if key.symbol == 'e' and core.getRealTime() > timeTrig then
                timeTrig = core.getRealTime() + 4
                waterCheck()
            end
        end
    }
}
