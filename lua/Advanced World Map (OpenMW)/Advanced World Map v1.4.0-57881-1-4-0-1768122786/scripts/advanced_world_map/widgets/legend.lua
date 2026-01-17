local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local playerRef = require("openmw.self")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")
local localStorage = require("scripts.advanced_world_map.storage.localStorage")

local uiUtils = require("scripts.advanced_world_map.ui.utils")
local eventSys = require("scripts.advanced_world_map.eventSys")

local borders = require("scripts.advanced_world_map.ui.borders")
local checkBox = require("scripts.advanced_world_map.ui.checkBox")

local l10n = core.l10n(commonData.l10nKey)


local widgetIcon = ui.texture{ path = commonData.mapMarkerPath }


---@param menu advancedWorldMap.ui.menu.map
local function create(menu)

    local iconLayout = {
        type = ui.TYPE.Image,
        props = {
            resource = widgetIcon,
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(menu.headerHeight - 2, menu.headerHeight - 2),
            color = config.data.ui.defaultColor,
        }
    }

    menu.centerOnPlayer = config.data.main.centerOnPlayer
    menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.region, config.data.legend.visibility.regions)
    menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.name, config.data.legend.visibility.cities)
    menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.player, config.data.legend.visibility.playerMarker)
    menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.nonInteractive, config.data.legend.visibility.labels)
    menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.marker, config.data.legend.visibility.markers)

    ---@param menu advancedWorldMap.ui.menu.map
    local function onOpen(menu, content)
        iconLayout.props.color = config.data.ui.whiteColor

        local mapWidgetSize = menu.mapWidget:getSize()

        local size = util.vector2(
            math.max(mapWidgetSize.x / 4, 200),
            mapWidgetSize.y
        )


        local focusOnPlayerCB = checkBox{
            updateFunc = menu.update,
            text = l10n("FollowPlayer"),
            textSize = config.data.ui.fontSize * 0.9,
            position = util.vector2(4, config.data.ui.fontSize),
            checked = config.data.main.centerOnPlayer,
            event = function (checked, layout)
                config.setValue("main.centerOnPlayer", checked)
                menu.centerOnPlayer = checked
                if checked then
                    local playerCell = not playerRef.cell.isExterior and playerRef.cell.id or nil
                    if menu.mapWidget.cellId ~= playerCell then
                        menu:updateMapWidgetCell(playerCell)
                    end
                    if not playerCell then
                        menu.mapWidget:updatePlayerMarker(true, true)
                        menu.mapWidget:updateMarkers()
                    end
                    menu:update()
                end
            end
        }

        local layerVisibilityLabel = {
            type = ui.TYPE.Text,
            props = {
                text = l10n("LayerVisibility"),
                textSize = config.data.ui.fontSize,
                textColor = config.data.ui.defaultColor,
                autoSize = true,
                position = util.vector2(4, config.data.ui.fontSize * 3),
            },
        }

        local regionsLayerCB = checkBox{
            updateFunc = menu.update,
            text = l10n("Regions"),
            textSize = config.data.ui.fontSize * 0.9,
            position = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize * 4.75),
            checked = config.data.legend.visibility.regions,
            event = function (checked, layout)
                config.setValue("legend.visibility.regions", checked)
                menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.region, checked)
                menu:update()
            end
        }
        local citiesLayerCB = checkBox{
            updateFunc = menu.update,
            text = l10n("Cities"),
            textSize = config.data.ui.fontSize * 0.9,
            position = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize * 6.5),
            checked = config.data.legend.visibility.cities,
            event = function (checked, layout)
                config.setValue("legend.visibility.cities", checked)
                menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.name, checked)
                menu:update()
            end
        }
        local playerLayerCB = checkBox{
            updateFunc = menu.update,
            text = l10n("PlayerMarker"),
            textSize = config.data.ui.fontSize * 0.9,
            position = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize * 8.25),
            checked = config.data.legend.visibility.playerMarker,
            event = function (checked, layout)
                config.setValue("legend.visibility.playerMarker", checked)
                menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.player, checked)
                if checked then
                    menu.mapWidget:updatePlayerMarker(true, true)
                end
                menu:update()
            end
        }
        local labelLayerCB = checkBox{
            updateFunc = menu.update,
            text = l10n("Labels"),
            textSize = config.data.ui.fontSize * 0.9,
            position = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize * 10),
            checked = config.data.legend.visibility.labels,
            event = function (checked, layout)
                config.setValue("legend.visibility.labels", checked)
                menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.nonInteractive, checked)
                menu:update()
            end
        }
        local markerLayerCB = checkBox{
            updateFunc = menu.update,
            text = l10n("Markers"),
            textSize = config.data.ui.fontSize * 0.9,
            position = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize * 11.75),
            checked = config.data.legend.visibility.markers,
            event = function (checked, layout)
                config.setValue("legend.visibility.markers", checked)
                menu.mapWidget:setLayerVisibility(menu.mapWidget.LAYER.marker, checked)
                menu:update()
            end
        }


        local windowLayout = {
            type = ui.TYPE.Widget,
            props = {
                size = size,
                color = config.data.ui.defaultColor,
            },
            userData = {

            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        relativeSize = util.vector2(1, 1),
                        color = config.data.ui.backgroundColor,
                        alpha = 1,
                        resource = uiUtils.whiteTexture,
                    },
                },
                focusOnPlayerCB,
                layerVisibilityLabel,
                regionsLayerCB,
                citiesLayerCB,
                playerLayerCB,
                labelLayerCB,
                markerLayerCB,
                borders()
            }
        }

        content:add(windowLayout)
    end

    local function onClose()
        iconLayout.props.color = config.data.ui.defaultColor
    end

    menu:addWidget{
        id = "AdvancedWorldMap:Legend",
        layout = iconLayout,
        priority = 9900,
        onOpen = onOpen,
        onClose = onClose,
    }

end


eventSys.registerHandler(eventSys.EVENT.onMapShown, function (e)
    e.mapWidget:setLayerVisibility(e.mapWidget.LAYER.region, config.data.legend.visibility.regions)
    e.mapWidget:setLayerVisibility(e.mapWidget.LAYER.name, config.data.legend.visibility.cities)
    e.mapWidget:setLayerVisibility(e.mapWidget.LAYER.player, config.data.legend.visibility.playerMarker)
    e.mapWidget:setLayerVisibility(e.mapWidget.LAYER.nonInteractive, config.data.legend.visibility.labels)
    e.mapWidget:setLayerVisibility(e.mapWidget.LAYER.marker, config.data.legend.visibility.markers)
end, 9900)



eventSys.registerHandler(eventSys.EVENT["onMenuOpened"], function (e)
    create(e.menu)
end, 9900)