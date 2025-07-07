local T = require('openmw.types')

local D = require('scripts.BMSO.definition')
local S = require('scripts.BMSO.settings')

local module = {}

-- If some NPCs have too high or too low trading skills, you can override their level here, like the commented line for Arrille
module.npcLevelOverrides = {
    --["arrille"] = 5,
}

local statType = {
    skills = "skills",
    attributes = "attributes",
}

module.statTypes = {
    mercantile = statType.skills,
    speechcraft = statType.skills,
    personality = statType.attributes,
    luck = statType.attributes,
}

module.statsToRestore = {
    mercantile = true,
    speechcraft = true,
    luck = true,
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

module.getMod = function(stat)
    return stat.modified - stat.base
end

module.buffStats = function(actor, buffs)
    local messages = {}
    for _, buff in ipairs(buffs) do
        local stat = T.NPC.stats[module.statTypes[buff.statId]][buff.statId](actor)
        local prevStat = stat.modified
        local value = math.floor(buff.value + 0.5)
        if value < 0 then
            stat.damage = -value
            stat.modifier = 0
        else
            stat.damage = 0
            stat.modifier = value
        end
        table.insert(messages, string.format("%s=%d->%d (%.2f)", buff.statId, prevStat, stat.modified, stat.base + buff.value))
    end
    module.log(string.format("\"%s\"'s buffs: %s", actor.recordId, table.concat(messages, ", ")))
end

module.copyMap = function(map)
    local copy = {}
    for k, v in pairs(map) do
        copy[k] = v
    end
    return copy
end

return module

