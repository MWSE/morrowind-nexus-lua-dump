local objectCache = include("diject.mapMarkerLib.objectCache")
local activeCells = include("diject.mapMarkerLib.activeCells")
local markerLib = include("diject.mapMarkerLib.marker")
local mcm = include("diject.mapMarkerLib.mcm")

local cellBeforeLoad

--- @param e saveEventData
local function saveCallback(e)
    if not markerLib.enabled then return end
    markerLib.save()
end
event.register(tes3.event.save, saveCallback)

--- @param e uiActivatedEventData
local function menuMapActivated(e)
    if not markerLib.enabled then return end

    local menu = e.element
    markerLib.initMapMenuInfo(menu)

    menu:getTopLevelMenu():registerAfter(tes3.uiEvent.update, function (e1)
        if not markerLib.isMapMenuInitialized then return end

        if markerLib.menu.localMap.visible then
            markerLib.activeMenu = "MenuMapLocal"
            markerLib.createLocalMarkers()
            markerLib.updateLocalMarkers()
        elseif markerLib.menu.worldMap.visible then
            local redraw = markerLib.activeMenu ~= "MenuMapWorld"
            markerLib.activeMenu = "MenuMapWorld"
            markerLib.createWorldMarkers()
            markerLib.updateWorldMarkers(redraw)
        end
        markerLib.removeDeletedMarkers()
    end)

    menu:updateLayout()
end

event.register(tes3.event.uiActivated, menuMapActivated, {filter = "MenuMap", priority = -277})

do
    local menu = tes3ui.findMenu("MenuMap")
    if menu and markerLib.enabled then
        menuMapActivated({claim = false, element = menu, newlyCreated = true})
    end
end

--- @param e uiActivatedEventData
local function menuMultiActivated(e)
    if not markerLib.enabled then return end

    local menu = e.element
    markerLib.initMultiMenuInfo(menu)

    menu:getTopLevelMenu():registerAfter(tes3.uiEvent.update, function (e1)
        if not markerLib.isMultiMenuInitialized then return end

        if markerLib.menu.multiMap.visible and os.clock() - markerLib.lastLocalUpdate > markerLib.minDelayBetweenUpdates then
            markerLib.activeMenu = "MenuMulti"
            markerLib.createLocalMarkers()
            markerLib.updateLocalMarkers()
            markerLib.removeDeletedMarkers()
        end
    end)
end

event.register(tes3.event.uiActivated, menuMultiActivated, {filter = "MenuMulti"})

do
    local menu = tes3ui.findMenu("MenuMulti")
    if menu and markerLib.enabled then
        menuMultiActivated({claim = false, element = menu, newlyCreated = true})
    end
end

--- @param e simulatedEventData
local function simulatedCallback(e)
    if not markerLib.enabled then return end
    if os.clock() - markerLib.lastLocalUpdate > markerLib.updateInterval then
        local menuMap = markerLib.menu.menuMap
        if markerLib.isMapMenuInitialized and menuMap.visible then ---@diagnostic disable-line: need-check-nil
            menuMap:updateLayout() ---@diagnostic disable-line: need-check-nil
        elseif markerLib.isMultiMenuInitialized then
            markerLib.activeMenu = "MenuMulti"
            markerLib.createLocalMarkers()
            markerLib.updateLocalMarkers()
            markerLib.removeDeletedMarkers()
        else
            markerLib.lastLocalUpdate = os.clock()
            return
        end
    end
end
event.register(tes3.event.simulated, simulatedCallback)



--- @param e referenceActivatedEventData
local function referenceActivatedCallback(e)
    if not markerLib.enabled then return end
    objectCache.addRef(e.reference)
    markerLib.tryAddMarkersForRef(e.reference)
end
event.register(tes3.event.referenceActivated, referenceActivatedCallback)

--- @param e referenceDeactivatedEventData
local function referenceDeactivatedCallback(e)
    if not markerLib.enabled then return end
    objectCache.removeRef(e.reference)
end
event.register(tes3.event.referenceDeactivated, referenceDeactivatedCallback)


--- @param e cellActivatedEventData
local function cellActivatedCallback(e)
    if not markerLib.enabled then return end
    if not markerLib.isReady() then
        markerLib.init()
    end
    activeCells.registerCell(e.cell)
    markerLib.registerMarkersForCell(e.cell)
end
event.register(tes3.event.cellActivated, cellActivatedCallback)

--- @param e cellDeactivatedEventData
local function cellDeactivatedCallback(e)
    if not markerLib.enabled then return end
    activeCells.unregisterCell(e.cell)
end
event.register(tes3.event.cellDeactivated, cellDeactivatedCallback)

--- @param e cellChangedEventData
local function cellChangedCallback(e)
    if not markerLib.enabled then return end
    markerLib.registerMarkersForCell()
end
event.register(tes3.event.cellChanged, cellChangedCallback)

--- @param e loadedEventData
local function loadedCallback(e)
    if not markerLib.enabled then return end
    if not markerLib.isReady() then
        markerLib.init()
    end

    markerLib.registerWorld()

    if cellBeforeLoad then
        local cells
        if tes3.player.cell.isInterior then
            cells = {}
            table.insert(cells, {cell = tes3.player.cell})
        else
            cells = tes3.dataHandler.exteriorCells
        end
        for _, dt in pairs(cells) do
            cellActivatedCallback({cell = dt.cell}) ---@diagnostic disable-line: missing-fields
            for ref in dt.cell:iterateReferences() do
                referenceActivatedCallback({reference = ref}) ---@diagnostic disable-line: missing-fields
            end
        end
    end

    local watchdogTimer = timer.start({
        duration = 0.5,
        iterations = -1,
        type = timer.real,
        callback = function()
            if os.clock() - markerLib.lastUpdate > 0.25 then
                markerLib.updateMapMenu()
            end
        end
    })
end
event.register(tes3.event.loaded, loadedCallback, {priority = 8277})

if tes3.player and markerLib.enabled then
    markerLib.init()
end

--- @param e referenceActivatedEventData
local function playerActivatedEvent(e)
    if not markerLib.enabled then return end
    if e.reference.baseObject.id == "player" then
        if not markerLib.isReady() then
            markerLib.init(e.reference)
        end
        event.unregister(tes3.event.referenceActivated, playerActivatedEvent)
    end
end
event.register(tes3.event.referenceActivated, playerActivatedEvent, {priority = 8277})

--- @param e loadEventData
local function loadCallback(e)
    if not markerLib.enabled then return end
    markerLib.reset()
    objectCache.clear()

    if tes3.player then
        cellBeforeLoad = tes3.player.cell.editorName
    else
        cellBeforeLoad = nil
    end

    if not event.isRegistered(tes3.event.referenceActivated, playerActivatedEvent, {priority = 8277}) then
        event.register(tes3.event.referenceActivated, playerActivatedEvent, {priority = 8277})
    end
end
event.register(tes3.event.load, loadCallback)

--- @param e modConfigReadyEventData
local function modConfigReadyCallback(e)
    mcm.registerModConfig()
end
event.register(tes3.event.modConfigReady, modConfigReadyCallback)

pcall(modConfigReadyCallback)