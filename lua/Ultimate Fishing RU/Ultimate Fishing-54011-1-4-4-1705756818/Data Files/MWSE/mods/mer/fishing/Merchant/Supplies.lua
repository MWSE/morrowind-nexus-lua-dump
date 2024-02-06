--[[
    Class for registering items to be sold by the merchant
]]

---@class Fishing.Supplies
local Supplies = {
    supplyList = {}
}

---@class Fishing.Supply.config
---@field id string the Item id
---@field count number the number of items to add to the merchant's inventory. Can be negative for restocking supplies

---Register an item to be sold by the merchant
---@param e Fishing.Supply.config
function Supplies.register(e)
    Supplies.supplyList[e.id:lower()] = e.count
end

return Supplies
