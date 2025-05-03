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
    [skillsSettingsKey] = {
        key = skillsSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_skills",
        page = mDef.MOD_NAME,
        order = 1,
        description = "settingsDesc_skills",
        permanentStorage = false,
        settings = {
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
                key = "uncapperMaxValue",
                name = "uncapperMaxValue_name",
                description = "skillUncapperMaxValue_description",
                default = 1000,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "perSkillUncapper",
                name = "perSkillUncapper_name",
                description = "perSkillUncapper_description",
                default = nil,
                renderer = mDef.renderers.per_skill_uncapper,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "capSkillTraining",
                name = "capSkillTraining_name",
                description = "capSkillTraining_description",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "progressiveTrainingDuration",
                name = "progressiveTrainingDuration_name",
                description = "progressiveTrainingDuration_description",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "skillIncreaseFromBooks",
                name = "skillIncreaseFromBooks_name",
                description = "",
                default = true,
                renderer = "checkbox",
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
        order = 2,
        description = "settingsDesc_attributes",
        permanentStorage = false,
        settings = {
            {
                key = "startValuesRatio",
                name = "startValuesRatio_name",
                description = "startValuesRatio_description",
                default = "half",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "none", "quarter", "half", "threeQuarters", "full" },
                    values = { 0, 1 / 4, 1 / 2, 3 / 4, 1 },
                },
            },
            {
                key = "attributeGrowthRate",
                name = "attributeGrowthRate_name",
                description = "attributeGrowthRate_description",
                default = "attrGrowthSlow",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "attrGrowthSlow", "attrGrowthStandard", "attrGrowthFast" },
                    values = { 1, 2, 3 },
                },
            },
            {
                key = "luckGrowthRate",
                name = "luckGrowthRate_name",
                description = "luckGrowthRate_description",
                default = "luckGrowthLow",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "luckGrowthNone", "luckGrowthLow", "luckGrowthMed", "luckGrowthHigh" },
                    values = { 0, 1 / 4, 1 / 2, 1 },
                },
            },
            {
                key = "growthFactorFromMajorSkills",
                name = "growthFactorFromMajorSkills_name",
                description = "growthFactorFromMajorSkills_description",
                default = 100,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
            {
                key = "growthFactorFromMinorSkills",
                name = "growthFactorFromMinorSkills_name",
                description = "growthFactorFromMinorSkills_description",
                default = 100,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
            {
                key = "growthFactorFromMiscSkills",
                name = "growthFactorFromMiscSkills_name",
                description = "growthFactorFromMiscSkills_description",
                default = 50,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
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
        }
    },
    [healthSettingsKey] = {
        key = healthSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_health",
        page = mDef.MOD_NAME,
        order = 3,
        description = "settingsDesc_health",
        permanentStorage = false,
        settings = {
            {
                key = "stateBasedHP",
                name = "stateBasedHP_name",
                description = "stateBasedHP_description",
                default = false,
                renderer = "checkbox"
            },
            {
                key = "baseHPRatio",
                name = "baseHPRatio_name",
                description = "baseHPRatio_description",
                default = "full",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "full", "3/4", "1/2", "1/4" },
                    values = { 1, 3 / 4, 1 / 2, 1 / 4 },
                },
            },
            {
                key = "perLevelHPGain",
                name = "perLevelHPGain_name",
                description = "perLevelHPGain_description",
                default = "hpGrowthMed",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "hpGrowthNone", "hpGrowthLow", "hpGrowthMed", "hpGrowthHigh" },
                    values = { 0, 0.02, 0.04, 0.08 },
                },
            },
            {
                key = "deathCounter",
                name = "deathCounter_name",
                description = "deathCounter_description",
                default = false,
                renderer = "checkbox"
            },
        }
    },
    [mbspSettingsKey] = {
        key = mbspSettingsKey,
        l10n = mDef.MOD_NAME,
        name = "settingsTitle_MBSP",
        page = mDef.MOD_NAME,
        order = 4,
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
        order = 5,
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
                    description = mHelpers.areFloatEqual(record.skillGain[useType + 1], useConfig.vanilla)
                            and L("skillUsesVanilla_desc", { vanilla = useConfig.vanilla })
                            or L("skillUsesModded_desc", { vanilla = useConfig.vanilla, modded = record.skillGain[useType + 1] }),
                    default = useConfig.gain,
                    renderer = mDef.renderers.number,
                    argument = { min = 0, max = 100 },
                })
            end
        end
    end

    I.Settings.registerGroup(settingGroups[globalSettingsKey])
    I.Settings.registerGroup(settingGroups[skillsSettingsKey])
    I.Settings.registerGroup(settingGroups[attributesSettingsKey])
    I.Settings.registerGroup(settingGroups[healthSettingsKey])
    I.Settings.registerGroup(settingGroups[mbspSettingsKey])
    I.Settings.registerGroup(settingGroups[skillUsesSettingsKey])

    getStorage(skillsSettingsKey):subscribe(async:callback(function(_, key)
        if key == "skillDecayRate" then
            self:sendEvent(mDef.events.refreshDecay)
        elseif key == "uncapperMaxValue" or key == "perSkillUncapper" then
            self:sendEvent(mDef.events.updateGrowthAllAttrsOnResume)
        end
    end))

    getStorage(attributesSettingsKey):subscribe(async:callback(function(_, key)
        if key == "startValuesRatio" then
            self:sendEvent(mDef.events.updateStartAttrsOnResume)
        else
            self:sendEvent(mDef.events.updateGrowthAllAttrsOnResume)
        end
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
