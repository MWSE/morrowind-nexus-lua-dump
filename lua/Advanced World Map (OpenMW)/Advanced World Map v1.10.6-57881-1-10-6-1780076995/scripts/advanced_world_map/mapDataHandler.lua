local core = require("openmw.core")
local storage = require("openmw.storage")
local types = require("openmw.types")
local util = require("openmw.util")

local pDoor = require("scripts.advanced_world_map.helpers.protectedDoor")

local log = require("scripts.advanced_world_map.utils.log")

local stringLib = require("scripts.advanced_world_map.utils.string")
local tableLib = require("scripts.advanced_world_map.utils.table")
local commonData = require("scripts.advanced_world_map.common")
local cellHelper = require("scripts.advanced_world_map.helpers.cell")

local this = {}

this.version = 7

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
---@type advancedWorldMap.dynamicDataHandler.transport
this.transport = nil

this.cellCount = 0
this.contentFileCount = 0

local initialized = false


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

---@class advancedWorldMap.dynamicDataHandler.transport
---@field nodes advancedWorldMap.dynamicDataHandler.transport.node[] list of transport nodes
---@field actors table<string, {tp: integer, ns: integer[]}> by npc record id
---@field data table<integer, integer[]> list of node ids by transport type (1 - caravaner, 2 - shipmaster, 3 - guild guide, 4 - gondolier)

---@class advancedWorldMap.dynamicDataHandler.transport.node
---@field tp integer type (1 - caravaner, 2 - shipmaster, 3 - guild guide, 4 - gondolier)
---@field p Vector2 position
---@field ls integer[] list of node ids that have this node in their list of destinations
---@field ars string[]? list of actor record ids that are on this node

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


---@param entrances table<string, advancedWorldMap.dynamicDataHandler.entranceData[]>
local function buildTransportData(entrances)
    local world = require("openmw.world")

    local transportNpcs = {}
    local nodes = {}
    local exitNodes = {}
    local transportClass = {
        ["caravaner"] = 1,
        ["shipmaster"] = 2,
        ["t_mw_riverstriderservice"] = 2,
        ["guild guide"] = 3,
        ["gondolier"] = 4,
    }
    local transport = {nodes = nodes, actors = transportNpcs, data = {}}
    for _, id in pairs(transportClass) do
        transport.data[id] = {}
    end
    transport.data[-1] = {}

    local function getNodeId(pos, tp)
        local unknownTypeNode
        local unknownTypeNodeId
        local unknownTypeNodeDist = math.huge
        local node
        local nodeId
        local dist = math.huge
        for i, nodeDt in pairs(nodes) do
            local d = commonData.distance2D(nodeDt.p, pos)

            if nodeDt.tp == tp or (tp == -1 and nodeDt.tp ~= -1) then
                if d < dist then
                    dist = d
                    node = nodeDt
                    nodeId = i
                end
            end

            if nodeDt.tp == -1 and tp ~= -1 then
                if d < unknownTypeNodeDist then
                    unknownTypeNodeDist = d
                    unknownTypeNode = nodeDt
                    unknownTypeNodeId = i
                end
            end
        end

        if node and dist < 2048 then
            return nodeId, node
        end

        if unknownTypeNode and unknownTypeNodeDist < 2048 then
            unknownTypeNode.tp = tp
            return unknownTypeNodeId, unknownTypeNode
        end

        local ind = #nodes + 1
        nodes[ind] = {tp = tp, p = pos, ls = {}}
        return ind, nodes[ind]
    end

    for _, rec in pairs(types.NPC.records) do
        if not rec.travelDestinations then
            goto continue
        end

        local data = {tp = transportClass[rec.class or ""] or -1, ns = {}}

        for _, destDt in pairs(rec.travelDestinations) do
            if not destDt.cellId then goto continue end
            if destDt.cellId:find(commonData.exteriorCellLabel) then
                local pos = destDt.position
                local nodeId = getNodeId(pos, data.tp)

                data.ns[nodeId] = true
            else
                local cachedExitNode = exitNodes[destDt.cellId]
                if cachedExitNode then
                    data.ns[cachedExitNode] = true
                else
                    local exits = cellHelper.findExitPoss(destDt.cellId, entrances)
                    if not exits or not exits[1] then goto continue end

                    local exit = exits[1]
                    local nodeId = getNodeId(exit, data.tp)
                    data.ns[nodeId] = true

                    exitNodes[destDt.cellId] = nodeId
                end
            end

            ::continue::
        end

        if next(data.ns) then
            data.ns = tableLib.keys(data.ns)
            transportNpcs[rec.id] = data
        end

        ::continue::
    end

    for _, cell in pairs(world.cells) do
        if not cell.id then goto continue end

        local actors = cell:getAll(types.NPC)
        for _, actor in pairs(actors) do
            local transporterData = transportNpcs[actor.recordId]
            if not transporterData then goto continue end

            local actorNodeId
            if cell.isExterior then
                actorNodeId = getNodeId(actor.position, transporterData.tp)
            else
                local cachedExitNode = exitNodes[cell.id]
                if cachedExitNode then
                    actorNodeId = cachedExitNode
                else
                    local exits = cellHelper.findExitPoss(cell.id, entrances)
                    if not exits or not exits[1] then goto continue end

                    local exit = exits[1]
                    local nodeId = getNodeId(exit, transporterData.tp)
                    actorNodeId = nodeId

                    exitNodes[cell.id] = nodeId
                end
            end

            if actorNodeId then
                local actorNode = nodes[actorNodeId]
                if actorNode then
                    actorNode.ars = actorNode.ars or {}
                    table.insert(actorNode.ars, actor.recordId)

                    for _, nodeId in pairs(transporterData.ns) do
                        if nodeId ~= actorNodeId then
                            local nDt = nodes[nodeId]
                            if not nDt then goto continue end

                            if nDt.tp == -1 then
                                nDt.tp = actorNode.tp
                            end

                            actorNode.ls[nodeId] = true
                        end

                        ::continue::
                    end

                end
            end

            ::continue::
        end

        ::continue::
    end

    for i, nodeDt in pairs(nodes) do
        nodeDt.ls = tableLib.keys(nodeDt.ls)
        table.insert(transport.data[nodeDt.tp], i)
    end

    return transport
end


local function buildData()
    local world = require("openmw.world")

    local function getRegionName(id)
        if not id then return "" end
        if not core.regions or not core.regions.records then return stringLib.capitalizeFirst(id) end

        local region = core.regions.records[id]
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

        if cell.gridX > 1000 or cell.gridX < -1000 or cell.gridY > 1000 or cell.gridY < -1000 then
            goto continue
        end

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
        if not cell.id then goto continue end

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

            local doorHash = commonData.doorHash(door, dest.id or "")

            entrances[cell.id] = entrances[cell.id] or {}
            ---@type advancedWorldMap.dynamicDataHandler.entranceData
            entrances[cell.id][doorHash] = {
                pos = door.position,
                cId = cell.id,
                isEx = cell.isExterior,
                dCId = dest.id or "",
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

    processLines(cellNameLines, 8192 * 6, 3072)

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

    this.transport = buildTransportData(entrances)
end


function this.globalBuildData(playerRef, options)
    buildData()
    playerRef:sendEvent("AdvWMap:updateMapData", {
        cellNameData = this.cellNameData,
        regionNameData = this.regionNameData,
        entrances = this.entrances,
        cellNameById = this.cellNameById,
        grid = this.grid,
        worldMapTileRectangles = this.worldMapTileRectangles,
        transport = this.transport,
        cellCount = this.cellCount,
        options = options,
        plId = playerRef.id,
    })
    initialized = true
end


function this.globalInit(playerRef, options)
    if not playerRef then return end
    local cells = require("openmw.world").cells
    playerRef:sendEvent("AdvWMap:initMapData", {cellCount = #cells, options = options})
end


function this.playerInit(playerRef, cellCount, options)
    local stor = storage.playerSection(commonData.mapDataStorageName)

    local shouldRebuild = stor:get("version") ~= this.version or stor:get("cellCount") ~= cellCount or
        stor:get("contentFileCount") ~= #core.contentFiles.list

    if shouldRebuild then
        if not commonData.isSaveBloatFixed() and require("scripts.advanced_world_map.config.config").data.data.safeInit then
            types.Player.sendMenuEvent(playerRef, "AdvWMap:startDataRebuilding", {plId = playerRef.id, options = options})
        else
            core.sendGlobalEvent("AdvWMap:rebuildMapData", {plId = playerRef.id, options = options})
        end
        return false
    else
        local data = stor:asTable()

        this.cellNameData = data.cellNameData or {}
        this.regionNameData = data.regionNameData or {}
        this.entrances = data.entrances or {}
        this.cellNameById = data.cellNameById or {}
        this.grid = data.grid or {min = {x = 0, y = 0}, max = {x = 0, y = 0}}
        this.worldMapTileRectangles = data.worldMapTileRectangles or {}
        this.transport = data.transport or {}
        this.cellCount = data.cellCount or 0
        this.contentFileCount = data.contentFileCount or 0

        core.sendGlobalEvent("AdvWMap:updateMapData", {
            cellNameData = this.cellNameData,
            regionNameData = this.regionNameData,
            entrances = this.entrances,
            cellNameById = this.cellNameById,
            grid = this.grid,
            worldMapTileRectangles = this.worldMapTileRectangles,
            transport = this.transport,
        })

        if options then
            playerRef:sendEvent("AdvWMap:processMapDataOptions", options)
        end

        initialized = true

        return true
    end
end



function this.updateData(playerRef, data)
    this.cellNameData = data.cellNameData or {}
    this.regionNameData = data.regionNameData or {}
    this.entrances = data.entrances or {}
    this.cellNameById = data.cellNameById or {}
    this.grid = data.grid or {min = {x = 0, y = 0}, max = {x = 0, y = 0}}
    this.worldMapTileRectangles = data.worldMapTileRectangles or {}
    this.transport = data.transport or {}
    this.cellCount = data.cellCount or 0
    this.contentFileCount = data.contentFileCount or 0

    local stor = storage.playerSection(commonData.mapDataStorageName)
    stor:set("cellNameData", this.cellNameData)
    stor:set("regionNameData", this.regionNameData)
    stor:set("entrances", this.entrances)
    stor:set("cellNameById", this.cellNameById)
    stor:set("grid", this.grid)
    stor:set("worldMapTileRectangles", this.worldMapTileRectangles)
    stor:set("transport", this.transport)
    stor:set("cellCount", this.cellCount)
    stor:set("contentFileCount", #core.contentFiles.list)
    stor:set("version", this.version)
    stor:set("apiVersion", core.API_REVISION)

    log("Map data updated and saved to storage")
    if not commonData.isSaveBloatFixed() and require("scripts.advanced_world_map.config.config").data.data.safeInit then
        types.Player.sendMenuEvent(playerRef, "AdvWMap:finishDataRebuilding", {plId = data.plId, options = data.options})
    else
        core.sendGlobalEvent("AdvWMap:processMapDataOptions", {plId = data.plId, options = data.options})
    end

    initialized = true
end


function this.loadMapData(data)
    this.cellNameData = data.cellNameData or {}
    this.regionNameData = data.regionNameData or {}
    this.entrances = data.entrances or {}
    this.cellNameById = data.cellNameById or {}
    this.grid = data.grid or {min = {x = 0, y = 0}, max = {x = 0, y = 0}}
    this.worldMapTileRectangles = data.worldMapTileRectangles or {}
    this.transport = data.transport or {}

    initialized = true
end


function this.isInitialized()
    return initialized
end


return this