local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Tapestry")
local config = require("mer.joyOfPainting.config")
local Tapestry = {}

---@class JOP.Tapestry.data
---@field id string

---@param e JOP.Tapestry.data
function Tapestry.registerTapestry(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    config.tapestries[e.id:lower()] = e
end

return Tapestry