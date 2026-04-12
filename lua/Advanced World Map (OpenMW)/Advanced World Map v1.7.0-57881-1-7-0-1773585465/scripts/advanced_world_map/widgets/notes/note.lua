local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local NPC = require("openmw.types").NPC
local playerRef = require("openmw.self")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.configLib")

local button = require("scripts.advanced_world_map.ui.button")
local interval = require("scripts.advanced_world_map.ui.interval")

local l10n = core.l10n(commonData.l10nKey)

local editorMenu = require("scripts.advanced_world_map.widgets.notes.editorMenu")
local widgetMarker = require("scripts.advanced_world_map.widgets.notes.marker")
local widgetData = require("scripts.advanced_world_map.widgets.notes.data")
local widgetMenu = require("scripts.advanced_world_map.widgets.notes.widgetMenu")


local iconTexture = ui.texture{ path = commonData.noteMarkerPath }


---@type AdvancedWorldMap.Interface
local AdvancedWorldMap = I.AdvancedWorldMap



---@param menu AdvancedWorldMap.Menu.Map
local function menuOpened(menu)

    -- Get the height of the map menu header
    local headerHeight = menu.headerHeight

    local iconLayout = {
        type = ui.TYPE.Image,
        props = {
            resource = iconTexture,
                anchor = util.vector2(0.5, 0.5), -- All elements in the header should be centered
            size = util.vector2(headerHeight - 3, headerHeight - 3),
            color = config.data.ui.defaultColor,
        }
    }

    -- Add the widget icon to the map menu header
    -- A new menu object is created when the menu opens, so the icon
    -- must be added on each opening
    -- The id must be unique. Adding a widget with the same id
    -- will replace the previous widget
    menu:addWidget{
        id = "AdvancedWorldMap:Notes",
        layout = iconLayout,
        -- Priority for sorting widgets in the menu header. Higher values place the widget more to the left
        priority = 1000,
        -- Event when the widget icon is pressed
        -- Note: 'content' is the content of the main widget's horizontal Flex
        -- into which you should add your UI elements,
        -- but those elements must have a fixed size (not autoSize)
        onOpen = function (menu, content)
            widgetMenu.create(menu, content)
            iconLayout.props.color = config.data.ui.whiteColor
        end,
        -- Widget close event
        onClose = function (menu)
            iconLayout.props.color = config.data.ui.defaultColor
        end,
    }
end


---@param e AdvancedWorldMap.Event.OnRightMouseMenuEvent
local function onRightMouseMenu(e)

    -- Deprecated
    -- Only add note buttons when in zoom-in mode (interior or exterior with sufficient zoom)
    -- if not e.mapWidget:isInZoomInMode() then
    --     return
    -- end

    -- Interior cells always use zoom-in mode. Exteriors depend on zoom level.
    local isInZoomInMode = e.mapWidget:isInZoomInMode()

    ---@type Layout
    local btn

    -- If there's a marker under the cursor, 'marker' will provide the handler for that marker
    -- If that marker contains 'userData' with the note type, create an edit-note button
    -- 'userData' can be added when creating the marker or by modifying its parameters via its handler
    if e.marker then
        local userData = e.marker:getUserData()
        if userData and userData.type == commonData.noteMarkerType and userData.noteData then
            btn = button{
                updateFunc = e.mapWidget.update,
                text = l10n("EditNote"),
                event = function (layout)
                    editorMenu.create{
                        data = userData.noteData,
                        yesCallback = function (dt)
                            if dt.pos then
                                widgetData.addMarkerData(dt, not isInZoomInMode)
                                widgetMarker.create(dt, e.mapWidget, true)
                                widgetMenu.update()
                            end
                        end,
                        removeCallback = function (dt)
                            widgetData.removeMarkerDataAlt(dt)
                            widgetMarker.remove(dt, true)
                            widgetMenu.update()
                        end
                    }
                    -- Close the context menu after pressing the button
                    -- This is necessary because it does not close automatically
                    e.mapWidget:closeRightMouseMenu()
                end
            }
        end
    end

    if not btn then
        btn = button{
            updateFunc = e.mapWidget.update,
            text = l10n("AddNote"),
            event = function (layout)
                editorMenu.create{
                    data = {
                        pos = e.mapWidget:getWorldPositionByRelativePosition(e.relPos),
                        cellId = e.mapWidget.cellId,
                    },
                    yesCallback = function (dt)
                        if dt.pos then
                            widgetData.addMarkerData(dt, not isInZoomInMode)
                            widgetMarker.create(dt, e.mapWidget, true)
                            widgetMenu.update()
                        end
                    end,
                }
                e.mapWidget:closeRightMouseMenu()
            end
        }
    end

    -- Add the button to the context menu
    e.content:add(
        btn
    )

end


local function init()
    local playerName = NPC.record(playerRef.recordId).name or ""

    ---@type AdvancedWorldMap.Event
    local events = AdvancedWorldMap.events

    -- Event triggered when the map menu is opened
    events.registerHandler(events.EVENT.onMenuOpened, function (e)
        menuOpened(e.menu)
        widgetMarker.init(e.menu)
    end)

    -- Event triggered when the right-click context menu is opened
    -- Priority 100 so it runs before other widgets' events
    -- This event passes to the handler an event with map info, mouse position and
    -- ui.Content into which you can add your own UI elements
    events.registerHandler(events.EVENT.onRightMouseMenu, onRightMouseMenu, 100)

    -- Event triggered when a location map widget is initialized
    -- This event is called once when the map widget is created
    -- Map widgets are cached, so when reopening the same location
    -- the widget is not recreated and this event is not called
    events.registerHandler(events.EVENT.onMapInitialized, function (e)
        local isMarkerCreated = false
        for _, _, dt in widgetData.getCellIterator(e.cellId) do
            isMarkerCreated = widgetMarker.create(dt, e.mapWidget) or isMarkerCreated
        end

        if isMarkerCreated then
            -- After creating markers they are not visible until you update them
            -- or change the zoom
            e.mapWidget:updateMarkers()
            -- Update the entire menu element
            e.menu:update()
        end
    end)

    -- Event triggered when the location map is shown (map widget)
    -- This event is called each time the map widget is opened
    events.registerHandler(events.EVENT.onMapShown, function (e)
        if widgetMenu.update then
            widgetMenu.update()
        end
    end)


    -- Event triggered when a location map widget is destroyed
    -- This event is called when the map widget is removed from cache
    -- Remove all markers related to that map widget to free memory
    events.registerHandler(events.EVENT.onMapDestroyed, function (e)
        widgetMarker.dispose(e.mapWidget.cellId)
    end)


    -- Event triggered before showing the tooltip for a door marker
    -- We will add note info to the tooltip if there are notes for that cell
    events.registerHandler(events.EVENT.onMarkerTooltipShow, function (e)
        -- Check if the marker is a door marker with a cellId
        -- All door markers have cellId in their userData
        local userData = e.marker:getUserData()
        if not userData or userData.type ~= commonData.doorMarkerType or not userData.cellId then return end
        if not widgetData.hasCellNotes(userData.cellId) then return end

        local layout = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
                anchor = util.vector2(0, 0.5),
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content{}
        }

        local cellId = userData.cellId
        local addedCount = 0
        for _, mId, data in widgetData.getCellIterator(cellId) do
            if data.plName and ((not config.data.notes.markerVisibility.personal and data.plName == playerName) or
                    (not config.data.notes.markerVisibility.global and data.plName ~= playerName)) then
                goto continue
            end

            if addedCount >= 2 then
                layout.content:add{
                    type = ui.TYPE.Text,
                    props = {
                        text = "...",
                        textColor = config.data.ui.defaultColor,
                        textSize = config.data.ui.fontSize,
                    }
                }
                break
            end

            local tooltipContLay = widgetMarker.getTooltipContentLayout(data, false, false)
            if tooltipContLay then
                if addedCount ~= 0 then
                    layout.content:add(interval(0, config.data.ui.fontSize / 3))
                end
                layout.content:add(tooltipContLay[1])

                addedCount = addedCount + 1
            end

            ::continue::
        end

        if addedCount > 0 then
            e.content:add(layout)
        end
    end, -10)

    -- Event triggered when the legend widget is created.
    -- You can add your own elements to the legend by adding them to the provided content layout.
    events.registerHandler(events.EVENT.onLegendWidgetCreate, function (e)

        local flexContent = ui.content{}

        local size = e.size

        local function addVPadding(elem, padding)
            return {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(
                        size.x,
                        (elem.props.textSize or elem.props.size and elem.props.size.y or config.data.ui.fontSize) * (padding or 1.5)
                    ),
                },
                content = ui.content{
                    elem
                }
            }
        end

        local label = {
            type = ui.TYPE.Text,
            props = {
                text = l10n("Notes"),
                textSize = config.data.ui.fontSize,
                textColor = config.data.ui.defaultColor,
                autoSize = true,
                anchor = util.vector2(0, 0.5),
                position = util.vector2(4, config.data.ui.fontSize * 0.75),
            },
        }

        local personalCB = AdvancedWorldMap.uiElements.checkbox{
            updateFunc = e.menu.update,
            text = l10n("PersonalNotesCB"),
            textSize = config.data.ui.fontSize,
            anchor = util.vector2(0, 0.5),
            position = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize * 0.75),
            checked = config.data.notes.markerVisibility.personal,
            getScrollBoxMeta = function ()
                return e.scrollBox
            end,
            event = function (checked, layout)
                config.setValue("notes.markerVisibility.personal", checked)
                widgetMarker.recreate(e.menu)
            end
        }

        local globalCB = AdvancedWorldMap.uiElements.checkbox{
            updateFunc = e.menu.update,
            text = l10n("GlobalNotesCB"),
            textSize = config.data.ui.fontSize,
            anchor = util.vector2(0, 0.5),
            position = util.vector2(config.data.ui.fontSize, config.data.ui.fontSize * 0.75),
            checked = config.data.notes.markerVisibility.global,
            getScrollBoxMeta = function ()
                return e.scrollBox
            end,
            event = function (checked, layout)
                config.setValue("notes.markerVisibility.global", checked)
                widgetMarker.recreate(e.menu)
            end
        }

        flexContent:add(
            addVPadding(label)
        )
        flexContent:add(
            addVPadding(personalCB)
        )
        flexContent:add(
            addVPadding(globalCB)
        )

        e.content:add{
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
            },
            content = flexContent,
        }
    end, 100)
end


-- A simple way to initialize the interface if it loads after this script
if not AdvancedWorldMap then
    async:newUnsavableSimulationTimer(0.01, function ()
        AdvancedWorldMap = I.AdvancedWorldMap
        if AdvancedWorldMap then
            init()
        end
    end)
else
    init()
end
