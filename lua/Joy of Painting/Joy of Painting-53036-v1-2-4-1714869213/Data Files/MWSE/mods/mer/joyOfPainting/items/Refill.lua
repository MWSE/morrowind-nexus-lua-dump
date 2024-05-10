local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Refill")

---@class JOP.Refill
---@field paintType string The paint type to refill
---@field recipe CraftingFramework.Recipe.data The recipe to use to refill this paint type

local Refill = {}

---@param e JOP.Refill
function Refill.registerRefill(e)
    logger:assert(type(e.paintType) == "string", "paintType must be a string")
    logger:assert(type(e.recipe) == "table", "recipe must be a table")
    logger:debug("Registering refill %s", e.paintType)

    if not config.refills[e.paintType] then
        config.refills[e.paintType] = {}
    end
    table.insert(config.refills[e.paintType], e)
end

return Refill
