local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local util = require("BuildYourOwnRebalance.util")
local gameConfig = config.getGameConfig()
local gameConfigUpdated = config.getGameConfigUpdated()

local unmodifiedClothings = {} -- id = statsTable
local tierZeroSearchPatterns = {} -- searchPattern = tier
local tierSearchPatterns = {} -- searchPattern = tier

local tierFailureCount = 0

local function getTier(clothing, unmodifiedClothing, slot)
    
    local maxEnchants = gameConfig.clothing.detectTier.maxEnchant[slot]
    
    local tier = common.getValueBySearchPattern(clothing, tierSearchPatterns, "Tier", "%d")
    if tier ~= nil then return tier end
    
    tier = common.getValueByStat(unmodifiedClothing.enchantCapacity * 0.1, maxEnchants, "Tier", "Enchant", "%d", "%d", 200)
    if tier ~= nil then return tier end
    
    common.log("  Tier: Failed")
    tierFailureCount = tierFailureCount + 1
    return nil
    
end

local function getSlot(clothing)
    
    local slot = common.getClothingSlotConfigKey(clothing.slot)
    common.log("  Slot: %s", util.capitalizeFirstLetter(slot))
    return slot
    
end

local function logExcludedFromRebalance(clothing, reason)
    
    common.log("  Excluded From Rebalance: %s", reason)
    
    common.log("  Weight: %.2f", clothing.weight)
    common.logEnchant(clothing, nil)
    common.log("  Value: %d", clothing.value)
    
end

local function rebalanceClothing(clothing)
    
    local unmodifiedClothing = unmodifiedClothings[clothing.id]
    if unmodifiedClothing == nil then return end
    
    common.log("Clothing ID: %s | Name: %s", clothing.id, clothing.name)
    common.log("  Source Mod: %s", clothing.sourceMod)
    
    local slot = getSlot(clothing)
    if slot == nil then return end
    
    local tier = getTier(clothing, unmodifiedClothing, slot)
    if tier == nil then return end
    
    --------------------------------------------------
    
    if gameConfig.shared.excludedItemIds[clothing.id] then
        logExcludedFromRebalance(clothing, "In \"Excluded Items\" List")
        return
    end
    
    if tier == 0 then
        logExcludedFromRebalance(clothing, "Tier Zero")
        return
    end
    
    if clothing.enchantment == nil
    and gameConfig.clothing.unenchantedItem.excludeHighValueItems
    and unmodifiedClothing.value > gameConfig.clothing.unenchantedItem.maxValue then
        
        logExcludedFromRebalance(clothing, "Over \"Max Value\"")
        return
        
    end
    
    common.log("  Included In Rebalance")
    
    --------------------------------------------------
    
    local weight =
        gameConfig.clothing.slot.weight[slot] *
        gameConfig.clothing.tier.weight[tier]
    
    local enchant =
        gameConfig.clothing.slot.enchant[slot] *
        gameConfig.clothing.tier.enchant[tier]
    
    local value =
        gameConfig.clothing.slot.value[slot] *
        gameConfig.clothing.tier.value[tier]
    
    if clothing.enchantment ~= nil then
        
        if gameConfig.clothing.enchantedItem.recalculateValue
        then value = value * gameConfig.clothing.enchantedItem.valueMult
        else value = unmodifiedClothing.value * gameConfig.clothing.enchantedItem.valueScale end
        
    end
    
    --------------------------------------------------
    
    weight = util.round(weight, 2)
    enchant = util.round(enchant, 0) * 10
    value = util.round(value, 0)
    
    --------------------------------------------------
    
    if clothing.enchantment ~= nil then enchant = clothing.enchantCapacity end
    
    if value < 1 then value = 1 end
    
    --------------------------------------------------
    
    common.log("  Weight: %.2f -> %.2f", clothing.weight, weight)
    common.logEnchant(clothing, enchant)
    common.log("  Value: %d -> %d", clothing.value, value)
    
    --------------------------------------------------
    
    clothing.weight = weight
    clothing.enchantCapacity = enchant
    clothing.value = value
    
end

local function cacheClothing(clothing)
    
    if not common.shouldCacheObject(clothing) then return end
    
    unmodifiedClothings[clothing.id] = {
        enchantCapacity = clothing.enchantCapacity,
        value = clothing.value,
    }
    
end

local function onLoaded()
    
    if not gameConfigUpdated.clothing then return end
    gameConfigUpdated.clothing = false
    
    common.log("--------------------------------------------------")
    common.log("Clothing Search Terms")
    common.log("--------------------------------------------------")
    
    local validTiers = util.getSetFromRange(1, gameConfig.clothing.tierCount)
    
    tierSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.clothing.detectTier.searchTerms,
        validTiers,
        "Tier",
        true)
    
    util.deepMerge(tierSearchPatterns, tierZeroSearchPatterns)
    
    common.log("--------------------------------------------------")
    common.log("Clothing Rebalance")
    common.log("--------------------------------------------------")
    
    tierFailureCount = 0
    
    for clothing in common.sortedIterateObjects(tes3.objectType.clothing) do
        rebalanceClothing(clothing)
    end
    
    local sumFailureCount =
        tierFailureCount
    
    if sumFailureCount > 0 then
        
        common.log("--------------------------------------------------")
        common.log("Clothing Rebalance Failures")
        common.log("--------------------------------------------------")
        
        common.log("Failed Tiers: %d", tierFailureCount)
        
        common.toast("Failed to rebalance %d clothing pieces.", sumFailureCount)
        
    end
    
end

local function onInitialized()
    
    if not gameConfig.shared.modEnabled then return end
    if not gameConfig.clothing.rebalanceEnabled then return end
    
    event.register(tes3.event.loaded, onLoaded, { priority = config.eventPriority.loaded.clothing })
    
    for clothing in tes3.iterateObjects(tes3.objectType.clothing) do
        cacheClothing(clothing)
    end
    
    common.log("--------------------------------------------------")
    common.log("Clothing Search Terms (Restart Required)")
    common.log("--------------------------------------------------")
    
    tierZeroSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.clothing.detectTier.searchTerms,
        { [0] = true },
        "Tier Zero",
        true)
    
end

event.register(tes3.event.initialized, onInitialized, { priority = config.eventPriority.initialized.clothing })
