local I = require("openmw.interfaces")
local async = require("openmw.async")
local core = require("openmw.core")

local common = require("scripts.advanced_world_map_tracking.common")
local activeObjects = require("scripts.advanced_world_map_tracking.handlers.activeObjects")
local activeMarkers = require("scripts.advanced_world_map_tracking.handlers.activeMarkers")
local dataHandler = require("scripts.advanced_world_map_tracking.data.dataHandler")
local tableLib = require("scripts.advanced_world_map_tracking.utils.table")
local config = require("scripts.advanced_world_map_tracking.config.config")


local this = {}

---@type AdvancedWorldMap.Interface?
local advancedWorldMap = nil


---@type table<string, string>
this.activeCells = {}



local function removeActiveCells(cellId)
    if cellId then
        this.activeCells[cellId] = nil
    else
        for cId, cTp in pairs(this.activeCells) do
            if this.activeCells[cId] == common.worldCellLabel then
                this.activeCells[cId] = nil
            end
        end
    end
end


local function addPosMarkers(cellIdMap, rect, isZoomOut)
    if isZoomOut and rect then
        for _, markerData in dataHandler.iterMarkerGroup(common.worldCellLabel) do
            for _, posDt in pairs(markerData.positions or {}) do
                if common.isPointInRegion(rect, posDt.pos) then
                    activeMarkers.register(markerData)
                    break
                end
            end
        end
    elseif not isZoomOut then
        for cellId, _ in pairs(this.activeCells) do
            for _, markerData in dataHandler.iterMarkerGroup(cellId) do
                activeMarkers.register(markerData)
            end
        end
    else
        local cellId = next(cellIdMap)
        if not cellId then return end

        for _, markerData in dataHandler.iterMarkerGroup(cellId) do
            activeMarkers.register(markerData)
        end
    end
end


local function addObjectMarkers(cellIdMap)
    for _, markerData in dataHandler.iterMarkerGroup(common.objectsLabel) do
        for _, obj in pairs(markerData.objects or {}) do

            if not obj:isValid() or not cellIdMap[obj.cell.id] then goto continue end
            local handler = activeObjects.getHandler(obj.recordId)
            if not handler then goto continue end
            local objHandler = handler:get(obj.id)

            if objHandler then
                activeMarkers.register(markerData, objHandler)
            end

            ::continue::
        end
    end

    for _, markerData in dataHandler.iterMarkerGroup(common.recordsLabel) do
        for _, recordId in pairs(markerData.records or {}) do
            for _, objHandler in activeObjects.getObjectIterator(recordId) do
                if cellIdMap[objHandler.cell.id] then
                    activeMarkers.register(markerData, objHandler)
                end
            end
        end
    end

    for _, markerData in dataHandler.iterMarkerGroup(common.typesLabel) do
        for _, typeId in pairs(markerData.types or {}) do
            for _, objHandler in activeObjects.getObjectIterator(typeId) do
                if cellIdMap[objHandler.cell.id] then
                    activeMarkers.register(markerData, objHandler)
                end
            end
        end
    end

    for cellId, _ in pairs(cellIdMap) do
        activeObjects.requestCellObjects(cellId)
    end
end


function this.init()
    if not I.AdvancedWorldMap or I.AdvancedWorldMap.version < 10 then
        print("[Advanced World Map]: Tracking module requires Advanced World Map version 1.6.0 or higher.")
        return
    end

    ---@type AdvancedWorldMap.Interface
    advancedWorldMap = I.AdvancedWorldMap
    activeMarkers.advWMap = advancedWorldMap


    tableLib.addMissing(config.data, advancedWorldMap.getConfig())

    local events = advancedWorldMap.events

    events.EVENT.onTrackingTooltipShow = "onTrackingTooltipShow"


    events.registerHandler(events.EVENT.onMapInitialized, function (e)
        activeMarkers.registerMapWidget(e.mapWidget)

        if e.cellId then
            this.activeCells[e.cellId] = e.cellId
            addPosMarkers({[e.cellId] = true})
            addObjectMarkers({[e.cellId] = true})
        end
    end)


    events.registerHandler(events.EVENT.onMapDestroyed, function (e)
        activeMarkers.unregisterMapWidget(e.mapWidget)
        removeActiveCells(e.mapWidget.cellId)
    end)


    local lastUpdatedMap = nil
    ---@type AdvancedWorldMap.MapWidget.Region?
    local lastUpdatedRect = nil
    ---@param e AdvancedWorldMap.Event.OnZoomMarkersUpdatedEvent
    local function onZoomMarkersUpdatedCallback(e)
        activeMarkers.registerMapWidget(e.mapWidget)
        lastUpdatedMap = e.mapWidget.cellId or common.worldCellLabel

        if e.mapWidget.cellId then return end

        if lastUpdatedRect and lastUpdatedRect.left == e.region.left and lastUpdatedRect.right == e.region.right and
                lastUpdatedRect.top == e.region.top and lastUpdatedRect.bottom == e.region.bottom then
            return
        end

        lastUpdatedRect = e.region

        activeMarkers.clearRegisterQueue()
        activeMarkers.removeMarkersOutsideRegion(e.region)
        removeActiveCells()

        local cells = {}

        local isZoomOut = not e.mapWidget:isInZoomInMode()

        if isZoomOut then
            addPosMarkers(cells, e.region, true)
            this.activeCells[common.worldCellLabel] = common.worldCellLabel
        else
            local region = e.region
            for x = math.floor(region.left / 8192), math.floor(region.right / 8192) do
                for y = math.floor(region.bottom / 8192), math.floor(region.top / 8192) do
                    local cId = common.getCellIdByGrid(x, y)
                    cells[cId] = true
                    this.activeCells[cId] = common.worldCellLabel
                end
            end

            addPosMarkers(cells, e.region, false)
            addObjectMarkers(cells)
        end
    end
    events.registerHandler(events.EVENT.onZoomMarkersUpdated, onZoomMarkersUpdatedCallback)

    events.registerHandler(events.EVENT.onMapShown, function (e)
        local mapWidget = e.menu.mapWidget
        if lastUpdatedMap ~= (e.cellId or common.worldCellLabel) and mapWidget.onZoomMarkersRect then
            onZoomMarkersUpdatedCallback({
                mapWidget = mapWidget,
                region = mapWidget.onZoomMarkersRect
            })
            lastUpdatedMap = e.cellId or common.worldCellLabel
        end
        activeMarkers.updateCell(e.cellId)

        activeMarkers.startUpdateVisibilityCoroutine(e.cellId, advancedWorldMap.realTimer) ---@diagnostic disable-line: undefined-field
    end)


    events.registerHandler(events.EVENT.onMapElementRemoved, function (e)
        ---@type activeMarkers.markerUserdata
        local userData = e.marker:getUserData()
        if not userData or userData.type ~= common.userDataMarkerType then return end

        activeMarkers.removeActiveMarker(e.mapWidget.cellId, e.marker)
    end)


    events.registerHandler(events.EVENT.onMapElementCreated, function (e)
        ---@type activeMarkers.markerUserdata
        local userData = e.marker:getUserData()
        if not userData or userData.type ~= common.userDataMarkerType then return end

        activeMarkers.addActiveMarker(e.mapWidget.cellId, e.marker)
    end)


    events.registerHandler(events.EVENT.onUpdate, function (e)
        local mapWidget = e.menu.mapWidget
        local cellId = mapWidget.cellId or common.worldCellLabel

        if activeMarkers.updatePositions(cellId) then
            e.menu:requestUpdate()
        end
    end)


    events.registerHandler(events.EVENT.onMenuOpened, function (e)
        activeMarkers.registerMenu(e.menu)
    end)


    events.registerHandler(events.EVENT.onMenuClosed, function (e)
        activeMarkers.unregisterMenu()
        activeObjects.clearInactive()
        activeMarkers.removeInvalid()
        activeMarkers.destroyUpdateVisibilityCoroutine()
        lastUpdatedMap = nil
        lastUpdatedRect = nil
    end)

    print("[Advanced World Map]: Tracking module initialized.")

    return true
end


function this.isInit()
    return advancedWorldMap ~= nil
end


return this