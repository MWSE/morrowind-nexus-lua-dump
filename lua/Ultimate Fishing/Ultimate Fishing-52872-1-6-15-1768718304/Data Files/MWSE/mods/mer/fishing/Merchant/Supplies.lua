local common = require("mer.fishing.common")
local logger = common.createLogger("Supplies")

---Class for registering items to be sold by the merchant
---@class Fishing.Supplies
local Supplies = {
    supplyList = {}
}

---Get the list of items to be sold by fishing merchants
---@return table<string, number>
function Supplies.getSupplyList()
    return Supplies.supplyList
end

---Register an item to be sold by fishing merchants
---@param e { id: string, count: number}
function Supplies.register(e)
    logger:debug("Registering Fishing Supply %s:%d", e.id, e.count)
    Supplies.supplyList[e.id:lower()] = e.count
end

return Supplies
