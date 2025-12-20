---@meta AdvancedWorldMap.Event

---Forward declarations for cross-referenced types
---@class AdvancedWorldMap.Menu.Map
---@class AdvancedWorldMap.MapWidget
---@class AdvancedWorldMap.MapElement

---Event data for menu opened event
---@class AdvancedWorldMap.Event.OnMenuOpenedEvent
---@field menu AdvancedWorldMap.Menu.Map Map menu instance

---Event data for menu closed event
---@class AdvancedWorldMap.Event.OnMenuClosedEvent
---@field menu AdvancedWorldMap.Menu.Map Map menu instance

---Event data for map initialized event
---@class AdvancedWorldMap.Event.OnMapInitializedEvent
---@field menu AdvancedWorldMap.Menu.Map Map menu instance
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field cellId string? Cell identifier (nil for exterior/world map)

---Event data for map shown event
---@class AdvancedWorldMap.Event.OnMapShownEvent
---@field menu AdvancedWorldMap.Menu.Map Map menu instance
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field cellId string? Cell identifier (nil for exterior/world map)

---Event data for map closed event
---@class AdvancedWorldMap.Event.OnMapClosedEvent
---@field menu AdvancedWorldMap.Menu.Map Map menu instance
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field cellId string? Cell identifier (nil for exterior/world map)

---Event data for marker click event
---@class AdvancedWorldMap.Event.OnMarkerClickEvent
---@field marker AdvancedWorldMap.MapElement Marker that was clicked

---Event data for marker clicked event
---@class AdvancedWorldMap.Event.OnMarkerClickedEvent
---@field marker AdvancedWorldMap.MapElement Marker that was clicked

---Event data for marker tooltip show event
---@class AdvancedWorldMap.Event.OnMarkerTooltipShowEvent
---@field marker AdvancedWorldMap.MapElement Marker to show tooltip for
---@field content Content Tooltip content

---Event data for marker tooltip showed event
---@class AdvancedWorldMap.Event.OnMarkerTooltipShowedEvent
---@field marker AdvancedWorldMap.MapElement Marker with tooltip
---@field content Content Tooltip content
---@field tooltip Element Displayed tooltip instance

---Event data for map element initialized event
---@class AdvancedWorldMap.Event.OnMapElementInitializedEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field marker AdvancedWorldMap.MapElement Initialized map element

---Event data for map element created event
---@class AdvancedWorldMap.Event.OnMapElementCreatedEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field marker AdvancedWorldMap.MapElement Created map element

---Event data for map element removed event
---@class AdvancedWorldMap.Event.OnMapElementRemovedEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field marker AdvancedWorldMap.MapElement Removed map element

---Event data for mouse press event
---@class AdvancedWorldMap.Event.OnMousePressEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field marker AdvancedWorldMap.MapElement? Marker under cursor (if any)
---@field offset openmw.util.Vector2 Cursor offset relative to marker
---@field position openmw.util.Vector2 Cursor position
---@field button integer Pressed mouse button number

---Event data for mouse release event
---@class AdvancedWorldMap.Event.OnMouseReleaseEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field marker AdvancedWorldMap.MapElement? Marker under cursor (if any)
---@field offset openmw.util.Vector2 Cursor offset relative to marker
---@field position openmw.util.Vector2 Cursor position
---@field button integer Released mouse button number

---Event data for focus loss event
---@class AdvancedWorldMap.Event.OnFocusLossEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field marker AdvancedWorldMap.MapElement? Marker that lost focus (if any)

---Event data for mouse move event
---@class AdvancedWorldMap.Event.OnMouseMoveEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field marker AdvancedWorldMap.MapElement? Marker under cursor (if any)
---@field offset openmw.util.Vector2 Cursor offset relative to marker
---@field position openmw.util.Vector2 Cursor position

---Event data for right mouse menu event
---@class AdvancedWorldMap.Event.OnRightMouseMenuEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field marker AdvancedWorldMap.MapElement? Marker under cursor (if any)
---@field content Content Context menu content
---@field relPos openmw.util.Vector2 Relative cursor position

---Event data for window resized event
---@class AdvancedWorldMap.Event.OnResizedEvent
---@field menu AdvancedWorldMap.Menu.Map Map menu instance
---@field size openmw.util.Vector2 New window size
---@field mapWidgetSize openmw.util.Vector2 New map widget size

---Event data for zoom changed event
---@class AdvancedWorldMap.Event.OnZoomedEvent
---@field mapWidget AdvancedWorldMap.MapWidget Map widget instance
---@field zoom number New zoom level

---Search event result entry
---@class AdvancedWorldMap.Event.OnSearchEvent.Result
---@field cellId string? Cell identifier (nil for exterior/world map)
---@field pos openmw.util.Vector2 World position
---@field text string Marker text
---@field color openmw.util.Color Marker color
---@field priority number? Marker priority in search results

---Search event parameters
---@class AdvancedWorldMap.Event.OnSearchEvent.Params
---@field showUnrevealed boolean Value indicating whether to include unrevealed locations in the search
---@field searchAllLocations boolean Value indicating whether to search in all locations or only the current one

---Event data for search event
---@class AdvancedWorldMap.Event.OnSearchEvent
---@field results AdvancedWorldMap.Event.OnSearchEvent.Result[] Search results
---@field filter string Search filter string
---@field params AdvancedWorldMap.Event.OnSearchEvent.Params Search parameters

---Event data for fast travel event
---@class AdvancedWorldMap.Event.OnFastTravelEvent
---@field position openmw.util.Vector3 Target world position
---@field cellId string? Target cell identifier (nil for exterior/world map)

---Event data for fast travel resolve event
---@class AdvancedWorldMap.Event.OnFastTravelResolveEvent
---@field cost number Fast travel cost
---@field message string Fast travel message
---@field position openmw.util.Vector3 Target world position
---@field cell any Target cell
---@field rotation openmw.util.Vector3 Target rotation
---@field followers GameObject[] List of follower actors

---Event data for fast travel resolved event
---@class AdvancedWorldMap.Event.OnFastTravelResolvedEvent
---@field cost number Fast travel cost
---@field message string Fast travel message
---@field position openmw.util.Vector3 Target world position
---@field cell any Target cell
---@field rotation openmw.util.Vector3 Target rotation
---@field followers GameObject[]? List of follower actors

---Advanced World Map event system
---@class AdvancedWorldMap.Event
---@field EVENT AdvancedWorldMap.Event.EVENT Table containing event identifiers
local AdvancedWorldMapEvent = {}

---Table containing event identifiers for the Advanced World Map event system
---@class AdvancedWorldMap.Event.EVENT
AdvancedWorldMapEvent.EVENT = {
    onMenuOpened = "onMenuOpened", -- Event triggered when the map menu is opened
    onMenuClosed = "onMenuClosed", -- Event triggered when the map menu is closed
    onMapInitialized = "onMapInitialized", -- Event triggered when the map is initialized
    onMapShown = "onMapShown", -- Event triggered when the map is shown
    onMapClosed = "onMapClosed", -- Event triggered when the map is closed
    onMarkerClick = "onMarkerClick", -- Event triggered when a built-in marker is clicked
    onMarkerClicked = "onMarkerClicked", -- Event triggered after a built-in marker click is completed
    onMarkerTooltipShow = "onMarkerTooltipShow", -- Event triggered when a built-in marker tooltip is about to be shown
    onMarkerTooltipShowed = "onMarkerTooltipShowed", -- Event triggered after a built-in marker tooltip is shown
    onMapElementInitialized = "onMapElementInitialized", -- Event triggered when a map element (marker) is initialized
    onMapElementCreated = "onMapElementCreated", -- Event triggered when a map element (marker) is created on the map
    onMapElementRemoved = "onMapElementRemoved", -- Event triggered when a map element (marker) is removed from the map
    onMousePress = "onMousePress", -- Event triggered when a mouse button is pressed on the map
    onMouseRelease = "onMouseRelease", -- Event triggered when a mouse button is released on the map
    onFocusLoss = "onFocusLoss", -- Event triggered when focus is lost on the map
    onMouseMove = "onMouseMove", -- Event triggered when the mouse moves on the map
    onRightMouseMenu = "onRightMouseMenu", -- Event triggered when the right-click context menu is opened
    onResized = "onResized", -- Event triggered when the map window is resized
    onZoomed = "onZoomed", -- Event triggered when the map zoom level changes
    onSearch = "onSearch", -- Event triggered when a search is performed
    onFastTravel = "onFastTravel", -- Event triggered when a fast travel is initiated
    onFastTravelResolve = "onFastTravelResolve", -- Event triggered when a fast travel is being resolved
    onFastTravelResolved = "onFastTravelResolved", -- Event triggered after a fast travel has been resolved
}

---Registers an event handler in the event system.
---Handler can return up to two values:
---  - First value (boolean?): if true, stops further event processing
---  - Second value (boolean?): if true, prevents default behavior from happening (only used in some events)
---@param eventId string Event identifier
---@param priority number? Handler priority (default is 0, higher value = higher priority)
---@overload fun(eventId: "onMenuOpened", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMenuOpenedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMenuClosed", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMenuClosedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMapInitialized", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMapInitializedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMapShown", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMapShownEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMapClosed", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMapClosedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMarkerClick", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMarkerClickEvent): boolean?, boolean?, priority: number?)
---@overload fun(eventId: "onMarkerClicked", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMarkerClickedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMarkerTooltipShow", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMarkerTooltipShowEvent): boolean?, boolean?, priority: number?)
---@overload fun(eventId: "onMarkerTooltipShowed", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMarkerTooltipShowedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMapElementInitialized", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMapElementInitializedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMapElementCreated", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMapElementCreatedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMapElementRemoved", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMapElementRemovedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onMousePress", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMousePressEvent): boolean?, boolean?, priority: number?)
---@overload fun(eventId: "onMouseRelease", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMouseReleaseEvent): boolean?, boolean?, priority: number?)
---@overload fun(eventId: "onFocusLoss", handlerFunc: fun(e: AdvancedWorldMap.Event.OnFocusLossEvent): boolean?, boolean?, priority: number?)
---@overload fun(eventId: "onMouseMove", handlerFunc: fun(e: AdvancedWorldMap.Event.OnMouseMoveEvent): boolean?, boolean?, priority: number?)
---@overload fun(eventId: "onRightMouseMenu", handlerFunc: fun(e: AdvancedWorldMap.Event.OnRightMouseMenuEvent): boolean?, priority: number?)
---@overload fun(eventId: "onResized", handlerFunc: fun(e: AdvancedWorldMap.Event.OnResizedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onZoomed", handlerFunc: fun(e: AdvancedWorldMap.Event.OnZoomedEvent): boolean?, priority: number?)
---@overload fun(eventId: "onSearch", handlerFunc: fun(e: AdvancedWorldMap.Event.OnSearchEvent): boolean?, priority: number?)
---@overload fun(eventId: "onFastTravel", handlerFunc: fun(e: AdvancedWorldMap.Event.OnFastTravelEvent): boolean?, boolean?, priority: number?)
---@overload fun(eventId: "onFastTravelResolve", handlerFunc: fun(e: AdvancedWorldMap.Event.OnFastTravelResolveEvent): boolean?, boolean?, priority: number?)
---@overload fun(eventId: "onFastTravelResolved", handlerFunc: fun(e: AdvancedWorldMap.Event.OnFastTravelResolvedEvent): boolean?, priority: number?)
function AdvancedWorldMapEvent.registerHandler(eventId, handlerFunc, priority) end

---Removes a registered event handler from the event system
---@param eventId string Event identifier
---@param handlerFunc function Handler function to remove
function AdvancedWorldMapEvent.unregisterHandler(eventId, handlerFunc) end

---Checks if an event has at least one registered handler
---@param eventId string Event identifier to check
---@return boolean hasHandler true if at least one handler is registered for the event
function AdvancedWorldMapEvent.isContainsHandler(eventId) end

---Triggers execution of all handlers registered for an event.
---Handlers are executed in descending order of priority.
---Execution stops if a handler returns true as the first return value.
---@param eventId string Event identifier to trigger
---@param e table? Event data table
---@return boolean? blocked true if at least one handler returned block=true
function AdvancedWorldMapEvent.triggerEvent(eventId, e) end

return AdvancedWorldMapEvent
