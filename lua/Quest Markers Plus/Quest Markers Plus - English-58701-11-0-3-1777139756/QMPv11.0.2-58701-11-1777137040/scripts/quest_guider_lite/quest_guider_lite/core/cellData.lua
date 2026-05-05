local core = require("openmw.core")

local this = {}

---@param cell tes3cell
---@return tes3cellData
function this.getCellData(cell)
	local name
	if cell.isExterior then
		local region = core.regions and core.regions.records[cell.region or ""] and core.regions.records[cell.region or ""].name
			or cell.region or ""
		local cellName = cell.displayName or cell.name or ""
		if not cellName or cellName == "" then
			name = string.format("%s (%d, %d)", cellName, cell.gridX, cell.gridY)
		else
			name = string.format("%s (%d, %d)", region, cell.gridX, cell.gridY)
		end
	else
		name = cell.displayName or cell.name or "???"
	end

	---@type tes3cellData
	local dt = {
		isExterior = cell.isExterior,
		gridX = cell.isExterior and cell.gridX or nil,
		gridY = cell.isExterior and cell.gridY or nil,
		id = not cell.isExterior and cell.id or nil,
		name = name,
	}
	return dt
end

return this