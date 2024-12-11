local common = require("mer.justDropIt.common")
local config = require("mer.justDropIt.config")
local JustDropIt = {}

---@class JustDropIt.registeredItem
---@field id string The ID of the object
---@field maxSteepness number The maximum angle the object will be placed at

---@param e JustDropIt.registeredItem
function JustDropIt.registerItem(e)
    common.logger:assert(type(e.id) == "string", "Item ID must be a string")
    common.logger:assert(type(e.maxSteepness) == "number", "Item maxSteepness must be a number")

    common.logger:debug("Registering item %s", e.id)
    config.registeredItems[e.id:lower()] = e
end

return JustDropIt