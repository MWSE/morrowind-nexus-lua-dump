local utils = require("firemoth.utils")
local isFiremothCell = utils.cells.isFiremothCell
local previousValues = {}

local function setFogValues(e)

	local cell = e.cell
	local c = mge.distantLandRenderConfig

	if isFiremothCell(cell) then
		if table.empty(previousValues) then
			previousValues.aboveWaterFogEnd = c.aboveWaterFogEnd
			previousValues.aboveWaterFogStart = c.aboveWaterFogStart
			previousValues.belowWaterFogEnd = c.belowWaterFogEnd
			previousValues.belowWaterFogStart = c.belowWaterFogStart

			c.aboveWaterFogEnd = 3.5
			c.aboveWaterFogStart = 0
			c.belowWaterFogEnd = 0.1
			c.belowWaterFogStart = 0
		end
	else
		if not table.empty(previousValues) then
			c.aboveWaterFogEnd = previousValues.aboveWaterFogEnd
			c.aboveWaterFogStart = previousValues.aboveWaterFogStart
			c.belowWaterFogEnd = previousValues.belowWaterFogEnd
			c.belowWaterFogStart = previousValues.belowWaterFogStart
			previousValues = {}
		end
	end

end

local function reset()
	local c = mge.distantLandRenderConfig
	if not table.empty(previousValues) then
		c.aboveWaterFogEnd = previousValues.aboveWaterFogEnd
		c.aboveWaterFogStart = previousValues.aboveWaterFogStart
		c.belowWaterFogEnd = previousValues.belowWaterFogEnd
		c.belowWaterFogStart = previousValues.belowWaterFogStart
		previousValues = {}
	end
end

event.register(tes3.event.load, reset)
event.register(tes3.event.cellChanged, setFogValues)