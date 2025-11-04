local core = require("openmw.core")

local this = {}

---@param cell tes3cell
---@return tes3cellData?
function this.getCellData(cell)
	---@type tes3cellData
	local dt = {
		isExterior = cell.isExterior,
		gridX = cell.isExterior and cell.gridX or nil,
		gridY = cell.isExterior and cell.gridY or nil,
		id = not cell.isExterior and cell.id or nil,
		name = cell.isExterior and string.format("%s (%d, %d)",
			core.regions and core.regions.records[cell.region or ""] and core.regions.records[cell.region or ""].name
			or cell.region or "", cell.gridX, cell.gridY) or cell.displayName or cell.name,
	}
	return dt
end

return this