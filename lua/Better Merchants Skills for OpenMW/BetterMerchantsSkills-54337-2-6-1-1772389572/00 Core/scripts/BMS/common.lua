local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')

local log = require("scripts.BMS.util.log")
local mDef = require('scripts.BMS.config.definition')
local mH = require("scripts.BMS.util.helpers")

local module = {}

module.GMSTs = {
    fFatigueBase = core.getGMST("fFatigueBase"),
    fDispositionMod = core.getGMST("fDispositionMod"),
}

-- If some NPCs have too high or too low trading skills, you can override their level here, like the commented line for Arrille
module.npcLevelOverrides = {
    --["arrille"] = 5,
}

local statType = {
    skills = "skills",
    attributes = "attributes",
}

local statTypes = {
    mercantile = statType.skills,
    speechcraft = statType.skills,
    personality = statType.attributes,
    luck = statType.attributes,
}

module.operationType = {
    saveStats = "saveStats",
    computeStats = "computeStats",
    buff = "buff",
    restore = "restore",
}

module.buffType = {
    service = "service",
    barter = "barter",
    haggling = "haggling",
    persuasion = "persuasion",
}

module.getDescriptionIfOpenMWTooOld = function(key)
    if not mDef.isLuaApiRecentEnough then
        if mDef.isOpenMW049 then
            return "requiresNewerOpenMW49"
        else
            return "requiresOpenMW49"
        end
    end
    return key
end

module.isObjectInvalid = function(object)
    return not object or not object:isValid() or object.count == 0
end

module.modsToString = function(stats)
    local parts = {}
    for statId, values in pairs(stats) do
        table.insert(parts, string.format("%s=(pos=%s, neg=%s)", statId, values.pos, values.neg))
    end
    return table.concat(parts, ", ")
end

module.basesToString = function(stats)
    local parts = {}
    for statId, value in pairs(stats) do
        table.insert(parts, string.format("%s=%d", statId, value))
    end
    return table.concat(parts, ", ")
end

local function getMod(stat)
    return {
        pos = stat.modifier,
        neg = stat.damage,
        mod = stat.modifier - stat.damage
    }
end

module.getMods = function(actor)
    local mods = {}
    for statId, type in pairs(statTypes) do
        mods[statId] = getMod(T.NPC.stats[type][statId](actor))
    end
    return mods
end

module.getBases = function(actor)
    local bases = {}
    for statId, type in pairs(statTypes) do
        bases[statId] = T.NPC.stats[type][statId](actor).base
    end
    return bases
end

module.getModsDiff = function(stats1, stats2)
    local hasDiff = false
    local diff = {}
    for statId, modTypes in pairs(stats1) do
        diff[statId] = {}
        for modType, value in pairs(modTypes) do
            diff[statId][modType] = stats2[statId][modType] - value
            if mH.round(diff[statId][modType], 5) ~= 0 then
                hasDiff = true
            end
        end
    end
    return diff, hasDiff
end

module.getBasesDiff = function(stats1, stats2)
    local hasDiff = false
    local diff = {}
    for statId, value in pairs(stats1) do
        diff[statId] = stats2[statId] - value
        if diff[statId] ~= 0 then
            hasDiff = true
        end
    end
    return diff, hasDiff
end

module.applyModsDiff = function(mods, modDiffs)
    for statId, values in pairs(modDiffs) do
        for modType, value in pairs(values) do
            mods[statId][modType] = mH.round(mods[statId][modType] + value)
        end
    end
end

module.addModsDiff = function(mods, modDiffs)
    for statId, values in pairs(modDiffs) do
        for modType, value in pairs(values) do
            mods[statId][modType] = mH.round(mods[statId][modType] + value)
        end
    end
end

module.getModsCopy = function(mods)
    local copy = {}
    for statId, values in pairs(mods) do
        copy[statId] = {}
        for modType, value in pairs(values) do
            copy[statId][modType] = value
        end
    end
    return copy
end

module.addToMod = function(mod, value)
    if value > 0 then
        mod.pos = mH.round(mod.pos + value)
    else
        mod.neg = mH.round(mod.neg - value)
    end
    mod.mod = mod.mod + value
end

module.modStats = function(mods)
    local messages = {}
    for statId, values in pairs(mods) do
        local stat = T.NPC.stats[statTypes[statId]][statId](self)
        table.insert(messages, string.format("%s=(%d-%d)->(%d-%d) (%d+%d-%d=%d)",
                statId, stat.modifier, stat.damage, values.pos, values.neg, stat.base, stat.modifier, stat.damage, stat.modified))
        if stat.modifier ~= values.pos then
            stat.modifier = values.pos
        end
        if stat.damage ~= values.neg then
            stat.damage = values.neg
        end
    end
    log(string.format("Mod stats: %s", table.concat(messages, ", ")))
end

return module

