local this = {}

function this.getCellName(cell)
    if cell.name ~= "" then
        return cell.name
    else
        return tostring(cell.gridX)..", "..tostring(cell.gridY)
    end
end

-- https://stackoverflow.com/questions/1426954/split-string-in-lua
function this.split(str, separator)
    local tb={}
    for s in string.gmatch(str, "([^"..separator.."]+)") do
            table.insert(tb, s)
    end
    return tb
end

return this