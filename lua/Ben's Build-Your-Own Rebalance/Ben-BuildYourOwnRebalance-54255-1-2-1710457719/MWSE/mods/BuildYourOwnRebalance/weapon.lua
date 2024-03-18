local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local util = require("BuildYourOwnRebalance.util")
local gameConfig = config.getGameConfig()
local gameConfigUpdated = config.getGameConfigUpdated()

local unmodifiedWeapons = {} -- id = statsTable
local weaponTypeSingleSubtype = {} -- weaponType = subtype
local weaponTypeSearchPatterns = {} -- weaponType = { searchPattern = subtype }
local weaponTypeMaxSpeeds = {} -- weaponType = { subtype = maxSpeed }
local weaponTypeMaxReaches = {} -- weaponType = { subtype = maxReach }
local weaponTypeMaxDamages = {} -- weaponType = { subtype = maxDamage = {} }
local weightClassSearchPatterns = {} -- searchPattern = L/M/H
local tierZeroSearchPatterns = {} -- searchPattern = tier
local tierSearchPatterns = {} -- searchPattern = tier

local subtypeFailureCount = 0
local weightClassFailureCount = 0
local tierFailureCount = 0

local function getIgnoresNormalWeaponResistance(weapon, tier, isSilver)
    
    if tier >= gameConfig.weapon.ignoresNormalWeaponResistance.minTier then return true end
    if gameConfig.weapon.ignoresNormalWeaponResistance.includeSilver and isSilver then return true end
    if gameConfig.weapon.ignoresNormalWeaponResistance.includeEnchanted and weapon.enchantment then return true end
    
    return false
    
end

local function getIsSilver(weapon)
    
    if weapon.isSilver then return true end
    if not gameConfig.weapon.fixIsSilverFlag then return false end
    
    local isSilver = common.getValueBySearchPattern(weapon, gameConfig.weapon.isSilverSearchPatterns, nil, nil)
    if isSilver ~= nil then return isSilver end
    
    return false
    
end

local function getBoundWeaponTier()
    
    local tier = gameConfig.weapon.boundItem.tier
    common.log("  Tier: %d | Bound Weapon", tier)
    return tier
    
end

local function getTier(weapon, unmodifiedWeapon, subtype, isBoundItem)
    
    if isBoundItem then return getBoundWeaponTier() end
    
    local tier = common.getValueBySearchPattern(weapon, tierSearchPatterns, "Tier", "%d")
    if tier ~= nil then return tier end
    
    local maxDamages = weaponTypeMaxDamages[weapon.type][subtype]
    tier = common.getValueByStat(unmodifiedWeapon.damage, maxDamages, "Tier", "Damage", "%d", "%d", 200)
    if tier ~= nil then return tier end
    
    common.log("  Tier: Failed")
    tierFailureCount = tierFailureCount + 1
    return nil
    
end

local function getBoundWeaponWeightClass()
    
    local searchValue = gameConfig.weapon.boundItem.weightClass
    common.log("  Weight Class: %s | Bound Weapon", searchValue)
    
    local weightClass = common.getWeaponWeightClassSearchValueConfigKey(searchValue)
    if weightClass ~= nil then return weightClass end
    
    this.log("  Weight Class: Failed")
    weightClassFailureCount = weightClassFailureCount + 1
    return nil
    
end

local function getWeightClass(weapon, isBoundItem)
    
    if isBoundItem then return getBoundWeaponWeightClass() end
    
    local searchValue = common.getValueBySearchPattern(
        weapon, weightClassSearchPatterns, "Weight Class", "%s")
    
    if searchValue == nil then
        searchValue = gameConfig.weapon.defaultWeightClass
        common.log("  Weight Class: %s | Default", searchValue)
    end
    
    local weightClass = common.getWeaponWeightClassSearchValueConfigKey(searchValue)
    if weightClass ~= nil then return weightClass end
    
    this.log("  Weight Class: Failed")
    weightClassFailureCount = weightClassFailureCount + 1
    return nil
    
end

local function getSubtype(weapon, unmodifiedWeapon)
    
    local subtype = weaponTypeSingleSubtype[weapon.type]
    if subtype ~= nil then common.log("  Subtype: %d | Only Subtype", subtype) return subtype end
    
    local subtypeSearchPatterns = weaponTypeSearchPatterns[weapon.type]
    subtype = common.getValueBySearchPattern(weapon, subtypeSearchPatterns, "Subtype", "%d")
    if subtype ~= nil then return subtype end
    
    local maxSpeeds = weaponTypeMaxSpeeds[weapon.type]
    subtype = common.getValueByStat(unmodifiedWeapon.speed, maxSpeeds, "Subtype", "Speed", "%d", "%.2f", 5)
    if subtype ~= nil then return subtype end
    
    local maxReaches = weaponTypeMaxReaches[weapon.type]
    subtype = common.getValueByStat(unmodifiedWeapon.reach, maxReaches, "Subtype", "Reach", "%d", "%.2f", 5)
    if subtype ~= nil then return subtype end
    
    common.log("  Subtype: Failed")
    subtypeFailureCount = subtypeFailureCount + 1
    return nil
    
end

local function logExcludedFromRebalance(weapon, reason)
    
    common.log("  Excluded From Rebalance: %s", reason)
    
    common.log("  Chop: %d-%d", weapon.chopMin, weapon.chopMax)
    common.log("  Slash: %d-%d", weapon.slashMin, weapon.slashMax)
    common.log("  Thrust: %d-%d", weapon.thrustMin, weapon.thrustMax)
    
    common.log("  Speed: %.2f", weapon.speed)
    common.log("  Reach: %.2f", weapon.reach)
    common.log("  Weight: %.2f", weapon.weight)
    common.logEnchant(weapon, nil)
    common.log("  Health: %d", weapon.maxCondition)
    common.log("  Value: %d", weapon.value)
    
    common.log("  Silver Weapon: %s", tostring(weapon.isSilver))
    common.log("  Ignores Normal Weapon Resistance: %s", tostring(weapon.ignoresNormalWeaponResistance))
    
end

local function rebalanceWeapon(weapon)
    
    local unmodifiedWeapon = unmodifiedWeapons[weapon.id]
    if unmodifiedWeapon == nil then return end
    
    common.log("Weapon ID: %s | Name: %s", weapon.id, weapon.name)
    common.log("  Source Mod: %s", weapon.sourceMod)
    
    local weaponType = common.getWeaponTypeConfigKey(weapon.type)
    local weaponTypeDisplayName = common.getWeaponTypeConfigKeyDisplayName(weaponType)
    
    common.log("  Type: %s", weaponTypeDisplayName)
    
    local subtype = getSubtype(weapon, unmodifiedWeapon)
    if subtype == nil then return end
    
    local isBoundItem = common.getIsBoundItem(weapon)
    
    local weightClass = getWeightClass(weapon, isBoundItem)
    if weightClass == nil then return end
    
    local tier = getTier(weapon, unmodifiedWeapon, subtype, isBoundItem)
    if tier == nil then return end
    
    --------------------------------------------------
    
    if gameConfig.shared.excludedItemIds[weapon.id] then
        logExcludedFromRebalance(weapon, "In \"Excluded Items\" List")
        return
    end
    
    if tier == 0 then
        logExcludedFromRebalance(weapon, "Tier Zero")
        return
    end
    
    common.log("  Included In Rebalance")
    
    --------------------------------------------------
    
    local subtypeTable = gameConfig.weapon.subtype[weaponType][subtype]
    
    local damage =
        subtypeTable.damage *
        gameConfig.weapon.weightClass.damage[weightClass] *
        gameConfig.weapon.tier.damage[tier]
    
    local weight =
        subtypeTable.weight *
        gameConfig.weapon.weightClass.weight[weightClass] *
        gameConfig.weapon.tier.weight[tier]
    
    local enchant =
        subtypeTable.enchant *
        gameConfig.weapon.weightClass.enchant[weightClass] *
        gameConfig.weapon.tier.enchant[tier]
    
    local health =
        subtypeTable.health *
        gameConfig.weapon.weightClass.health[weightClass] *
        gameConfig.weapon.tier.health[tier]
    
    local value =
        subtypeTable.value *
        gameConfig.weapon.weightClass.value[weightClass] *
        gameConfig.weapon.tier.value[tier]
    
    if weapon.enchantment ~= nil then
        
        if gameConfig.weapon.enchantedItem.recalculateValue
        then value = value * gameConfig.weapon.enchantedItem.valueMult
        else value = unmodifiedWeapon.value * gameConfig.weapon.enchantedItem.valueScale end
        
    end
    
    local chopMax = damage * subtypeTable.chop
    local slashMax = damage * subtypeTable.slash
    local thrustMax = damage * subtypeTable.thrust
    
    local chopMin = chopMax * subtypeTable.minDamage
    local slashMin = slashMax * subtypeTable.minDamage
    local thrustMin = thrustMax * subtypeTable.minDamage
    
    local speed = subtypeTable.speed
    local reach = subtypeTable.reach
    
    local isSilver = getIsSilver(weapon)
    local ignoresNormalWeaponResistance = getIgnoresNormalWeaponResistance(weapon, tier, isSilver)
    
    --------------------------------------------------
    
    if isBoundItem then
        
        weight = 0
        enchant = 0
        value = 0
        
    end
    
    --------------------------------------------------
    
    chopMax = util.round(chopMax, 0)
    slashMax = util.round(slashMax, 0)
    thrustMax = util.round(thrustMax, 0)
    
    chopMin = util.round(chopMin, 0)
    slashMin = util.round(slashMin, 0)
    thrustMin = util.round(thrustMin, 0)
    
    speed = util.round(speed, 2)
    reach = util.round(reach, 2)
    weight = util.round(weight, 2)
    enchant = util.round(enchant, 0) * 10
    health = util.round(health, 0)
    value = util.round(value, 0)
    
    --------------------------------------------------
    
    if weapon.enchantment ~= nil then enchant = weapon.enchantCapacity end
    
    if chopMax < 1 then chopMax = 1 end
    if slashMax < 1 then slashMax = 1 end
    if thrustMax < 1 then thrustMax = 1 end
    
    if chopMin < 1 then chopMin = 1 end
    if slashMin < 1 then slashMin = 1 end
    if thrustMin < 1 then thrustMin = 1 end
    
    if health < 1 then health = 1 end
    if value < 1 then value = 1 end
    
    --------------------------------------------------
    
    if subtypeTable.bestAttack == "chop" then
        
        if slashMax == chopMax then
            if slashMin > 1 then slashMin = slashMin - 1
            elseif slashMax > 1 then slashMax = slashMax - 1 end
        end
        
        if thrustMax == chopMax then
            if thrustMin > 1 then thrustMin = thrustMin - 1
            elseif thrustMax > 1 then thrustMax = thrustMax - 1 end
        end
        
    elseif subtypeTable.bestAttack == "slash" then
        
        if chopMax == slashMax then
            if chopMin > 1 then chopMin = chopMin - 1
            elseif chopMax > 1 then chopMax = chopMax - 1 end
        end
        
        if thrustMax == slashMax then
            if thrustMin > 1 then thrustMin = thrustMin - 1
            elseif thrustMax > 1 then thrustMax = thrustMax - 1 end
        end
        
    elseif subtypeTable.bestAttack == "thrust" then
        
        if chopMax == thrustMax then
            if chopMin > 1 then chopMin = chopMin - 1
            elseif chopMax > 1 then chopMax = chopMax - 1 end
        end
        
        if slashMax == thrustMax then
            if slashMin > 1 then slashMin = slashMin - 1
            elseif slashMax > 1 then slashMax = slashMax - 1 end
        end
        
    end
    
    --------------------------------------------------
    
    common.log("  Chop: %d-%d -> %d-%d", weapon.chopMin, weapon.chopMax, chopMin, chopMax)
    common.log("  Slash: %d-%d -> %d-%d", weapon.slashMin, weapon.slashMax, slashMin, slashMax)
    common.log("  Thrust: %d-%d -> %d-%d", weapon.thrustMin, weapon.thrustMax, thrustMin, thrustMax)
    
    common.log("  Speed: %.2f -> %.2f", weapon.speed, speed)
    common.log("  Reach: %.2f -> %.2f", weapon.reach, reach)
    common.log("  Weight: %.2f -> %.2f", weapon.weight, weight)
    common.logEnchant(weapon, enchant)
    common.log("  Health: %d -> %d", weapon.maxCondition, health)
    common.log("  Value: %d -> %d", weapon.value, value)
    
    common.log("  Silver Weapon: %s -> %s",
        tostring(weapon.isSilver),
        tostring(isSilver))
    
    common.log("  Ignores Normal Weapon Resistance: %s -> %s",
        tostring(weapon.ignoresNormalWeaponResistance),
        tostring(ignoresNormalWeaponResistance))
    
    --------------------------------------------------
    
    weapon.chopMax = chopMax
    weapon.slashMax = slashMax
    weapon.thrustMax = thrustMax
    
    weapon.chopMin = chopMin
    weapon.slashMin = slashMin
    weapon.thrustMin = thrustMin
    
    weapon.speed = speed
    weapon.reach = reach
    weapon.weight = weight
    weapon.enchantCapacity = enchant
    weapon.maxCondition = health
    weapon.value = value
    
    weapon.ignoresNormalWeaponResistance = ignoresNormalWeaponResistance
    
end

local function cacheWeapon(weapon)
    
    if not common.shouldCacheObject(weapon) then return end
    
    local damage = util.getHighestValue({
        weapon.chopMax,
        weapon.slashMax,
        weapon.thrustMax
    })
    
    unmodifiedWeapons[weapon.id] = {
        damage = damage,
        speed = weapon.speed,
        reach = weapon.reach,
        value = weapon.value,
    }
    
end

local function onDamage(e)
    
    -- This overrides the vanilla functionality that causes enchanted weapons
    -- to bypass the "Resist Normal Weapons" magic effect. This only prevents
    -- the weapon damage. "on Touch" and "on Target" enchantment effects
    -- affect the target normally.
    
    if e.source ~= tes3.damageSource.attack then return end
    if gameConfig.weapon.ignoresNormalWeaponResistance.includeEnchanted then return end
    
    local weapon = nil
    
    if e.projectile ~= nil then
        weapon = e.projectile.firingWeapon
    elseif e.attacker ~= nil and e.attacker.readiedWeapon ~= nil then
        weapon = e.attacker.readiedWeapon.object
    end
    
    if weapon == nil then return end
    if weapon.enchantment == nil then return end
    if weapon.ignoresNormalWeaponResistance then return end
    
    if e.mobile.resistNormalWeapons >= 100 then
        
        tes3.messageBox(tes3.findGMST(tes3.gmst.sMagicTargetResistsWeapons).value)
        e.block = true -- prevent the damage completely
        return
        
    end
    
    e.damage = e.damage * (100 - e.mobile.resistNormalWeapons) / 100
    
end

local function onLoaded()
    
    if not gameConfigUpdated.weapon then return end
    gameConfigUpdated.weapon = false
    
    common.log("--------------------------------------------------")
    common.log("Weapon Search Terms")
    common.log("--------------------------------------------------")
    
    for weaponTypeConfigKey, subtypes in util.sortedPairs(gameConfig.weapon.subtype, common.sortFunction_ByWeaponTypeConfigKey) do
        
        weaponType = common.getConfigKeyWeaponType(weaponTypeConfigKey)
        
        weaponTypeSearchPatterns[weaponType] = {}
        weaponTypeMaxSpeeds[weaponType] = {}
        weaponTypeMaxReaches[weaponType] = {}
        weaponTypeMaxDamages[weaponType] = {}
        
        local onlySubtype = util.getFirstKeyIfOnlyOneElement(subtypes)
        if onlySubtype ~= nil then weaponTypeSingleSubtype[weaponType] = onlySubtype end
        
        for subtype, subtypeTable in util.sortedPairs(subtypes) do
            
            local searchPatterns = common.getSearchPatterns_SingleLine(
                subtypeTable.searchTerms,
                subtype,
                subtypeTable.displayName,
                true)
            
            for searchPattern, subtype in pairs(searchPatterns) do
                weaponTypeSearchPatterns[weaponType][searchPattern] = subtype
            end
            
            weaponTypeMaxSpeeds[weaponType][subtype] = subtypeTable.maxSpeed
            weaponTypeMaxReaches[weaponType][subtype] = subtypeTable.maxReach
            
            weaponTypeMaxDamages[weaponType][subtype] = util.deepCopy(subtypeTable.maxDamage)
            weaponTypeMaxDamages[weaponType][subtype][0] = subtypeTable.maxDamageTierZero
            
        end
        
        common.log("--------------------------------------------------")
        
    end
    
    local validWeightClasses = { L = true, M = true, H = true }
    
    weightClassSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.weapon.detectWeightClass.searchTerms,
        validWeightClasses,
        "Weight Class",
        false,
        util.capitalizeFirstLetter)
    
    common.log("--------------------------------------------------")
    
    local validTiers = util.getSetFromRange(1, gameConfig.weapon.tierCount)
    
    tierSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.weapon.detectTier.searchTerms,
        validTiers,
        "Tier",
        true)
    
    util.deepMerge(tierSearchPatterns, tierZeroSearchPatterns)
    
    common.log("--------------------------------------------------")
    common.log("Weapon Rebalance")
    common.log("--------------------------------------------------")
    
    subtypeFailureCount = 0
    weightClassFailureCount = 0
    tierFailureCount = 0
    
    for weapon in common.sortedIterateObjects({ tes3.objectType.weapon, tes3.objectType.ammunition }) do
        rebalanceWeapon(weapon)
    end
    
    local sumFailureCount =
        subtypeFailureCount +
        weightClassFailureCount +
        tierFailureCount
    
    if sumFailureCount > 0 then
        
        common.log("--------------------------------------------------")
        common.log("Weapon Rebalance Failures")
        common.log("--------------------------------------------------")
        
        common.log("Failed Subtypes: %d", subtypeFailureCount)
        common.log("Failed Weight Classes: %d", weightClassFailureCount)
        common.log("Failed Tiers: %d", tierFailureCount)
        
        common.toast("Failed to rebalance %d weapons.", sumFailureCount)
        
    end
    
end

local function onInitialized()
    
    if not gameConfig.shared.modEnabled then return end
    if not gameConfig.weapon.rebalanceEnabled then return end
    
    event.register(tes3.event.loaded, onLoaded, { priority = config.eventPriority.loaded.weapon })
    event.register(tes3.event.damage, onDamage, { priority = config.eventPriority.damage.weapon })
    
    for weapon in tes3.iterateObjects({ tes3.objectType.weapon, tes3.objectType.ammunition }) do
        cacheWeapon(weapon)
    end
    
    common.log("--------------------------------------------------")
    common.log("Weapon Search Terms (Restart Required)")
    common.log("--------------------------------------------------")
    
    tierZeroSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.weapon.detectTier.searchTerms,
        { [0] = true },
        "Tier Zero",
        true)
    
end

event.register(tes3.event.initialized, onInitialized, { priority = config.eventPriority.initialized.weapon })
