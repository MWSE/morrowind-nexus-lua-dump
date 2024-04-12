local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local types = require('openmw.types')
local Player = require('openmw.types').Player
local dynamic = types.Actor.stats.dynamic

local S = require('scripts.NCGDMW.settings')
local H = require('scripts.NCGDMW.helpers')

local L = core.l10n(S.MOD_NAME)

local function debugPrint(str, ...)
    if S.playerGlobalStorage:get("debugMode") then
        local arg = { ... }
        if arg ~= nil then
            print(string.format("DEBUG: " .. str, unpack(arg)))
        else
            print("DEBUG: " .. str)
        end
    end
end

local ambient

if S.isLuaApiRecentEnough then
    ambient = require('openmw.ambient')
end

local hasStats = false
local baseSkills = {}
local maxSkills = {}
local attributeDiffs = {}
local baseAttributes = {}
local healthAttributes = {}
local startAttributes = {}

-- Map string values to numbers and back
local rateValues = {
    fast = 3,
    standard = 2,
    slow = 1,
    none = 0,
}

local rateMap = {
    [L("fast")] = rateValues.fast,
    [L("standard")] = rateValues.standard,
    [L("slow")] = rateValues.slow,
    [L("none")] = rateValues.none,
    [rateValues.fast] = L("fast"),
    [rateValues.standard] = L("standard"),
    [rateValues.slow] = L("slow"),
    [rateValues.none] = L("none")
}

-- Map lowercased, concatenated skill names to human-readable form
local skillsMap = {
    ["mediumarmor"] = "Medium Armor",
    ["heavyarmor"] = "Heavy Armor",
    ["bluntweapon"] = "Blunt Weapon",
    ["longblade"] = "Long Blade",
    ["lightarmor"] = "Light Armor",
    ["shortblade"] = "Short Blade",
    ["handtohand"] = "Hand To Hand",
}

local vanillaAttributes = {
    strength = "STR",
    intelligence = "INT",
    willpower = "WIL",
    agility = "AGI",
    speed = "SPE",
    endurance = "END",
    personality = "PER",
    luck = "LUK"
}

local affectedAttributes = {
    block = { strength = 2, agility = 1, endurance = 4 },
    armorer = { strength = 1, endurance = 4, personality = 2 },
    mediumarmor = { endurance = 4, speed = 2, willpower = 1 },
    heavyarmor = { strength = 1, endurance = 4, speed = 2 },
    bluntweapon = { strength = 4, endurance = 1, willpower = 2 },
    longblade = { strength = 2, agility = 4, speed = 1 },
    axe = { strength = 4, agility = 2, willpower = 1 },
    spear = { strength = 4, endurance = 2, speed = 1 },
    athletics = { endurance = 2, speed = 4, willpower = 1 },

    enchant = { intelligence = 4, willpower = 2, personality = 1 },
    destruction = { intelligence = 2, willpower = 4, personality = 1 },
    alteration = { speed = 1, intelligence = 2, willpower = 4 },
    illusion = { agility = 1, intelligence = 2, personality = 4 },
    conjuration = { intelligence = 4, willpower = 1, personality = 2 },
    mysticism = { intelligence = 4, willpower = 2, personality = 1 },
    restoration = { endurance = 1, willpower = 4, personality = 2 },
    alchemy = { endurance = 1, intelligence = 4, personality = 2 },
    unarmored = { endurance = 1, speed = 4, willpower = 2 },

    security = { agility = 4, intelligence = 2, personality = 1 },
    sneak = { agility = 4, speed = 1, personality = 2 },
    acrobatics = { strength = 1, agility = 2, speed = 4 },
    lightarmor = { agility = 1, endurance = 2, speed = 4 },
    shortblade = { agility = 4, speed = 2, personality = 1 },
    marksman = { strength = 4, agility = 2, speed = 1 },
    mercantile = { intelligence = 2, willpower = 1, personality = 4 },
    speechcraft = { intelligence = 1, willpower = 2, personality = 4 },
    handtohand = { strength = 4, agility = 2, endurance = 1 }
}

local skillProgress = {
    block = 0,
    armorer = 0,
    mediumarmor = 0,
    heavyarmor = 0,
    bluntweapon = 0,
    longblade = 0,
    axe = 0,
    spear = 0,
    athletics = 0,
    enchant = 0,
    destruction = 0,
    illusion = 0,
    alteration = 0,
    restoration = 0,
    mysticism = 0,
    conjuration = 0,
    alchemy = 0,
    unarmored = 0,
    security = 0,
    sneak = 0,
    acrobatics = 0,
    lightarmor = 0,
    shortblade = 0,
    marksman = 0,
    mercantile = 0,
    speechcraft = 0,
    handtohand = 0,
}

local skillNames = {
    block = 'Block',
    armorer = 'Armorer',
    mediumarmor = 'Medium Armor',
    heavyarmor = 'Heavy Armor',
    bluntweapon = 'Blunt Weapon',
    longblade = 'Long Blade',
    axe = 'Axe',
    spear = 'Spear',
    athletics = 'Athletics',
    enchant = 'Enchant',
    destruction = 'Destruction',
    illusion = 'Illusion',
    alteration = 'Alteration',
    restoration = 'Restoration',
    mysticism = 'Mysticism',
    conjuration = 'Conjuration',
    alchemy = 'Alchemy',
    unarmored = 'Unarmored',
    security = 'Security',
    sneak = 'Sneak',
    acrobatics = 'Acrobatics',
    lightarmor = 'Light Armor',
    shortblade = 'Short Blade',
    marksman = 'Marksman',
    mercantiile = 'Mercantile',
    speechcraft = 'Speechcraft',
    handtohand = 'Hand to Hand',
}

-- Common functions

local function maybePlaySound(sound, options)
    if S.isLuaApiRecentEnough then
        ambient.playSound(sound, options)
    end
end

local function totalGameTimeInHours()
    return core.getGameTime() / 60 / 60
end

local function getGrowthRateNum()
    return rateMap[L(S.playerAttributesStorage:get("growthRate"))]
end

local function getStat(kind, statId)
    return Player.stats[kind][statId](self).base
end

local function getStatName(kind, statId)
    if S.isLuaApiRecentEnough then
        if kind == "attributes" then
            return core.stats.Attribute.record(statId).name
        else
            return core.stats.Skill.record(statId).name
        end
    end
    local statName = H.capitalize(statId)
    if kind == "skills" then
        if skillsMap[statId] ~= nil then
            statName = skillsMap[statId]
        end
    end
    return statName
end

local function setStat(kind, statId, value)
    local current = Player.stats[kind][statId](self).base
    if current == value then return false end
    local toShow
    if kind == "attributes" then
        if value > current then
            toShow = "attrUp"
        elseif value < current then
            toShow = "attrDown"
        end
        baseAttributes[statId] = value
    elseif kind == "skills" then
        if value > current then
            toShow = "skillUp"
        elseif value < current then
            toShow = "skillDown"
        end
    end

    Player.stats[kind][statId](self).base = value
    ui.showMessage(L(toShow, { stat = getStatName(kind, statId), value = value }))
    return true
end

local function modStat(kind, stat, value)
    return setStat(kind, stat, Player.stats[kind][stat](self).base + value)
end

local function increaseSkill(skillId)
    modStat("skills", skillId, 1)
    maybePlaySound("skillraise")
end

local function modMagicka(amount)
    dynamic.magicka(self).current = dynamic.magicka(self).current + amount
end

local function onLoad(data)
    hasStats = data.hasStats
    baseSkills = data.baseSkills
    baseAttributes = data.baseAttributes
    healthAttributes = data.healthAttributes
    startAttributes = data.startAttributes
    maxSkills = data.maxSkills
    attributeDiffs = data.attributeDiffs
    skillProgress = data.skillProgress

    --Handle Loading Save Without Mod--
    for skillId, _ in pairs(skillProgress) do
        --If below vanilla skill cap, update skill progress for use in calculations
        if Player.stats.skills[skillId](self).base < 100 then
            if Player.stats.skills[skillId](self).progress > 0 then
                skillProgress[skillId] = Player.stats.skills[skillId](self).progress
            else
                Player.stats.skills[skillId](self).progress = skillProgress[skillId]
            end
            --If at or above vanilla skill cap, get current progress, then override
        elseif Player.stats.skills[skillId](self).progress > 0 then
            skillProgress[skillId] = Player.stats.skills[skillId](self).progress
            Player.stats.skills[skillId](self).progress = 0
        end
    end
end

local function onSave(data)
    data.hasStats = hasStats
    data.baseSkills = baseSkills
    data.baseAttributes = baseAttributes
    data.healthAttributes = healthAttributes
    data.startAttributes = startAttributes
    data.maxSkills = maxSkills
    data.attributeDiffs = attributeDiffs
    data.skillProgress = skillProgress
end

return {
    debugPrint = debugPrint,
    hasStats = function() return hasStats end,
    setHasStats = function(value) hasStats = value end,
    baseSkills = function() return baseSkills end,
    maxSkills = function() return maxSkills end,
    attributeDiffs = function() return attributeDiffs end,
    baseAttributes = function() return baseAttributes end,
    healthAttributes = function() return healthAttributes end,
    startAttributes = function() return startAttributes end,
    rateValues = function() return rateValues end,
    rateMap = function() return rateMap end,
    vanillaAttributes = function() return vanillaAttributes end,
    affectedAttributes = function() return affectedAttributes end,
    skillProgress = function() return skillProgress end,
    skillNames = function() return skillNames end,
    maybePlaySound = maybePlaySound,
    totalGameTimeInHours = totalGameTimeInHours,
    getGrowthRateNum = getGrowthRateNum,
    getStat = getStat,
    setStat = setStat,
    modStat = modStat,
    increaseSkill = increaseSkill,
    modMagicka = modMagicka,
    onLoad = onLoad,
    onSave = onSave,
}