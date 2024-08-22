local this = {}

---@param cell tes3cell
---@return string
function this.getCellName(cell)
    if cell.gridX and cell.gridY then
        return tostring(cell.gridX)..", "..tostring(cell.gridY)
    else
        return cell.id
    end
end

function this.clearFilename(str)
    return string.gsub(str, "[*\"/\\<>:|?]", "")
end


return this