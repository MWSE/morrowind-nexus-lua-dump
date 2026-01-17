local ui = require("openmw.ui")
local util = require("openmw.util")

local uiUtils = require("scripts.advanced_world_map.ui.utils")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.config")

local widgetData = require("scripts.advanced_world_map.widgets.notes.data")
local widgetEditorMenu = require("scripts.advanced_world_map.widgets.notes.editorMenu")
local widgetMenu = require("scripts.advanced_world_map.widgets.notes.widgetMenu")

local markerTexture = ui.texture{ path = commonData.noteMarkerPath }

local this = {}

---@type table<string, {textH : AdvancedWorldMap.MapElement?, imageH : AdvancedWorldMap.MapElement?}> by marker id
this.activeMarkers = {}

---@type AdvancedWorldMap.Menu.Map?
this.lastMenu = nil


---@param menu AdvancedWorldMap.Menu.Map
function this.init(menu)
    this.lastMenu = menu
end


---@param data advancedWorldMap.widget.notes.data.markerData
---@param mapWidget AdvancedWorldMap.MapWidget?
---@param update boolean?
---@return boolean?
function this.create(data, mapWidget, update)

    if not mapWidget then
        if not this.lastMenu then return end

        -- Get the map widget from the menu cache by the cell id.
        -- Currently, all map widgets that have been opened are stored in the menu cache.
        -- But the cache may be cleared when the mod settings are changed.
        mapWidget = this.lastMenu:getCachedMapWidget(data.cellId)
        if not mapWidget then return end
    end

    -- Create tooltip content if there is something to show
    -- The marker API has a built-in tooltip support
    local tooltipContent
    if (data.descr and data.descr ~= "") or (data.name and data.name ~= "") then
        local text = widgetData.getDataText(data)

        tooltipContent = ui.content{
            {
                type = ui.TYPE.TextEdit,
                props = {
                    text = text,
                    textSize = config.data.ui.fontSize,
                    textColor = config.data.ui.defaultColor,
                    autoSize = true,
                    multiline = true,
                    wordWrap = true,
                    readOnly = true,
                    size = util.vector2(uiUtils.getScaledScreenSize().x / 5, 0),
                    textAlignH = ui.ALIGNMENT.Center,
                }
            }
        }
    end

    -- Note: the marker size is related to 1 zoom
    -- and the final size may depend on map zoom and the scaling function used!
    local imageMarkerSize = 1. * (config.data.notes.mapFontSize / 18)

    -- Create an image marker for the note on the map
    local imageMarkerHandler = mapWidget:createImageMarker{
        -- marker texture
        texture = markerTexture,
        -- marker layer. Markers on this layer can interact with the mouse.
        layerId = mapWidget.LAYER.marker,
        -- marker size
        size = util.vector2(imageMarkerSize, imageMarkerSize),
        -- Function to scale the marker depending on the map zoom.
        -- A linear scale function means the marker will shrink/grow proportionally with map zoom.
        -- You can use custom scaling functions.
        scaleFunc = mapWidget.SCALE_FUNCTION.linear,
        -- Marker position in world! coordinates
        pos = util.vector2(data.pos.x, data.pos.y),
        -- Anchor point of the marker. Here the center will be at pos
        anchor = util.vector2(0.5, 0.5),
        -- Marker color. If not specified, default from config is used
        color = data.colorId and widgetData.colors[data.colorId] or nil,
        -- Tooltip content when hovering over the marker
        tooltipContent = tooltipContent,
        -- Show marker when zoomed in. The world map has two zoom levels: near (zoomIn) and far (zoomOut).
        -- If not specified, the marker is shown at any zoom by default.
        showWhenZoomedIn = true,
        -- Additional marker data. Can be retrieved via the marker handler.
        userData = {
            type = commonData.noteMarkerType,
            noteData = data,
        },
        -- Marker events.
        -- Passed values are taken from the original openmw events.
        -- Only the events listed in the AdvancedWorldMap.MapWidget.CreateMarker.Events annotation are supported.
        events = {
            -- Mouse button release event over the marker
            -- Additionally 'beenPressed' is provided which indicates if the button was pressed on the same marker.
            mouseRelease = function (e, layout, beenPressed)
                if e.button ~= 1 or not beenPressed then return end

                widgetEditorMenu.create{
                    data = data,
                    yesCallback = function (dt)
                        if dt.pos then
                            widgetData.addMarkerData(dt)
                            this.create(dt, nil, true)
                            widgetMenu.update()
                        end
                    end,
                    removeCallback = function (dt)
                        widgetData.removeMarkerDataAlt(dt)
                        this.remove(dt, true)
                        widgetMenu.update()
                    end
                }
            end
        }
    }

    -- Create a text marker with the note name if provided
    ---@type AdvancedWorldMap.MapElement?
    local textMarkerHandler
    if data.name and data.namePosId then

        ---@type string
        local text = data.name
        local anchor
        local size = util.vector2(imageMarkerSize * 20, 0)
        local textAlignH = ui.ALIGNMENT.Center
        local textAlignV = ui.ALIGNMENT.Center

        if data.namePosId == 0 then
            anchor = util.vector2(0.5, 1.5)
            textAlignV = ui.ALIGNMENT.End
        elseif data.namePosId == 1 then
            anchor = util.vector2(-0.025, 0.5)
            textAlignH = ui.ALIGNMENT.Start
        elseif data.namePosId == 2 then
            anchor = util.vector2(0.5, -0.5)
            textAlignV = ui.ALIGNMENT.Start
        elseif data.namePosId == 3 then
            anchor = util.vector2(1.025, 0.5)
            textAlignH = ui.ALIGNMENT.End
        else
            anchor = util.vector2(0, 1)
        end

        -- Create the text marker for the note on the map
        textMarkerHandler = mapWidget:createTextMarker{
            -- Marker text
            text = text,
            -- Marker layer. Markers on this layer cannot interact with the mouse.
            layerId = mapWidget.LAYER.nonInteractive,
            -- Marker size. If not specified, automatic size is used.
            size = size,
            -- If this option is used, the marker height will auto-adjust to the text.
            -- However, since this changes the element type from Image to TextEdit, it cannot be created on an interactive layer,
            -- because TextEdit does not support mouse events and can interfere with interaction with other functions on that layer.
            -- The 'size' parameter must have y == 0 for autoHeight to work correctly.
            autoHeight = true,
            -- Text color of the marker. If not specified, default from config is used
            color = data.nameColorId and widgetData.colors[data.nameColorId] or nil,
            -- Function to scale the marker depending on map zoom.
            scaleFunc = mapWidget.SCALE_FUNCTION.linear,
            -- Marker font size. If not specified, default from config is used.
            -- Final font size depends on map zoom and the scaling function.
            fontSize = 1. * (config.data.notes.mapFontSize / 18),
            -- Horizontal alignment of the marker text
            textAlignH = textAlignH,
            -- Vertical alignment of the marker text
            textAlignV = textAlignV,
            -- Marker position in world! coordinates
            pos = data.pos,
            -- Anchor point of the marker.
            anchor = anchor,
            -- Show marker when zoomed in. The world map has two zoom levels: near (zoomIn) and far (zoomOut).
            -- If not specified, the marker is shown at any zoom by default.
            showWhenZoomedIn = true,
            -- Additional marker data. Can be retrieved via the marker handler.
            userData = {
                type = commonData.noteNameMarkerType,
                noteData = data,
            },
        }

    end

    local markerDataId = widgetData.getMarkerId(data.cellId, data.pos)
    if this.activeMarkers[markerDataId] then
        if this.activeMarkers[markerDataId].imageH then
            this.activeMarkers[markerDataId].imageH:destroy()
        end
        if this.activeMarkers[markerDataId].textH then
            this.activeMarkers[markerDataId].textH:destroy()
        end
    end
    this.activeMarkers[markerDataId] = {
        imageH = imageMarkerHandler,
        textH = textMarkerHandler,
    }

    if update then
        -- To apply changes, update markers and the map
        mapWidget:updateMarkers()
        mapWidget:update()
    end

    return true
end


---@param data advancedWorldMap.widget.notes.data.markerData
---@param update boolean?
function this.remove(data, update)
    local markerDataId = widgetData.getMarkerId(data.cellId, data.pos)
    if this.activeMarkers[markerDataId] then
        local mWidget

        local imH = this.activeMarkers[markerDataId].imageH
        if imH then
            mWidget = imH._parent
            imH:destroy()
        end
        local tH = this.activeMarkers[markerDataId].textH
        if tH then
            mWidget = tH._parent
            tH:destroy()
        end

        this.activeMarkers[markerDataId] = nil

        if update and mWidget then
            mWidget:update()
        end
    end
end


return this