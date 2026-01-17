local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')
local util = require('openmw.util')

local log = require("scripts.BMS.util.log")
local mDef = require('scripts.BMS.config.definition')

local Skills = core.stats.Skill.records
local Attributes = core.stats.Attribute.records

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
    [Skills.mercantile.id] = statType.skills,
    [Skills.speechcraft.id] = statType.skills,
    [Attributes.personality.id] = statType.attributes,
    [Attributes.luck.id] = statType.attributes,
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
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

module.isObjectInvalid = function(object)
    return not object or not object:isValid() or object.count == 0
end

local function getMod(stat)
    return util.round(stat.modifier - stat.damage)
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

module.getStatsDiff = function(stats1, stats2)
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

module.applyModsDiff = function(mods, diffs)
    for statId, value in pairs(diffs) do
        mods[statId] = mods[statId] + value
    end
end

module.modStats = function(mods)
    local messages = {}
    for statId, value in pairs(mods) do
        local stat = T.NPC.stats[statTypes[statId]][statId](self)
        local prevModifier = stat.modifier
        local prevDamage = stat.damage
        local modifier, damage
        if value < 0 then
            modifier = 0
            damage = -value
        else
            modifier = value
            damage = 0
        end
        if stat.modifier ~= modifier then
            stat.modifier = modifier
        end
        if stat.damage ~= damage then
            stat.damage = damage
        end
        table.insert(messages, string.format("%s=(%d-%d)->(%d-%d) (%d+%d-%d=%d)",
                statId, prevModifier, prevDamage, stat.modifier, stat.damage, stat.base, stat.modifier, stat.damage, stat.modified))
    end
    log(string.format("Mod stats: %s", table.concat(messages, ", ")))
end

return module

