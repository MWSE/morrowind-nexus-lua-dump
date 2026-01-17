---@class RealisticRepair.ItemConditionService
--- Manages item condition data including degradation and enhancement levels.
--- Enforces mutual exclusivity: items cannot have both degradation and enhancement.
local ItemConditionService = {}

local config = require("mer.RealisticRepair.config")
local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---Initialize itemData if needed
---@param item tes3weapon|tes3armor|tes3repairTool
---@param itemData tes3itemData?
---@return tes3itemData
function ItemConditionService.ensureItemData(item, itemData)
    if not itemData then
        itemData = tes3.addItemData{
            to = tes3.player,
            item = item,
        }
        if not itemData then
            error("Failed to create itemData for item: " .. item.name)
        end
    end
    itemData.data = itemData.data or {}
    return itemData
end

---Get the degradation level of an item
---@param itemData tes3itemData?
---@return number degradationLevel Amount of max condition lost (0 if none)
function ItemConditionService.getDegradationLevel(itemData)
    if not itemData or not itemData.data then
        return 0
    end
    return itemData.data.degradationLevel or 0
end

---Get the enhancement level of an item
---Enhancement is represented by condition being above maxCondition
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return number enhancementLevel Amount of condition above base max (0 if none)
function ItemConditionService.getEnhancementLevel(item, itemData)
    if not itemData then
        return 0
    end
    local currentCondition = itemData.condition or item.maxCondition
    local baseMax = item.maxCondition
    local degradation = ItemConditionService.getDegradationLevel(itemData)
    local maxRepairCondition = baseMax - degradation

    -- Enhancement is anything above the max repairable condition
    return math.max(0, currentCondition - maxRepairCondition)
end

---Check if item has any degradation
---@param itemData tes3itemData?
---@return boolean
function ItemConditionService.hasDegradation(itemData)
    return ItemConditionService.getDegradationLevel(itemData) > 0
end

---Check if item has any enhancement
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return boolean
function ItemConditionService.hasEnhancement(item, itemData)
    return ItemConditionService.getEnhancementLevel(item, itemData) > 0
end

---Get the effective max condition for an item
---Since enhancement is now stored in condition itself, this just returns current condition
---if enhanced, otherwise returns max repairable condition
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return number effectiveMaxCondition
function ItemConditionService.getEffectiveMaxCondition(item, itemData)
    if not itemData then
        return item.maxCondition
    end

    local currentCondition = itemData.condition
    local maxRepairCondition = ItemConditionService.getMaxRepairCondition(item, itemData)

    -- If condition is above max repairable (enhanced), return current condition
    -- Otherwise return max repairable condition
    return math.max(maxRepairCondition, currentCondition)
end

---Get the max condition achievable through repair (excludes enhancement)
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return number maxRepairCondition
function ItemConditionService.getMaxRepairCondition(item, itemData)
    local baseMax = item.maxCondition
    local degradation = ItemConditionService.getDegradationLevel(itemData)

    -- Repair can restore up to: base - degradation
    -- Enhancement is added separately, not through repair
    return math.max(1, baseMax - degradation)
end

---Set degradation level on an item
---Automatically clears enhancement (mutual exclusivity) by capping condition
---Also caps current condition if it would exceed the new max repairable condition
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@param degradationAmount number
---@return tes3itemData itemData The modified itemData
function ItemConditionService.setDegradation(item, itemData, degradationAmount)
    logger:debug("Setting degradation to %d for item %s", degradationAmount, item.name)
    itemData = ItemConditionService.ensureItemData(item, itemData)

    -- Clamp to valid range [0, maxCondition]
    -- Lower bound: can't go negative
    -- Upper bound: degradation can't exceed maxCondition
    degradationAmount = math.clamp(degradationAmount, 0, item.maxCondition)

    -- Clear enhancement (mutual exclusivity) by capping condition to maxRepairCondition
    if ItemConditionService.hasEnhancement(item, itemData) then
        logger:debug("Clearing enhancement before applying degradation")
        -- Enhancement is removed by capping condition
    end

    -- Set degradation
    if degradationAmount > 0 then
        itemData.data.degradationLevel = degradationAmount
        logger:debug("Set degradation to %d for %s", degradationAmount, item.name)
    else
        itemData.data.degradationLevel = nil
        logger:debug("Cleared degradation for %s", item.name)
    end

    -- Cap current condition if it exceeds the new max repairable condition
    local maxRepairCondition = item.maxCondition - degradationAmount
    if itemData.condition > maxRepairCondition then
        local oldCondition = itemData.condition
        itemData.condition = maxRepairCondition
        logger:debug("Capped condition from %d to %d due to degradation", oldCondition, itemData.condition)
    end

    return itemData
end

---Adjust degradation level by a delta amount
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@param deltaAmount number Amount to add (positive) or remove (negative)
---@return tes3itemData itemData The modified itemData
function ItemConditionService.adjustDegradation(item, itemData, deltaAmount)
    local currentDegradation = ItemConditionService.getDegradationLevel(itemData)
    local newDegradation = currentDegradation + deltaAmount
    return ItemConditionService.setDegradation(item, itemData, newDegradation)
end

---Clear all degradation from an item
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return tes3itemData itemData The modified itemData
function ItemConditionService.clearDegradation(item, itemData)
    return ItemConditionService.setDegradation(item, itemData, 0)
end

---Set enhancement level on an item by directly increasing condition above maxCondition
---Automatically clears degradation (mutual exclusivity)
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@param enhancementAmount number Target enhancement amount (condition above maxRepairCondition)
---@return tes3itemData itemData The modified itemData
function ItemConditionService.setEnhancement(item, itemData, enhancementAmount)
    itemData = ItemConditionService.ensureItemData(item, itemData)

    -- Enhancement cannot exceed base max condition
    enhancementAmount = math.clamp(enhancementAmount, 0, item.maxCondition)

    -- Clear degradation (mutual exclusivity)
    if ItemConditionService.hasDegradation(itemData) then
        logger:debug("Clearing degradation before applying enhancement")
        itemData.data.degradationLevel = nil
    end

    -- Set condition to maxCondition + enhancement
    local newCondition = item.maxCondition + enhancementAmount
    itemData.condition = newCondition

    logger:debug("Set enhancement to %d for %s (condition: %d)", enhancementAmount, item.name, newCondition)

    return itemData
end

---Adjust enhancement level by a delta amount (modifies condition directly)
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@param deltaAmount number Amount to add (positive) or remove (negative)
---@return tes3itemData itemData The modified itemData
function ItemConditionService.adjustEnhancement(item, itemData, deltaAmount)
    itemData = ItemConditionService.ensureItemData(item, itemData)

    local currentEnhancement = ItemConditionService.getEnhancementLevel(item, itemData)
    local newEnhancement = currentEnhancement + deltaAmount
    local maxRepairCondition = ItemConditionService.getMaxRepairCondition(item, itemData)

    -- Calculate new condition (maxRepairCondition + new enhancement)
    local newCondition = maxRepairCondition + math.max(0, newEnhancement)
    itemData.condition = newCondition

    logger:debug("Adjusted enhancement by %d for %s (condition: %d)", deltaAmount, item.name, newCondition)

    return itemData
end

---Clear all enhancement from an item by setting condition to maxRepairCondition
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return tes3itemData itemData The modified itemData
function ItemConditionService.clearEnhancement(item, itemData)
    if not itemData then
        return itemData
    end

    local maxRepairCondition = ItemConditionService.getMaxRepairCondition(item, itemData)
    itemData.condition = maxRepairCondition

    logger:debug("Cleared enhancement for %s (condition: %d)", item.name, maxRepairCondition)

    return itemData
end

---Check if an item is at its maximum repairable condition
---(condition equals maxRepairCondition, ignoring enhancement)
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return boolean
function ItemConditionService.isAtMaxRepairCondition(item, itemData)
    local currentCondition = itemData and itemData.condition or item.maxCondition
    local maxRepairCondition = ItemConditionService.getMaxRepairCondition(item, itemData)
    return currentCondition >= maxRepairCondition
end

---Check if an item is fully repaired (no damage, but may have degradation)
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return boolean
function ItemConditionService.isFullyRepaired(item, itemData)
    local currentCondition = itemData and itemData.condition or item.maxCondition
    local maxRepairCondition = ItemConditionService.getMaxRepairCondition(item, itemData)
    return currentCondition >= maxRepairCondition
end



---Check if an item can be repaired
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return boolean canRepair
function ItemConditionService.canBeRepaired(item, itemData)
    local currentCondition = itemData and itemData.condition or item.maxCondition
    local maxRepairCondition = ItemConditionService.getMaxRepairCondition(item, itemData)
    return currentCondition < maxRepairCondition
end

return ItemConditionService
