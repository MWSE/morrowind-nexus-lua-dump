local self = require("openmw.self")
local input = require("openmw.input")
local async = require("openmw.async")

local function JumpOutOfWater()
    if self.type.isSwimming(self) and (self.cell.waterLevel - 150 < self.position.z) then
		self.type.activeSpells(self):add({id = 'Water Walking', effects = { 0 }})
		async:newUnsavableSimulationTimer(0.75, function()
			self.type.activeEffects(self):remove('waterwalking')
        end)
    end
end

input.registerTriggerHandler('Jump', async:callback(function() JumpOutOfWater() end))


