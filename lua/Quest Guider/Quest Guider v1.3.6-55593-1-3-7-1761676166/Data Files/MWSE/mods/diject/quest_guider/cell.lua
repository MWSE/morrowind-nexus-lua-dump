local config = include("diject.quest_guider.config")

local this = {}

---@param cell tes3cell
---@return tes3vector3|nil outPos
---@return tes3travelDestinationNode[]|nil doorPath
---@return tes3cell[]|nil cellPath
---@return boolean|nil isExterior
---@return table<tes3cell,boolean>|nil checkedCells
---@return integer?
function this.findExitPos(cell, path, checked, cellPath, depth)
    local maxDepth = config.data.tracking.maxCellDepth
    if not checked then checked = {} end
    if not path then path = {} end
    if not depth then depth = 1 end
    if not cellPath then
        cellPath = {}
        table.insert(cellPath, cell)
    end

    if (checked[cell] and (checked[cell] > depth)) or depth > maxDepth then return nil, nil, nil, nil, checked, depth end
    checked[cell] = depth

    local results = {}
    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then

            ---@type tes3travelDestinationNode[]
            local pathCopy = table.copy(path)
            table.insert(pathCopy, door.destination)

            local cellPathCopy = table.copy(cellPath)
            table.insert(cellPathCopy, door.destination.cell)

            if door.destination.cell.isOrBehavesAsExterior then
                table.insert(results, {door.destination.marker.position:copy(), pathCopy, cellPathCopy, not door.destination.cell.isInterior, checked, depth})
            else
                local out, destPath, cPath, isEx, ch, dp = this.findExitPos(door.destination.cell, pathCopy, checked, cellPathCopy, depth + 1)
                if out then
                    table.insert(results, {out, destPath, cPath, isEx, checked, dp})
                end
            end
        end
    end

    if next(results) then
        table.sort(results, function (a, b)
            return a[6] < b[6]
        end)
        return table.unpack(results[1]) ---@diagnostic disable-line: redundant-return-value
    end

    return nil, nil, nil, nil, checked, depth
end

---@param node tes3travelDestinationNode
---@param cells table<string, {cell : tes3cell, depth : integer}>? by editor name
---@return table<string, {cell : tes3cell, depth : integer}>?
---@return boolean hasExitToExterior
function this.findReachableCellsByNode(node, cells, depth)
    local maxDepth = config.data.tracking.maxCellDepth
    if not cells then cells = {} end
    if not depth then depth = 1 end

    local hasExitToExterior = not node.cell.isInterior

    local cellData = cells[node.cell.editorName]
    if (cellData and cellData.depth <= depth) or depth > maxDepth then
        return cells, false
    end

    if hasExitToExterior then
        return cells, true
    end

    if cellData then
        cellData.depth = depth
    else
        cells[node.cell.editorName] = {cell = node.cell, depth = depth}
    end

    for door in node.cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            if not door.destination.cell.isInterior then
                hasExitToExterior = true
            else
                local cls, hasExit = this.findReachableCellsByNode(door.destination, cells, depth + 1)
                hasExitToExterior = hasExitToExterior or hasExit
            end
        end
    end

    return cells, hasExitToExterior
end


---@param cell tes3cell
---@return tes3vector3[]?
function this.findExitPositions(cell, checked, res)
    if not checked then checked = {} end
    if not res then res = {} end
    if not cell.isInterior or checked[cell] then return end

    checked[cell] = true

    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            if not door.destination.cell.isInterior then
                table.insert(res, door.destination.marker.position:copy())
            else
                this.findExitPositions(door.destination.cell, checked, res)
            end
        end
    end

    return res
end


---@param cell tes3cell
---@return table<string, {cell : tes3cell, depth : integer}>?
function this.findExitCells(cell, checked, cells, depth)
    local maxDepth = config.data.tracking.maxCellDepth
    if not checked then checked = {} end
    if not cells then cells = {} end
    if not depth then depth = 0 end

    if checked[cell.editorName] and checked[cell.editorName] < depth then return end
    checked[cell.editorName] = depth

    if depth > maxDepth or not cell.isInterior then return cells end

    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not door.deleted and not door.disabled then
            local destCell = door.destination.cell
            if not destCell.isInterior then
                local cellData = cells[cell.editorName] or {cell = cell}
                cellData.depth = math.min(depth, cellData.depth or depth)
                cells[cell.editorName] = cellData
            else
                this.findExitCells(destCell, checked, cells, depth + 1)
            end
        end
    end

    return cells
end


local findClosestExitPositionsCache = {}

---@param cell tes3cell
---@param onePerCell boolean?
---@return tes3vector3[]?
function this.findClosestExitPositions(cell, onePerCell)
    local cellRes = findClosestExitPositionsCache[cell] or this.findExitCells(cell)
    findClosestExitPositionsCache[cell] = cellRes
    if not cellRes then return end

    cellRes = table.values(cellRes, function (a, b)
        return a.depth < b.depth
    end)

    local lowestDepth
    ---@type tes3cell[]
    local cells = {}
    for _, dt in ipairs(cellRes) do
        if not lowestDepth then
            lowestDepth = dt.depth
        end

        if dt.depth == lowestDepth then
            table.insert(cells, dt.cell)
        else
            break
        end
    end

    local res = {}
    for _, cl in pairs(cells) do
        local dests = {}
        for door in cl:iterateReferences(tes3.objectType.door) do
            if door.destination and not door.deleted and not door.disabled and not door.destination.cell.isInterior then
                table.insert(dests, door.destination.marker.position:copy())
            end
        end

        if not next(dests) then goto continue end

        if onePerCell then
            local pos = table.choice(dests)
            table.insert(res, pos)
        else
            for _, pos in pairs(dests) do
                table.insert(res, pos)
            end
        end

        ::continue::
    end

    return res
end


local findNearestDoorCache = {}

---@param cell tes3cell?
---@param position tes3vector3
---@return tes3reference?
function this.findNearestDoor(position, cell)
    if not cell then
        cell = tes3.getCell{position = position}
        if not cell then return end
    end

    local hashVal = string.format("%d_%d_%d_%s", math.floor(position.x), math.floor(position.y), math.floor(position.z), cell.editorName)
    if findNearestDoorCache[hashVal] then
        return findNearestDoorCache[hashVal]
    end

    local nearestDoor
    local nearestdist = math.huge

    local function checkDoor(doorRef)
        if not doorRef.position then return end

        local dist = doorRef.position:distance(position)
        if nearestdist > dist then
            nearestdist = dist
            nearestDoor = doorRef
        end
    end

    if cell.isInterior then
        for doorRef in cell:iterateReferences(tes3.objectType.door) do
            checkDoor(doorRef)
        end
    else
        checkDoor(cell)
        if nearestdist > 500 then
            for i = -1, 1 do
                for j = -1, 1 do
                    local cl = tes3.getCell{x = cell.gridX + i, y = cell.gridY + j}
                    if cl then
                        for doorRef in cl:iterateReferences(tes3.objectType.door) do
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

return this