local types = require('openmw.types')
local util = require("openmw.util")

local tableLib = require("scripts.quest_guider_lite.utils.table")
local utils = require("scripts.quest_guider_lite.utils.common")
local tes3 = require("scripts.quest_guider_lite.core.tes3")

local maxDepth = 20

local this = {}

---@param cell tes3cell
---@return tes3vector3|nil outPos
---@return tes3travelDestinationNode[]|nil doorPath
---@return tes3cellData[]|nil cellPath
---@return boolean|nil isExterior
---@return table<string,tes3cell>|nil checkedCells
function this.findExitPos(cell, path, checked, cellPath)
    if not checked then checked = {} end
    if not path then path = {} end
    if not cellPath then
        cellPath = {}
        table.insert(cellPath, tes3.getCellData(cell))
    end

    if checked[cell.id] then return nil, nil, nil, nil, checked end
    checked[cell.id] = cell
    for _, door in pairs(cell:getAll(types.Door)) do
        if not types.Door.isTeleport(door) or not door.enabled then goto continue end

        local destCell
        local destPos
        pcall(function ()
            destCell = types.Door.destCell(door)
            destPos = types.Door.destPosition(door)
        end)

        if not destCell or not destPos then goto continue end

        local destCellData = tes3.getCellData(destCell)

        ---@type tes3travelDestinationNode[]
        local pathCopy = tableLib.copy(path)
        table.insert(pathCopy, {cellData = destCellData, marker = {position = destPos}})

        local cellPathCopy = tableLib.copy(cellPath)
        table.insert(cellPathCopy, destCellData)

        if destCell.isExterior or destCell:hasTag("QuasiExterior") then
            return utils.copyVector3(destPos), pathCopy, cellPathCopy, destCell.isExterior, checked
        else
            local out, destPath, cPath, isEx = this.findExitPos(destCell, pathCopy, checked, cellPathCopy)
            if out then return out, destPath, cPath, isEx, checked end
        end


        ::continue::
    end
    return nil, nil, nil, nil, checked
end

---@param node tes3travelDestinationNode
---@param cells table<string, {cell : tes3cell, depth : integer}>? by editor name
---@return table<string, {cell : tes3cell, depth : integer}>?
---@return boolean? hasExitToExterior
function this.findReachableCellsByNode(node, cells, depth)
    if not node.cell then return end
    if not cells then cells = {} end
    if not depth then depth = 1 end

    local hasExitToExterior = node.cell.isExterior

    local cellData = cells[node.cell.id]
    if (cellData and cellData.depth <= depth) or depth > maxDepth then
        return cells, false
    end

    if hasExitToExterior then
        return cells, true
    end

    if cellData then
        cellData.depth = depth
    else
        cells[node.cell.id] = {cell = node.cell, depth = depth}
    end

    for _, door in pairs(node.cell:getAll(types.Door)) do
        if not types.Door.isTeleport(door) or not door.enabled then goto continue end

        local destCell = types.Door.destCell(door)
        local destPos = types.Door.destPosition(door)

        if not destCell or not destPos then goto continue end

        if destCell.isExterior then
            hasExitToExterior = true
        else
            local cls, hasExit = this.findReachableCellsByNode({cell = destCell, cellData = tes3.getCellData(destCell), marker = {position = destPos}}, cells, depth + 1)
            hasExitToExterior = hasExitToExterior or hasExit
        end

        ::continue::
    end

    return cells, hasExitToExterior
end

local findExitPositionsCache = {}

---@param cell tes3cell
---@return {pos : tes3vector3, depth : number}[]?
---@return table<string, tes3cell>?
---@return table<string, tes3cell>? entranceCells
---@return number? lowestDepth
function this.findExitPositions(cell, checked, res, resCells, entranceCells, depth)
    if not checked then checked = {} end
    if not entranceCells then entranceCells = {} end
    if not res then res = {} end
    if not depth then depth = 0 end

    if cell.isExterior then
        resCells[cell.id] = cell
        return
    end
    if checked[cell.id] then
        checked[cell.id] = math.min(checked[cell.id], depth)
        if entranceCells[cell.id] then
            entranceCells[cell.id] = math.min(entranceCells[cell.id], depth)
        end
        return
    end

    if findExitPositionsCache[cell.id] then
        return table.unpack(findExitPositionsCache[cell.id]) ---@diagnostic disable-line: redundant-return-value
    end

    checked[cell.id] = depth

    for _, door in pairs(cell:getAll(types.Door)) do
        if not types.Door.isTeleport(door) or not door.enabled then goto continue end

        local destCell = types.Door.destCell(door)
        local destPos = types.Door.destPosition(door)

        if not destCell or not destPos then goto continue end

        if destCell.isExterior then
            table.insert(res, {pos = utils.copyVector3(destPos), depth = depth})
            entranceCells[cell.id] = depth
        else
            this.findExitPositions(destCell, checked, res, resCells, entranceCells, depth + 1)
        end

        ::continue::
    end

    local lowestDepth = 9999
    for _, dpt in pairs(entranceCells) do
        lowestDepth = math.min(lowestDepth, dpt)
    end

    if depth == 0 then
        findExitPositionsCache[cell.id] = {res, resCells, entranceCells, lowestDepth}
    end
    return res, resCells, entranceCells, lowestDepth
end


local findNearestDoorCache = {}

---@param cell tes3cell?
---@param position tes3vector3
---@return any?
function this.findNearestDoor(position, cell)
    if not cell then
        cell = tes3.getCell{position = position}
        if not cell then return end
    end
    local hashVal = string.format("%d_%d_%d_%s", math.floor(position.x), math.floor(position.y), math.floor(position.z), cell.id)
    if findNearestDoorCache[hashVal] then
        return findNearestDoorCache[hashVal]
    end
    local nearestDoor
    local nearestdist = math.huge

    local function checkDoor(doorRef)
        if not types.Door.isTeleport(doorRef) then return end

        local destPos = doorRef.position
        if not destPos then return end

        local dist = (destPos - position):length()
        if nearestdist > dist then
            nearestdist = dist
            nearestDoor = doorRef
        end
    end

    local function checkDoorsInCell(cl)
        for _, doorRef in pairs(cl:getAll(types.Door)) do
            checkDoor(doorRef)
        end
    end

    if not cell.isExterior then
        checkDoorsInCell(cell)
    else
        checkDoorsInCell(cell)
        if nearestdist > 500 then
            for i = -1, 1 do
                for j = -1, 1 do
                    local cl = tes3.getCell{x = cell.gridX + i, y = cell.gridY + j}
                    if cl then
                        for _, doorRef in pairs(cell:getAll(types.Door)) do
                            checkDoor(doorRef)
                        end
                    end
                end
            end
        end
    end

    findNearestDoorCache[hashVal] = nearestDoor
    return nearestDoor
end


---@return table<string, {position : any, distance : number, namePath : string[]}> ret by lowercase cell id. __world__ - for exterior
function this.getInteriorCellApproxDistancesToPos(cell, pos, distance, checked, namePath)
    if not checked then checked = {} end
    if not distance then distance = 0 end
    if not namePath then namePath = {} end

    local cellId = cell.id
    if checked[cellId] and checked[cellId].distance <= distance then return checked end

    table.insert(namePath, tes3.getCellData(cell).name)

    if cell.isExterior then
        local exData = checked["__world__"]
        if not exData or distance < exData.distance then
            checked["__world__"] = {
                position = pos,
                distance = distance,
                namePath = tableLib.copy(namePath),
            }
        end
        return checked
    else
        checked[cellId] = {
            position = pos,
            distance = distance,
            namePath = tableLib.copy(namePath),
        }
    end

    for _, door in pairs(cell:getAll(types.Door)) do
        if not types.Door.isTeleport(door) or not door.enabled then goto continue end

        local destCell = types.Door.destCell(door)
        local destPos = types.Door.destPosition(door)
        if not destCell or not destPos then goto continue end

        this.getInteriorCellApproxDistancesToPos(destCell, destPos, distance + (pos - door.position):length(), checked, tableLib.copy(namePath))

        ::continue::
    end

    return checked
end


---@param posData questGuider.quest.getRequirementPositionData.positionData[]
function this.fillDistanceToPlayer(posData, playerRef)
    local plPos = playerRef.position
    local plCell = playerRef.cell

    local interiorCellDistance = this.getInteriorCellApproxDistancesToPos(plCell, plPos)
    local worldPlPosData = interiorCellDistance["__world__"]

    for _, pos in pairs(posData or {}) do
        if not pos.position then goto continue end

        if not pos.id and worldPlPosData then
            pos.distanceToPlayer = utils.distance2D(worldPlPosData.position, pos.position)
            pos.pathFromPlayer = worldPlPosData.namePath
        elseif pos.id then
            local distData = interiorCellDistance[pos.id:lower()]
            if distData then
                pos.distanceToPlayer = distData.distance + utils.distance2D(distData.position, pos.position)
                pos.pathFromPlayer = distData.namePath
            elseif pos.exitPos and pos.isExitEx then
                pos.distanceToPlayer = utils.distance2D(plPos, pos.exitPos)
            else
                pos.distanceToPlayer = math.huge
            end
        else
            pos.distanceToPlayer = math.huge
        end

        ::continue::
    end
end


return this