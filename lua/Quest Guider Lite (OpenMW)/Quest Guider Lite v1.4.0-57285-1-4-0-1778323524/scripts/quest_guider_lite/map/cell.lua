local I = require("openmw.interfaces")

local utils = require("scripts.quest_guider_lite.utils.common")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local cacheLib = require("scripts.quest_guider_lite.utils.cache")


local maxDepth = 10
local exCellFormat = "Esm3ExteriorCell:%d:%d"


local this = {}


local function getExteriorCellId(gridX, gridY)
    return exCellFormat:format(gridX, gridY)
end


---@param data AdvancedWorldMap.DataHandler.EntranceData
---@return tes3cellData
function this.getEntranceCellData(data)
    local gridX = data.isEx and math.floor(data.pos.x / 8192) or nil
    local gridY = data.isEx and math.floor(data.pos.y / 8192) or nil
    ---@type tes3cellData
    local out = {
        id = not data.isEx and data.cId or nil,
        name = data.isEx and I.AdvancedWorldMap.getExteriorCellName(data.pos) or I.AdvancedWorldMap.getCellNameById(data.cId) or "",
        gridX = gridX,
        gridY = gridY,
        isExterior = data.isEx
    }

    return out
end


---@param data AdvancedWorldMap.DataHandler.EntranceData
---@return tes3cellData
function this.getEntranceDestCellData(data)
    local gridX = data.isDEx and math.floor(data.dPos.x / 8192) or nil
    local gridY = data.isDEx and math.floor(data.dPos.y / 8192) or nil
    ---@type tes3cellData
    local out = {
        id = not data.isDEx and data.dCId or nil,
        name = data.fName,
        gridX = gridX,
        gridY = gridY,
        isExterior = data.isDEx
    }

    return out
end


---@param cellId string
---@return tes3vector3|nil outPos
---@return tes3travelDestinationNode[]|nil doorPath
---@return tes3cellData[]|nil cellPath
---@return boolean|nil isExterior
---@return table<string,tes3cell>|nil checkedCells
---@return number|nil depth
function this.findExitPos(cellId, path, checked, cellPath, depth)
    if not checked then checked = {} end
    if not path then path = {} end
    if not depth then depth = 1 end

    ---@type table<string, AdvancedWorldMap.DataHandler.EntranceData>
    local doors = I.AdvancedWorldMap.getEntranceMarkerData(cellId)
    if not doors then
        return nil, nil, nil, nil, checked, depth
    end

    local _, doorDt = next(doors)
    if not doorDt then
        return nil, nil, nil, nil, checked, depth
    end

    local cellData = this.getEntranceCellData(doorDt)

    if not cellPath then
        cellPath = {}
        table.insert(cellPath, cellData)
    end

    if (checked[cellId] and checked[cellId] < depth) or depth > maxDepth then
        return nil, nil, nil, nil, checked, depth
    end
    checked[cellId] = math.min(checked[cellId] or depth, depth)

    if depth == 1 then
        local cacheData = cacheLib.get("findExitPosAdvWM", cellId)
        if cacheData then
            return table.unpack(cacheData) ---@diagnostic disable-line: redundant-return-value
        end
    end

    local bestResult = nil

    for _, door in pairs(doors) do
        if checked[door.dCId] and checked[door.dCId] < depth + 1 then goto continue end

        local destCellData = this.getEntranceDestCellData(door)

        table.insert(path, {doorDt = door, cId = cellId, cellData = destCellData, marker = {position = door.dPos}})
        table.insert(cellPath, destCellData)

        local candidate
        if door.isDEx or door.isDLEx then
            candidate = {door.dPos, tableLib.copy(path), tableLib.copy(cellPath), door.isDEx, checked, depth}
        else
            local out, destPath, cPath, isEx, ch, dp = this.findExitPos(door.dCId, path, checked, cellPath, depth + 1)
            if out then
                candidate = {out, destPath, cPath, isEx, checked, dp}
            end
        end

        table.remove(path)
        table.remove(cellPath)

        if candidate then
            if not bestResult or candidate[6] < bestResult[6] then
                bestResult = candidate
            end

            if bestResult[6] == 1 then break end
        end

        ::continue::
    end

    if bestResult then
        local res = bestResult
        for _, drData in pairs(res[2] or {}) do
            if drData.doorDt then
                if drData.cellData.isExterior then
                    ---@diagnostic disable-next-line: undefined-field
                    local door = this.findNearestDoor(drData.marker.position, not drData.doorDt.isDEx and drData.doorDt.dCId or nil)

                    ---@diagnostic disable-next-line: undefined-field
                    if door then
                        if door.dCId == drData.cId then ---@diagnostic disable-line: undefined-field
                            drData.pos = door.pos or drData.marker.position
                        else
                            drData.pos = drData.marker.position
                        end
                    else
                        drData.pos = drData.marker.position
                    end
                else
                    ---@diagnostic disable-next-line: undefined-field
                    local door = this.findNearestDoor(drData.marker.position, not drData.doorDt.isDEx and drData.doorDt.dCId or nil)
                    drData.pos = door and door.pos or drData.marker.position
                end

                drData.doorDt = nil ---@diagnostic disable-line: inject-field
                drData.cId = nil ---@diagnostic disable-line: inject-field
            end
        end

        if depth == 1 then
            cacheLib.set("findExitPosAdvWM", cellId, {table.unpack(bestResult)})
        end

        return table.unpack(bestResult) ---@diagnostic disable-line: redundant-return-value
    end

    return nil, nil, nil, nil, checked, depth
end


---@param cellId string
---@param position tes3vector3
---@return AdvancedWorldMap.DataHandler.EntranceData?
function this.findNearestDoor(position, cellId)
    local hashVal = string.format("%d_%d_%d_%s", math.floor(position.x), math.floor(position.y), math.floor(position.z), cellId)
    local cachedVal = cacheLib.get("findNearestDoorAdvWM", hashVal)
    if cachedVal then
        return cachedVal
    end
    local nearestDoor
    local nearestdist = math.huge

    ---@param doorDt AdvancedWorldMap.DataHandler.EntranceData
    local function checkDoor(doorDt)
        local dist = (doorDt.pos - position):length()
        if nearestdist > dist then
            nearestdist = dist
            nearestDoor = doorDt
        end
    end

    local function checkDoorsInCell(cId)
        ---@type table<string, AdvancedWorldMap.DataHandler.EntranceData>
        local doors = I.AdvancedWorldMap.getEntranceMarkerData(cellId)
        if not doors then return end

        for _, door in pairs(doors) do
            checkDoor(door)
        end
    end

    if cellId then
        checkDoorsInCell(cellId)
    else
        local gridX = math.floor(position.x / 8192)
        local gridY = math.floor(position.y / 8192)

        for i = -1, 1 do
            for j = -1, 1 do
                local doors = I.AdvancedWorldMap.getEntranceMarkerData(getExteriorCellId(gridX + i, gridY + j))
                if doors then
                    for _, door in pairs(doors) do
                        checkDoor(door)
                    end
                end
            end
        end
    end

    cacheLib.set("findNearestDoorAdvWM", hashVal, nearestDoor)
    return nearestDoor
end


---@param cellId string
---@return {pos : tes3vector3, depth : number}[]?
---@return table<string, string>?
---@return table<string, integer>? entranceCells
---@return number? lowestDepth
function this.findExitPositions(cellId, checked, res, resCells, entranceCells, depth)
    if not checked then checked = {} end
    if not entranceCells then entranceCells = {} end
    if not res then res = {} end
    if not depth then depth = 0 end

    ---@type table<string, AdvancedWorldMap.DataHandler.EntranceData>
    local doors = I.AdvancedWorldMap.getEntranceMarkerData(cellId)
    if not doors then
        return
    end

    local _, doorDt = next(doors)
    if not doorDt then
        return
    end

    if doorDt.isEx then
        resCells[doorDt.cId] = doorDt.cId
        return
    end
    if checked[doorDt.cId] then
        checked[doorDt.cId] = math.min(checked[doorDt.cId], depth)
        if entranceCells[doorDt.cId] then
            entranceCells[doorDt.cId] = math.min(entranceCells[doorDt.cId], depth)
        end
        return
    end

    local cachedVal = cacheLib.get("findExitPositionsAdvWM", doorDt.cId)
    if cachedVal then
        return table.unpack(cachedVal) ---@diagnostic disable-line: redundant-return-value
    end

    checked[doorDt.cId] = depth

    for _, door in pairs(doors) do
        if door.isDEx then
            table.insert(res, {pos = door.dPos, depth = depth})
            entranceCells[doorDt.cId] = depth
        else
            this.findExitPositions(door.dCId, checked, res, resCells, entranceCells, depth + 1)
        end
    end

    local lowestDepth = 9999
    for _, dpt in pairs(entranceCells) do
        lowestDepth = math.min(lowestDepth, dpt)
    end

    if depth == 0 then
        cacheLib.set("findExitPositionsAdvWM", doorDt.cId, {res, resCells, entranceCells, lowestDepth})
    end
    return res, resCells, entranceCells, lowestDepth
end


---@return table<string, {position : any, distance : number, namePath : string[]}> ret by lowercase cell id. __world__ - for exterior
function this.getInteriorCellApproxDistancesToPos(cellId, pos, distance, checked, namePath)
    if not checked then checked = {} end
    if not distance then distance = 0 end
    if not namePath then namePath = {} end

    if not cellId or checked[cellId] and checked[cellId].distance <= distance then return checked end

    local hashVal = string.format("%s_%d_%d", cellId, math.floor(pos.x), math.floor(pos.y))
    local cachedVal = cacheLib.get("getInteriorCellApproxDistancesToPos", hashVal)
    if cachedVal then
        return cachedVal
    end

    ---@type table<string, AdvancedWorldMap.DataHandler.EntranceData>
    local doors = I.AdvancedWorldMap.getEntranceMarkerData(cellId)
    if not doors then
        return checked
    end

    local _, doorDt = next(doors)
    if not doorDt then
        return checked
    end

    local cellData = this.getEntranceCellData(doorDt)

    table.insert(namePath, cellData.name or "")

    if cellData.isExterior then
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

    for _, door in pairs(doors) do
        this.getInteriorCellApproxDistancesToPos(door.dCId, door.dPos, distance + (pos - door.pos):length(), checked, tableLib.copy(namePath))
    end

    cacheLib.set("getInteriorCellApproxDistancesToPos", hashVal, checked)
    return checked
end


---@param posData questGuider.quest.getRequirementPositionData.positionData[]
function this.fillDistanceToPlayer(posData, playerRef)
    local plPos = playerRef.position
    local plCellId = playerRef.cell.id

    local interiorCellDistance = this.getInteriorCellApproxDistancesToPos(plCellId, plPos)
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


function this.isReady()
    return I.AdvancedWorldMap and I.AdvancedWorldMap.version >= 11 and I.AdvancedWorldMap.isMapDataInitialized() or false
end


return this