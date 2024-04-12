local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local gameConfig = config.getGameConfig()

local function isItemWithCondition(item)
    
    return item.objectType == tes3.objectType.weapon
        or item.objectType == tes3.objectType.armor
    
end

local function fixItemConditionEnabled()
    
    return gameConfig.condition.fixItemHealthOverflow
        or gameConfig.condition.repairDamagedItems
    
end

this = {}

this.onItemLoaded = function(e)
    
    if not fixItemConditionEnabled() then return end
    if not isItemWithCondition(e.item) then return end
    if e.itemData == nil then return end
    
    local oldCondition = e.itemData.condition
    
    if e.itemData.condition > e.item.maxCondition then
        
        if not gameConfig.condition.fixItemHealthOverflow then return end
        e.itemData.condition = e.item.maxCondition
        
    elseif e.itemData.condition < e.item.maxCondition then
        
        if e.isPlayerInventory then return end -- never repair player-held items
        if not gameConfig.condition.repairDamagedItems then return end
        e.itemData.condition = e.item.maxCondition
        
    end
    
    if e.itemData.condition ~= oldCondition then
        
        local message =
            "Item ID: %s | Name: %s" ..
            " | Condition: %d/%d -> %d/%d"
        
        common.log(message,
            e.item.id, e.item.name,
            oldCondition, e.item.maxCondition,
            e.itemData.condition, e.item.maxCondition)
        
    end
    
end

return this
