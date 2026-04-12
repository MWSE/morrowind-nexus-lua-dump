local core = require('openmw.core')
local self = require('openmw.self')
local async = require('openmw.async')
local time = require('openmw_aux.time')
local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local storage = require('openmw.storage')
local types = require("openmw.types")
local debug = require('openmw.debug')
local ambient = require('openmw.ambient')
local animation = require("openmw.animation")
local nearby = require("openmw.nearby")

local pDoor = require("scripts.advanced_world_map.helpers.protectedDoor")

local log = require("scripts.advanced_world_map.utils.log")

local commonData = require("scripts.advanced_world_map.common")

local configLib = require("scripts.advanced_world_map.config.configLib")
local config = require("scripts.advanced_world_map.config.config")
local tableLib = require("scripts.advanced_world_map.utils.table")
local dateLib = require("scripts.advanced_world_map.utils.date")
local cellLib = require("scripts.advanced_world_map.utils.cell")

local localStorage = require("scripts.advanced_world_map.storage.localStorage")
local playerPos = require("scripts.advanced_world_map.playerPosition")

local realTimer = require("scripts.advanced_world_map.realTimer")

local menuMode = require("scripts.advanced_world_map.ui.menuMode")

local eventSys = require("scripts.advanced_world_map.eventSys")
local mapTextureHandler = require("scripts.advanced_world_map.mapTextureHandler")
local menuHandler = require("scripts.advanced_world_map.menuHandler")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")
local discoveredLocs = require("scripts.advanced_world_map.discoveredLocations")
local disabledDoors = require("scripts.advanced_world_map.disabledDoors")

local mapMenu = require("scripts.advanced_world_map.ui.menu.map")
local firstInitMenu = require("scripts.advanced_world_map.ui.menu.firstInit")

local messageBox = require("scripts.advanced_world_map.ui.menu.messageBox")

local markers = require("scripts.advanced_world_map.widgets.markers")
local notesWidgetData = require("scripts.advanced_world_map.widgets.notes.data")

-- widgets
require("scripts.advanced_world_map.widgets.mapTypeLabel")
require("scripts.advanced_world_map.widgets.markers")
require("scripts.advanced_world_map.widgets.legend")
require("scripts.advanced_world_map.widgets.search")
local fastTravel = require("scripts.advanced_world_map.widgets.fastTravel")
require("scripts.advanced_world_map.widgets.notes.note")
local cellNameWidget = require("scripts.advanced_world_map.widgets.cellName")

local l10n = core.l10n(commonData.l10nKey)

local hasAttemptedToGetData = false



pcall(function ()
    if not ui.layers.indexOf(commonData.messageLayer) then
        ui.layers.insertBefore("DragAndDrop", commonData.messageLayer, { interactive = true })
    end
end)


local fightingActors = {}


storage.playerSection(commonData.configTilesetSectionName):subscribe(async:callback(function(_, id)
    mapMenu.clearMapWidgetCache()
end))

storage.playerSection(commonData.configLegendSectionName):subscribe(async:callback(function(_, id)
    mapMenu.clearMapWidgetCache()
end))

storage.playerSection(commonData.configDataSectionName):subscribe(async:callback(function(_, id)
    mapTextureHandler.init()
    mapMenu.clearMapWidgetCache()
end))

storage.playerSection(commonData.configNotesSectionName):subscribe(async:callback(function(_, id)
    mapMenu.clearMapWidgetCache()
end))

storage.playerSection(commonData.configUISectionName):subscribe(async:callback(function(_, id)
    if id == "ui.defaultTextureColor" then
        mapTextureHandler.init()
    end
    mapMenu.clearMapWidgetCache()
end))

local mainSectionStorage = storage.playerSection(commonData.configMainSectionName)

local function resetSizePos()
    menuHandler.destroyAllMenus()
    configLib.setValue("main.relativeSize.x", config.default.main.relativeSize.x)
    configLib.setValue("main.relativeSize.y", config.default.main.relativeSize.y)
    configLib.setValue("main.relativePosition.x", config.default.main.relativePosition.x)
    configLib.setValue("main.relativePosition.y", config.default.main.relativePosition.y)
    configLib.setValue("main.minimap.relativeSize.x", config.default.main.minimap.relativeSize.x)
    configLib.setValue("main.minimap.relativeSize.y", config.default.main.minimap.relativeSize.y)
    configLib.setValue("main.minimap.relativePosition.x", config.default.main.minimap.relativePosition.x)
    configLib.setValue("main.minimap.relativePosition.y", config.default.main.minimap.relativePosition.y)
    ui.showMessage(l10n("MapSizePositionResetMessage"))
end

if mainSectionStorage:get("main.resetSizePos") then
    resetSizePos()
    mainSectionStorage:set("main.resetSizePos", false)
end

local isStorageTimerRunning = false
mainSectionStorage:subscribe(async:callback(function(_, _)
    local reset = mainSectionStorage:get("main.resetSizePos")
    if reset and not isStorageTimerRunning then
        isStorageTimerRunning = true
        async:newUnsavableSimulationTimer(0.1, function ()
            resetSizePos()
            mainSectionStorage:set("main.resetSizePos", false)
            isStorageTimerRunning = false
        end)
    end
end))


local function onInit()
    if not localStorage.isPlayerStorageReady() then
        localStorage.initPlayerStorage()
    end
    playerPos.init()
    discoveredLocs.init()
    disabledDoors.init()
    -- must be after localStorage init
    notesWidgetData.loadData()
    core.sendGlobalEvent("AdvWMap:requestTimeUpdate", self.object)
end


local function onLoad(data)
    localStorage.initPlayerStorage(data)
    playerPos.init()
    discoveredLocs.init()
    disabledDoors.init()
    if config.data.data.hasSafeInitMessageBeenShown then
        hasAttemptedToGetData = true
        core.sendGlobalEvent("AdvWMap:initMapData", {plRef = self.object})
    end
    -- must be after localStorage init
    notesWidgetData.loadData()
    core.sendGlobalEvent("AdvWMap:requestTimeUpdate", self.object)
end


local function onSave()
    local data = {}
    localStorage.save(data)
    notesWidgetData.saveData()
    return data
end


local function onMouseWheel(vertical)
    menuHandler.onMouseWheelCallback(vertical)
end


local function onCombatTargetsChanged(eventData)
    pcall(function ()
        if eventData.actor == nil then return end

        if next(eventData.targets) ~= nil then
            fightingActors[eventData.actor.id] = true
        else
            fightingActors[eventData.actor.id] = nil
        end
    end)
end


local function getMenu()
    return menuHandler.getMenu(commonData.mapMenuId)
end


local function initDataForMenu(options)
    local initialized = mapDataHandler.isInitialized()

    if not initialized then
        if not hasAttemptedToGetData then
            hasAttemptedToGetData = true
            if menuMode.isMenuInteractive() then
                menuMode.deactivate()
            end
            core.sendGlobalEvent("AdvWMap:initMapData", {plRef = self.object, options = options})
            return false
        else
            ui.showMessage(l10n("mapDataNotInitialized"))
            return false
        end
    end
    hasAttemptedToGetData = true
    return true
end


local function openMenu(inMenuMode)
    if not initDataForMenu({openMenu = true, openInMenuMode = inMenuMode}) then return end

    if inMenuMode and not menuMode.isMenuInteractive() then
        menuMode.activate()
    end

    local menu = menuHandler.getMenu(commonData.mapMenuId)
    if menu then
        return menu
    end

    menuHandler.registerMenu(commonData.mapMenuId, mapMenu.create{
        onClose = function ()
            if inMenuMode then
                menuMode.deactivate()
            end
        end
    })

    local menu = menuHandler.getMenu(commonData.mapMenuId)
    if menu and menu:updateInteractiveElements() then
        menu:update()
    end
    return menu
end


local function closeMenu()
    menuHandler.destroyAllMenus()
end


if configLib.data.main.overrideDefault then
    I.UI.registerWindow("Map",
        function()
            realTimer.newTimer(0.1, function ()
                if configLib.data.main.saveVisibilityStateInInterfaceMenu and I.UI.getMode() == "Interface" and
                        localStorage.data[commonData.hideInInterfaceMenuFieldId] then
                    return
                end
                openMenu()
            end)
        end,
        function ()
            if localStorage.data[commonData.pinnedStateFieldId] then
                local menu = menuHandler.getMenu(commonData.mapMenuId)
                if menu then
                    if menu:updateInteractiveElements() then
                        menu:update()
                    end
                    return
                end
            end

            closeMenu()
        end
    )
end


local function toggleMenu()
    if menuHandler.getMenu(commonData.mapMenuId) then
        if menuMode.isActive() then
            if localStorage.data[commonData.pinnedStateFieldId] then
                menuMode.deactivate()
            else
                menuHandler.destroyMenu(commonData.mapMenuId)
            end
        else
            menuHandler.destroyMenu(commonData.mapMenuId)
        end
    else
        local function registerMenu()
            if not initDataForMenu({toggleMenu = true}) then return end

            if not menuMode.isMenuInteractive() then
                menuMode.activate()
            end

            menuHandler.registerMenu(commonData.mapMenuId, mapMenu.create{
                onClose = function ()
                    menuMode.deactivate()
                end
            })
        end

        if configLib.data.main.firstInitMenu or not configLib.data.data.hasSafeInitMessageBeenShown then
            if not menuMode.isMenuInteractive() then
                menuMode.activate()
            end

            menuHandler.registerMenu(commonData.firstInitMenuId, firstInitMenu.new{
                yesCallback = function ()
                    if not configLib.data.data.hasSafeInitMessageBeenShown then
                        configLib.setValue("data.hasSafeInitMessageBeenShown", true)
                    end
                    configLib.setValue("main.firstInitMenu", false)
                    registerMenu()
                end
            })

        else
            registerMenu()
        end
    end
end

if I.DijectKeyBindings then
    I.DijectKeyBindings.action.register(commonData.menuKeyId, function ()
        core.sendGlobalEvent("AdvWMap:toggleMenuCheck", self.object)
    end)

    I.DijectKeyBindings.action.register(commonData.moveHistoryBackKeyId, function ()
        if not menuMode.isMenuInteractive() then return end
        local menu = menuHandler.getMenu(commonData.mapMenuId)
        if menu then
            menu:moveHistory(-1)
        end
    end)

    I.DijectKeyBindings.action.register(commonData.moveHistoryForwardKeyId, function ()
        if not menuMode.isMenuInteractive() then return end
        local menu = menuHandler.getMenu(commonData.mapMenuId)
        if menu then
            menu:moveHistory(1)
        end
    end)
end


local function updateTimer()
    playerPos.checkPos()

    local rAxisY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
    if rAxisY > 0.5 then
        menuHandler.onMouseWheelCallback(-1, true)
    elseif rAxisY < -0.5 then
        menuHandler.onMouseWheelCallback(1, true)
    end

    realTimer.newTimer(0.2, function ()
        updateTimer()
    end)
end

updateTimer()


local nearbyDoors = {}
local function addNearbyDoors()
    nearbyDoors = {}
    for _, ref in pairs(nearby.doors) do
        if types.Door.isTeleport(ref) then
            table.insert(nearbyDoors, ref)
        end
    end
end

async:newUnsavableSimulationTimer(0.25, function ()
    addNearbyDoors()
end)


local function discoverNearby()
    for _, ref in pairs(nearbyDoors) do
        if not types.Door.isTeleport(ref)
                or (ref.position - self.position):length() > configLib.data.main.discoveryRadius then
            goto continue
        end

        local cell = pDoor.destCell(ref)
        if cell and not discoveredLocs.isDiscovered(cell.id) then
            local newDiscovered = discoveredLocs.addDiscoveredCell(cell)
            if newDiscovered then
                markers.updateDiscovered(newDiscovered)
            end
        end

        ::continue::
    end
end

time.runRepeatedly(discoverNearby, 0.42)


local function fastTravelMessageCallback(data)
    local followers = tableLib.copy(fastTravel.followers)
    fastTravel.followers = {}

    if next(fightingActors) ~= nil and debug.isAIEnabled() then
        ui.showMessage(l10n("fastTravelWhileInCombat"))
        return
    end

    local cost = configLib.data.fastTravel.baseMagickaCost

    local capacity = types.Actor.getCapacity(self)
    local encumbrance = types.Actor.getEncumbrance(self)

    cost = cost + data.worldDistance / 16384 * configLib.data.fastTravel.additionalCost
    cost = cost + 2 * math.min(10, data.depthToPoint) * configLib.data.fastTravel.additionalCost
    cost = cost + math.max(0, (encumbrance - capacity) / 10) *
        configLib.data.fastTravel.additionalCost
    cost = math.floor(math.max(0, cost * (2 - types.NPC.stats.skills.mysticism(self).base / 100)))
    cost = cost * (1 + 0.5 * #followers)
    if data.isInSameInteriorBlock then
        cost = cost * 0.66
    end

    local plSpeed = types.Actor.stats.attributes.speed(self).modified
    local travelTime = configLib.data.fastTravel.passTime and core.API_REVISION >= 111 and
        math.ceil((data.worldDistance + data.depthToPoint * 4096) / 24576 * 100 / plSpeed * (encumbrance / capacity + 0.5)) or 0

    local eventData = {
        cost = cost,
        cell = pDoor.destCell(data.targetDoor),
        position = pDoor.destPosition(data.targetDoor),
        rotation = pDoor.destRotation(data.targetDoor),
        message = data.message,
        followers = followers,
        travelTime = travelTime,
    }

    if not eventData.cell then return end

    if eventSys.triggerEvent(eventSys.EVENT.onFastTravelResolve, eventData) then
        return
    end

    local message = eventData.message or ""
    if cost > 0 or travelTime > 0 then
        message = message.."\n"..l10n("fastTravelCostMessage"):format(
            cost > 0 and l10n("fastTravelMagickaCost", {count = cost}):format(cost) or "",
            cost > 0 and travelTime > 0 and l10n("fastTravelAnd") or "",
            travelTime > 0 and l10n("fastTravelTimeCost", {count = travelTime}):format(travelTime) or ""
        )
    end

    menuHandler.registerMenu(commonData.messageBoxMenuId, messageBox.newSimple{
        message = message,
        relativeSize = util.vector2(0.25, 0.2),
        yesCallback = function ()
            local currentMagicka = types.Actor.stats.dynamic.magicka(self).current
            if currentMagicka < eventData.cost then
                ui.showMessage(l10n("NotEnoughMagicka"))
                menuHandler.destroyMenu(commonData.mapMenuId)
                return
            end

            types.Actor.stats.dynamic.magicka(self).current = math.max(0, currentMagicka - eventData.cost)

            if configLib.data.fastTravel.withFollowers then
                data.followers = followers
            end

            eventData.followers = data.followers
            data.travelTime = eventData.travelTime
            eventSys.triggerEvent(eventSys.EVENT.onFastTravelResolved, eventData)

            discoveredLocs.blockDiscovery = true
            core.sendGlobalEvent("AdvWMap:fastTravelTeleport", data)
            async:newUnsavableSimulationTimer(0.5, function ()
                discoveredLocs.blockDiscovery = false

                if not types.Player.isTeleportingEnabled(self) then

                    --- this doesn't work as expected
                    -- types.Player.setTeleportingEnabled(self, true)
                    -- core.sendGlobalEvent("AdvWMap:fastTravelTeleport", {
                    --     position = pPos,
                    --     cellId = pCellId,
                    --     followers = data.followers
                    -- })

                    ui.showMessage(core.getGMST("sTeleportDisabled") or "")
                end
            end)

            if I.SkillProgression then
                I.SkillProgression.skillUsed("mysticism", {
                    useType = I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success,
                    scale = util.clamp(eventData.cost / 50, 1, 3)
                })
            end

            localStorage.data[commonData.fastTravelTimestampFieldId] = core.getGameTime()
            fastTravel.lastTimestamp = core.getRealTime()

            menuHandler.destroyMenu(commonData.mapMenuId)
        end,
    })
end




local lastPlayerCellId
local menuStateUpdateTimer

return {
    interfaceName = "AdvancedWorldMap",
    ---@type AdvancedWorldMap.Interface
    interface = {
        version = 10,
        events = require("scripts.advanced_world_map.eventSys"),
        getConfig = function ()
            return configLib.data
        end,
        setConfigValue = function (valuePath, value)
            configLib.setValue(valuePath, value)
        end,
        openMapMenu = openMenu,
        closeMapMenu = closeMenu,
        toggleMapMenu = toggleMenu,
        getMapMenu = getMenu,
        isDiscovered = function (cellId)
            return discoveredLocs.isDiscovered(cellId)
        end,
        isVisited = function (cellId)
            return discoveredLocs.isVisited(cellId)
        end,
        getCellNameById = function (cellId)
            return mapDataHandler.cellNameById[cellId]
        end,
        getExteriorCellName = function (pos)
            return mapDataHandler.cellNameById[cellLib.getCellIdByPos(pos)]
        end,
        getEntranceMarkerData = function (cellId)
            return mapDataHandler.entrances[cellId]
        end,
        uiElements = {
            scrollBox = require("scripts.advanced_world_map.ui.scrollBox"),
            borders = require("scripts.advanced_world_map.ui.borders"),
            button = require("scripts.advanced_world_map.ui.button"),
            interval = require("scripts.advanced_world_map.ui.interval"),
            checkbox = require("scripts.advanced_world_map.ui.checkBox"),
            tooltip = require("scripts.advanced_world_map.ui.tooltip"),
        },
        realTimer = realTimer.newTimer,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = onInit,
        onTeleported = function ()
            addNearbyDoors()
            discoverNearby()
        end,
        onFrame = function(dt)
            realTimer.updateTimers()
        end,
        onMouseWheel = onMouseWheel,
        onKeyPress = function (key)
            if key.code == input.KEY.Escape and menuHandler.hasActiveMenus() then
                local pinned = localStorage.data[commonData.pinnedStateFieldId]
                if pinned and menuMode.isMenuInteractive() then
                    local menu = menuHandler.getMenu(commonData.mapMenuId)
                    if menu then
                        menuMode.deactivate()
                        return
                    end
                end

                if not pinned then
                    closeMenu()
                end
            end
        end,
        onControllerButtonPress = function (buttonId)
            if buttonId == input.CONTROLLER_BUTTON.B and menuHandler.hasActiveMenus() then
                local pinned = localStorage.data[commonData.pinnedStateFieldId]
                if pinned and menuMode.isMenuInteractive() then
                    local menu = menuHandler.getMenu(commonData.mapMenuId)
                    if menu then
                        menuMode.deactivate()
                        return
                    end
                end

                if not pinned then
                    closeMenu()
                end
            end
        end,
        onMouseButtonRelease = function (buttonId)
            menuHandler.onMouseReleaseCallback(buttonId)
        end,
    },
    eventHandlers = {
        -- when changing location, a loading menu is displayed, which triggers this event
        UiModeChanged = function(e)
            if menuStateUpdateTimer then
                menuStateUpdateTimer()
            end
            menuStateUpdateTimer = realTimer.newTimer(0.1, function ()
                if not menuMode.isMenuInteractive() then
                    menuMode.setActivatedFlag(false)
                end
                local menu = menuHandler.getMenu(commonData.mapMenuId)
                if menu and menu:updateInteractiveElements() then
                    menu:update()
                end
                menuStateUpdateTimer = nil
            end)

            if e.oldMode == "Loading" or e.oldMode == nil and e.newMode == nil and lastPlayerCellId ~= self.cell.id then
                lastPlayerCellId = self.cell.id

                core.sendGlobalEvent("AdvWMap:requestTimeUpdate", self.object)
                addNearbyDoors()
                discoverNearby()

                local newVisited = discoveredLocs.addVisitedCell(self.cell)
                if newVisited then
                    markers.updateDiscovered(newVisited)
                end
                local newDiscovered = discoveredLocs.addDiscoveredCell(self.cell, true)
                if newDiscovered then
                    markers.updateDiscovered(newDiscovered)
                end

                local cellId = not self.cell.isExterior and self.cell.id or nil

                local menu = menuHandler.getMenu(commonData.mapMenuId)
                if menu and menu.centerOnPlayer then
                    if menu.mapWidget.cellId == cellId then
                        menu.mapWidget:updateOnZoomMarkers()
                    else
                        menu:updateMapWidgetCell(cellId)
                    end
                    cellNameWidget.updateLabel(menu)
                    menu:update()
                end

                core.sendGlobalEvent("AdvWMap:cellChanged", self.object)
            elseif e.newMode == "Loading" then
                -- update timestamp of the visited cell before the player leaves it
                discoveredLocs.updateVisited(self.cell)
            end
        end,

        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,

        -- for compatibility with mods that change player chargen state
        ["AdvWMap:toggleMenuCheck"] = function (data)
            if types.Player.isCharGenFinished(self) or data.isCharGenFinished then
                toggleMenu()
            else
                ui.showMessage(l10n("charGenNotFinished"))
            end
        end,

        ["AdvWMap:initMapData"] = function (data)
            if mapDataHandler.playerInit(self, data and data.cellCount, data and data.options) then
                mapTextureHandler.init()
            end
        end,

        ["AdvWMap:updateMapData"] = function (data)
            mapDataHandler.updateData(self, data)
            mapTextureHandler.init()
        end,

        ["AdvWMap:processMapDataOptions"] = function (options)
            if not options then return end

            if options.toggleMenu then
                toggleMenu()
            end

            if options.openMenu then
                openMenu(options.openInMenuMode)
            end
        end,

        ["AdvWMap:showMessage"] = function (str)
            ui.showMessage(str)
        end,

        ["AdvWMap:playSound"] = function (data)
            ambient.playSound(data.soundId, {})
        end,

        ["AdvWMap:fastTravelMessage"] = function (data)
            realTimer.newTimer(0.2, function ()
                fastTravelMessageCallback(data)
            end)
        end,

        ["AdvWMap:fastTravelFollowerData"] = function (data)
            if not data.actor then return end

            table.insert(fastTravel.followers, data.actor)
        end,

        ["AdvWMap:cancelAnimation"] = function (data)
            if not data or not data.groupName then return end
            animation.cancel(self, data.groupName)
        end,

        ["AdvWMap:registerDisabledDoor"] = function(ref)
            disabledDoors.register(ref)
            markers.updateDoorMarkerVisibility(ref)
        end,

        ["AdvWMap:unregisterDisabledDoor"] = function(ref)
            disabledDoors.unregister(ref)
            markers.updateDoorMarkerVisibility(ref)
        end,

        ["AdvWMap:getMapStatics"] = function (data)
            local menu = menuHandler.getMenu(commonData.mapMenuId)
            if menu then
                menu.mapWidget.cellStatics = data.res
                menu.mapWidget:updateMarkers()
                menu:update()
            end
        end,

        ["AdvWMap:requestTimeUpdate"] = function (data)
            dateLib.setGlobalTime(data.day, data.month, data.year)
        end,

        ["AdvWMap:tmCall"] = function (id)
            realTimer.executeTimer(id)
        end,
    },
}