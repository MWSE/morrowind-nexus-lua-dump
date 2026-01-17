local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local playerRef = require("openmw.self")
local I = require("openmw.interfaces")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")

local uiUtils = require("scripts.advanced_world_map.ui.utils")
local eventSys = require("scripts.advanced_world_map.eventSys")


local l10n = core.l10n(commonData.l10nKey)

local btnLayout

local function isMapTypeWorld(mapWidget)
    if mapWidget.cellId then return false end
    local normalizedZoom = config.data.tileset.zoomToShow * 32 / mapWidget.mapInfo.pixelsPerCell
    if mapWidget.zoom >= normalizedZoom then return false end
    return true
end

local function updateLabel(mapWidget)
    if not btnLayout then return end
    local playerCell = playerRef.cell

    if playerCell.isExterior then
        local mapTypeWorld = isMapTypeWorld(mapWidget)
        btnLayout.props.text = mapTypeWorld and l10n("Local") or l10n("World")
    else
        btnLayout.props.text = mapWidget.cellId == nil and l10n("Local") or l10n("World")
    end
end


---@param menu advancedWorldMap.ui.menu.map
local function toggleMap(menu)
    if menu.mapWidget.cellId then
        menu:updateMapWidgetCell()
    else
        local playerCell = playerRef.cell

        if playerCell.isExterior then
            local normalizedZoom = config.data.tileset.zoomToShow * 32 / menu.mapWidget.mapInfo.pixelsPerCell

            if isMapTypeWorld(menu.mapWidget) then
                menu.mapWidget:setZoom(normalizedZoom + 1)
            else
                menu.mapWidget:setZoom(normalizedZoom - 1)
            end
        else
            menu:updateMapWidgetCell(playerCell.id)
            menu.mapWidget:focusOnWorldPosition(playerRef.position)
        end
    end
end


---@param menu advancedWorldMap.ui.menu.map
local function create(menu)

    btnLayout = {
        type = ui.TYPE.Text,
        props = {
            text = isMapTypeWorld(menu.mapWidget) and l10n("Local") or l10n("World"),
            textSize = menu.headerHeight - 2,
            anchor = util.vector2(0.5, 0.5),
            textColor = config.data.ui.defaultColor,
        },
    }
    updateLabel(menu.mapWidget)


    menu:addWidget{
        id = "AdvancedWorldMap:MapTypeLabel",
        layout = btnLayout,
        onClick = function (m, e)
            toggleMap(menu)
            updateLabel(m.mapWidget)
        end,
        priority = 10000,
    }

end


local toogleMapTypeActionFunc


eventSys.registerHandler(eventSys.EVENT.onZoomed, function (e)
    updateLabel(e.mapWidget)
end)

eventSys.registerHandler(eventSys.EVENT.onMapShown, function (e)
    updateLabel(e.mapWidget)
end)

eventSys.registerHandler(eventSys.EVENT.onMenuOpened, function (e)
    create(e.menu)

    toogleMapTypeActionFunc = function ()
        toggleMap(e.menu)
        updateLabel(e.menu.mapWidget)
        e.menu:update()
    end

    I.DijectKeyBindings.action.register(commonData.toggleMapTypeKeyId, toogleMapTypeActionFunc)
end, 10000)

eventSys.registerHandler(eventSys.EVENT.onMenuClosed, function (e)
    I.DijectKeyBindings.action.unregister(commonData.toggleMapTypeKeyId, toogleMapTypeActionFunc)
end)