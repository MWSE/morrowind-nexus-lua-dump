-- Poison Crafting
---@class PoisonCrafting
local this ={}

--- @param item tes3weapon
--- @param itemData tes3itemData?
--- @return tes3alchemy?
function this.GetPoison(item, itemData)
    local id
    local projectile = tes3.player.data.g7_poisons and tes3.player.data.g7_poisons[item.id] or nil
    if projectile then
        id = projectile.poison
    elseif itemData then
        id = itemData.data.g7_poison
    end
    if id then
        local obj = tes3.getObject(id) ---@cast obj tes3alchemy
        return obj
    end
end

return this