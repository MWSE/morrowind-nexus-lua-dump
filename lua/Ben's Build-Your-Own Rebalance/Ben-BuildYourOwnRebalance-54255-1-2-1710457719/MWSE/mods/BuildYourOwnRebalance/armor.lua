local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local util = require("BuildYourOwnRebalance.util")
local gameConfig = config.getGameConfig()
local gameConfigUpdated = config.getGameConfigUpdated()

local unmodifiedArmors = {} -- id = statsTable
local weightClassSearchPatterns = {} -- searchPattern = L/M/H
local tierZeroSearchPatterns = {} -- searchPattern = tier
local tierSearchPatterns = {} -- searchPattern = tier

local weightClassFailureCount = 0
local tierFailureCount = 0

local function getBoundArmorTier()
    
    local tier = gameConfig.armor.boundItem.tier
    common.log("  Tier: %d | Bound Armor", tier)
    return tier
    
end

local function getTier(armor, unmodifiedArmor, isBoundItem, weightClass)
    
    if isBoundItem then return getBoundArmorTier() end
    
    local tier = common.getValueBySearchPattern(armor, tierSearchPatterns, "Tier", "%d")
    if tier ~= nil then return tier end
    
    local maxArmorRatings = gameConfig.armor.detectTier.maxArmorRating[weightClass]
    tier = common.getValueByStat(unmodifiedArmor.armorRating, maxArmorRatings, "Tier", "AR", "%d", "%d", 200)
    if tier ~= nil then return tier end
    
    common.log("  Tier: Failed")
    tierFailureCount = tierFailureCount + 1
    return nil
    
end

local function getExcludedArmorWeightClass(unmodifiedArmor)
    
    local searchValue = common.getArmorWeightClassSearchValue(unmodifiedArmor.weightClass)
    local weightClass = common.getArmorWeightClassSearchValueConfigKey(searchValue)
    
    common.log("  Weight Class: %s | Original", searchValue)
    return weightClass
    
end

local function getBoundArmorWeightClass()
    
    local searchValue = gameConfig.armor.boundItem.weightClass
    common.log("  Weight Class: %s | Bound Armor", searchValue)
    
    local weightClass = common.getArmorWeightClassSearchValueConfigKey(searchValue)
    if weightClass ~= nil then return weightClass end
    
    this.log("  Weight Class: Failed")
    weightClassFailureCount = weightClassFailureCount + 1
    return nil
    
end

local function getWeightClass(armor, unmodifiedArmor)
    
    if isBoundItem then return getBoundArmorWeightClass() end
    
    local searchValue = common.getValueBySearchPattern(
        armor, weightClassSearchPatterns, "Weight Class", "%s")
    
    if searchValue == nil then
        searchValue = common.getArmorWeightClassSearchValue(unmodifiedArmor.weightClass)
        common.log("  Weight Class: %s | Original", searchValue)
    end
    
    local weightClass = common.getArmorWeightClassSearchValueConfigKey(searchValue)
    if weightClass ~= nil then return weightClass end
    
    this.log("  Weight Class: Failed")
    weightClassFailureCount = weightClassFailureCount + 1
    return nil
    
end

local function getSlot(armor)
    
    local slot = common.getArmorSlotConfigKey(armor.slot)
    common.log("  Slot: %s", util.capitalizeFirstLetter(slot))
    return slot
    
end

local function rebalanceExcludedArmor(armor, unmodifiedArmor, slot, reason)
    
    common.log("  Excluded From Rebalance: %s", reason)
    
    local weightClass = getExcludedArmorWeightClass(unmodifiedArmor)
    if weightClass == nil then return end
    
    local weightMult =
        gameConfig.armor.slot.weight[slot] *
        gameConfig.armor.weightClass.weight[weightClass]
    
    local weightMin = weightMult * 1.50 -- tier min
    local weightMax = weightMult * 2.90 -- tier max
    
    if weightClass == "light" then weightMin = nil end
    if weightClass == "heavy" then weightMax = nil end
    
    local weight = unmodifiedArmor.weight
    weight = util.clamp(weight, weightMin, weightMax)
    weight = util.round(weight, 2)
    
    common.log("  AR: %d", armor.armorRating)
    common.log("  Weight: %.2f -> %.2f", armor.weight, weight)
    common.logEnchant(armor, nil)
    common.log("  Health: %d", armor.maxCondition)
    common.log("  Value: %d", armor.value)
    
    armor.weight = weight
    
end

local function rebalanceArmor(armor)
    
    local unmodifiedArmor = unmodifiedArmors[armor.id]
    if unmodifiedArmor == nil then return end
    
    common.log("Armor ID: %s | Name: %s", armor.id, armor.name)
    common.log("  Source Mod: %s", armor.sourceMod)
    
    local slot = getSlot(armor)
    if slot == nil then return end
    
    local isBoundItem = common.getIsBoundItem(armor)
    
    local weightClass = getWeightClass(armor, unmodifiedArmor, isBoundItem)
    if weightClass == nil then return end
    
    local tier = getTier(armor, unmodifiedArmor, isBoundItem, weightClass)
    if tier == nil then return end
    
    --------------------------------------------------
    
    if gameConfig.shared.excludedItemIds[armor.id] then
        rebalanceExcludedArmor(armor, unmodifiedArmor, slot, "In \"Excluded Items\" List")
        return
    end
    
    if tier == 0 then
        rebalanceExcludedArmor(armor, unmodifiedArmor, slot, "Tier Zero")
        return
    end
    
    common.log("  Included In Rebalance")
    
    --------------------------------------------------
    
    local armorRating =
        gameConfig.armor.weightClass.armorRating[weightClass] *
        gameConfig.armor.tier.armorRating[tier] *
        gameConfig.armor.baseArmorSkill / 100
    
    local weight =
        gameConfig.armor.slot.weight[slot] *
        gameConfig.armor.weightClass.weight[weightClass] *
        gameConfig.armor.tier.weight[tier]
    
    local enchant =
        gameConfig.armor.slot.enchant[slot] *
        gameConfig.armor.weightClass.enchant[weightClass] *
        gameConfig.armor.tier.enchant[tier]
    
    local health =
        gameConfig.armor.slot.health[slot] *
        gameConfig.armor.weightClass.health[weightClass] *
        gameConfig.armor.tier.health[tier]
    
    local value =
        gameConfig.armor.slot.value[slot] *
        gameConfig.armor.weightClass.value[weightClass] *
        gameConfig.armor.tier.value[tier]
    
    if armor.enchantment ~= nil then
        
        if gameConfig.armor.enchantedItem.recalculateValue
        then value = value * gameConfig.armor.enchantedItem.valueMult
        else value = unmodifiedArmor.value * gameConfig.armor.enchantedItem.valueScale end
        
    end
    
    --------------------------------------------------
    
    if isBoundItem then
        
        weight = 0.01
        enchant = 0
        value = 0
        
        if not gameConfig.armor.boundItem.scaleWithLightArmorSkill then
            
            armorRating = gameConfig.armor.boundItem.armorRating
            weight = 0 -- weightless items don't scale with any armor skill
            
        end
        
    end
    
    --------------------------------------------------
    
    armorRating = util.round(armorRating, 0)
    weight = util.round(weight, 2)
    enchant = util.round(enchant, 0) * 10
    health = util.round(health, 0)
    value = util.round(value, 0)
    
    --------------------------------------------------
    
    if armor.enchantment ~= nil then enchant = armor.enchantCapacity end
    
    if weight < 0.01 and not isBoundItem then weight = 0.01 end
    if health < 1 then health = 1 end
    if value < 1 then value = 1 end
    
    --------------------------------------------------
    
    common.log("  AR: %d -> %d", armor.armorRating, armorRating)
    common.log("  Weight: %.2f -> %.2f", armor.weight, weight)
    common.logEnchant(armor, enchant)
    common.log("  Health: %d -> %d", armor.maxCondition, health)
    common.log("  Value: %d -> %d", armor.value, value)
    
    --------------------------------------------------
    
    armor.armorRating = armorRating
    armor.weight = weight
    armor.enchantCapacity = enchant
    armor.maxCondition = health
    armor.value = value
    
end

local function cacheArmor(armor)
    
    if not common.shouldCacheObject(armor) then return end
    
    unmodifiedArmors[armor.id] = {
        armorRating = armor.armorRating,
        weightClass = armor.weightClass,
        weight = armor.weight,
        value = armor.value,
    }
    
end

local function onLoaded()
    
    if not gameConfigUpdated.armor then return end
    gameConfigUpdated.armor = false
    
    common.log("--------------------------------------------------")
    common.log("Armor GMSTs")
    common.log("--------------------------------------------------")
    
    common.setGmsts(gameConfig.armor.gameSettings)
    
    common.log("--------------------------------------------------")
    common.log("Armor Search Terms")
    common.log("--------------------------------------------------")
    
    local validWeightClasses = { L = true, M = true, H = true }
    
    weightClassSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.armor.detectWeightClass.searchTerms,
        validWeightClasses,
        "Weight Class",
        false,
        util.capitalizeFirstLetter)
    
    common.log("--------------------------------------------------")
    
    local validTiers = util.getSetFromRange(1, gameConfig.armor.tierCount)
    
    tierSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.armor.detectTier.searchTerms,
        validTiers,
        "Tier",
        true)
    
    util.deepMerge(tierSearchPatterns, tierZeroSearchPatterns)
    
    common.log("--------------------------------------------------")
    common.log("Armor Rebalance")
    common.log("--------------------------------------------------")
    
    weightClassFailureCount = 0
    tierFailureCount = 0
    
    for armor in common.sortedIterateObjects(tes3.objectType.armor) do
        rebalanceArmor(armor)
    end
    
    local sumFailureCount =
        weightClassFailureCount +
        tierFailureCount
    
    if sumFailureCount > 0 then
        
        common.log("--------------------------------------------------")
        common.log("Armor Rebalance Failures")
        common.log("--------------------------------------------------")
        
        common.log("Failed Weight Classes: %d", weightClassFailureCount)
        common.log("Failed Tiers: %d", tierFailureCount)
        
        common.toast("Failed to rebalance %d armor pieces.", sumFailureCount)
        
    end
    
end

local function onInitialized()
    
    if not gameConfig.shared.modEnabled then return end
    if not gameConfig.armor.rebalanceEnabled then return end
    
    event.register(tes3.event.loaded, onLoaded, { priority = config.eventPriority.loaded.armor })
    
    for armor in tes3.iterateObjects(tes3.objectType.armor) do
        cacheArmor(armor)
    end
    
    common.log("--------------------------------------------------")
    common.log("Armor Search Terms (Restart Required)")
    common.log("--------------------------------------------------")
    
    tierZeroSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.armor.detectTier.searchTerms,
        { [0] = true },
        "Tier Zero",
        true)
    
end

event.register(tes3.event.initialized, onInitialized, { priority = config.eventPriority.initialized.armor })
