---@meta AdvancedWorldMap.MapWidget

---Forward declaration for map element type
---@class AdvancedWorldMap.MapElement

---Layer identifiers for different map elements
---@class AdvancedWorldMap.MapWidget.LayerId
---@field map integer Base map layer (ground textures)
---@field region integer Region labels layer
---@field name integer Location name labels layer
---@field player integer Player marker layer
---@field nonInteractive integer Non-interactive markers layer
---@field marker integer Interactive markers layer

---Scale functions for different element types
---@class AdvancedWorldMap.MapWidget.ScaleFunctions
---@field linear fun(size: number|openmw.util.Vector2, zoom: number): number|openmw.util.Vector2 Linear scaling function
---@field marker fun(size: number|openmw.util.Vector2, zoom: number): number|openmw.util.Vector2 Marker scaling function (uses fourth root)
---@field playerMarker fun(size: number|openmw.util.Vector2, zoom: number): number|openmw.util.Vector2 Player marker scaling function

---Rectangular region definition
---@class AdvancedWorldMap.MapWidget.Region
---@field left number Left boundary coordinate
---@field right number Right boundary coordinate
---@field top number Top boundary coordinate
---@field bottom number Bottom boundary coordinate

---Map metadata information
---@class AdvancedWorldMap.MapWidget.MapInfo
---@field height integer height of the map texture
---@field width integer width of the map texture
---@field pixelsPerCell integer number of pixels per cell
---@field gridX {min: integer, max: integer} grid X boundaries in cells
---@field gridY {min: integer, max: integer} grid Y boundaries in cells

---Event data for mouse event
---@class AdvancedWorldMap.MapWidget.CreateMarker.Events.MouseEvent
---@field button integer? Mouse button index
---@field offset openmw.util.Vector2 Cursor offset relative to marker
---@field position openmw.util.Vector2 Cursor position

---@class AdvancedWorldMap.MapWidget.CreateMarker.Events
---@field focusLoss fun(e : nil, layout : Layout)?
---@field mouseMove fun(e : AdvancedWorldMap.MapWidget.CreateMarker.Events.MouseEvent, layout : Layout)?
---@field mousePress fun(e : AdvancedWorldMap.MapWidget.CreateMarker.Events.MouseEvent, layout : Layout)?
---@field mouseRelease fun(e : AdvancedWorldMap.MapWidget.CreateMarker.Events.MouseEvent, layout : Layout, beenPressed : boolean)?

---Parameters for creating an image marker
---@class AdvancedWorldMap.MapWidget.CreateImageMarkerParams
---@field layerId integer Target layer for the marker
---@field id string? Unique identifier (auto-generated if not provided)
---@field pos openmw.util.Vector2|openmw.util.Vector3 World position (vector3 or vector2)
---@field texture TextureResource UI texture resource
---@field events AdvancedWorldMap.MapWidget.CreateMarker.Events? Event handlers table
---@field tooltipContent Content? Content to display in tooltip
---@field size openmw.util.Vector2 Marker size (vector2)
---@field color openmw.util.Color? RGB color (vector3 or array)
---@field anchor openmw.util.Vector2? Anchor point (vector2, default 0.5, 0.5)
---@field alpha number? Opacity [0-1] (default 1)
---@field visible boolean? Visibility state (default true)
---@field showWhenZoomedIn boolean? Only show when zoomed in
---@field showWhenZoomedOut boolean? Only show when zoomed out
---@field scaleFunc (fun(size: number|openmw.util.Vector2, zoom: number): number|openmw.util.Vector2)? Custom scaling function
---@field userData table? Custom user data

---Parameters for creating a text marker
---@class AdvancedWorldMap.MapWidget.CreateTextMarkerParams
---@field layerId integer Target layer for the marker
---@field id string? Unique identifier (auto-generated if not provided)
---@field pos openmw.util.Vector2|openmw.util.Vector3 World position (vector3 or vector2)
---@field text string Text content to display
---@field events AdvancedWorldMap.MapWidget.CreateMarker.Events? Event handlers table
---@field tooltipContent Content? Content to display in tooltip
---@field fontSize number? Font size (default 18)
---@field size openmw.util.Vector2? Marker size (vector2, auto if not provided)
---@field autoHeight boolean? Automatically adjust height based on text content. size.y must be 0. Not allowed on 'marker' layer.
---@field color openmw.util.Color? RGB color (vector3 or array)
---@field anchor openmw.util.Vector2? Anchor point (vector2, default 0.5, 0.5)
---@field textAlignH ALIGNMENT? Horizontal text alignment
---@field textAlignV ALIGNMENT? Vertical text alignment
---@field alpha number? Opacity [0-1] (default 1)
---@field visible boolean? Visibility state (default true)
---@field showWhenZoomedIn boolean? Only show when zoomed in
---@field showWhenZoomedOut boolean? Only show when zoomed out
---@field scaleFunc (fun(size: number|openmw.util.Vector2, zoom: number): number|openmw.util.Vector2)? Custom scaling function
---@field userData table? Custom user data

---Parameters for creating a map widget
---@class AdvancedWorldMap.MapWidget.Params
---@field size openmw.util.Vector2 Widget size (vector2)
---@field fontSize integer? Font size for UI elements
---@field position openmw.util.Vector2? Absolute position (vector2)
---@field relativePosition openmw.util.Vector2? Relative position (vector2, [0-1] range)
---@field anchor openmw.util.Vector2? Anchor point (vector2)
---@field cellId string? Interior cell ID (nil for exterior/world map)
---@field updateFunc function Callback function to trigger UI updates

---Map widget providing map display and interaction functionality
---@class AdvancedWorldMap.MapWidget
---@field LAYER AdvancedWorldMap.MapWidget.LayerId Layer identifiers
---@field SCALE_FUNCTION AdvancedWorldMap.MapWidget.ScaleFunctions Scale functions
---@field cellId string? Current cell ID (nil for world map)
---@field mapInfo AdvancedWorldMap.MapWidget.MapInfo Map metadata (width, height, grid bounds, etc.)
---@field zoom number Current zoom level
---@field minZoom number Minimum allowed zoom level
---@field maxZoom number Maximum allowed zoom level
---@field layout Layout Root UI layout structure
local AdvancedWorldMapMapWidget = {}

---Generates a unique ID for map elements
---@return integer id Unique identifier
function AdvancedWorldMapMapWidget:getUniqueId() end

---Gets the display size of the map (including padding)
---@param scale number? Scale multiplier (uses current zoom if not provided)
---@return openmw.util.Vector2 size Display size as vector2
function AdvancedWorldMapMapWidget:getDisplaySize(scale) end

---Gets the padding around the map
---@param scale number? Scale multiplier (uses current zoom if not provided)
---@return openmw.util.Vector2 padding Padding as vector2
function AdvancedWorldMapMapWidget:getPadding(scale) end

---Gets the layout for a specific layer
---@param id integer Layer identifier
---@return Layout layout Layer layout structure
function AdvancedWorldMapMapWidget:getLayerLayout(id) end

---Gets the relative center point of the map (normalized coordinates)
---@return openmw.util.Vector2 center Center position as vector2 [0-1]
function AdvancedWorldMapMapWidget:getRelativeCenter() end

---Gets the relative rotation pivot point (for rotated interior maps)
---@return openmw.util.Vector2 pivot Pivot position as vector2 [0-1]
function AdvancedWorldMapMapWidget:getRelativeRotationPivot() end

---Gets the absolute rotation pivot point in pixels
---@param scale number? Scale multiplier (uses 1 if not provided)
---@return openmw.util.Vector2 pivot Pivot position as vector2 in pixels
function AdvancedWorldMapMapWidget:getRotationPivot(scale) end

---Converts world position to relative map position [0-1]
---@param worldPos openmw.util.Vector2|openmw.util.Vector3 World coordinates (vector2 or vector3)
---@return openmw.util.Vector2 relPos Relative position as vector2 [0-1]
function AdvancedWorldMapMapWidget:getRelativePositionByWorldPosition(worldPos) end

---Converts world position to absolute pixel position on the map
---@param worldPos openmw.util.Vector2|openmw.util.Vector3 World coordinates (vector2 or vector3)
---@param ignoreNorthAngle boolean? If true, ignores map rotation
---@return openmw.util.Vector2 absPos Absolute position as vector2 in pixels
function AdvancedWorldMapMapWidget:getAbsolutePositionByWorldPosition(worldPos, ignoreNorthAngle) end

---Gets the relative position [0-1] of the cursor on the map
---@return openmw.util.Vector2 relPos Cursor position as vector2 [0-1]
function AdvancedWorldMapMapWidget:getRelativePositionOfCursor() end

---Converts relative map position [0-1] to world coordinates
---@param relPos openmw.util.Vector2 Relative position as vector2 [0-1]
---@return openmw.util.Vector2 worldPos World coordinates as vector2
function AdvancedWorldMapMapWidget:getWorldPositionByRelativePosition(relPos) end

---Gets the currently visible rectangular area of the map
---@return AdvancedWorldMap.MapWidget.Region rect Visible rectangle in pixel coordinates
function AdvancedWorldMapMapWidget:getVisibleMapRect() end

---Gets the currently visible rectangular area in world coordinates
---@return AdvancedWorldMap.MapWidget.Region rectWorld Visible rectangle in world coordinates
---@return AdvancedWorldMap.MapWidget.Region rectPixels Visible rectangle in pixel coordinates
function AdvancedWorldMapMapWidget:getVisibleMapRectInWorldCoordinates() end

---Gets the world position at the center of the visible area
---@return openmw.util.Vector2 worldPos Center world position as vector2
function AdvancedWorldMapMapWidget:getWorldPositionOfVisibleCenter() end

---Gets the relative position [0-1] at the center of the visible area
---@return openmw.util.Vector2 relPos Center relative position as vector2 [0-1]
function AdvancedWorldMapMapWidget:getRelativePositionOfVisibleCenter() end

---Gets the current widget size
---@return openmw.util.Vector2 size Widget size as vector2
function AdvancedWorldMapMapWidget:getSize() end

---Updates markers that appear/disappear based on zoom level
function AdvancedWorldMapMapWidget:updateOnZoomMarkers() end

---Sets the zoom level, optionally centering on a specific point
---@param zoom number New zoom level
---@param relativePos openmw.util.Vector2? Position to center on (vector2 [0-1], defaults to visible center)
function AdvancedWorldMapMapWidget:setZoom(zoom, relativePos) end

---Checks if the map is currently in zoomed-in mode
---@return boolean isInZoomInMode True if in zoomed-in mode
function AdvancedWorldMapMapWidget:isInZoomInMode() end

---Centers the map view on a specific world position
---@param worldPos openmw.util.Vector2|openmw.util.Vector3 World coordinates to focus on (vector2 or vector3)
function AdvancedWorldMapMapWidget:focusOnWorldPosition(worldPos) end

---Forces a complete marker update (recalculates zoom and visibility)
function AdvancedWorldMapMapWidget:updateMarkers() end

---Creates an image marker on the map
---@param params AdvancedWorldMap.MapWidget.CreateImageMarkerParams Marker creation parameters
---@return AdvancedWorldMap.MapElement? marker Created marker instance, or nil if creation failed
function AdvancedWorldMapMapWidget:createImageMarker(params) end

---Creates a text marker on the map
---@param params AdvancedWorldMap.MapWidget.CreateTextMarkerParams Marker creation parameters
---@return AdvancedWorldMap.MapElement? marker Created marker instance, or nil if creation failed
function AdvancedWorldMapMapWidget:createTextMarker(params) end

---Removes a marker from the map
---@param id string Marker identifier
---@param layer integer Layer identifier where the marker is located
function AdvancedWorldMapMapWidget:removeMarker(id, layer) end

---Removes zoom-dependent markers, optionally keeping those in a specific region
---@param allowRect AdvancedWorldMap.MapWidget.Region? Region to preserve markers in (world coordinates)
function AdvancedWorldMapMapWidget:removeOnZoomMarkers(allowRect) end

---Updates the player marker position and rotation
---@param focusOnPlayer boolean? If true, centers the map on the player
---@param forceUpdate boolean? If true, forces update even if position hasn't changed significantly
---@return boolean updated True if the marker was updated
function AdvancedWorldMapMapWidget:updatePlayerMarker(focusOnPlayer, forceUpdate) end

---Closes the right-click context menu if open
function AdvancedWorldMapMapWidget:closeRightMouseMenu() end

---Sets the visibility of a specific layer
---@param layerId integer Layer identifier
---@param visible boolean Visibility state
---@return boolean success True if the layer exists and was modified
function AdvancedWorldMapMapWidget:setLayerVisibility(layerId, visible) end

---Gets the visibility state of a specific layer
---@param layerId integer Layer identifier
---@return boolean? visible Visibility state, or nil if layer doesn't exist
function AdvancedWorldMapMapWidget:getLayerVisibility(layerId) end

---Gets all currently active markers (including zoom-dependent ones)
---@return AdvancedWorldMap.MapElement[] markers Array of active marker instances
function AdvancedWorldMapMapWidget:getActiveMarkers() end

---Checks if a point is within a rectangular region
---@param region AdvancedWorldMap.MapWidget.Region Region to check
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean isInside True if the point is inside the region
function AdvancedWorldMapMapWidget.isPointInRegion(region, x, y) end

---Generates a unique ID for map elements (static function)
---@return integer id Unique identifier
function AdvancedWorldMapMapWidget.getUniqueId() end

---Updates the map widget's parent menu
function AdvancedWorldMapMapWidget.update() end

return AdvancedWorldMapMapWidget
