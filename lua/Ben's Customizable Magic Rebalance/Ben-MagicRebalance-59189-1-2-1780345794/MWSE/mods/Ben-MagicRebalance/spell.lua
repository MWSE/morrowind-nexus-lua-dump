local config = require("Ben-MagicRebalance.config")
local common = require("Ben-MagicRebalance.common")
local util = require("Ben-MagicRebalance.util")
local gameConfig = config.getGameConfig()
local gameConfigUpdated = config.getGameConfigUpdated()

local haveFeature_SpellmakingMatchesEditor = tes3.hasCodePatchFeature(tes3.codePatchFeature.spellmakingMatchesEditor)
local haveFeature_SpellmakerAreaEffectCost = tes3.hasCodePatchFeature(tes3.codePatchFeature.spellmakerAreaEffectCost)
local fEffectCostMult = nil -- GMST pulled in onLoaded
local unmodifiedSpells_WithoutSourceMod = {} -- id = statsTable
local unmodifiedSpells_WithSourceMod = {} -- id = statsTable

local function logNewSpell(spell, alreadyExists)

    common.log("Spell ID: %s | Name: %s", spell.id, spell.name)
    common.log("  Already Exists: %s", alreadyExists)

    common.logEffects(spell)

    common.log("  Magicka Cost: %.2f", spell.magickaCost)
    common.log("  Auto Calculate: %s", spell.autoCalc)
    common.log("  Starting Spell: %s", spell.playerStart)

end

local function logExcludedFromRebalance(spell, reason)

    common.log("  Excluded From Rebalance: %s", reason)

    common.logEffects(spell)

    common.log("  Magicka Cost: %.2f", spell.magickaCost)
    common.log("  Auto Calculate: %s", spell.autoCalc)
    common.log("  Starting Spell: %s", spell.playerStart)

end

local function getIsCustomSpell(spell)

    if spell.sourceless then return false end
    if spell.sourceMod ~= nil then return false end
    if tonumber(spell.id) == nil then return false end

    return true

end

local function getHasZeroMagickaEffect(spell)

    for i = 1, 8 do

        local effect = spell.effects[i]

        if effect.id >= 0 then
            local effectConfig = common.getEffectConfig(effect.id)
            if effectConfig.baseMagickaCost == 0 then return true end
        end

    end

    return false

end

local function getHasExcludedEffect(spell)

    for _, effect in ipairs(spell.effects) do
        if gameConfig.shared.excludedEffectIds[effect.id] then return true end
    end

    return false

end

local function getNewAutoCalc(spell)

    -- Most NPCs have the ability to cast any spell that's flagged as autoCalc.
    -- Set this flag to false on everything except spells with modded effects
    -- to better control which spells NPCs are allowed to cast.

    if common.getHasModdedEffect(spell) then
        return spell.autoCalc
    end

    return false

end

local function getEffectCost(effect, isCustomSpell, useUnmodifiedBaseMagickaCost)

    local min = effect.min or 1
    if min < 1 then min = 1 end

    local max = effect.max or 1
    if max < 1 then max = 1 end

    local duration = effect.duration or 1
    if duration < 1 then duration = 1 end

    local area = effect.radius or 0
    if area < 0 then area = 0 end

    local baseMagickaCost = effect.object.baseMagickaCost

    if useUnmodifiedBaseMagickaCost then
        local unmodifiedMagicEffect = common.getUnmodifiedMagicEffect(effect.id)
        baseMagickaCost = unmodifiedMagicEffect.baseMagickaCost
    end

    if isCustomSpell and not haveFeature_SpellmakingMatchesEditor then -- use vanilla spellmaking formula
        duration = duration + 1
    end

    local effectCost = nil
    local useMcpArea = haveFeature_SpellmakerAreaEffectCost
        and (isCustomSpell or gameConfig.shared.useMcpAreaFormulaEverywhere)
        and not useUnmodifiedBaseMagickaCost

    if useMcpArea then -- use MCP area formula
        effectCost = (min + max) * (duration) * (1 + area ^ 2 / 400) * baseMagickaCost / 20
    else -- use vanilla area formula
        effectCost = ((min + max) * (duration) + area) * baseMagickaCost / 20
    end

    if effect.rangeType == tes3.effectRange.target then
        effectCost = effectCost * 1.5
    end

    local gmstCostMult = fEffectCostMult
    if useUnmodifiedBaseMagickaCost then gmstCostMult = 0.5 end

    -- apply GMST multiplier, default value is 0.5
    effectCost = effectCost * gmstCostMult

    -- avoid floating point rounding errors
    effectCost = util.round(effectCost, 4)

    return effectCost

end

local function getMagickaCost(effects, isCustomSpell, useUnmodifiedBaseMagickaCost, costMult)

    if util.isEmpty(effects) then return 0 end

    local magickaCost = 0

    for _, effect in ipairs(effects) do

        if effect.object ~= nil then
            local effectCost = getEffectCost(effect, isCustomSpell, useUnmodifiedBaseMagickaCost)
            magickaCost = magickaCost + effectCost
        end

    end

    -- handle enchanting
    if costMult ~= nil then magickaCost = magickaCost * costMult end

    -- avoid floating point rounding errors
    magickaCost = util.round(magickaCost, 2)

    if isCustomSpell and not haveFeature_SpellmakingMatchesEditor then -- use vanilla spellmaking formula
        magickaCost = math.floor(magickaCost)
    else -- use vanilla construction set formula
        magickaCost = util.round(magickaCost, 0)
    end

    if magickaCost < 1 then magickaCost = 1 end

    return magickaCost

end

local function getMagnitudeVariance(effectId)

    if effectId == tes3.effect.restoreFatigue
    or effectId == tes3.effect.restoreHealth
    or effectId == tes3.effect.restoreMagicka then

        return gameConfig.spell.magnitudeVariance.restore

    elseif effectId == tes3.effect.poison
    or effectId == tes3.effect.fireDamage
    or effectId == tes3.effect.frostDamage
    or effectId == tes3.effect.shockDamage
    or effectId == tes3.effect.damageFatigue
    or effectId == tes3.effect.damageHealth
    or effectId == tes3.effect.damageMagicka
    or effectId == tes3.effect.damageAttribute
    or effectId == tes3.effect.damageSkill
    or effectId == tes3.effect.drainFatigue
    or effectId == tes3.effect.drainHealth
    or effectId == tes3.effect.drainMagicka
    or effectId == tes3.effect.absorbFatigue
    or effectId == tes3.effect.absorbHealth
    or effectId == tes3.effect.absorbMagicka then

        return gameConfig.spell.magnitudeVariance.attack

    elseif effectId == tes3.effect.sound
    or effectId == tes3.effect.blind
    or effectId == tes3.effect.burden
    or effectId == tes3.effect.drainAttribute
    or effectId == tes3.effect.drainSkill
    or effectId == tes3.effect.absorbAttribute
    or effectId == tes3.effect.absorbSkill then

        return gameConfig.spell.magnitudeVariance.debuff

    end

    return 0

end

local function getMinMax(effectId, magnitude)

    local variance = getMagnitudeVariance(effectId)
    local min = nil
    local max = nil

    if variance == 0 or magnitude < 10 then

        min = magnitude
        max = magnitude

    elseif variance == 100 then

        min = 0
        max = magnitude * 2

    else -- variance > 0 and < 100

        local delta = util.round(magnitude * variance / 100, 2)
        local roundTo = (magnitude < 40) and 5 or 10 -- round to 5 if < 40, round to 10 otherwise
        min = math.floor((magnitude - delta) / roundTo) * roundTo -- round down to nearest multiple of X
        max = magnitude * 2 - min -- increase max by amount min was decreased

    end

    --------------------------------------------------

    -- avoid floating point rounding errors
    min = util.round(min, 2)
    max = util.round(max, 2)

    min = math.floor(min)
    max = math.floor(max)

    --------------------------------------------------

    return {min, max}

end

local function getEffectDurMinMax_FromEffectInfo(effectInfo)

    local magicEffect = tes3.getMagicEffect(effectInfo.id)

    if magicEffect.hasNoMagnitude
    and magicEffect.hasNoDuration then
        return {1, 1, 1}
    end

    --------------------------------------------------

    local effectConfig = common.getEffectConfig(effectInfo.id)
    local recMinDuration = effectConfig.recMinDuration or 1
    local duration = nil

    if effectInfo.durationFlat ~= nil then

        duration = util.clamp(effectInfo.durationFlat, recMinDuration)

    else -- use durationMult

        local durationMult = effectInfo.durationMult or 1
        duration = recMinDuration * durationMult

    end

    --------------------------------------------------

    local magnitudeDivisor = duration / recMinDuration -- increasing duration dilutes magnitude
    local recMinMagnitude = effectConfig.recMinMagnitude or 1
    local tier = effectInfo.tier or 1

    local uncappedMagnitude = recMinMagnitude * tier / magnitudeDivisor
    local magnitude = util.clamp(uncappedMagnitude, effectConfig.minMagnitude, effectConfig.recMaxMagnitude)
    duration = duration * (uncappedMagnitude / magnitude)

    if magicEffect.hasNoMagnitude then
        duration = duration * magnitude
        magnitude = 1
    elseif magicEffect.hasNoDuration then
        magnitude = magnitude * duration
        duration = 1
    end

    -- tier 0.X can go lower than recommended minimums, but cannot go lower than spellmaking minimums
    magnitude = util.clamp(magnitude, effectConfig.minMagnitude, effectConfig.recMaxMagnitude)
    duration = util.clamp(duration, effectConfig.minDuration, effectConfig.maxDuration)

    --------------------------------------------------

    local minMax = getMinMax(effectInfo.id, magnitude)
    local min, max = table.unpack(minMax)

    -- avoid floating point rounding errors
    duration = util.round(duration, 2)
    duration = math.floor(duration)

    --------------------------------------------------

    return {duration, min, max}

end

local function mergeSpellInfo(spell, spellInfo, autoCalc)

    for i = 1, 8 do

        local effect = spell.effects[i]
        local effectInfo = spellInfo.effectInfos[i]

        if effectInfo ~= nil then

            local durMinMax = getEffectDurMinMax_FromEffectInfo(effectInfo)
            local duration, min, max = table.unpack(durMinMax)

            effect.id = effectInfo.id
            effect.attribute = effectInfo.attribute or -1
            effect.skill = effectInfo.skill or -1
            effect.rangeType = effectInfo.rangeType or tes3.effectRange.self
            effect.radius = effectInfo.radius or 0
            effect.duration = duration
            effect.min = min
            effect.max = max

        elseif effect.id >= 0 then -- clear values

            effect.id = -1
            effect.attribute = 0
            effect.skill = 0
            effect.rangeType = 0
            effect.radius = 0
            effect.duration = 0
            effect.min = 0
            effect.max = 0

        end

    end

    local touchedAutoCalc = false
    local touchedPlayerStart = false

    spell.name = spellInfo.name
    spell.magickaCost = spellInfo.magickaCost or getMagickaCost(spell.effects, false, false)
    if gameConfig.spell.addNpcSpells then spell.autoCalc = autoCalc; touchedAutoCalc = true end
    if gameConfig.spell.addStartSpells then spell.playerStart = false; touchedPlayerStart = true end

    return {
        touchedAutoCalc = touchedAutoCalc,
        touchedPlayerStart = touchedPlayerStart
    }

end

local function enforceEffectLimits(effect)

    if effect.id < 0 then return false end

    local magicEffect = effect.object

    if magicEffect.hasNoMagnitude
    and magicEffect.hasNoDuration then
        return false
    end

    local effectConfig = common.getEffectConfig(effect.id)

    local oldDuration = util.zeroAsNil(effect.duration) or 1
    local newDuration = util.clamp(oldDuration, effectConfig.minDuration, effectConfig.maxDuration)
    local durationDelta = util.round(math.abs(oldDuration - newDuration), 2)
    local durationDeltaMult = oldDuration / newDuration

    if effect.id == tes3.effect.drainHealth and oldDuration == 1 then
        durationDeltaMult = 1 -- this change should not affect magnitude
    end

    local oldAvgMagnitude = (effect.min + effect.max) / 2
    local oldAvgMagnitudeAdjusted = oldAvgMagnitude * durationDeltaMult
    local newAvgMagnitude = util.clamp(oldAvgMagnitudeAdjusted, effectConfig.minMagnitude, effectConfig.maxMagnitude)
    local avgMagnitudeDelta = util.round(math.abs(oldAvgMagnitude - newAvgMagnitude), 2)

    if durationDelta == 0
    and avgMagnitudeDelta ~= 0 then

        local oldDurationAdjusted = oldDuration * oldAvgMagnitude / newAvgMagnitude
        newDuration = util.clamp(oldDurationAdjusted, effectConfig.minDuration, effectConfig.maxDuration)
        durationDelta = util.round(math.abs(oldDuration - newDuration), 0)

    end

    local effectChanged = false

    if durationDelta ~= 0 then

        effect.duration = newDuration
        effectChanged = true

    end

    if avgMagnitudeDelta ~= 0 then

        local minMax = getMinMax(effect.Id, newAvgMagnitude)
        local min, max = table.unpack(minMax)

        effect.min = min
        effect.max = max

        effectChanged = true

    end

    return effectChanged

end

local function enforceSpellEffectLimits(spell)

    local anyEffectChanged = false

    for i = 1, 8 do
        local effectChanged = enforceEffectLimits(spell.effects[i])
        if effectChanged then anyEffectChanged = true end
    end

    return anyEffectChanged

end

local function getRangeTypes(effectId)

    local magicEffect = tes3.getMagicEffect(effectId)
    local rangeTypes = {}

    if magicEffect.isHarmful and magicEffect.canCastTouch then
        table.insert(rangeTypes, tes3.effectRange.touch)
    end

    if magicEffect.isHarmful and magicEffect.canCastTarget then
        table.insert(rangeTypes, tes3.effectRange.target)
    end

    if not magicEffect.isHarmful and magicEffect.canCastSelf then
        table.insert(rangeTypes, tes3.effectRange.self)
    end

    return rangeTypes

end

local function getAttribute(effectId)

    if effectId == tes3.effect.restoreAttribute
    or effectId == tes3.effect.fortifyAttribute
    or effectId == tes3.effect.damageAttribute
    or effectId == tes3.effect.drainAttribute
    or effectId == tes3.effect.absorbAttribute then

        return tes3.attribute.strength

    end

    return nil

end

local function getSkill(effectId)

    if effectId == tes3.effect.restoreSkill
    or effectId == tes3.effect.fortifySkill
    or effectId == tes3.effect.damageSkill
    or effectId == tes3.effect.drainSkill
    or effectId == tes3.effect.absorbSkill then

        return tes3.skill.athletics

    end

    return nil

end

local function getEffectDurMinMax_FromMagickaCost(effectId, magickaCost)

    local magicEffect = tes3.getMagicEffect(effectId)

    if magicEffect.hasNoMagnitude
    and magicEffect.hasNoDuration then
        return {1, 1, 1}
    end

    --------------------------------------------------

    local effectConfig = common.getEffectConfig(effectId)
    local duration = effectConfig.recMinDuration or 1

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

    -- starting spells can go lower than recommended minimums, but cannot go lower than spellmaking minimums
    magnitude = util.clamp(magnitude, effectConfig.minMagnitude, effectConfig.recMaxMagnitude)
    duration = util.clamp(duration, effectConfig.minDuration, effectConfig.maxDuration)

    --------------------------------------------------

    local minMax = getMinMax(effectId, magnitude)
    local min, max = table.unpack(minMax)

    -- avoid floating point rounding errors
    duration = util.round(duration, 2)
    duration = math.floor(duration)

    --------------------------------------------------

    return {duration, min, max}

end

local function addStartSpell(effectId)

    local spellId = string.format("Ben_Start_E%03d", effectId)

    -- keep updating spells that already exist in the game
    local isCurrent = gameConfig.spell.startEffectIds[effectId]
    local alreadyExists = tes3.getObject(spellId) ~= nil

    if not isCurrent and not alreadyExists then return end
    if not alreadyExists and not gameConfig.spell.addStartSpells then return end

    local spell = tes3.createObject({id = spellId, objectType = tes3.objectType.spell})
    tes3.setSourceless(spell, true) -- this doesn't seem to do anything

    local effect = spell.effects[1]
    local rangeTypes = getRangeTypes(effectId)
    local durMinMax = getEffectDurMinMax_FromMagickaCost(effectId, gameConfig.spell.startMagickaCost)
    local duration, min, max = table.unpack(durMinMax)

    local name = common.getEffectName(effect)
    if string.len(name) > 29 then name = string.sub(name, 1, 29) end
    name = string.format("[%s]", name)

    effect.id = effectId
    effect.attribute = getAttribute(effectId)
    effect.skill = getSkill(effectId)
    effect.rangeType = rangeTypes[1]
    effect.radius = 0
    effect.duration = duration
    effect.min = min
    effect.max = max

    spell.name = name
    spell.magickaCost = getMagickaCost(spell.effects, false, false)
    spell.autoCalc = false
    spell.playerStart = isCurrent

    logNewSpell(spell, alreadyExists)

end

local function addNpcSpells(effectId)

    local rangeTypes = getRangeTypes(effectId)

    for _, rangeType in ipairs(rangeTypes) do
        for tier = 1, gameConfig.spell.npcTierCount do

            -- https://mwse.github.io/MWSE/apis/tes3/#tes3createobject
            -- id and name are limited to 31 characters, not an issue with these values

            local spellId = string.format("Ben_NPC_E%03d_R%d_T%d", effectId, rangeType, tier)

            -- keep updating spells that already exist in the game
            local isCurrent = gameConfig.spell.npcEffectIds[effectId]
            local alreadyExists = tes3.getObject(spellId) ~= nil

            if not isCurrent and not alreadyExists then break end
            if not alreadyExists and not gameConfig.spell.addNpcSpells then return end

            local spellName = string.format("NPC E%03d R%d T%d", effectId, rangeType, tier)
            local spell = tes3.createObject({id = spellId, objectType = tes3.objectType.spell})
            tes3.setSourceless(spell, true) -- this doesn't seem to do anything

            local effect = spell.effects[1]
            local magickaCost = tier * 10
            if rangeType == tes3.effectRange.target then magickaCost = magickaCost / 1.5 end
            local durMinMax = getEffectDurMinMax_FromMagickaCost(effectId, magickaCost)
            local duration, min, max = table.unpack(durMinMax)

            local name = common.getEffectName(effect)
            if string.len(name) > 28 then name = string.sub(name, 1, 28) end
            name = string.format("%s T%d", name, tier)

            effect.id = effectId
            effect.attribute = getAttribute(effectId)
            effect.skill = getSkill(effectId)
            effect.rangeType = rangeType
            effect.radius = 0
            effect.duration = duration
            effect.min = min
            effect.max = max

            spell.name = name
            spell.magickaCost = getMagickaCost(spell.effects, false, false)
            spell.autoCalc = isCurrent
            spell.playerStart = false

            logNewSpell(spell, alreadyExists)

        end
    end

end

local function addNpcSpells_Old(effectId)

    local rangeTypes = getRangeTypes(effectId)

    for _, rangeType in ipairs(rangeTypes) do
        for tier = 1, gameConfig.spell.npcTierCount do

            -- https://mwse.github.io/MWSE/apis/tes3/#tes3createobject
            -- id and name are limited to 31 characters, not an issue with these values

            local spellId = string.format("Ben_NPC_E%03d_R%d_T%d", effectId, rangeType, tier)

            -- keep updating spells that already exist in the game
            local isCurrent = gameConfig.spell.npcEffectIds[effectId]
            local alreadyExists = tes3.getObject(spellId) ~= nil

            if not isCurrent and not alreadyExists then break end
            if not alreadyExists and not gameConfig.spell.addNpcSpells then return end

            local spellName = string.format("NPC E%03d R%d T%d", effectId, rangeType, tier)
            local spell = tes3.createObject({id = spellId, objectType = tes3.objectType.spell})
            tes3.setSourceless(spell, true) -- this doesn't seem to do anything

            local effectInfo = {
                id = effectId,
                attribute = getAttribute(effectId),
                skill = getSkill(effectId),
                rangeType = rangeType,
                radius = 0,
                durationMult = 1,
                durationFlat = nil,
                tier = tier,
            }

            local spellInfo = {
                name = spellName,
                magickaCost = nil,
                effectInfos = {effectInfo},
            }

            mergeSpellInfo(spell, spellInfo, isCurrent)
            logNewSpell(spell, alreadyExists)

        end
    end

end

local function getSpellInfo(spell)

    if not gameConfig.spell.updateSpellEffects then return nil end
    return gameConfig.spell.spellInfos[spell.id]

end

local function rebalanceSpell(spell, unmodifiedSpells)

    -- https://mwse.github.io/MWSE/types/tes3spell/

    local unmodifiedSpell = unmodifiedSpells[spell.id]
    if unmodifiedSpell == nil then return end

    common.log("Spell ID: %s | Name: %s", spell.id, spell.name)
    common.log("  Source Mod: %s", spell.sourceMod or "nil")

    --------------------------------------------------

    local spellInfo = getSpellInfo(spell)
    local oldMagickaCost = spell.magickaCost
    local oldAutoCalc = spell.autoCalc
    local oldPlayerStart = spell.playerStart

    if spellInfo ~= nil then

        common.log("  Included In Rebalance - In Spell List")

        if spell.name ~= spellInfo.name then
            common.log("  New Name: %s", spellInfo.name)
        end

        common.logEffects(spell, "Old ")
        local mergeResult = mergeSpellInfo(spell, spellInfo, false)
        common.logEffects(spell, "New ")

        common.log("  Original Calculated Magicka Cost: %.2f", unmodifiedSpell.calculatedMagickaCost)
        common.logValueChange("  Magicka Cost: ", "%.2f", oldMagickaCost, spell.magickaCost)
        common.logValueChange("  Auto Calculate: ", "%s", oldAutoCalc, spell.autoCalc, mergeResult.touchedAutoCalc)
        common.logValueChange("  Starting Spell: ", "%s", oldPlayerStart, spell.playerStart, mergeResult.touchedPlayerStart)

    else -- spell not explicitly redefined

        if getHasExcludedEffect(spell) then
            logExcludedFromRebalance(spell, "In \"Excluded Effects\" List")
            return
        end

        if getHasZeroMagickaEffect(spell) then
            logExcludedFromRebalance(spell, "Base Magicka Cost is Zero")
            return
        end

        common.log("  Included In Rebalance - Not In Spell List")
        common.logEffects(spell, "Old ")

        if gameConfig.spell.enforceLimitsOnPremadeSpells then
            local anyEffectChanged = enforceSpellEffectLimits(spell)
            if anyEffectChanged then common.logEffects(spell, "New ") end
        end

        local touchedMagickaCost = false
        local touchedAutoCalc = false
        local touchedPlayerStart = false

        local isCustomSpell = getIsCustomSpell(spell)
        local newCalculatedMagickaCost = getMagickaCost(spell.effects, isCustomSpell, false)

        if unmodifiedSpell.canUpdateMagickaCost
        or newCalculatedMagickaCost < spell.magickaCost
        or gameConfig.spell.forceRecalculateAllMagickaCosts then
            spell.magickaCost = util.clamp(newCalculatedMagickaCost, nil, 10000)
            touchedMagickaCost = true
        end

        if gameConfig.spell.addNpcSpells then spell.autoCalc = getNewAutoCalc(spell); touchedAutoCalc = true end
        if gameConfig.spell.addStartSpells then spell.playerStart = false; touchedPlayerStart = true end

        common.logValueChange("  Calculated Magicka Cost: ", "%.2f", unmodifiedSpell.calculatedMagickaCost, newCalculatedMagickaCost)
        common.logValueChange("  Magicka Cost: ", "%.2f", oldMagickaCost, spell.magickaCost, touchedMagickaCost)
        common.logValueChange("  Auto Calculate: ", "%s", oldAutoCalc, spell.autoCalc, touchedAutoCalc)
        common.logValueChange("  Starting Spell: ", "%s", oldPlayerStart, spell.playerStart, touchedPlayerStart)

    end

end

local function blah()

end

local function getCanUpdateMagickaCost(spell, calculatedMagickaCost)

    if spell.autoCalc then return true end
    if getIsCustomSpell(spell) then return true end

    -- if current cost matches calculated cost (ignoring rounding errors), assume cost is safe to rebalance
    local magickaCostDelta = util.round(math.abs(spell.magickaCost - calculatedMagickaCost), 0)
    if magickaCostDelta <= 1 then return true end

    return false

end

local function getUnmodifiedSpell(spell)

    local calculatedMagickaCost = getMagickaCost(spell.effects, false, true)
    local canUpdateMagickaCost = getCanUpdateMagickaCost(spell, calculatedMagickaCost)

    return {
        calculatedMagickaCost = calculatedMagickaCost,
        canUpdateMagickaCost = canUpdateMagickaCost,
    }

end

local function cacheSpell_WithoutSourceMod(spell)

    if spell.isSpell == false then return end
    if spell.sourceMod ~= nil then return end

    -- no need to rebalance spells added by this mod
    if string.find(spell.id, "^Ben_NPC_") ~= nil then return end
    if string.find(spell.id, "^Ben_Start_") ~= nil then return end

    unmodifiedSpells_WithoutSourceMod[spell.id] = getUnmodifiedSpell(spell)

end

local function cacheSpell_WithSourceMod(spell)

    if spell.isSpell == false then return end
    if spell.sourceMod == nil then return end

    unmodifiedSpells_WithSourceMod[spell.id] = getUnmodifiedSpell(spell)

end

local function cacheSpells_WithoutSourceMod()

    -- these spells exist per save
    unmodifiedSpells_WithoutSourceMod = {}

    for spell in tes3.iterateObjects({ tes3.objectType.spell }) do
        cacheSpell_WithoutSourceMod(spell)
    end

end

local function cacheSpells_WithSourceMod()

    if next(unmodifiedSpells_WithSourceMod) ~= nil then return end

    for spell in tes3.iterateObjects({ tes3.objectType.spell }) do
        cacheSpell_WithSourceMod(spell)
    end

end

local this = {}

this.onCalcEnchantingSpellPointCost = function(e)

    if not gameConfig.shared.newEnchantingCostCalculation then return end
    if util.isEmpty(e.effects) then return 0 end

    local effects = {}

    for i, data in ipairs(e.effects) do

        local magicEffect = tes3.getMagicEffect(data.effect.id)

        effects[i] = {
            id = magicEffect.id,
            object = magicEffect,
            rangeType = data.range,
            radius = data.area,
            duration = data.duration,
            min = data.magnitudeLow,
            max = data.magnitudeHigh,
        }

        if e.castType == tes3.enchantmentType.constant then
            -- Yup, I was surprised this was needed too.
            effects[i].duration = 1
        end

    end

    local costMult = nil

    if e.castType == tes3.enchantmentType.constant then
        -- fEnchantmentConstantDurationMult GMST is bugged at magnitude 0 and 1.
        -- This setting is not tied to that GMST but it fulfills the same purpose.
        costMult = gameConfig.shared.enchantmentConstantDurationMult
    end

    -- This new cost matches the vanilla construction set.
    -- costMult needs taken into account before rounding occurs.
    local magickaCost = getMagickaCost(effects, false, false, costMult)

    e.spellPointCost = magickaCost

end

this.onSpellCreated = function(e)

    if not gameConfig.shared.fixSpellmakingTargetCost then return end
    if e.source ~= tes3.spellSource.service then return end

    local magickaCost = getMagickaCost(e.spell.effects, true, false)
    if e.spell.magickaCost == magickaCost then return end

    -- When there are multiple "Target" effects in one custom spell, vanilla applies
    -- the x1.5 "Target" cost multiplier too many times, resulting in an inflated price.
    -- Recalculating the spell's magicka cost after creation is the easiest way to fix this.
    -- calcSpellmakingSpellPointCost is severely lacking compared to its enchanting equivalent.
    tes3.messageBox("Magicka Cost Updated: %d -> %d", e.spell.magickaCost, magickaCost)
    e.spell.magickaCost = magickaCost

end

this.onLoaded = function(e)

    if not gameConfig.spell.rebalanceEnabled then return end

    fEffectCostMult = tes3.findGMST(tes3.gmst.fEffectCostMult).value

    common.log("--------------------------------------------------")
    common.log("Starting Spells")
    common.log("--------------------------------------------------")

    for effectId = 0, 142 do
        addStartSpell(effectId)
    end

    common.log("--------------------------------------------------")
    common.log("NPC Spells")
    common.log("--------------------------------------------------")

    for effectId = 0, 142 do
        addNpcSpells(effectId)
    end

    common.log("--------------------------------------------------")
    common.log("Spell Rebalance - Without Source Mod")
    common.log("--------------------------------------------------")

    cacheSpells_WithoutSourceMod()

    for spell in common.sortedIterateObjects({ tes3.objectType.spell }) do
        rebalanceSpell(spell, unmodifiedSpells_WithoutSourceMod)
    end

    if gameConfigUpdated.spell then

        gameConfigUpdated.spell = false

        common.log("--------------------------------------------------")
        common.log("Spell Rebalance - With Source Mod")
        common.log("--------------------------------------------------")

        cacheSpells_WithSourceMod()

        for spell in common.sortedIterateObjects({ tes3.objectType.spell }) do
            rebalanceSpell(spell, unmodifiedSpells_WithSourceMod)
        end

    end

    -- force player's UI to refresh
    tes3.updateMagicGUI({reference = tes3.player})

end

return this
