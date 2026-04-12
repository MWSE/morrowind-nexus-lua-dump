local types = require("openmw.types")

require("scripts.ItBeats.utils.consts")

local exploredCells = {}
local function exploreCell(cell)
    for _, door in pairs(cell:getAll(types.Door)) do
        local destCell = types.Door.destCell(door)
        if not destCell or exploredCells[destCell.id] then
            goto continue
        end

        exploredCells[cell.id] = true

        if destCell.isExterior then
            if destCell.region == RedMountainRegion then
                return true
            end
        elseif exploreCell(destCell) then
            return true
        end

        ::continue::
    end
    return false
end

function IsInteriorInRMR(cell)
    exploredCells = {}
    return exploreCell(cell)
end
