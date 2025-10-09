local core = require("openmw.core")
local T = require("openmw.types")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mCfg = require("scripts.fresh-loot.config.configuration")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mObj = require("scripts.fresh-loot.util.objects")

local l10n = core.l10n(mDef.MOD_NAME);

local module = {}

--[[
Modifier type id cache structure example
{
    props = { ... },
    effects = {
        [TypeArmor] = {
            ids = { prefix = {Ids}, suffix = {Ids} },
            subTypes = {
                [GreavesIndex] = {
                    ids = { prefix = {Ids}, suffix = {Ids} },
                    classes = {
                        Light = { prefix = {Ids}, suffix = {Ids} }
                    }
                }
            }
        }
    }
}
]]

local function getSubTypesFromNotSubTypes(type, notSubTypes)
    local subTypes = {}
    for _, subType in pairs(type.TYPE) do
        if not notSubTypes or not notSubTypes[subType] then
            subTypes[subType] = true
        end
    end
    return subTypes
end

local function getDescription(mod, level)
    if mod.effects then
        return nil
    else
        local _, values = next(mod.modifiers or mod.multipliers)
        return l10n("desc_" .. mod.id, { value = values[level] })
    end
end
module.getDescription = getDescription

local function getAffixName(mod)
    return l10n(string.format("%s_%s", mod.affixType, mod.id))
end
module.getAffixName = getAffixName

local function assertModFields(mod)
    assert(mod.id, "Missing mod id")
    assert(mod.affixType == mTypes.affixTypes.Prefix or mod.affixType == mTypes.affixTypes.Suffix, "Invalid affix type for mod " .. mod.id)
    assert(mod.value, "Missing value for mod " .. mod.id)
    if mod.effects then
        assert(mod.castType, "Missing castType for mod " .. mod.id)
    end
    assert(mod.itemTypes, "Missing itemTypes for mod " .. mod.id)
end
module.assertModFields = assertModFields

local function buildModifierMap(state, modifiers)
    local count, deprecated = 0, 0
    local missingLocales = {}
    for _, mod in ipairs(modifiers) do
        assertModFields(mod)
        if string.find(getAffixName(mod), "_") then
            table.insert(missingLocales, mod.id)
        end
        if not mod.deprecated then
            count = count + 1
            state.cache.modifiers[mod.id] = mod
        else
            deprecated = deprecated + 1
        end
    end
    if #missingLocales > 0 then
        core.sendGlobalEvent(mDef.events.sendPlayersEvent, mTypes.new.playersEvent(
                mDef.events.showMessage,
                mTypes.new.message(string.format("Missing localizations for %d modifiers", #missingLocales))))
        log(string.format("Missing localizations for mods: %s", table.concat(missingLocales, ", ")))
    end
    log(string.format("Modifier map built, found %d modifiers, %d deprecated", count, deprecated))
end

local function buildModifierTypeCache(state, modifiers, forEffects)
    local count = 0
    local typeIds = {}
    for type, props in pairs(mTypes.itemTypes) do
        typeIds[type] = { ids = { prefix = {}, suffix = {} }, subTypes = {} }
        for _, index in pairs(type.TYPE) do
            typeIds[type].subTypes[index] = { ids = { prefix = {}, suffix = {} }, classes = {} }
            for _, class in ipairs(props.classes) do
                typeIds[type].subTypes[index].classes[class] = { prefix = {}, suffix = {} }
            end
        end
    end
    for _, modifier in ipairs(modifiers) do
        if not modifier.deprecated and not forEffects == not modifier.effects then
            count = count + 1
            for type, props in pairs(modifier.itemTypes) do
                if props == true then
                    table.insert(typeIds[type].ids[modifier.affixType], modifier.id)
                else
                    local subTypes = props.types or getSubTypesFromNotSubTypes(type, props.notTypes)
                    for subType in pairs(subTypes) do
                        if props.classes then
                            for class in pairs(props.classes) do
                                table.insert(typeIds[type].subTypes[subType].classes[class][modifier.affixType], modifier.id)
                            end
                        else
                            table.insert(typeIds[type].subTypes[subType].ids[modifier.affixType], modifier.id)
                        end
                    end
                end
            end
        end
    end
    if forEffects then
        state.cache.modifierTypes.effects = typeIds
    else
        state.cache.modifierTypes.props = typeIds
    end
    log(string.format("%s modifier type id cache built, found %d modifiers", forEffects and "Effects" or "Props", count))
end

local function init(state, modifiers)
    buildModifierMap(state, modifiers)
    buildModifierTypeCache(state, modifiers, false)
    buildModifierTypeCache(state, modifiers, true)
end
module.init = init

local function addModIdsFromCache(list, cache, affixType, filter)
    if affixType == mTypes.affixTypes.Any then
        mHelpers.addArrayToArray(list, cache[mTypes.affixTypes.Prefix], filter)
        mHelpers.addArrayToArray(list, cache[mTypes.affixTypes.Suffix], filter)
    else
        mHelpers.addArrayToArray(list, cache[affixType], filter)
    end
end

local function getModSortScore(mod)
    if not mod.effects then
        return 0
    end
    for _, effect in ipairs(mod.effects) do
        if effect.id == core.magic.EFFECT_TYPE.Dispel then
            return 1
        end
    end
    for _, effect in ipairs(mod.effects) do
        if mTypes.weaknessEffects[effect.id] then
            return 2
        end
    end
    return 3
end

local function sortLvlMods(lvlMods)
    table.sort(lvlMods, function(lvlMod1, lvlMod2)
        local score1, score2 = getModSortScore(lvlMod1.mod), getModSortScore(lvlMod2.mod)
        return score1 == score2 and lvlMod1.mod.id < lvlMod2.mod.id or score1 < score2
    end)
end
module.sortLvlMods = sortLvlMods

local function lvlModsToLvlModIds(lvlMods)
    local lvlModIds = {}
    for _, lvlMod in ipairs(lvlMods) do
        table.insert(lvlModIds, mTypes.new.lvlModId(lvlMod.mod.id, lvlMod.lvl))
    end
    return lvlModIds
end
module.lvlModsToLvlModIds = lvlModsToLvlModIds

local function lvlModIdsToLvlMods(state, lvlModIds)
    local lvlMods = {}
    for _, lvlModId in ipairs(lvlModIds) do
        table.insert(lvlMods, mTypes.new.lvlMod(state.cache.modifiers[lvlModId.id], lvlModId.lvl))
    end
    return lvlMods
end
module.lvlModIdsToLvlMods = lvlModIdsToLvlMods

local function hasModifierLevel(mod, level)
    if mod.effects then
        local values = mod.effects[1].min or mod.effects[1].duration or mod.levels
        assert(type(values) == "table", "Invalid level values for mod " .. mod.id)
        assert(values[level] ~= nil or level > #values, string.format("Invalid nil value level %d in mod %s", level, mod.id))
        return values[level]
    end
    for _, levels in pairs(mod.modifiers or mod.multipliers) do
        assert(type(levels) == "table", "Invalid level values for mod " .. mod.id)
        assert(levels[level] ~= nil or level > #levels, string.format("Invalid nil value level %d in mod %s", level, mod.id))
        return levels[level]
    end
end
module.hasModifierLevel = hasModifierLevel

local function hasExcludedEffects(mod, ctx)
    if ctx.loot.type ~= T.Container
            and mod.effects
            and mod.castType == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        for _, effect in ipairs(mod.effects) do
            if mTypes.effectExclusions.actorsEquippedConstantEffects[effect.id] then
                return true
            end
            if not mObj.isActorHostile(ctx.loot) and mTypes.effectExclusions.passiveActorsEquippedConstantEffects[effect.id] then
                return true
            end
        end
    end
    return false
end

local function getModPrice(record, type, mod, level)
    local value = mod.value
    if mTypes.itemTypes[type].convertWholeStackTypes[record.type] then
        value = math.max(1, value / mCfg.itemConversion.projectileValueReduction)
    end
    if mod.multipliers then
        return (value + record.value) * mCfg.itemConversion.propsLevelMult.priceForRelativeMod[level]
    else
        return value * mCfg.itemConversion.propsLevelMult.priceForAbsoluteMod[level]
    end
end
module.getModPrice = getModPrice

local function isModConflictingWith(mod1, mod2)
    if not mod1.conflicts then return false end
    if mod1.conflicts.effects then
        for _, effect in ipairs(mod2.effects or {}) do
            if mod1.conflicts.effects[effect.id] then return true end
        end
    end
    if mod1.conflicts.ranges then
        for _, effect in ipairs(mod2.effects or {}) do
            if mod1.conflicts.ranges[effect.range] then return true end
        end
    end
    return false
end

local function areModConflicting(mod1, mod2)
    if mod1.affixType == mod2.affixType then return true end
    if mod1.castType and mod2.castType and mod1.castType ~= mod2.castType then return true end
    if isModConflictingWith(mod1, mod2) or isModConflictingWith(mod2, mod1) then return true end
    return false
end

local function filterMods(state, modLevel, ctx)
    return function(id)
        local mod = state.cache.modifiers[id]
        for _, lvlMod in ipairs(ctx.item.lvlMods) do
            if areModConflicting(mod, lvlMod.mod) then return false end
        end
        if ctx.maxWealthValue > 0 then
            if ctx.ownerWealth.spent + getModPrice(ctx.item.record, ctx.item.type, mod, modLevel) > ctx.maxWealthValue then
                ctx.item.tooExpensiveMods = ctx.item.tooExpensiveMods + 1
                return false
            end
        end
        return hasModifierLevel(mod, modLevel) and not hasExcludedEffects(mod, ctx)
    end
end

local function getModIdsFromItem(state, typeIdCache, affixType, itemType, modLevel, ctx)
    local mods = {}
    addModIdsFromCache(mods, typeIdCache[itemType].ids, affixType, filterMods(state, modLevel, ctx))
    local subTypes = typeIdCache[itemType].subTypes[ctx.item.record.type]
    addModIdsFromCache(mods, subTypes.ids, affixType, filterMods(state, modLevel, ctx))
    local class = mObj.getItemClass(itemType, ctx.item.record)
    if class then
        addModIdsFromCache(mods, subTypes.classes[class], affixType, filterMods(state, modLevel, ctx))
    end
    return mods
end
module.getModIdsFromItem = getModIdsFromItem

local function getKey(lvlMods)
    local keyElements = {}
    for _, lvlMod in ipairs(lvlMods) do
        table.insert(keyElements, lvlMod.mod.id)
        table.insert(keyElements, lvlMod.lvl)
    end
    return table.concat(keyElements, "_")
end
module.getKey = getKey

local function getEnchantId(lvlMods)
    local enchantIdElements = {}
    for _, lvlMod in ipairs(lvlMods) do
        if lvlMod.mod.effects then
            table.insert(enchantIdElements, lvlMod.mod.id)
            table.insert(enchantIdElements, lvlMod.lvl)
        end
    end
    local enchantId
    if #enchantIdElements ~= 0 then
        table.insert(enchantIdElements, 1, mDef.MOD_NAME)
        enchantId = table.concat(enchantIdElements, "_")
    end
    return enchantId
end
module.getEnchantId = getEnchantId

local function getItemName(itemBaseName, lvlMods)
    local prefixes = {}
    local suffixes = {}
    for _, lvlMod in ipairs(lvlMods) do
        local affixName = getAffixName(lvlMod.mod)
        if lvlMod.mod.affixType == mTypes.affixTypes.Prefix then
            table.insert(prefixes, affixName)
        else
            table.insert(suffixes, affixName)
        end
    end
    assert(#prefixes < 2 and #suffixes < 2 and (#prefixes > 0 or #suffixes > 0), "Incorrect number of prefixes or suffixes for item " .. itemBaseName)
    if #suffixes == 0 then
        return l10n("formatPrefix", { name = itemBaseName, prefix = prefixes[1] })
    elseif #prefixes == 0 then
        return l10n("formatSuffix", { name = itemBaseName, suffix = suffixes[1] })
    else
        return l10n("formatPrefixSuffix", { name = itemBaseName, prefix = prefixes[1], suffix = suffixes[1] })
    end
end
module.getItemName = getItemName

local function getRandomModifierLevel(state, lootLevel)
    local probs = {}
    local probSum = 0
    local level = math.min(lootLevel, state.settings[mStore.cfg.endGameLootLevel.key])
            / (state.settings[mStore.cfg.endGameLootLevel.key] / (mCfg.modifierLevel.maxLevel - 1)) + 1

    for modLevel = 1, mCfg.modifierLevel.maxLevel do
        local probability = math.exp(-mCfg.modifierLevel.pickAlpha * math.abs(modLevel - level) ^ 2)
        probs[modLevel] = probability
        probSum = probSum + probability
    end

    for modLevel = 1, mCfg.modifierLevel.maxLevel do
        probs[modLevel] = probs[modLevel] / probSum
    end

    local randomValue = math.random()
    probSum = 0
    for modLevel = 1, mCfg.modifierLevel.maxLevel do
        probSum = probSum + probs[modLevel]
        if randomValue <= probSum then
            return modLevel
        end
    end

    return 1
end
module.getRandomModifierLevel = getRandomModifierLevel

local function haveModTypeCommonSubType(type, filter1, filter2)
    if filter1.types then
        if filter2.types then
            for subType in pairs(filter1.types) do
                if filter2.types[subType] then return true end
            end
        elseif filter2.notTypes then
            for subType in pairs(filter1.types) do
                if not filter2.notTypes[subType] then return true end
            end
        else
            return true
        end
    elseif filter1.notTypes then
        if filter2.types then
            for subType in pairs(filter2.types) do
                if not filter1.notTypes[subType] then return true end
            end
        elseif filter2.notTypes then
            for subType in pairs(type.TYPE) do
                if not filter1.notTypes[subType] and not filter2.notTypes[subType] then return true end
            end
        else
            return true
        end
    else
        return true
    end
    return false
end

local function areModsCompatible(mod1, mod2)
    if areModConflicting(mod1, mod2) then return false end

    for type, filter1 in pairs(mod1.itemTypes) do
        local filter2 = mod2.itemTypes[type]
        if filter2 then
            if filter1 == true or filter2 == true then
                return true
            elseif haveModTypeCommonSubType(type, filter1, filter2) then
                if filter1.classes and filter2.classes then
                    for class in pairs(filter1.classes) do
                        if filter2.classes[class] then
                            return true
                        end
                    end
                else
                    return true
                end
            end
        end
    end
    return false
end
module.areModsCompatible = areModsCompatible

local function assertModLevelledFields(record, field, values, level)
    assert(record[field], string.format("Cannot find field \"%s\" for record \"%s\"", field, record.id))
    assert(values[level], string.format("Cannot find levelled value level %d in field \"%s\" for record \"%s\"", level, field, record.id))
end

local function applyLvlModsOnItem(lvlMods, type, oldRecord, newRecord)
    local priceAdd = 0
    for _, lvlMod in ipairs(lvlMods) do
        local mod, level = lvlMod.mod, lvlMod.lvl
        priceAdd = priceAdd + getModPrice(oldRecord, type, mod, level)
        for field, values in pairs(mod.modifiers or {}) do
            assertModLevelledFields(newRecord, field, values, level)
            newRecord[field] = newRecord[field] + values[level]
        end
        for field, values in pairs(mod.multipliers or {}) do
            assertModLevelledFields(newRecord, field, values, level)
            newRecord[field] = newRecord[field] * values[level]
        end
        for greaterField, lowerField in pairs(mTypes.itemTypes[type].areGreaterFields) do
            newRecord[greaterField] = math.max(newRecord[greaterField], newRecord[lowerField])
        end
    end
    newRecord.value = oldRecord.value + priceAdd
end
module.applyLvlModsOnItem = applyLvlModsOnItem

return module