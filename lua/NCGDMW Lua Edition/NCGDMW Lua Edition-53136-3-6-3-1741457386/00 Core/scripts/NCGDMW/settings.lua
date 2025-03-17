local core = require('openmw.core')
local async = require('openmw.async')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')
local self = require('openmw.self')

local def = require('scripts.NCGDMW.definition')
local L = core.l10n(def.MOD_NAME)
local cfg = require('scripts.NCGDMW.configuration')
local H = require('scripts.NCGDMW.helpers')

local globalSettingsKey = "SettingsPlayer" .. def.MOD_NAME
local skillsSettingsKey = "SettingsPlayerSkills" .. def.MOD_NAME
local attributesSettingsKey = "SettingsPlayerAttributes" .. def.MOD_NAME
local mbspSettingsKey = "SettingsPlayerMBSP" .. def.MOD_NAME
local skillUsesSettingsKey = "SettingsPlayerSkillUses" .. def.MOD_NAME

local settingGroups = {
    [globalSettingsKey] = {
        key = globalSettingsKey,
        l10n = def.MOD_NAME,
        name = "settingsTitle",
        page = def.MOD_NAME,
        order = 0,
        description = "settingsDesc",
        permanentStorage = false,
        settings = {
            {
                key = "statsMenuKey",
                name = "statsMenuKey_name",
                default = nil,
                renderer = def.renderers.hotkey,
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
                key = "starwindNames",
                name = "starwindNames_name",
                default = false,
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
        l10n = def.MOD_NAME,
        name = "settingsTitle_skills",
        page = def.MOD_NAME,
        order = 1,
        description = "settingsDesc_skills",
        permanentStorage = false,
        settings = {
            {
                key = "uncapperMaxValue",
                name = "uncapperMaxValue_name",
                description = "skillUncapperMaxValue_description",
                renderer = def.renderers.number,
                default = 1000,
                argument = { integer = true, min = 5, max = 1000 },
            },
            {
                key = "perSkillUncapper",
                name = "perSkillUncapper_name",
                description = "perSkillUncapper_description",
                default = nil,
                renderer = def.renderers.per_skill_uncapper,
                argument = { integer = true, min = 5, max = 1000 },
            },
            {
                key = "decayRate",
                name = "decayRate_name",
                description = "decayRate_description",
                default = "none",
                argument = {
                    l10n = def.MOD_NAME,
                    items = { "fast", "standard", "slow", "none" },
                    values = { 3, 2, 1, 0 },
                },
                renderer = "select"
            },
            {
                key = "skillIncreaseFromBooks",
                name = "skillIncreaseFromBooks_name",
                description = "",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "skillIncreaseConstantFactor",
                name = "skillIncreaseConstantFactor_name",
                description = "skillIncreaseConstantFactor_description",
                default = "vanilla",
                argument = {
                    l10n = def.MOD_NAME,
                    items = { "vanilla", "half", "quarter" },
                    values = { 1, 2, 4 },
                },
                renderer = "select",
            },
            {
                key = "skillIncreaseSquaredLevelFactor",
                name = "skillIncreaseSquaredLevelFactor_name",
                description = "skillIncreaseSquaredLevelFactor_description",
                default = "disabled",
                argument = {
                    l10n = def.MOD_NAME,
                    items = { "disabled", "downToHalf", "downToAQuarter", "downToAEighth" },
                    values = { 1, 2, 4, 8 },
                },
                renderer = "select",
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
        l10n = def.MOD_NAME,
        name = "settingsTitle_attributes",
        page = def.MOD_NAME,
        order = 2,
        description = "settingsDesc_attributes",
        permanentStorage = false,
        settings = {
            {
                key = "growthRate",
                name = "growthRate_name",
                default = "slow",
                argument = {
                    l10n = def.MOD_NAME,
                    items = { "fast", "standard", "slow" },
                    values = { 3, 2, 1 },
                },
                renderer = "select"
            },
            {
                key = "uncapperMaxValue",
                name = "uncapperMaxValue_name",
                description = "attributeUncapperMaxValue_description",
                renderer = def.renderers.number,
                default = 1000,
                argument = { integer = true, min = 5, max = 1000 },
            },
            {
                key = "perAttributeUncapper",
                name = "perAttributeUncapper_name",
                description = "perAttributeUncapper_description",
                default = nil,
                renderer = def.renderers.per_attribute_uncapper,
                argument = { integer = true, min = 5, max = 1000 },
            },
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
                argument = {
                    l10n = def.MOD_NAME,
                    items = { "full", "3/4", "1/2", "1/4" },
                    values = { 1, 3 / 4, 1 / 2, 1 / 4 },
                },
                renderer = "select"
            },
            {
                key = "perLevelHPGain",
                name = "perLevelHPGain_name",
                description = "perLevelHPGain_description",
                default = "high",
                argument = {
                    l10n = def.MOD_NAME,
                    items = { "high", "low" }
                },
                renderer = "select"
            },
        }
    },
    [mbspSettingsKey] = {
        key = mbspSettingsKey,
        l10n = def.MOD_NAME,
        name = "settingsTitle_MBSP",
        page = def.MOD_NAME,
        order = 3,
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
                argument = {
                    l10n = def.MOD_NAME,
                    items = { "5", "10", "15", "20", "25" },
                },
                renderer = "select",
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
                argument = {
                    l10n = def.MOD_NAME,
                    items = { "1", "2", "3", "4", "5" },
                },
                renderer = "select",
            },
            {
                key = "refundStart",
                name = "refundStart_name",
                description = "refundStart_desc",
                default = 35,
                renderer = def.renderers.number,
                argument = { integer = true, min = 1, max = 1000 },
            },
        }
    },
    [skillUsesSettingsKey] = {
        key = skillUsesSettingsKey,
        l10n = def.MOD_NAME,
        name = "settingsTitle_SkillUses",
        description = "settingsDesc_SkillUses",
        page = def.MOD_NAME,
        order = 4,
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
    return string.format("skillUse-%s-%s", skillId, cfg.skillUseTypes[skillId][useType].key)
end

local function initSettings()
    I.Settings.registerPage {
        key = def.MOD_NAME,
        l10n = def.MOD_NAME,
        name = "name",
        description = "description"
    }

    for _, specialization in ipairs({ def.skillTypes.combat, def.skillTypes.magic, def.skillTypes.stealth }) do
        for _, skillId in ipairs(def.skillsBySchool[specialization]) do
            for useType, useConfig in pairs(cfg.skillUseTypes[skillId]) do
                local key = getSkillUsesKey(skillId, useType)
                local record = core.stats.Skill.records[skillId]
                table.insert(settingGroups[skillUsesSettingsKey].settings, {
                    key = key,
                    name = L("skillUses_name", { skill = record.name, useType = L(string.format("skillUseType_%s", useConfig.key)) }),
                    description = H.areFloatEqual(record.skillGain[useType + 1], useConfig.vanilla)
                            and L("skillUsesVanilla_desc", { vanilla = useConfig.vanilla })
                            or L("skillUsesModded_desc", { vanilla = useConfig.vanilla, modded = record.skillGain[useType + 1] }),
                    default = useConfig.gain,
                    renderer = def.renderers.number,
                    argument = { min = 0, max = 100 },
                })
            end
        end
    end

    I.Settings.registerGroup(settingGroups[globalSettingsKey])
    I.Settings.registerGroup(settingGroups[skillsSettingsKey])
    I.Settings.registerGroup(settingGroups[attributesSettingsKey])
    I.Settings.registerGroup(settingGroups[mbspSettingsKey])
    I.Settings.registerGroup(settingGroups[skillUsesSettingsKey])

    getStorage(skillsSettingsKey):subscribe(async:callback(function(_, key)
        if key == "decayRate" then
            self:sendEvent(def.events.refreshDecay)
        elseif key == "uncapperMaxValue" or key == "perSkillUncapper" then
            self:sendEvent(def.events.updateProfileOnUpdate)
        end
    end))

    getStorage(attributesSettingsKey):subscribe(async:callback(function(_, _)
        self:sendEvent(def.events.updateProfileOnUpdate)
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
    mbspStorage = getStorage(mbspSettingsKey),
    -- Select key to values converters
    getSkillDecayRates = function(key)
        return getSettingSelectValue(skillsSettingsKey, "decayRate", key)
    end,
    getSkillIncreaseConstantFactor = function(key)
        return getSettingSelectValue(skillsSettingsKey, "skillIncreaseConstantFactor", key)
    end,
    getSkillIncreaseSquaredLevelFactor = function(key)
        return getSettingSelectValue(skillsSettingsKey, "skillIncreaseSquaredLevelFactor", key)
    end,
    getAttributeGrowthRates = function(key)
        return getSettingSelectValue(attributesSettingsKey, "growthRate", key)
    end,
    getBaseHPRatioFactor = function(key)
        return getSettingSelectValue(attributesSettingsKey, "baseHPRatio", key)
    end,
    getSkillMaxValue = function(skillId)
        return getStatMaxValue(skillId, skillsSettingsKey, "perSkillUncapper")
    end,
    getPerSkillMaxValues = function()
        return getPerStatMaxValues(skillsSettingsKey, "perSkillUncapper")
    end,
    getAttributeMaxValue = function(attributeId)
        return getStatMaxValue(attributeId, attributesSettingsKey, "perAttributeUncapper")
    end,
    getPerAttributeMaxValues = function()
        return getPerStatMaxValues(attributesSettingsKey, "perAttributeUncapper")
    end,
    getSkillUseGain = function(skillId, useType)
        return getStorage(skillUsesSettingsKey):get(getSkillUsesKey(skillId, useType))
    end,
}