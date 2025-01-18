local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Refill")

---@class (exact) JOP.Refill.data
---@field paintType string The paint type to refill
---@field recipe CraftingFramework.Recipe.data The recipe to use to refill this paint type

---@class JOP.Refill : JOP.Refill.data
local Refill = {
    ---@type table<string, JOP.Refill.data[]>
    registeredRefills = {},
    ---@type table<string, table>
    registeredRefillItems = {}
}

---@param e JOP.Refill.data
function Refill.registerRefill(e)
    logger:assert(type(e.paintType) == "string", "paintType must be a string")
    logger:assert(type(e.recipe) == "table", "recipe must be a table")
    logger:debug("Registering refill %s", e.paintType)

    if not Refill.registeredRefills[e.paintType] then
        Refill.registeredRefills[e.paintType] = {}
    end
    table.insert(Refill.registeredRefills[e.paintType], e)
end

---@param paintType JOP.PaintType
function Refill.getRefills(paintType)
    return Refill.registeredRefills[paintType.id] or {}
end

---@param e { id: string}
function Refill.registerRefillItem(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:debug("Registering refill item %s", e.id)
    e.id = e.id:lower()
    Refill.registeredRefillItems[e.id] = table.copy(e, {})
end

---@param id string
---@return boolean
function Refill.isRefillItem(id)
    return Refill.registeredRefillItems[id:lower()] ~= nil
end

return Refill
