local types = require("openmw.types")

local pDoor = require("scripts.advanced_world_map.helpers.protectedDoor")

local commonData = require("scripts.advanced_world_map.common")
local disabledDoors = require("scripts.advanced_world_map.disabledDoors")


local this = {}


function this.getGridCoordinates(pos)
    local gridX = math.floor(pos.x / 8192)
    local gridY = math.floor(pos.y / 8192)
    return gridX, gridY
end


function this.getCellIdByPos(pos)
    return commonData.exteriorCellIdFormat:format(this.getGridCoordinates(pos))
end


function this.getCellIdByGrid(gridX, gridY)
    return commonData.exteriorCellIdFormat:format(gridX, gridY)
end


---@return {pos : any, depth : number, cell : any?}[]
---@return table<string, integer> depths depts by cell id
---@return table<string, any> exitCells
---@return number? lowestDepth
function this.findExitPositions(cell, filterNotAvailable, checked, res, exitCells, depth)
    if not checked then checked = {} end
    if not exitCells then exitCells = {} end
    if not res then res = {} end
    if not depth then depth = 0 end

    if checked[cell.id] then
        checked[cell.id] = math.min(checked[cell.id], depth)
        if exitCells[cell.id] then
            exitCells[cell.id] = math.min(exitCells[cell.id], depth)
        end
        return res, checked, exitCells
    end

    checked[cell.id] = depth

    for _, door in pairs(cell:getAll(types.Door)) do
        if not types.Door.isTeleport(door) or not door.enabled or
                (filterNotAvailable and (disabledDoors.contains(door) or types.Lockable.isLocked(door))) then
            goto continue
        end

        local destCell = pDoor.destCell(door)
        local destPos = pDoor.destPosition(door)

        if not destCell or not destPos then goto continue end

        if destCell.isExterior then
            table.insert(res, {pos = commonData.copyVector3(destPos), cell = destCell, depth = depth + 1})
            exitCells[destCell.id] = math.min(exitCells[destCell.id] or math.huge, depth + 1)
            checked[destCell.id] = math.min(checked[destCell.id] or math.huge, depth + 1)
        else
            this.findExitPositions(destCell, filterNotAvailable, checked, res, exitCells, depth + 1)
        end

        ::continue::
    end

    local lowestDepth = math.huge
    for _, dpt in pairs(exitCells) do
        lowestDepth = math.min(lowestDepth, dpt)
    end

    return res, checked, exitCells, lowestDepth
end


return this