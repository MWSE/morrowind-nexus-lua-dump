local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local types = require('openmw.types')
local Player = require('openmw.types').Player
local dynamic = types.Actor.stats.dynamic

local def = require('scripts.NCGDMW.definition')
local cfg = require('scripts.NCGDMW.configuration')
local S = require('scripts.NCGDMW.settings')
local H = require('scripts.NCGDMW.helpers')

local L = core.l10n(def.MOD_NAME)

local function debugPrint(str)
    if S.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end

local ambient

if def.isLuaApiRecentEnough then
    ambient = require('openmw.ambient')
end

local hasStats = false
local baseSkills = {}
local baseAttributes = {}
local startAttributes = {}
local fortifiedHealthV48 = 0
local maxSkills = H.initNewTable(0, Player.stats.skills)
local skillProgress = H.initNewTable(0, Player.stats.skills)
local decaySkills = H.initNewTable(0, Player.stats.skills)
local attributeDiffs = H.initNewTable(0, Player.stats.attributes)
local messagesLog = {}

-- Map lowercased, concatenated skill names to human-readable form
local skillsMapV48 = {
    ["mediumarmor"] = "Medium Armor",
    ["heavyarmor"] = "Heavy Armor",
    ["bluntweapon"] = "Blunt Weapon",
    ["longblade"] = "Long Blade",
    ["lightarmor"] = "Light Armor",
    ["shortblade"] = "Short Blade",
    ["handtohand"] = "Hand To Hand",
}

local starwindSkills = {
    alchemy = true,
    alteration = true,
    armorer = true,
    conjuration = true,
    destruction = true,
    enchant = true,
    illusion = true,
    mysticism = true,
    restoration = true,
    spear = true,
}

local skillsBySchool = {
    combat = { "block", "armorer", "mediumarmor", "heavyarmor", "bluntweapon", "longblade", "axe", "spear", "athletics" },
    magic = { "enchant", "destruction", "alteration", "illusion", "conjuration", "mysticism", "restoration", "alchemy", "unarmored" },
    stealth = { "security", "sneak", "acrobatics", "lightarmor", "shortblade", "marksman", "mercantile", "speechcraft", "handtohand" },
}

local skillIdToSchool = {}
for type, skills in pairs(skillsBySchool) do
    for _, skillId in ipairs(skills) do
        skillIdToSchool[skillId] = type
    end
end

local magickaSkills = {
    destruction = true,
    restoration = true,
    conjuration = true,
    mysticism = true,
    illusion = true,
    alteration = true,
}

-- Common functions

local function init()
    baseSkills = {}
    maxSkills = H.initNewTable(0, Player.stats.skills)
    decaySkills = H.initNewTable(0, Player.stats.skills)
    baseAttributes = {}
    startAttributes = {}
    attributeDiffs = attributeDiffs or {}
end

local function showMessage(message)
    ui.showMessage(message, {showInDialogue = false})
    table.insert(messagesLog, 1, { message = message, time = os.date("%H:%M:%S") })
    if #messagesLog > 11 then
        table.remove(messagesLog)
    end
end

local function maybePlaySound(sound, options)
    if def.isLuaApiRecentEnough then
        ambient.playSound(sound, options)
    end
end

local function totalGameTimeInHours()
    return core.getGameTime() / 60 / 60
end

local currentSerializedBaseStatsMods

local function getBaseStatsModifiers()
    local baseStatsMods = { attributes = {}, skills = {} }
    if not def.isLuaApiRecentEnough then return baseStatsMods end
    for _, spell in pairs(Player.activeSpells(self)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                local kind, statId
                if effect.affectedAttribute ~= nil and effect.id == "fortifyattribute" then
                    kind = "attributes"
                    statId = effect.affectedAttribute
                elseif effect.affectedSkill ~= nil and effect.id == "fortifyskill" then
                    kind = "skills"
                    statId = effect.affectedSkill
                end
                if kind ~= nil then
                    baseStatsMods[kind][statId] = (baseStatsMods[kind][statId] or 0) + effect.magnitudeThisFrame
                end
            end
        end
    end
    if next(baseStatsMods.attributes) or next(baseStatsMods.skills) then
        local serializedBaseStatsMods = H.tableOfTablesToString(baseStatsMods)
        if serializedBaseStatsMods ~= currentSerializedBaseStatsMods then
            currentSerializedBaseStatsMods = serializedBaseStatsMods
            debugPrint(string.format("Detected base statistics modifiers: %s", serializedBaseStatsMods))
        end
    end
    return baseStatsMods
end

local function getSkillGainFactorIfDecay(skillId)
    local skillLostLevels = maxSkills[skillId] - baseSkills[skillId]
    return skillLostLevels > 0 and cfg.decayLostLevelsSkillGainFact(skillLostLevels) or 1
end

-- Slow down decay based on skill gain
-- Will benefit from MBSP skill gain boost
-- Won't be affected by skill gain reduction settings
local function slowDownSkillDecayOnSkillUsed(skillId, skillGain)
    decaySkills[skillId] = math.max(0, decaySkills[skillId] - (skillGain * cfg.decayRecoveredHoursPerSkillUsed))
    if cfg.decayRecoveredHoursPerSkillUsedSynergyFactor ~= 0 then
        for _, otherSkillId in ipairs(skillsBySchool[skillIdToSchool[skillId]]) do
            if otherSkillId ~= skillId then
                decaySkills[otherSkillId] = math.max(0, decaySkills[otherSkillId]
                        - (skillGain * cfg.decayRecoveredHoursPerSkillUsed * cfg.decayRecoveredHoursPerSkillUsedSynergyFactor))
            end
        end
    end
end

local function slowDownSkillDecayOnSkillLevelUp(skillId)
    decaySkills[skillId] = decaySkills[skillId] * cfg.slowDownSkillDecayOnSkillLevelUpFactor
end

local function getMaxHealthModifier()
    if not def.isLuaApiRecentEnough then
        return fortifiedHealthV48
    end
    local healthMod = 0
    for _, spell in pairs(Player.activeSpells(self)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                if effect.id == "fortifyhealth" then
                    healthMod = healthMod + effect.magnitudeThisFrame
                end
            end
        end
    end
    if healthMod ~= 0 then
        debugPrint(string.format("Detected max health modifier: %d", healthMod))
    end
    return healthMod
end

local function getStat(kind, statId)
    return Player.stats[kind][statId](self).base
end

local function getStatName(kind, statId)
    if kind == "skills" and S.globalStorage:get("starwindNames") and starwindSkills[statId] then
        return L("starwind_" .. statId)
    end
    if def.isLuaApiRecentEnough then
        if kind == "attributes" then
            return core.stats.Attribute.record(statId).name
        else
            return core.stats.Skill.record(statId).name
        end
    end
    local statName = H.capitalize(statId)
    if kind == "skills" then
        if skillsMapV48[statId] ~= nil then
            statName = skillsMapV48[statId]
        end
    end
    return statName
end

local function setStat(kind, statId, value)
    local current = Player.stats[kind][statId](self).base
    local baseStatsMods = getBaseStatsModifiers()
    local realBase = value - (baseStatsMods[kind][statId] or 0)
    local toShow
    if kind == "attributes" then
        if value > current then
            toShow = "attrUp"
        elseif value < current then
            toShow = "attrDown"
        end
        baseAttributes[statId] = realBase
    elseif kind == "skills" then
        if value > current then
            toShow = "skillUp"
        elseif value < current then
            toShow = "skillDown"
        end
    end
    if current == value then return false end

    Player.stats[kind][statId](self).base = value
    showMessage(L(toShow, { stat = getStatName(kind, statId), value = realBase }))
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
    hasStats = data.hasStats or false
    baseSkills = data.baseSkills
    baseAttributes = data.baseAttributes
    startAttributes = data.startAttributes
    fortifiedHealthV48 = data.fortifiedHealthV48 or 0
    maxSkills = data.maxSkills or maxSkills
    skillProgress = data.skillProgress or {}
    decaySkills = data.decaySkills or decaySkills
    attributeDiffs = data.attributeDiffs or attributeDiffs
    messagesLog = data.messagesLog or {}

    --Handle Loading Save Without Mod--
    for skillId, _ in pairs(Player.stats.skills) do
        --If below vanilla skill cap, update skill progress for use in calculations
        if Player.stats.skills[skillId](self).base < 100 then
            if Player.stats.skills[skillId](self).progress > 0 or skillProgress[skillId] == nil then
                skillProgress[skillId] = Player.stats.skills[skillId](self).progress
            else
                Player.stats.skills[skillId](self).progress = skillProgress[skillId]
            end
            --If at or above vanilla skill cap, get current progress, then override
        elseif Player.stats.skills[skillId](self).progress > 0 then
            skillProgress[skillId] = Player.stats.skills[skillId](self).progress
        end
    end
end

local function onSave(data)
    data.hasStats = hasStats
    data.baseSkills = baseSkills
    data.baseAttributes = baseAttributes
    data.startAttributes = startAttributes
    data.fortifiedHealthV48 = fortifiedHealthV48
    data.maxSkills = maxSkills
    data.skillProgress = skillProgress
    data.decaySkills = decaySkills
    data.attributeDiffs = attributeDiffs
    data.messagesLog = messagesLog
end

return {
    debugPrint = debugPrint,
    hasStats = function() return hasStats end,
    setHasStats = function(value) hasStats = value end,
    baseSkills = function() return baseSkills end,
    baseAttributes = function() return baseAttributes end,
    startAttributes = function() return startAttributes end,
    setFortifiedHealthV48 = function(value) fortifiedHealthV48 = value end,
    maxSkills = function() return maxSkills end,
    skillProgress = function() return skillProgress end,
    decaySkills = function() return decaySkills end,
    attributeDiffs = function() return attributeDiffs end,
    messagesLog = function() return messagesLog end,
    skillsBySchool = function() return skillsBySchool end,
    skillIdToSchool = function() return skillIdToSchool end,
    magickaSkills = magickaSkills,
    init = init,
    showMessage = showMessage,
    maybePlaySound = maybePlaySound,
    totalGameTimeInHours = totalGameTimeInHours,
    getBaseStatsModifiers = getBaseStatsModifiers,
    getSkillGainFactorIfDecay = getSkillGainFactorIfDecay,
    slowDownSkillDecayOnSkillUsed = slowDownSkillDecayOnSkillUsed,
    slowDownSkillDecayOnSkillLevelUp = slowDownSkillDecayOnSkillLevelUp,
    getMaxHealthModifier = getMaxHealthModifier,
    getStat = getStat,
    getStatName = getStatName,
    setStat = setStat,
    modStat = modStat,
    increaseSkill = increaseSkill,
    modMagicka = modMagicka,
    onLoad = onLoad,
    onSave = onSave,
}