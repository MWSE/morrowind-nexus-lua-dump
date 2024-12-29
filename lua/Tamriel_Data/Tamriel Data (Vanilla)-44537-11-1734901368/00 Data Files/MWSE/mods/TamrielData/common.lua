local this = {}

this.i18n = mwse.loadTranslations("TamrielData")

-- Util functions
function table.contains(table, element)
	for _,v in pairs(table) do
	  if v == element then
		return true
	  end
	end
	return false
end

---@param cell tes3cell
function this.getExteriorCell(cell, cellVisitTable)
	if cell.isOrBehavesAsExterior then
		return cell
	end

	cellVisitTable = cellVisitTable or { tes3.player.cell }
	
	for ref in cell:iterateReferences(tes3.objectType.door) do
		if ref.destination and not table.contains(cellVisitTable, ref.destination.cell) then
			table.insert(cellVisitTable, ref.destination.cell)
			return this.getExteriorCell(ref.destination.cell, cellVisitTable)
		end
	end
end

return this