local config = require("Ben-MagicRebalance.config")
local common = require("Ben-MagicRebalance.common")
local util = require("Ben-MagicRebalance.util")
local gameConfig = config.getGameConfig()
local gameConfigUpdated = config.getGameConfigUpdated()

local fEffectCostMult = nil -- GMST pulled in onLoaded
local tierSearchPatterns = {} -- searchPattern = tier

local function getPotionName(effect, tier)

    if gameConfig.alchemy.standardizeNames == false then return nil end

    local magicEffect = tes3.getMagicEffect(effect)
    local prefix = gameConfig.alchemy.tier.prefix[tier]
    local suffix = gameConfig.alchemy.tier.suffix[tier]

    local name = common.getEffectName(effect)
    if string.len(prefix) > 0 then name = prefix .. name end
    if string.len(suffix) > 0 then name = name .. suffix end
    if string.len(name) > 31 then name = string.sub(name, 1, 31) end

    return name

end

local function getEffectDurMag(effectId, effectConfig, tier)

    local magicEffect = tes3.getMagicEffect(effectId)

    if magicEffect.hasNoMagnitude
    and magicEffect.hasNoDuration then
        return {1, 1}
    end

    --------------------------------------------------

    local magickaCost = gameConfig.alchemy.tier.other_magickaCost[tier]
    local duration = gameConfig.alchemy.tier.other_duration[tier]

    if effectId == tes3.effect.restoreFatigue
    or effectId == tes3.effect.restoreHealth
    or effectId == tes3.effect.restoreMagicka
    or effectId == tes3.effect.restoreAttribute
    or effectId == tes3.effect.restoreSkill then

        magickaCost = gameConfig.alchemy.tier.restore_magickaCost[tier]
        duration = gameConfig.alchemy.tier.restore_duration[tier]

    end

    if magicEffect.hasNoDuration
    or effectId == tes3.effect.restoreAttribute
    or effectId == tes3.effect.restoreSkill
    or effectId == tes3.effect.poison
    or effectId == tes3.effect.fireDamage
    or effectId == tes3.effect.frostDamage
    or effectId == tes3.effect.shockDamage
    or effectId == tes3.effect.damageFatigue
    or effectId == tes3.effect.damageHealth
    or effectId == tes3.effect.damageMagicka
    or effectId == tes3.effect.damageAttribute
    or effectId == tes3.effect.damageSkill then

        duration = 1

    end

    duration = util.clamp(duration, nil, effectConfig.maxDuration)

    --------------------------------------------------

    local uncappedMagnitude = 10 * magickaCost / magicEffect.baseMagickaCost / duration / fEffectCostMult
    local magnitude = util.clamp(uncappedMagnitude, nil, effectConfig.recMaxMagnitude)
    duration = duration * (uncappedMagnitude / magnitude)

    if magicEffect.hasNoMagnitude then
        duration = duration * magnitude
        magnitude = 1
    elseif magicEffect.hasNoDuration then
        magnitude = magnitude * duration
        duration = 1
    end

    magnitude = util.clamp(magnitude, nil, effectConfig.recMaxMagnitude)
    duration = util.clamp(duration, nil, effectConfig.maxDuration)

    --------------------------------------------------

    -- avoid floating point rounding errors
    magnitude = util.round(magnitude, 2)
    duration = util.round(duration, 2)

    magnitude = math.floor(magnitude)
    duration = math.floor(duration)

    --------------------------------------------------

    return {duration, magnitude}

end

local function getTier(alchemy)

    local tier = common.getValueBySearchPattern(alchemy, tierSearchPatterns, "Tier", "%d")
    if tier ~= nil then return tier end

    return nil

end

local function logExcludedFromRebalance(alchemy, reason)

    common.log("  Excluded From Rebalance: %s", reason)

    common.logEffects(alchemy)

    common.log("  Weight: %.2f", alchemy.weight)
    common.log("  Value: %d", alchemy.value)

end

local function rebalanceAlchemy(alchemy)

    -- https://mwse.github.io/MWSE/types/tes3alchemy/

    common.log("Potion ID: %s | Name: %s", alchemy.id, alchemy.name)
    common.log("  Source Mod: %s", alchemy.sourceMod or "nil")

    --------------------------------------------------

    if alchemy:getActiveEffectCount() ~= 1 then
        logExcludedFromRebalance(alchemy, "Multiple Effects or No Effects")
        return
    end

    local effect = common.getFirstEffect(alchemy)

    if gameConfig.shared.excludedEffectIds[effect.id] then
        logExcludedFromRebalance(alchemy, "In \"Excluded Effects\" List")
        return
    end

    local effectConfig = common.getEffectConfig(effect.id)

    if effectConfig.baseMagickaCost == 0 then
        logExcludedFromRebalance(alchemy, "Base Magicka Cost is Zero")
        return
    end

    local tier = getTier(alchemy)

    if tier == 0 then
        logExcludedFromRebalance(alchemy, "Tier Zero")
        return
    end

    if tier == nil then
        logExcludedFromRebalance(alchemy, "Unknown Tier")
        return
    end

    common.log("  Included In Rebalance")

    --------------------------------------------------

    local durMag = getEffectDurMag(effect.id, effectConfig, tier)
    local duration, magnitude = table.unpack(durMag)

    local name = getPotionName(effect, tier)
    local weight = gameConfig.alchemy.tier.weight[tier]
    local value = gameConfig.alchemy.tier.value[tier]

    --------------------------------------------------

    if name ~= nil and alchemy.name ~= name then
        common.log("  New Name: %s", name)
    end

    --------------------------------------------------

    common.logEffects(alchemy, "Old ")

    effect.duration = duration
    effect.min = magnitude
    effect.max = magnitude

    common.logEffects(alchemy, "New ")

    --------------------------------------------------

    common.log("  Weight: %.2f -> %.2f", alchemy.weight, weight)
    common.log("  Value: %d -> %d", alchemy.value, value)

    --------------------------------------------------

    if name ~= nil then alchemy.name = name end
    alchemy.weight = weight
    alchemy.value = value

end

local this = {}

this.onLoaded = function(e)

    if not gameConfig.alchemy.rebalanceEnabled then return end
    if not gameConfigUpdated.alchemy then return end
    gameConfigUpdated.alchemy = false

    fEffectCostMult = tes3.findGMST(tes3.gmst.fEffectCostMult).value

    common.log("--------------------------------------------------")
    common.log("Potion Search Terms")
    common.log("--------------------------------------------------")

    local validTiers = util.getSetFromRange(1, 5)

    tierSearchPatterns = common.getSearchPatterns_MultiLine(
        gameConfig.alchemy.detectTier.searchTerms,
        validTiers,
        "Tier",
        true)

    common.log("--------------------------------------------------")
    common.log("Potion Rebalance")
    common.log("--------------------------------------------------")

    for alchemy in common.sortedIterateObjects({ tes3.objectType.alchemy }) do
        rebalanceAlchemy(alchemy)
    end

end

return this
