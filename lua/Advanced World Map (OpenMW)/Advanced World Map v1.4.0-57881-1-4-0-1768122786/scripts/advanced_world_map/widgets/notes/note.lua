local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local I = require("openmw.interfaces")

local commonData = require("scripts.advanced_world_map.common")
local config = require("scripts.advanced_world_map.config.config")

local button = require("scripts.advanced_world_map.ui.button")

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

    -- Only add note buttons when in zoom-in mode (interior or exterior with sufficient zoom)
    if not e.mapWidget:isInZoomInMode() then
        return
    end

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
                                widgetData.addMarkerData(dt)
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
                            widgetData.addMarkerData(dt)
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
