---@meta AdvancedWorldMap.Menu.Map

---Forward declaration for map widget type
---@class AdvancedWorldMap.MapWidget

---Parameters for adding a header widget/button
---@class AdvancedWorldMap.Menu.AddHeaderElementParams
---@field id string Unique identifier for the widget
---@field layout Layout UI layout structure for the widget
---@field onOpen fun(menu: AdvancedWorldMap.Menu.Map, content: Content)? Callback when widget is opened. 'content' is the content of horizontal Flex. Important: all elements added to this content must have definite size (no autoSize)
---@field onClose fun(menu: AdvancedWorldMap.Menu.Map)? Callback when widget is closed
---@field onClick fun(menu: AdvancedWorldMap.Menu.Map, event: AdvancedWorldMap.MapWidget.CreateMarker.Events.MouseEvent)? Callback when widget is clicked
---@field proiority number? Priority for ordering widgets in the header
---@field showWhenMenuInactive boolean? If true, shows widget even in inactive menu mode

---Parameters for creating a map menu
---@class AdvancedWorldMap.Menu.Map.CreateParams
---@field relativePosition Vector2? Menu position relative to screen [0-1] (vector2)
---@field relativeSize Vector2? Menu size relative to screen [0-1] (vector2)
---@field fontSize number? Font size for UI text elements
---@field onClose fun()? Callback function when menu is closed

---Map menu providing the main UI for the Advanced World Map
---@class AdvancedWorldMap.Menu.Map
---@field menu Element OpenMW UI menu instance
---@field params AdvancedWorldMap.Menu.Map.CreateParams Creation parameters
---@field size Vector2 Menu size as vector2
---@field mainSize Vector2 Main content area size as vector2
---@field headerHeight number Height of the header bar
---@field mapWidget AdvancedWorldMap.MapWidget Current active map widget instance
---@field centerOnPlayer boolean Whether to center map on player position
local AdvancedWorldMapMenuMap = {}

---Opens or toggles a header widget by ID.
---If the widget is already open, closes it. If another widget is open, closes it and opens this one.
---@param id string Widget identifier
---@return boolean success True if the operation succeeded
function AdvancedWorldMapMenuMap:openWidget(id) end

---Closes the currently active header widget, if any
function AdvancedWorldMapMenuMap:closeActiveWidget() end

---Adds a widget/button to the header bar.
---The widget can have callbacks for open/close events and can be shown in active or inactive menu modes.
---@param params AdvancedWorldMap.Menu.AddHeaderElementParams Widget parameters
function AdvancedWorldMapMenuMap:addWidget(params) end

---Returns whether a specific widget is currently active/open.
---@param id string Widget identifier
---@return boolean isActive True if the specified widget is currently active/open
function AdvancedWorldMapMenuMap:isWidgetActive(id) end

---Returns whether any header widget is currently active/open.
---@return boolean hasActive True if any widget is currently active/open
function AdvancedWorldMapMenuMap:hasActiveWidget() end

---Gets or creates a map widget for a specific cell.
---Uses cached widgets if available. Creates new widget if needed.
---@param cellId string? Cell identifier (nil for exterior/world map)
---@return Layout? layout Map widget UI layout
---@return AdvancedWorldMap.MapWidget? meta Map widget instance
---@return boolean? isNew True if a new widget was created
function AdvancedWorldMapMenuMap:getMapWidgetForCell(cellId) end

---Gets a cached map widget instance for a specific cell
---@param cellId string? Cell identifier (nil for exterior/world map)
---@return AdvancedWorldMap.MapWidget? widget Cached widget instance, or nil if not found
function AdvancedWorldMapMenuMap:getCachedMapWidget(cellId) end

---Switches the displayed map to a different cell.
---Triggers onMapClosed, onMapInitialized (if new), and onMapShown events.
---@param cellId string? Cell identifier (nil for exterior/world map)
---@return boolean changed True if the map was actually changed
function AdvancedWorldMapMenuMap:updateMapWidgetCell(cellId) end

---Updates interactive elements based on menu mode (active/inactive).
---Shows/hides header widgets and adjusts visibility accordingly.
---@return boolean changed True if the menu mode changed
function AdvancedWorldMapMenuMap:updateInteractiveElements() end

---Gets the height of the header bar
---@return number height Header height in pixels
function AdvancedWorldMapMenuMap:getHeaderHeight() end

---Closes the map menu and cleans up resources.
---Triggers the onMapClosed event and destroys the UI.
function AdvancedWorldMapMenuMap:close() end

---Calculates the total width of all widgets in the side panel
---@return number width Total width in pixels
function AdvancedWorldMapMenuMap:getWidgetWindowWidth() end

---Updates the map widget width based on side panel size.
---Adjusts map size to account for open widgets.
function AdvancedWorldMapMenuMap:updateMapWidgetWidth() end

---Triggers a UI update/refresh
function AdvancedWorldMapMenuMap:update() end

---Requests a map update on the next update cycle.
function AdvancedWorldMapMenuMap:requestUpdate() end

return AdvancedWorldMapMenuMap
