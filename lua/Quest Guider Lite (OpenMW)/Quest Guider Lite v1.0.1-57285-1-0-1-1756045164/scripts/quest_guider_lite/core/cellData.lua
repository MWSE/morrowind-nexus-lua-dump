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
		name = cell.isExterior and string.format("%s (%d, %d)", cell.region, cell.gridX, cell.gridY) or cell.name,
	}
	return dt
end

return this