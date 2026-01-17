---@class RealisticRepair.RepairCalculationService
--- Handles all calculation logic for repair, degradation, and enhancement amounts.
--- Pure calculation functions with no side effects.
local RepairCalculationService = {}

local config = require("mer.RealisticRepair.config")
local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---Get the player's current armorer skill level
---@return number armorerSkill
local function getArmorerSkill()
    return tes3.mobilePlayer:getSkillStatistic(tes3.skill.armorer).current
end

---Calculate degradation amount based on player skill
---At low skill: high degradation on failure
---At high skill: low degradation on failure
---@return number degradationAmount Amount of degradation (always positive)
function RepairCalculationService.calculateDegradationAmount()
    local armorerSkill = getArmorerSkill()

    local min = config.mcm.minDegradation
    local max = config.mcm.maxDegradation

    -- Remap skill from 0-100 to max-min (inverse relationship)
    local degradationAmount = math.remap(armorerSkill, 0, 100, max, min)
    degradationAmount = math.clamp(degradationAmount, min, max)
    degradationAmount = math.floor(degradationAmount)

    logger:debug("Calculated base degradation amount: %d (skill: %d)", degradationAmount, armorerSkill)

    return degradationAmount
end

---Calculate restoration amount for successful repairs at stations
---Restoration is set to 1/2 the repair amount
---@param repairAmount number The amount being repaired
---@return number restorationAmount Amount of degradation to remove (always positive)
function RepairCalculationService.calculateRestorationAmount(repairAmount)
    local armorerSkill = getArmorerSkill()

    -- Restoration is 1/2 the repair amount
    local restorationAmount = math.floor(repairAmount / 2)

    logger:debug("Calculated restoration amount: %d (1/2 of repair: %d, skill: %d)", restorationAmount, repairAmount, armorerSkill)

    return restorationAmount
end

---This function is no longer used - degradation on failure is not modified at stations
---Kept for potential future use
---@deprecated
---@param baseDegradation number Base degradation amount
---@param repairAmount number The amount being repaired
---@return number modifiedDegradation
function RepairCalculationService.applyStationModifier(baseDegradation, repairAmount)
    -- Stations no longer modify failure degradation
    -- Only success restoration is affected (see calculateRestorationAmount)
    return baseDegradation
end

---Calculate enhancement amount that can be applied
---Based on player skill and whether at a station
---@param atStation boolean? Whether player is at a station (defaults to false)
---@return number enhancementAmount Amount of enhancement to apply on success
function RepairCalculationService.calculateEnhancementAmount(atStation)
    local armorerSkill = getArmorerSkill()
    atStation = atStation or false

    -- Enhancement only possible at stations
    if not atStation then
        return 0
    end

    -- Calculate enhancement based on skill and config caps
    local minAmount = config.mcm.minEnhancement
    local maxAmount = config.mcm.maxEnhancement

    -- Higher skill = more enhancement per attempt
    -- At 0 skill: minAmount% of base condition
    -- At 100 skill: maxAmount% of base condition
    local enhancementAmount = math.remap(armorerSkill, 0, 100, minAmount, maxAmount)
    enhancementAmount = math.clamp(enhancementAmount, minAmount, maxAmount)
    logger:debug("Calculated enhancement amount: %d (skill: %d)", enhancementAmount, armorerSkill)
    return enhancementAmount
end

---Get the maximum enhancement cap for an item based on player skill
---Returns the percentage of base max condition that can be added as enhancement
---@param item tes3weapon|tes3armor
---@param armorerSkill number? Optional skill override (defaults to player's current skill)
---@return number maxEnhancement The maximum enhancement points allowed
function RepairCalculationService.getEnhancementCap(item, armorerSkill)
    armorerSkill = armorerSkill or getArmorerSkill()

    local minCap = config.mcm.minEnhancementCap
    local maxCap = config.mcm.maxEnhancementCap

    -- Calculate percentage based on skill
    local capPercent = math.remap(armorerSkill, 0, 100, minCap, maxCap)

    -- Convert percentage to actual points
    local maxEnhancement = math.floor(item.maxCondition * capPercent / 100)

    logger:debug("Enhancement cap for %s: %d points (%.1f%% of %d)",
        item.name, maxEnhancement, capPercent, item.maxCondition)

    return maxEnhancement
end

---Calculate how much enhancement can still be added to an item
---@param item tes3weapon|tes3armor
---@param currentEnhancement number Current enhancement level
---@param armorerSkill number? Optional skill override (defaults to player's current skill)
---@return number remainingCapacity How much more enhancement can be added
function RepairCalculationService.getRemainingEnhancementCapacity(item, currentEnhancement, armorerSkill)
    local maxCap = RepairCalculationService.getEnhancementCap(item, armorerSkill)
    return math.max(0, maxCap - currentEnhancement)
end

---Get the fraction of max condition lost to degradation (for UI display)
---@param item tes3weapon|tes3armor
---@param degradationLevel number
---@return number degradationFraction 0.0 to 1.0
function RepairCalculationService.getDegradationFraction(item, degradationLevel)
    if degradationLevel <= 0 then
        return 0
    end
    return math.min(1.0, degradationLevel / item.maxCondition)
end

---Get the fraction of max condition added as enhancement (for UI display)
---@param item tes3weapon|tes3armor
---@param enhancementLevel number
---@return number enhancementFraction 0.0 to 1.0
function RepairCalculationService.getEnhancementFraction(item, enhancementLevel)
    if enhancementLevel <= 0 then
        return 0
    end
    return math.min(1.0, enhancementLevel / item.maxCondition)
end

---Get the fraction of current condition relative to effective max (for UI display)
---@param item tes3weapon|tes3armor
---@param currentCondition number
---@param effectiveMaxCondition number
---@return number conditionFraction 0.0 to 1.0
function RepairCalculationService.getConditionFraction(item, currentCondition, effectiveMaxCondition)
    if effectiveMaxCondition <= 0 then
        return 0
    end
    return math.clamp(currentCondition / effectiveMaxCondition, 0, 1)
end

---Check if degradation should be applied based on repair result
---@param repairSucceeded boolean Whether the repair attempt succeeded
---@param degradationAmount number The calculated degradation amount
---@return boolean shouldApply
function RepairCalculationService.shouldApplyDegradation(repairSucceeded, degradationAmount)
    -- Apply degradation on failure if amount is positive
    if not repairSucceeded and degradationAmount > 0 then
        return true
    end

    -- Apply restoration (negative degradation) on success if amount is negative
    if repairSucceeded and degradationAmount < 0 then
        return true
    end

    return false
end

---Calculate the actual repair amount to apply, clamped to max repair condition
---@param item tes3weapon|tes3armor
---@param requestedRepairAmount number The amount the player wants to repair
---@param currentCondition number Current item condition
---@param maxRepairCondition number Maximum condition achievable through repair
---@return number actualRepairAmount The clamped repair amount
function RepairCalculationService.calculateActualRepairAmount(item, requestedRepairAmount, currentCondition, maxRepairCondition)
    local maxPossibleRepair = maxRepairCondition - currentCondition
    local actualAmount = math.min(requestedRepairAmount, maxPossibleRepair)
    actualAmount = math.max(0, actualAmount)

    logger:debug("Repair amount for %s: requested %d, max possible %d, actual %d",
        item.name, requestedRepairAmount, maxPossibleRepair, actualAmount)

    return actualAmount
end

return RepairCalculationService
