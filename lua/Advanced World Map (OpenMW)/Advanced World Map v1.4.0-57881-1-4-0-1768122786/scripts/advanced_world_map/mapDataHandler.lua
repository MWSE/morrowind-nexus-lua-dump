local core = require("openmw.core")
local storage = require("openmw.storage")
local types = require("openmw.types")
local util = require("openmw.util")

local pDoor = require("scripts.advanced_world_map.helpers.protectedDoor")

local log = require("scripts.advanced_world_map.utils.log")

local stringLib = require("scripts.advanced_world_map.utils.string")
local tableLib = require("scripts.advanced_world_map.utils.table")
local commonData = require("scripts.advanced_world_map.common")

local this = {}

this.version = 2

---@type table<string, advancedWorldMap.dynamicDataHandler.cellData> by cell name
this.cellNameData = nil
---@type table<string, advancedWorldMap.dynamicDataHandler.cellData> by region name
this.regionNameData = nil
---@type table<string, advancedWorldMap.dynamicDataHandler.entranceData[]> by cell id
this.entrances = nil
---@type table<string, string> by cell id
this.cellNameById = nil
---@type {max : {x : integer, y : integer}, min : {x : integer, y : integer}}
this.grid = nil
---@type {[1] : number, [2] : number, [3] : number, [4] : number}[]
this.worldMapTileRectangles = {}

this.cellCount = 0
this.contentFileCount = 0


---@class advancedWorldMap.dynamicDataHandler.cellData
---@field posX number
---@field posY number
---@field name string
---@field count integer

---@class advancedWorldMap.dynamicDataHandler.entranceData
---@field pos any position
---@field cId string cell id
---@field isEx boolean is in exterior cell
---@field isLEx boolean is destination in like exterior cell
---@field dCId string destination cell id
---@field dPos any destination position
---@field isDEx boolean is destination cell exterior
---@field isDLEx boolean is destination cell like exterior
---@field name string destination cell name
---@field fName string destination cell full name
---@field dHash string door hash

local function isContentFile(name)
    name = name:lower()

    local suffixes = {"esm", "esp", "omwaddon"}
    for _, suf in ipairs(suffixes) do
        if stringLib.isEndsWith(name, suf) then
            return true
        end
    end
    return false
end


local function findMaxRectangle(occupied)
    local bestX1, bestY1, bestX2, bestY2, bestArea = nil, nil, nil, nil, 0

    for x, col in pairs(occupied) do
        for y in pairs(col) do
            if not col[y] then goto continue end

            local maxX = x
            while occupied[maxX + 1] and occupied[maxX + 1][y] do
                maxX = maxX + 1
            end

            local maxY = y
            local canExpand = true
            while canExpand do
                local nextY = maxY + 1
                for xi = x, maxX do
                    if not (occupied[xi] and occupied[xi][nextY]) then
                        canExpand = false
                        break
                    end
                end
                if canExpand then
                    maxY = nextY
                end
            end

            local area = (maxX - x + 1) * (maxY - y + 1)
            if area > bestArea then
                bestX1, bestY1, bestX2, bestY2, bestArea = x, y, maxX, maxY, area
            end

            ::continue::
        end
    end

    if bestArea > 0 then
        return bestX1, bestY1, bestX2, bestY2
    end
    return nil
end

local function worldCoverWithRectangles(occupied)
    local res = {}

    while true do
        local x1, y1, x2, y2 = findMaxRectangle(occupied)
        if not x1 then break end

        table.insert(res, {x1, y1, x2, y2})

        for x = x1, x2 do
            local col = occupied[x]
            if col then
                for y = y1, y2 do
                    col[y] = nil
                end

                if not next(col) then
                    occupied[x] = nil
                end
            end
        end
    end

    return res
end


local function worldCoverWithRectanglesFast(occupied)
    local res = {}

    local xCoords = {}
    for x in pairs(occupied) do
        table.insert(xCoords, x)
    end
    table.sort(xCoords)

    for _, x in ipairs(xCoords) do
        local col = occupied[x]
        if col then
            local yCoords = {}
            for y in pairs(col) do
                table.insert(yCoords, y)
            end
            table.sort(yCoords)

            local i = 1
            while i <= #yCoords do
                local y1 = yCoords[i]
                local y2 = y1

                while i < #yCoords and yCoords[i + 1] == y2 + 1 do
                    i = i + 1
                    y2 = yCoords[i]
                end

                local x2 = x
                local canExpandX = true
                while canExpandX do
                    local nextX = x2 + 1
                    local nextCol = occupied[nextX]
                    if nextCol then

                        for y = y1, y2 do
                            if not nextCol[y] then
                                canExpandX = false
                                break
                            end
                        end

                        if canExpandX then
                            x2 = nextX
                        end
                    else
                        canExpandX = false
                    end
                end

                table.insert(res, {x, y1, x2, y2})

                for xi = x, x2 do
                    local c = occupied[xi]
                    if c then
                        for y = y1, y2 do
                            c[y] = nil
                        end
                        if not next(c) then
                            occupied[xi] = nil
                        end
                    end
                end

                i = i + 1
            end
        end
    end

    return res
end



local function buildData()
    local world = require("openmw.world")

    local function getRegionName(id)
        if not id then return "" end
        if not core.regions then return stringLib.capitalizeFirst(id) end

        local region = core.regions[id]
        if not region then return stringLib.capitalizeFirst(id) end

        return region.name or ""
    end

    this.cellNameById = {}

    local minGridX = math.huge
    local minGridY = math.huge
    local maxGridX = -math.huge
    local maxGridY = -math.huge

    local cellNameData = {}
    local regionNameData = {}
    local entrances = {}
    local occupied = {}
    this.cellCount = #world.cells
    for _, cell in pairs(world.cells) do
        if not cell.isExterior then goto continue end

        minGridX = math.min(minGridX, cell.gridX)
        maxGridX = math.max(maxGridX, cell.gridX)
        minGridY = math.min(minGridY, cell.gridY)
        maxGridY = math.max(maxGridY, cell.gridY)

        if core.land then
            local posX = cell.gridX * 8192
            local posY = cell.gridY * 8192
            local aboveWater = 0
            for i = 1024, 8192, 2048 do
                for j = 1024, 8192, 2048 do
                    if core.land.getHeightAt(util.vector3(posX + i, posY + j, 0), cell) > 0 then
                        aboveWater = aboveWater + 1
                    end
                end
            end
            if aboveWater > 8 then
                occupied[cell.gridX] = occupied[cell.gridX] or {}
                occupied[cell.gridX][cell.gridY] = true
            end
        else
            occupied[cell.gridX] = occupied[cell.gridX] or {}
            occupied[cell.gridX][cell.gridY] = true
        end

        if not cell.name or cell.name == "" then goto continue end

        local name = stringLib.getBeforeComma(cell.name)

        local cellDt = cellNameData[name]
        if not cellDt then
            cellDt = {
                name = stringLib.getBeforeComma(cell.displayName or cell.name), count = 0,
                minX = math.huge, maxX = -math.huge,
                minY = math.huge, maxY = -math.huge,
            }
            cellNameData[name] = cellDt
        end

        cellDt.minX = math.min(cell.gridX, cellDt.minX)
        cellDt.minY = math.min(cell.gridY, cellDt.minY)
        cellDt.maxX = math.max(cell.gridX, cellDt.maxX)
        cellDt.maxY = math.max(cell.gridY, cellDt.maxY)
        cellDt.count = cellDt.count + 1

        if cell.region then
            local regDt = regionNameData[cell.region]
            if not regDt then
                regDt = {
                    name = getRegionName(cell.region), count = 0,
                    minX = math.huge, maxX = -math.huge,
                    minY = math.huge, maxY = -math.huge,
                }
                regionNameData[cell.region] = regDt
            end

            regDt.minX = math.min(cell.gridX, regDt.minX)
            regDt.minY = math.min(cell.gridY, regDt.minY)
            regDt.maxX = math.max(cell.gridX, regDt.maxX)
            regDt.maxY = math.max(cell.gridY, regDt.maxY)
            regDt.count = regDt.count + 1
        end

        ::continue::
    end


    local function buildRectMapFast()
        this.worldMapTileRectangles = worldCoverWithRectanglesFast(occupied)
    end

    if not pcall(buildRectMapFast) then
        log("Error building world map tile rectangles")
        this.worldMapTileRectangles = {}
    end

    this.grid = {min = {x = minGridX, y = minGridY}, max = {x = maxGridX, y = maxGridY}}

    local function getCellName(cell)
        local name = cell.displayName or cell.name
        if cell.isExterior then
            if not name or name == "" then
                name = getRegionName(cell.region)
            end
        end
        return name
    end

    for _, cell in pairs(world.cells) do

        this.cellNameById[cell.id] = getCellName(cell)

        local doors = cell:getAll(types.Door)
        for _, door in pairs(doors) do
            if not types.Door.isTeleport(door) then goto continue end

            local dest = pDoor.destCell(door)
            local destPos = pDoor.destPosition(door)

            if not dest or not destPos then goto continue end

            local name = getCellName(dest)
            if name:find(",") then
                if cell.isExterior then
                    local cellNameMark = stringLib.getBeforeComma(cell.name)
                    if cellNameData[cellNameMark] then
                        name = stringLib.getAfterComma(name)
                    end
                else
                    name = stringLib.getAfterComma(name)
                end
            end

            local doorHash = commonData.doorHash(door, dest.id)

            entrances[cell.id] = entrances[cell.id] or {}
            ---@type advancedWorldMap.dynamicDataHandler.entranceData
            entrances[cell.id][doorHash] = {
                pos = door.position,
                cId = cell.id,
                isEx = cell.isExterior,
                dCId = dest.id,
                dPos = destPos,
                isDEx = dest.isExterior,
                name = name,
                fName = getCellName(dest),
                dHash = doorHash,
                isDLEx = dest.isExterior or dest:hasTag("QuasiExterior"),
                isLEx = cell.isExterior or cell:hasTag("QuasiExterior"),
            }

            ::continue::
        end

        ::continue::
    end


    local cellNameLines = {}
    local cellNames = {}
    for _, dt in pairs(cellNameData) do
        if dt.count < 1 then goto continue end

        local posX = (dt.minX + (dt.maxX - dt.minX) / 2) * 8192 + 4096
        local posY = (dt.minY + (dt.maxY - dt.minY) / 2) * 8192 + 4096

        local cellDt = {
            name = dt.name,
            count = dt.count,
            posX = posX,
            posY = posY,
        }
        cellNames[dt.name] = cellDt

        local hash = math.floor(posY / 4096)
        for i = -1, 1 do
            local h = hash + i
            cellNameLines[h] = cellNameLines[h] or {}
            table.insert(cellNameLines[h], cellDt)
        end

        ::continue::
    end


    local function processLines(lines, xPosDiff, heightDiff)
        local heightDiffHalf = heightDiff / 2
        for _, lineElems in pairs(lines) do

            table.sort(lineElems, function (a, b)
                return a.posX < b.posX
            end)

            for j = 2, #lineElems do
                local el1 = lineElems[j - 1]
                local el2 = lineElems[j]
                if el2.posX - el1.posX < xPosDiff and math.abs(el2.posY - el1.posY) < heightDiff then
                    if el1.posY > el2.posY then
                        el1.posY = el1.posY + heightDiffHalf
                        el2.posY = el2.posY - heightDiffHalf
                    else
                        el1.posY = el1.posY - heightDiffHalf
                        el2.posY = el2.posY + heightDiffHalf
                    end
                end
            end
        end
    end

    processLines(cellNameLines, 8192 * 6, 4096)

    this.cellNameData = cellNames


    local regNameLines = {}
    local regNames = {}
    for _, dt in pairs(regionNameData) do
        if dt.count < 1 then goto continue end

        local posX = (dt.minX + (dt.maxX - dt.minX) / 2) * 8192 + 4096
        local posY = (dt.minY + (dt.maxY - dt.minY) / 2) * 8192 + 4096

        local cellDt = {
            name = dt.name,
            count = dt.count,
            posX = posX,
            posY = posY,
        }
        regNames[dt.name] = cellDt

        local hash = math.floor(posY / 8192)
        for i = -1, 1 do
            local h = hash + i
            regNameLines[h] = regNameLines[h] or {}
            table.insert(regNameLines[h], cellDt)
        end

        ::continue::
    end

    processLines(regNameLines, 8192 * 12, 8192)

    this.regionNameData = regNames


    for cellId, list in pairs(entrances) do
        entrances[cellId] = tableLib.values(list)
    end
    this.entrances = entrances

end


function this.globalBuildData()
    buildData()
    require("openmw.world").players[1]:sendEvent("AdvWMap:updateMapData", {
        cellNameData = this.cellNameData,
        regionNameData = this.regionNameData,
        entrances = this.entrances,
        cellNameById = this.cellNameById,
        grid = this.grid,
        worldMapTileRectangles = this.worldMapTileRectangles,
        cellCount = this.cellCount,
    })
end


function this.globalInit()
    local cells = require("openmw.world").cells
    require("openmw.world").players[1]:sendEvent("AdvWMap:initMapData", {cellCount = #cells})
end


function this.playerInit(cellCount)
    local stor = storage.playerSection(commonData.mapDataStorageName)

    local shouldRebuild = stor:get("version") ~= this.version or stor:get("cellCount") ~= cellCount or
        stor:get("apiVersion") ~= core.API_REVISION or stor:get("contentFileCount") ~= #core.contentFiles.list

    if shouldRebuild then
        core.sendGlobalEvent("AdvWMap:rebuildMapData")
        return false
    else
        this.cellNameData = stor:get("cellNameData") or {}
        this.regionNameData = stor:get("regionNameData") or {}
        this.entrances = stor:get("entrances") or {}
        this.cellNameById = stor:get("cellNameById") or {}
        this.grid = stor:get("grid") or {min = {x = 0, y = 0}, max = {x = 0, y = 0}}
        this.worldMapTileRectangles = stor:get("worldMapTileRectangles") or {}
        this.cellCount = stor:get("cellCount") or 0
        this.contentFileCount = stor:get("contentFileCount") or 0

        return true
    end
end



function this.updateData(data)
    this.cellNameData = data.cellNameData or {}
    this.regionNameData = data.regionNameData or {}
    this.entrances = data.entrances or {}
    this.cellNameById = data.cellNameById or {}
    this.grid = data.grid or {min = {x = 0, y = 0}, max = {x = 0, y = 0}}
    this.worldMapTileRectangles = data.worldMapTileRectangles or {}
    this.cellCount = data.cellCount or 0
    this.contentFileCount = data.contentFileCount or 0

    local stor = storage.playerSection(commonData.mapDataStorageName)
    stor:set("cellNameData", this.cellNameData)
    stor:set("regionNameData", this.regionNameData)
    stor:set("entrances", this.entrances)
    stor:set("cellNameById", this.cellNameById)
    stor:set("grid", this.grid)
    stor:set("worldMapTileRectangles", this.worldMapTileRectangles)
    stor:set("cellCount", this.cellCount)
    stor:set("contentFileCount", #core.contentFiles.list)
    stor:set("version", this.version)
    stor:set("apiVersion", core.API_REVISION)

    log("Map data updated and saved to storage")
end


function this.isInitialized()
    return this.cellNameData ~= nil and this.regionNameData ~= nil and this.entrances ~= nil and
        this.cellNameById ~= nil and this.grid ~= nil and this.worldMapTileRectangles ~= nil
end


return this