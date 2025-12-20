---@meta AdvancedWorldMap.MapElement

---Forward declaration for map widget type
---@class AdvancedWorldMap.MapWidget

---Map element wrapper providing methods to manipulate markers on the map
---@class AdvancedWorldMap.MapElement
---@field _id string Unique identifier of the map element
---@field _layerId integer Layer identifier where the element is located
---@field _parent AdvancedWorldMap.MapWidget Parent map widget instance
---@field _params AdvancedWorldMap.MapWidget.CreateImageMarkerParams|AdvancedWorldMap.MapWidget.CreateTextMarkerParams Element parameters
---@field _elemLayout Layout UI layout structure for the element
local AdvancedWorldMapMapElement = {}

---Sets the visibility state of the map element
---@param val boolean Visibility state (true = visible, false = hidden)
function AdvancedWorldMapMapElement:setVisibility(val) end

---Gets the current visibility state of the map element
---@return boolean visible Current visibility state
function AdvancedWorldMapMapElement:getVisibility() end

---Sets the opacity/transparency of the map element
---@param val number Alpha value in range [0, 1], where 0 is fully transparent and 1 is fully opaque
function AdvancedWorldMapMapElement:setAlpha(val) end

---Gets the current opacity/transparency of the map element
---@return number alpha Alpha value in range [0, 1]
function AdvancedWorldMapMapElement:getAlpha() end

---Sets the size of the map element.
---For text elements, this sets the font size.
---For image elements, this sets both width and height to the same value.
---@param val integer Size value in pixels
function AdvancedWorldMapMapElement:setSize(val) end

---Gets the current size of the map element
---@return integer|{x : number, y : number} size Font size for text elements, or vector2 size for image elements
function AdvancedWorldMapMapElement:getSize() end

---Gets the current color of the map element
---@return number[]? color RGB color array, or nil if element has no color
function AdvancedWorldMapMapElement:getColor() end

---Sets the color of the map element.
---For text elements, this sets the text color.
---For image elements, this sets the tint color.
---@param color number[] RGB color array
function AdvancedWorldMapMapElement:setColor(color) end

---Updates the UI layout properties of the map element.
---Only updates properties that are provided in the data parameter.
---@param data AdvancedWorldMap.MapWidget.CreateImageMarkerParams|AdvancedWorldMap.MapWidget.CreateTextMarkerParams New property values to apply
function AdvancedWorldMapMapElement:updateLayout(data) end

---Updates the stored parameters of the map element.
---Only updates parameters that are provided in the data parameter.
---@param data AdvancedWorldMap.MapWidget.CreateImageMarkerParams|AdvancedWorldMap.MapWidget.CreateTextMarkerParams New parameter values to store
function AdvancedWorldMapMapElement:updateParams(data) end

---Restores the element's layout to match its stored parameters.
---Useful after manual layout modifications or to reset element state.
function AdvancedWorldMapMapElement:restoreLayout() end

---Gets the custom user data associated with this element
---@return table? userData Custom user data table, if any was provided during creation
function AdvancedWorldMapMapElement:getUserData() end

---Gets the unique identifier of this map element
---@return string id Element identifier
function AdvancedWorldMapMapElement:getId() end

---Gets the layer identifier where this element is located
---@return integer layerId Layer identifier (e.g., marker layer, region layer, etc.)
function AdvancedWorldMapMapElement:getLayerId() end

---Removes this map element from the map widget.
---After calling this method, the element is no longer visible and cannot be used.
function AdvancedWorldMapMapElement:destroy() end

---Creates a new map element wrapper instance
---@param parentMeta AdvancedWorldMap.MapWidget Parent map widget that owns this element
---@param id string Unique identifier for the element
---@param layerId integer Layer where the element should be placed
---@param elemParams AdvancedWorldMap.MapWidget.CreateImageMarkerParams|AdvancedWorldMap.MapWidget.CreateTextMarkerParams Creation parameters
---@param elemLayout Layout UI layout structure for the element
---@return AdvancedWorldMap.MapElement element New map element instance
function AdvancedWorldMapMapElement.new(parentMeta, id, layerId, elemParams, elemLayout) end

return AdvancedWorldMapMapElement
