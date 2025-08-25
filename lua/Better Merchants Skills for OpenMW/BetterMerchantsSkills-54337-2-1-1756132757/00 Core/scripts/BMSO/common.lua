local core = require('openmw.core')
local T = require('openmw.types')

local D = require('scripts.BMSO.definition')
local S = require('scripts.BMSO.settings')

local Skills = core.stats.Skill.records
local Attributes = core.stats.Attribute.records

local module = {}

-- If some NPCs have too high or too low trading skills, you can override their level here, like the commented line for Arrille
module.npcLevelOverrides = {
    --["arrille"] = 5,
}

module.round = function(value)
    return math.floor(value + 0.5)
end

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

module.copyMap = function(map)
    local copy = {}
    for k, v in pairs(map) do
        copy[k] = v
    end
    return copy
end

module.getDescriptionIfOpenMWTooOld = function(key)
    if not D.isLuaApiRecentEnough then
        if D.isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

module.log = function(str)
    if S.storage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end

local function getMod(stat)
    return module.round(stat.modifier - stat.damage)
end

module.getMods = function(actor)
    local mods = {}
    for statId, type in pairs(statTypes) do
        mods[statId] = getMod(T.NPC.stats[type][statId](actor))
    end
    return mods
end

module.statsToString = function(stats)
    local parts = {}
    for statId, value in pairs(stats) do
        table.insert(parts, string.format("%s=%d", statId, value))
    end
    return table.concat(parts, ", ")
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

module.modStats = function(actor, mods)
    local messages = {}
    for statId, value in pairs(mods) do
        local stat = T.NPC.stats[statTypes[statId]][statId](actor)
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
    module.log(string.format("\"%s\"'s stats: %s", actor.recordId, table.concat(messages, ", ")))
end

module.copyMap = function(map)
    local copy = {}
    for k, v in pairs(map) do
        copy[k] = v
    end
    return copy
end

return module

