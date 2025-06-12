local core = require('openmw.core')
local async = require('openmw.async')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')
local self = require('openmw.self')

local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mHelpers = require('scripts.NCGDMW.helpers')

local L = core.l10n(mDef.MOD_NAME)

local globalSettingsKey = "SettingsPlayer" .. mDef.MOD_NAME
local gameStartSettingsKey = "SettingsPlayerGameStart" .. mDef.MOD_NAME
local levelSettingsKey = "SettingsPlayerLevel" .. mDef.MOD_NAME
local skillsSettingsKey = "SettingsPlayerSkills" .. mDef.MOD_NAME
local attributesSettingsKey = "SettingsPlayerAttributes" .. mDef.MOD_NAME
local healthSettingsKey = "SettingsPlayerHealth" .. mDef.MOD_NAME
local mbspSettingsKey = "SettingsPlayerMBSP" .. mDef.MOD_NAME
local skillUsesSettingsKey = "SettingsPlayerSkillUses" .. mDef.MOD_NAME

local settingGroups = {
    [globalSettingsKey] = {
        key = globalSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle",
        page = mDef.MOD_NAME,
        order = 0,
        description = "settingsDesc",
        permanentStorage = false,
        settings = {
            {
                key = "statsMenuKey",
                name = "statsMenuKey_name",
                description = "statsMenuKey_description",
                default = nil,
                renderer = mDef.renderers.hotkey,
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
                default = 1100,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 800, max = 2000 },
            },
            --[[{
                key = "trackReadBooks",
                name = "trackReadBooks_name",
                description = "trackReadBooks_description",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "trackReadBooksInventory",
                name = "trackReadBooksInventory_name",
                description = "trackReadBooksInventory_description",
                default = true,
                renderer = "checkbox"
            },--]]
            {
                key = "showMessagesLog",
                name = "showMessagesLog_name",
                description = "showMessagesLog_description",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "showIntro",
                name = "showIntro_name",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "debugMode",
                name = "debugMode_name",
                default = false,
                renderer = "checkbox"
            },
        }
    },
    [gameStartSettingsKey] = {
        key = gameStartSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_gameStart",
        page = mDef.MOD_NAME,
        order = 1,
        description = "settingsDesc_gameStart",
        permanentStorage = false,
        settings = {
            {
                key = "startSkillValue",
                name = "startSkillValue_name",
                description = "startSkillValue_description",
                default = 5,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 1, max = 200 },
            },
            {
                key = "startSpecializationBonus",
                name = "startSpecializationBonus_name",
                description = "startSpecializationBonus_description",
                default = 5,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 200 },
            },
            {
                key = "startRaceSkillBonusMultiplier",
                name = "startRaceSkillBonusMultiplier_name",
                description = "startRaceSkillBonusMultiplier_description",
                default = 1,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "startMajorSkillBonus",
                name = "startMajorSkillBonus_name",
                description = "startMajorSkillBonus_description",
                default = 25,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 200 },
            },
            {
                key = "startMinorSkillBonus",
                name = "startMinorSkillBonus_name",
                description = "startMinorSkillBonus_description",
                default = 10,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 200 },
            },
            {
                key = "startRaceAttributeMultiplier",
                name = "startRaceAttributeMultiplier_name",
                description = "startRaceAttributeMultiplier_description",
                default = 1,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "startFavoredAttributeBonus",
                name = "startFavoredAttributeBonus_name",
                description = "startFavoredAttributeBonus_description",
                default = 10,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 9999 },
            },
            {
                key = "startAttributesPenalty",
                name = "startAttributesPenalty_name",
                description = "startAttributesPenalty_description",
                default = 15,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = -9999, max = 29 },
            },
            {
                key = "startLuckPenalty",
                name = "startLuckPenalty_name",
                description = "startLuckPenalty_description",
                default = 0,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = -9999, max = 29 },
            },
        }
    },
    [levelSettingsKey] = {
        key = levelSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_level",
        page = mDef.MOD_NAME,
        order = 2,
        description = "settingsDesc_level",
        permanentStorage = false,
        settings = {
            {
                key = "uncapperMaxValue",
                name = "uncapperMaxValue_name",
                description = "levelUncapperMaxValue_description",
                default = 100,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 1, max = 9999 },
            },
            {
                key = "levelFactorFromMajorSkills",
                name = "levelFactorFromMajorSkills_name",
                description = "levelFactorFromMajorSkills_description",
                default = 40,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 100 },
            },
            {
                key = "levelFactorFromMinorSkills",
                name = "levelFactorFromMinorSkills_name",
                description = "levelFactorFromMinorSkills_description",
                default = 35,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 100 },
            },
            {
                key = "levelFactorFromMiscSkills",
                name = "levelFactorFromMiscSkills_name",
                description = "levelFactorFromMiscSkills_description",
                default = 25,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 100 },
            },
            {
                key = "exponentLevelSkillLevel",
                name = "exponentLevelSkillLevel_name",
                description = "exponentLevelSkillLevel_description",
                default = 0.5,
                renderer = mDef.renderers.number,
                argument = { min = -10, max = 10 },
            },
        }
    },
    [skillsSettingsKey] = {
        key = skillsSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_skills",
        page = mDef.MOD_NAME,
        order = 3,
        description = "settingsDesc_skills",
        permanentStorage = false,
        settings = {
            {
                key = "uncapperMaxValue",
                name = "uncapperMaxValue_name",
                description = "skillUncapperMaxValue_description",
                default = 100,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 5, max = 200 },
            },
            {
                key = "perSkillUncapper",
                name = "perSkillUncapper_name",
                description = "perSkillUncapper_description",
                default = nil,
                renderer = mDef.renderers.per_skill_uncapper,
                argument = { integer = true, min = 5, max = 200 },
            },
            {
                key = "skillDecayRate",
                name = "skillDecayRate_name",
                description = "skillDecayRate_description",
                default = "skillDecayNone",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "skillDecayNone", "skillDecaySlow", "skillDecayStandard", "skillDecayFast" },
                    values = { 0, 1, 2, 3 },
                },
            },
            {
                key = "capSkillTrainingLevel",
                name = "capSkillTrainingLevel_name",
                description = "capSkillTrainingLevel_description",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "capSkillTrainingLevelValue",
                name = "capSkillTrainingLevelValue_name",
                description = "capSkillTrainingLevelValue_description",
                default = 6,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "progressiveTrainingDuration",
                name = "progressiveTrainingDuration_name",
                description = "progressiveTrainingDuration_description",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "skillTrainingValue",
                name = "skillTrainingValue_name",
                description = "skillTrainingValue_description",
                default = 1,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "skillBooksInventory",
                name = "skillBooksInventory_name",
                description = "skillBooksInventory_description",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "skillBooksMax",
                name = "skillBooksMax_name",
                description = "skillBooksMax_description",
                default = 5,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "skillBooksExp",
                name = "skillBooksExp_name",
                description = "skillBooksExp_description",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "skillBooksExpValue",
                name = "skillBooksExpValue_name",
                description = "skillBooksExpValue_description",
                default = 4,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "skillBooksSkillupValue",
                name = "skillBooksSkillupValue_name",
                description = "skillBooksSkillupValue_description",
                default = 1,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "skillGainFactorRange",
                name = "skillGainFactorRange_name",
                description = "skillGainFactorRange_description",
                default = { 125, 25 },
                renderer = mDef.renderers.logRange,
                argument = { min = 1, max = 1000 },
            },
            {
                key = "carryOverExcessSkillGain",
                name = "carryOverExcessSkillGain_name",
                description = "carryOverExcessSkillGain_description",
                default = true,
                renderer = "checkbox",
            },
        }
    },
    [attributesSettingsKey] = {
        key = attributesSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_attributes",
        page = mDef.MOD_NAME,
        order = 4,
        description = "settingsDesc_attributes",
        permanentStorage = false,
        settings = {
            {
                key = "uncapperMaxValue",
                name = "uncapperMaxValue_name",
                description = "attributeUncapperMaxValue_description",
                default = 1000,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "perAttributeUncapper",
                name = "perAttributeUncapper_name",
                description = "perAttributeUncapper_description",
                default = nil,
                renderer = mDef.renderers.per_attribute_uncapper,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "attributeGrowthBase",
                name = "attributeGrowthBase_name",
                description = "attributeGrowthBase_description",
                default = 0.2,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "luckReputationGrowthBase",
                name = "luckReputationGrowthBase_name",
                description = "luckReputationGrowthBase_description",
                default = 0.5,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "growthFactorFromMajorSkills",
                name = "growthFactorFromMajorSkills_name",
                description = "growthFactorFromMajorSkills_description",
                default = 1.4,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "growthFactorFromMinorSkills",
                name = "growthFactorFromMinorSkills_name",
                description = "growthFactorFromMinorSkills_description",
                default = 1.2,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "growthFactorFromMiscSkills",
                name = "growthFactorFromMiscSkills_name",
                description = "growthFactorFromMiscSkills_description",
                default = 1.0,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "growthFactorFromSpecialization",
                name = "growthFactorFromSpecialization_name",
                description = "growthFactorFromSpecialization_description",
                default = 1.2,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "growthFactorFromFavoredAttribute",
                name = "growthFactorFromFavoredAttribute_name",
                description = "growthFactorFromFavoredAttribute_description",
                default = 1.5,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "growthFactorFromLuckFavoredAttribute",
                name = "growthFactorFromLuckFavoredAttribute_name",
                description = "growthFactorFromLuckFavoredAttribute_description",
                default = 1.5,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "exponentRacialAffinity",
                name = "exponentRacialAffinity_name",
                description = "exponentRacialAffinity_description",
                default = 0.5,
                renderer = mDef.renderers.number,
                argument = { min = -10, max = 10 },
            },
            {
                key = "exponentAttributeSkillLevel",
                name = "exponentAttributeSkillLevel_name",
                description = "exponentAttributeSkillLevel_description",
                default = 0.75,
                renderer = mDef.renderers.number,
                argument = { min = -10, max = 10 },
            },
        }
    },
    [healthSettingsKey] = {
        key = healthSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_health",
        page = mDef.MOD_NAME,
        order = 5,
        description = "settingsDesc_health",
        permanentStorage = false,
        settings = {
            {
                key = "healthMultiplier",
                name = "healthMultiplier_name",
                description = "healthMultiplier_description",
                default = 1,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            {
                key = "retroactiveHealthMultiplier",
                name = "retroactiveHealthMultiplier_name",
                description = "retroactiveHealthMultiplier_description",
                default = 0.05,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 10 },
            },
            --[[{
                key = "deathCounter",
                name = "deathCounter_name",
                description = "deathCounter_description",
                default = false,
                renderer = "checkbox"
            },--]]
        }
    },
    [mbspSettingsKey] = {
        key = mbspSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_MBSP",
        page = mDef.MOD_NAME,
        order = 6,
        description = "settingsDesc_MBSP",
        permanentStorage = false,
        settings = {
            {
                key = "mbspEnabled",
                name = "mbspEnabled_name",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "magickaXPRate",
                name = "magickaXPRate_name",
                description = "magickaXPRate_desc",
                default = "10",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "5", "10", "15", "20", "25" },
                },
            },
            {
                key = "refundEnabled",
                name = "refundEnabled_name",
                description = "refundEnabled_desc",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "refundMult",
                name = "refundMult_name",
                description = "refundMult_desc",
                default = "4",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "1", "2", "3", "4", "5" },
                },
            },
            {
                key = "refundStart",
                name = "refundStart_name",
                description = "refundStart_desc",
                default = 35,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 1, max = 1000 },
            },
        }
    },
    [skillUsesSettingsKey] = {
        key = skillUsesSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_SkillUses",
        description = "settingsDesc_SkillUses",
        page = mDef.MOD_NAME,
        order = 7,
        permanentStorage = false,
        settings = {}
    },
}

local function getStorage(key)
    return storage.playerSection(key)
end

local function getSetting(groupKey, settingKey)
    local group = settingGroups[groupKey]
    if group ~= nil then
        for _, setting in ipairs(group.settings) do
            if setting.key == settingKey then
                return setting
            end
        end
    end
    print(string.format("Cannot find setting %s in group %s", settingKey, groupKey))
    return nil
end

local function getSettingSelectValue(groupKey, settingKey, item)
    local setting = getSetting(groupKey, settingKey)
    if setting ~= nil then
        for i, value in ipairs(setting.argument.items) do
            if value == item then
                return setting.argument.values[i]
            end
        end
    end
    return nil
end

local function getSkillUsesKey(skillId, useType)
    return string.format("skillUse-%s-%s", skillId, mCfg.skillUseTypes[skillId][useType].key)
end

local function initSettings()
    I.Settings.registerPage {
        key = mDef.MOD_NAME,
        l10n = mDef.MOD_NAME,
        name = "name",
        description = "description"
    }

    for _, specialization in ipairs({ mDef.skillTypes.combat, mDef.skillTypes.magic, mDef.skillTypes.stealth }) do
        for _, skillId in ipairs(mDef.skillsBySchool[specialization]) do
            for useType, useConfig in pairs(mCfg.skillUseTypes[skillId]) do
                local key = getSkillUsesKey(skillId, useType)
                local record = core.stats.Skill.records[skillId]
                table.insert(settingGroups[skillUsesSettingsKey].settings, {
                    key = key,
                    name = L("skillUses_name", { skill = record.name, useType = L(string.format("skillUseType_%s", useConfig.key)) }),
                    description = mHelpers.areFloatEqual(useConfig.gain, useConfig.vanilla)
                            and L("skillUsesVanilla_desc", { vanilla = useConfig.vanilla })
                            or L("skillUses_desc", { vanilla = useConfig.vanilla, default = useConfig.gain }),
                    default = useConfig.gain,
                    renderer = mDef.renderers.number,
                    argument = { min = 0, max = 100 },
                })
            end
        end
    end

    I.Settings.registerGroup(settingGroups[globalSettingsKey])
    I.Settings.registerGroup(settingGroups[gameStartSettingsKey])
    I.Settings.registerGroup(settingGroups[levelSettingsKey])
    I.Settings.registerGroup(settingGroups[skillsSettingsKey])
    I.Settings.registerGroup(settingGroups[attributesSettingsKey])
    I.Settings.registerGroup(settingGroups[healthSettingsKey])
    I.Settings.registerGroup(settingGroups[mbspSettingsKey])
    I.Settings.registerGroup(settingGroups[skillUsesSettingsKey])

    getStorage(gameStartSettingsKey):subscribe(async:callback(function(_, _)
        self:sendEvent(mDef.events.updateStartAttrsOnResume)
    end))

    getStorage(levelSettingsKey):subscribe(async:callback(function(_, _)
        self:sendEvent(mDef.events.updateGrowthAllAttrsOnResume)
    end))

    getStorage(skillsSettingsKey):subscribe(async:callback(function(_, key)
        if key == "skillDecayRate" then
            self:sendEvent(mDef.events.refreshDecay)
        elseif key == "uncapperMaxValue" or key == "perSkillUncapper" then
            self:sendEvent(mDef.events.updateStartAttrsOnResume)
        elseif key == "capSkillTrainingLevel" or key == "capSkillTrainingLevelValue" or key == "skillBooksMax" or key == "skillBooksExpValue" then
            self:sendEvent(mDef.events.updateGrowthAllAttrsOnResume)
        end
    end))

    getStorage(attributesSettingsKey):subscribe(async:callback(function(_, _)
        self:sendEvent(mDef.events.updateGrowthAllAttrsOnResume)
    end))

    getStorage(healthSettingsKey):subscribe(async:callback(function(_, _)
        self:sendEvent(mDef.events.updateGrowthAllAttrsOnResume)
    end))
end

local getStatMaxValue = function(statId, groupKey, settingKey)
    for _, item in ipairs(getStorage(groupKey):get(settingKey) or {}) do
        if item.key == statId then
            return tonumber(item.value)
        end
    end
    return getStorage(groupKey):get("uncapperMaxValue")
end

local getPerStatMaxValues = function(groupKey, settingKey)
    local map = {}
    for _, item in ipairs(getStorage(groupKey):get(settingKey) or {}) do
        map[item.key] = tonumber(item.value)
    end
    return map
end

return {
    initSettings = initSettings,
    -- Storages
    globalStorage = getStorage(globalSettingsKey),
    gameStartStorage = getStorage(gameStartSettingsKey),
    levelStorage = getStorage(levelSettingsKey),
    skillsStorage = getStorage(skillsSettingsKey),
    attributesStorage = getStorage(attributesSettingsKey),
    healthStorage = getStorage(healthSettingsKey),
    mbspStorage = getStorage(mbspSettingsKey),
    -- Select key to values converters
    getSkillDecayRates = function(key)
        return getSettingSelectValue(skillsSettingsKey, "skillDecayRate", key)
    end,
    getAttributeStartValuesRatio = function(key)
        return getSettingSelectValue(attributesSettingsKey, "startValuesRatio", key)
    end,
    getAttributeGrowthRates = function(key)
        return getSettingSelectValue(attributesSettingsKey, "attributeGrowthRate", key)
    end,
    getLuckGrowthRate = function(key)
        return getSettingSelectValue(attributesSettingsKey, "luckGrowthRate", key)
    end,
    getBaseHPRatioFactor = function(key)
        return getSettingSelectValue(healthSettingsKey, "baseHPRatio", key)
    end,
    getPerLevelHPGainFactor = function(key)
        return getSettingSelectValue(healthSettingsKey, "perLevelHPGain", key)
    end,
    getSkillMaxValue = function(skillId)
        return getStatMaxValue(skillId, skillsSettingsKey, "perSkillUncapper")
    end,
    getPerSkillMaxValues = function()
        return getPerStatMaxValues(skillsSettingsKey, "perSkillUncapper")
    end,
    getAttributeMaxValue = function(attrId)
        return getStatMaxValue(attrId, attributesSettingsKey, "perAttributeUncapper")
    end,
    getPerAttributeMaxValues = function()
        return getPerStatMaxValues(attributesSettingsKey, "perAttributeUncapper")
    end,
    getSkillUseGain = function(skillId, useType)
        return getStorage(skillUsesSettingsKey):get(getSkillUsesKey(skillId, useType))
    end,
}
