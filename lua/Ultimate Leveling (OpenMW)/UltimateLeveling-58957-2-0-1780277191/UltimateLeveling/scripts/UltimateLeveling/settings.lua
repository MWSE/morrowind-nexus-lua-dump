local core = require('openmw.core')
local async = require('openmw.async')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')
local self = require('openmw.self')

local ulDef = require('scripts.UltimateLeveling.definition')

--local L = core.l10n(ulDef.MOD_NAME)

local globalSettingsKey = "SettingsPlayer" .. ulDef.MOD_NAME
local uncapperSettingsKey = "SettingsPlayerUncapper".. ulDef.MOD_NAME
local gameStartSettingsKey = "SettingsPlayerGameStart" .. ulDef.MOD_NAME
local levelSettingsKey = "SettingsPlayerLevel" .. ulDef.MOD_NAME
local attributesSettingsKey = "SettingsPlayerAttributes" .. ulDef.MOD_NAME
local healthSettingsKey = "SettingsPlayerHealth" .. ulDef.MOD_NAME

local settingGroups = {
    [globalSettingsKey] = {
        key = globalSettingsKey,
        l10n = ulDef.MOD_NAME,
        name = "settingsTitle",
        page = ulDef.MOD_NAME,
        order = 0,
        description = "settingsDesc",
        permanentStorage = false,
        settings = {
            {
                key = "statsMenuKey",
                name = "statsMenuKey_name",
                description = "statsMenuKey_description",
                default = nil,
                renderer = ulDef.renderers.hotkey,
            },
            {
                key = "statsMenuToggle",
                name = "statsMenuToggle_name",
                description = "statsMenuToggle_description",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "statsMenuWidth",
                name = "statsMenuWidth_name",
                description = "statsMenuWidth_description",
                default = 1400,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 800, max = 2000 },
            },
            --[[{
                key = "levelupScreenWidth",
                name = "levelupScreenWidth_name",
                description = "levelupScreenWidth_description",
                default = 400,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 300, max = 1000 },
            },--]]
            {
                key = "showMessagesLog",
                name = "showMessagesLog_name",
                description = "showMessagesLog_description",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "showStartupMessage",
                name = "showStartupMessage_name",
                description = "showStartupMessage_description",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "showDebugMessages",
                name = "showDebugMessages_name",
                description = "showDebugMessages_description",
                default = false,
                renderer = "checkbox"
            },
        }
    },
    [uncapperSettingsKey] = {
        key = uncapperSettingsKey,
        l10n = ulDef.MOD_NAME,
        name = "settingsTitle_uncapper",
        page = ulDef.MOD_NAME,
        order = 1,
        description = "settingsDesc_uncapper",
        permanentStorage = false,
        settings = {
            {
                key = "skillMaxValueUncapper",
                name = "skillMaxValueUncapper_name",
                description = "skillMaxValueUncapper_description",
                default = 100,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 5, max = 200 },
            },
            {
                key = "perSkillMaxValueUncapper",
                name = "perSkillMaxValueUncapper_name",
                description = "perSkillMaxValueUncapper_description",
                default = nil,
                renderer = ulDef.renderers.per_skill_uncapper,
                argument = { integer = true, min = 5, max = 200 },
            },
            {
                key = "attributeMaxValueUncapper",
                name = "attributeMaxValueUncapper_name",
                description = "attributeMaxValueUncapper_description",
                default = 1000,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "perAttributeMaxValueUncapper",
                name = "perAttributeMaxValueUncapper_name",
                description = "perAttributeMaxValueUncapper_description",
                default = nil,
                renderer = ulDef.renderers.per_attribute_uncapper,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "levelMaxValueUncapper",
                name = "levelMaxValueUncapper_name",
                description = "levelMaxValueUncapper_description",
                default = 100,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 1, max = 9999 },
            },
        }
    },
    [gameStartSettingsKey] = {
        key = gameStartSettingsKey,
        l10n = ulDef.MOD_NAME,
        name = "settingsTitle_gameStart",
        page = ulDef.MOD_NAME,
        order = 2,
        description = "settingsDesc_gameStart",
        permanentStorage = false,
        settings = {
            {
                key = "skillStartValue",
                name = "skillStartValue_name",
                description = "skillStartValue_description",
                default = 5,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "customSkillStartValueMultiplier",
                name = "customSkillStartValueMultiplier_name",
                description = "customSkillStartValueMultiplier_description",
                default = 1,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "specializationSkillStartBonus",
                name = "specializationSkillStartBonus_name",
                description = "specializationSkillStartBonus_description",
                default = 5,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "customSkillSpecializationStartBonusMultiplier",
                name = "customSkillSpecializationStartBonusMultiplier_name",
                description = "customSkillSpecializationStartBonusMultiplier_description",
                default = 1,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "raceSkillStartBonusMultiplier",
                name = "raceSkillStartBonusMultiplier_name",
                description = "raceSkillStartBonusMultiplier_description",
                default = 1,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "majorSkillStartBonus",
                name = "majorSkillStartBonus_name",
                description = "majorSkillStartBonus_description",
                default = 25,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "minorSkillStartBonus",
                name = "minorSkillStartBonus_name",
                description = "minorSkillStartBonus_description",
                default = 10,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "genderNeutralAttributeStartValue",
                name = "genderNeutralAttributeStartValue_name",
                description = "genderNeutralAttributeStartValue_description",
                default = false,
                renderer = "checkbox"
            },
            {
                key = "raceAttributeStartMultiplier",
                name = "raceAttributeStartMultiplier_name",
                description = "raceAttributeStartMultiplier_description",
                default = 1,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "favoredAttributeStartBonus",
                name = "favoredAttributeStartBonus_name",
                description = "favoredAttributeStartBonus_description",
                default = 10,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 0, max = 9999 },
            },
            {
                key = "attributeStartPenalty",
                name = "attributeStartPenalty_name",
                description = "attributeStartPenalty_description",
                default = 10,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = -9999, max = 9999 },
            },
            {
                key = "luckStartPenalty",
                name = "luckStartPenalty_name",
                description = "luckStartPenalty_description",
                default = 0,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = -9999, max = 9999 },
            },
        }
    },
    [attributesSettingsKey] = {
        key = attributesSettingsKey,
        l10n = ulDef.MOD_NAME,
        name = "settingsTitle_attributes",
        page = ulDef.MOD_NAME,
        order = 3,
        description = "settingsDesc_attributes",
        permanentStorage = false,
        settings = {
            {
                key = "attributeGrowthBase",
                name = "attributeGrowthBase_name",
                description = "attributeGrowthBase_description",
                default = 0.2,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "luckReputationGrowthBase",
                name = "luckReputationGrowthBase_name",
                description = "luckReputationGrowthBase_description",
                default = 0.5,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "majorSkillAttributeImpactFactor",
                name = "majorSkillAttributeImpactFactor_name",
                description = "majorSkillAttributeImpactFactor_description",
                default = 1.4,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "minorSkillAttributeImpactFactor",
                name = "minorSkillAttributeImpactFactor_name",
                description = "minorSkillAttributeImpactFactor_description",
                default = 1.2,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "miscSkillAttributeImpactFactor",
                name = "miscSkillAttributeImpactFactor_name",
                description = "miscSkillAttributeImpactFactor_description",
                default = 1.0,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "specializationSkillAttributeImpactFactor",
                name = "specializationSkillAttributeImpactFactor_name",
                description = "specializationSkillAttributeImpactFactor_description",
                default = 1.2,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "exponentSkillValueAttributeImpactFactor",
                name = "exponentSkillValueAttributeImpactFactor_name",
                description = "exponentSkillValueAttributeImpactFactor_description",
                default = 0.75,
                renderer = ulDef.renderers.number,
                argument = { min = -10, max = 10 },
            },
            {
                key = "favoredAttributeGrowthFactor",
                name = "favoredAttributeGrowthFactor_name",
                description = "favoredAttributeGrowthFactor_description",
                default = 1.5,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "exponentRacialAffinityAttributeGrowthFactor",
                name = "exponentRacialAffinityAttributeGrowthFactor_name",
                description = "exponentRacialAffinityAttributeGrowthFactor_description",
                default = 0.5,
                renderer = ulDef.renderers.number,
                argument = { min = -10, max = 10 },
            },
        }
    },
    [levelSettingsKey] = {
        key = levelSettingsKey,
        l10n = ulDef.MOD_NAME,
        name = "settingsTitle_level",
        page = ulDef.MOD_NAME,
        order = 4,
        description = "settingsDesc_level",
        permanentStorage = false,
        settings = {
            {
                key = "sleepLevelup",
                name = "sleepLevelup_name",
                description = "sleepLevelup_description",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "trainingLevelCapper",
                name = "trainingLevelCapper_name",
                description = "trainingLevelCapper_description",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "trainingLevelCapperValue",
                name = "trainingLevelCapperValue_name",
                description = "trainingLevelCapperValue_description",
                default = 7,
                renderer = ulDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "majorSkillLevelImpactFactor",
                name = "majorSkillLevelImpactFactor_name",
                description = "majorSkillLevelImpactFactor_description",
                default = 40,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 100 },
            },
            {
                key = "minorSkillLevelImpactFactor",
                name = "minorSkillLevelImpactFactor_name",
                description = "minorSkillLevelImpactFactor_description",
                default = 35,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 100 },
            },
            {
                key = "miscSkillLevelImpactFactor",
                name = "miscSkillLevelImpactFactor_name",
                description = "miscSkillLevelImpactFactor_description",
                default = 25,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 100 },
            },
            {
                key = "exponentSkillValueLevelImpactFactor",
                name = "exponentSkillValueLevelImpactFactor_name",
                description = "exponentSkillValueLevelImpactFactor_description",
                default = 0.5,
                renderer = ulDef.renderers.number,
                argument = { min = -10, max = 10 },
            },
        }
    },
    [healthSettingsKey] = {
        key = healthSettingsKey,
        l10n = ulDef.MOD_NAME,
        name = "settingsTitle_health",
        page = ulDef.MOD_NAME,
        order = 5,
        description = "settingsDesc_health",
        permanentStorage = false,
        settings = {
            {
                key = "healthMultiplier",
                name = "healthMultiplier_name",
                description = "healthMultiplier_description",
                default = 1,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "retroactiveHealthMultiplier",
                name = "retroactiveHealthMultiplier_name",
                description = "retroactiveHealthMultiplier_description",
                default = 0.05,
                renderer = ulDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
        }
    },
}

local function getStorage(key)
    return storage.playerSection(key)
end

local function initSettings()
    I.Settings.registerPage {
        key = ulDef.MOD_NAME,
        l10n = ulDef.MOD_NAME,
        name = "name",
        description = "description"
    }

    I.Settings.registerGroup(settingGroups[globalSettingsKey])
    I.Settings.registerGroup(settingGroups[uncapperSettingsKey])
    I.Settings.registerGroup(settingGroups[gameStartSettingsKey])
    I.Settings.registerGroup(settingGroups[levelSettingsKey])
    I.Settings.registerGroup(settingGroups[attributesSettingsKey])
    I.Settings.registerGroup(settingGroups[healthSettingsKey])

    getStorage(uncapperSettingsKey):subscribe(async:callback(function(_, key)
        if string.find(string.lower(key), "skill") then
            self:sendEvent(ulDef.events.updateStartSkills, { baseStart = false, clearAll = false })
        elseif string.find(string.lower(key), "attribute") then
            self:sendEvent(ulDef.events.updateStartAttrs, { clearAll = false })
        else
            self:sendEvent(ulDef.events.updateLevel)
        end
    end))

    getStorage(gameStartSettingsKey):subscribe(async:callback(function(_, key)
        if string.find(string.lower(key), "skill") then
            self:sendEvent(ulDef.events.updateStartSkills, { baseStart = false, clearAll = false })
        else
            self:sendEvent(ulDef.events.updateStartAttrs, { clearAll = false })
        end
    end))

    getStorage(attributesSettingsKey):subscribe(async:callback(function(_, key)
        if string.find(string.lower(key), "skill") then
            self:sendEvent(ulDef.events.updateStats)
        else
            self:sendEvent(ulDef.events.updateAttributes)
        end
    end))

    getStorage(levelSettingsKey):subscribe(async:callback(function(_, key)
        if string.find(string.lower(key), "skill") then
            self:sendEvent(ulDef.events.updateStats)
        else
            self:sendEvent(ulDef.events.updateLevel)
        end
    end))

    getStorage(healthSettingsKey):subscribe(async:callback(function(_, _)
        self:sendEvent(ulDef.events.updateHealth)
    end))
end

local getSkillMaxValue = function(skillId)
    for _, item in ipairs(getStorage(uncapperSettingsKey):get("perSkillMaxValueUncapper") or {}) do
        if item.key == skillId then
            return tonumber(item.value)
        end
    end
    return getStorage(uncapperSettingsKey):get("skillMaxValueUncapper")
end

local getAttributeMaxValue = function(attrId)
    for _, item in ipairs(getStorage(uncapperSettingsKey):get("perAttributeMaxValueUncapper") or {}) do
        if item.key == attrId then
            return tonumber(item.value)
        end
    end
    return getStorage(uncapperSettingsKey):get("attributeMaxValueUncapper")
end

local getPerStatMaxValue = function(settingKey)
    local map = {}
    for _, item in ipairs(getStorage(uncapperSettingsKey):get(settingKey) or {}) do
        map[item.key] = tonumber(item.value)
    end
    return map
end

local getTypeSkillLevelImpactFactorSum = function()
    local levelStorage = getStorage(levelSettingsKey)
    local SLIF = "SkillLevelImpactFactor"
    local sum = 0
    for _, type in ipairs({ "major", "minor", "misc" }) do
        sum = sum + levelStorage:get(type .. SLIF)
    end
    return sum
end

return {
    initSettings = initSettings,
    -- Storages
    globalStorage = getStorage(globalSettingsKey),
    uncapperStorage = getStorage(uncapperSettingsKey),
    gameStartStorage = getStorage(gameStartSettingsKey),
    levelStorage = getStorage(levelSettingsKey),
    attributesStorage = getStorage(attributesSettingsKey),
    healthStorage = getStorage(healthSettingsKey),
    getSkillMaxValue = function(skillId)
        return getSkillMaxValue(skillId)
    end,
    getPerSkillMaxValue = function()
        return getPerStatMaxValue("perSkillMaxValueUncapper")
    end,
    getAttributeMaxValue = function(attrId)
        return getAttributeMaxValue(attrId)
    end,
    getPerAttributeMaxValue = function()
        return getPerStatMaxValue("perAttributeMaxValueUncapper")
    end,
    getTypeSkillLevelImpactFactorSum = function()
        return getTypeSkillLevelImpactFactorSum()
    end,
}
