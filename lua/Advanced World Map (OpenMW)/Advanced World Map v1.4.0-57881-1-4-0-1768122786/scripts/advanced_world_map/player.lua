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
local tableLib = require("scripts.advanced_world_map.utils.table")

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

-- widgets
require("scripts.advanced_world_map.widgets.mapTypeLabel")
require("scripts.advanced_world_map.widgets.markers")
require("scripts.advanced_world_map.widgets.legend")
require("scripts.advanced_world_map.widgets.search")
local fastTravel = require("scripts.advanced_world_map.widgets.fastTravel")
require("scripts.advanced_world_map.widgets.notes.note")
local cellNameWidget = require("scripts.advanced_world_map.widgets.cellName")

local l10n = core.l10n(commonData.l10nKey)


if not ui.layers.indexOf(commonData.messageLayer) then
    ui.layers.insertAfter("Windows", commonData.messageLayer, { interactive = true })
end


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


local function onInit()
    if not localStorage.isPlayerStorageReady() then
        localStorage.initPlayerStorage()
    end
    playerPos.init()
    discoveredLocs.init()
    disabledDoors.init()
end


local function onLoad(data)
    localStorage.initPlayerStorage(data)
    playerPos.init()
    discoveredLocs.init()
    disabledDoors.init()
end


local function onSave()
    local data = {}
    localStorage.save(data)
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


local function openMenu(inMenuMode)
    if not mapDataHandler.isInitialized() then
        ui.showMessage(l10n("mapDataNotInitialized"))
        return
    end

    if inMenuMode and not menuMode.isMenuInteractive() then
        menuMode.activate()
    end

    if menuHandler.getMenu(commonData.mapMenuId) then
        return
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
end


if configLib.data.main.overrideDefault then
    I.UI.registerWindow("Map",
        function()
            if configLib.data.main.saveVisibilityStateInInterfaceMenu and I.UI.getMode() == "Interface" and
                    localStorage.data[commonData.hideInInterfaceMenuFieldId] then
                return
            end
            openMenu()
        end,
        function ()
            if localStorage.data[commonData.pinnedStateFieldId] then
                local menu = menuHandler.getMenu(commonData.mapMenuId)
                if menu then
                    menu:updateInteractiveElements()
                    return
                end
            end

            menuHandler.destroyAllMenus()
        end
    )
end


local function toggleMenu()
    if not mapDataHandler.isInitialized() then
        ui.showMessage(l10n("mapDataNotInitialized"))
        return
    end

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
        if not menuMode.isMenuInteractive() then
            menuMode.activate()
        end

        local function registerMenu()
            menuHandler.registerMenu(commonData.mapMenuId, mapMenu.create{
                onClose = function ()
                    menuMode.deactivate()
                end
            })
        end

        if configLib.data.main.firstInitMenu then
            menuHandler.registerMenu(commonData.firstInitMenuId, firstInitMenu.new{
                yesCallback = function ()
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
        if types.Player.isCharGenFinished(self) then
            toggleMenu()
        else
            ui.showMessage(l10n("charGenNotFinished"))
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

addNearbyDoors()


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

    cost = cost + data.worldDistance / 16384 * configLib.data.fastTravel.additionalCost
    cost = cost + 2 * math.min(10, data.depthToPoint) * configLib.data.fastTravel.additionalCost
    cost = cost + math.max(0, (types.Actor.getEncumbrance(self) - types.Actor.getCapacity(self)) / 10) *
        configLib.data.fastTravel.additionalCost
    cost = math.floor(math.max(0, cost * (2 - types.NPC.stats.skills.mysticism(self).base / 100)))
    cost = cost * (1 + 0.5 * #followers)
    if data.isInSameInteriorBlock then
        cost = cost * 0.66
    end

    local eventData = {
        cost = cost,
        cell = pDoor.destCell(data.targetDoor),
        position = pDoor.destPosition(data.targetDoor),
        rotation = pDoor.destRotation(data.targetDoor),
        message = data.message,
        followers = followers,
    }

    if not eventData.cell then return end

    if eventSys.triggerEvent(eventSys.EVENT.onFastTravelResolve, eventData) then
        return
    end

    local message = eventData.message or ""
    if cost > 0 then
        message = message.."\n"..l10n("fastTraveMagickaCost"):format(eventData.cost)
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
        version = 6,
        events = require("scripts.advanced_world_map.eventSys"),
        getConfig = function ()
            return configLib.data
        end,
        openMapMenu = openMenu,
        toggleMapMenu = toggleMenu,
        isDiscovered = function (cellId)
            return discoveredLocs.isDiscovered(cellId)
        end,
        isVisited = function (cellId)
            return discoveredLocs.isVisited(cellId)
        end,
        uiElements = {
            scrollBox = require("scripts.advanced_world_map.ui.scrollBox"),
            borders = require("scripts.advanced_world_map.ui.borders"),
            button = require("scripts.advanced_world_map.ui.button"),
            interval = require("scripts.advanced_world_map.ui.interval"),
            checkbox = require("scripts.advanced_world_map.ui.checkBox"),
        }
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
                if localStorage.data[commonData.pinnedStateFieldId] and menuMode.isMenuInteractive() then
                    local menu = menuHandler.getMenu(commonData.mapMenuId)
                    if menu then
                        menuMode.deactivate()
                        return
                    end
                end

                menuHandler.destroyAllMenus()
            end
        end,
        onControllerButtonPress = function (buttonId)
            if buttonId == input.CONTROLLER_BUTTON.B and menuHandler.hasActiveMenus() then
                if localStorage.data[commonData.pinnedStateFieldId] and menuMode.isMenuInteractive() then
                    local menu = menuHandler.getMenu(commonData.mapMenuId)
                    if menu then
                        menuMode.deactivate()
                        return
                    end
                end

                menuHandler.destroyAllMenus()
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

                local cellId = self.cell.isExterior and commonData.exteriorMapId or self.cell.id
                if mapMenu.cachedMapWidgetMetatable[cellId] then
                    mapMenu.cachedMapWidgetMetatable[cellId]:updateOnZoomMarkers()
                end

                local menu = menuHandler.getMenu(commonData.mapMenuId)
                if menu and menu.centerOnPlayer then
                    menu:updateMapWidgetCell(cellId)
                    cellNameWidget.updateLabel(menu)
                    menu:update()
                end

                core.sendGlobalEvent("AdvWMap:cellChanged")
            end
        end,

        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,

        ["AdvWMap:initMapData"] = function (data)
            if mapDataHandler.playerInit(data and data.cellCount) then
                mapTextureHandler.init()
            end
        end,

        ["AdvWMap:updateMapData"] = function (data)
            mapDataHandler.updateData(data)
            mapTextureHandler.init()
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
        end
    },
}