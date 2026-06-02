---@meta

-- LuaLS stubs for OpenMW's Lua auxiliary utilities.
-- Runtime behavior is provided by OpenMW resources/vfs/openmw_aux/util.lua.
-- OpenMW script contexts: global|menu|local|player

---Utility functions implemented in Lua rather than C++.
---@class openmw_aux.util
local util = {}

---Works like `tostring` but also shows the content of tables.
---@param value any The value to convert to a string.
---@param maxDepth? number Max depth of table unpacking; defaults to 1.
---@return string
function util.deepToString(value, maxDepth) end

---Finds the element in the array with the lowest score returned by `scoreFn`.
---@param array table Any array-like table.
---@param scoreFn fun(value: any): number|false|nil Function that returns nil/false or a number for each element.
---@return any element The element with the lowest score.
---@return number? score The chosen element's score.
---@return integer? index The chosen element's index.
function util.findMinScore(array, scoreFn) end

---Computes `scoreFn` for each element and filters out false and nil results.
---@param array table Any array-like table.
---@param scoreFn fun(value: any): any Filter function.
---@return table values Output array.
---@return table scores Scores corresponding to `values`.
function util.mapFilter(array, scoreFn) end

---Filters and sorts `array` by the scores calculated by `scoreFn`.
---@param array table Any array-like table.
---@param scoreFn fun(value: any): any Filter function.
---@return table values Sorted output array.
---@return table scores Scores corresponding to `values`.
function util.mapFilterSort(array, scoreFn) end

---Calls event handlers from last to first until one returns false.
---@param handlers? table<integer, fun(...): any> Optional array of handlers to invoke.
---@param ... any Arguments passed to each handler.
---@return boolean handled True if no further handlers should be called.
function util.callEventHandlers(handlers, ...) end

---Calls arrays of event handlers until the event is handled.
---@param handlers table<integer, table<integer, fun(...): any>> Array of event handler arrays.
---@param ... any Arguments passed to each handler.
---@return boolean handled True if no further handlers should be called.
function util.callMultipleEventHandlers(handlers, ...) end

---Copies all key-value pairs from the input table to a new table.
---@param table table The table to copy.
---@return table copy A shallow copy of the input table.
function util.shallowCopy(table) end

return util
