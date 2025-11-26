local core = require('openmw.core')
local async = require('openmw.async')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')
local self = require('openmw.self')

local mDef = require('scripts.skill-evolution.config.definition')
local mCfg = require('scripts.skill-evolution.config.configuration')
local mH = require('scripts.skill-evolution.util.helpers')

local L = core.l10n(mDef.MOD_NAME)

local globalSettingsKey = "SettingsPlayer" .. mDef.MOD_NAME
local magickaSettingsKey = "SettingsPlayerMagicka" .. mDef.MOD_NAME
local skillsSettingsKey = "SettingsPlayerSkills" .. mDef.MOD_NAME
local skillUsesScaledSettingsKey = "SettingsPlayerSkillUsesScaled" .. mDef.MOD_NAME
local skillUsesGainsSettingsKey = "SettingsPlayerSkillUsesGains" .. mDef.MOD_NAME

local module = {}

local settingGroups = {
    [globalSettingsKey] = {
        order = 0,
        settings = {
            {
                key = "debugMode",
                description = false,
                default = false,
                renderer = "checkbox"
            },
        }
    },
    [skillsSettingsKey] = {
        order = 1,
        settings = {
            {
                key = "skillLevelBasedScalingRange",
                default = { 125, 25 },
                renderer = mDef.renderers.range,
                argument = { min = 1, max = 1000, log = mDef.logRangeTypes.skillLevelBasedScalingRange, desc = true, percent = true },
            },
            {
                key = "skillUncapper",
                default = 1000,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "perSkillUncapper",
                default = nil,
                renderer = mDef.renderers.perSkillUncapper,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "skillDecayRate",
                default = "skillDecaySlow",
                renderer = mDef.renderers.decayRate,
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "skillDecayNone", "skillDecayVerySlow", "skillDecaySlow", "skillDecayStandard", "skillDecayFast" },
                    values = { 0, 1, 2, 4, 8 },
                },
            },
            {
                key = "skillDecayReductionRate",
                default = "skillDecayReductionStandard",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "skillDecayReductionSlow", "skillDecayReductionStandard", "skillDecayReductionFast" },
                    values = { 0.5, 1, 2 },
                },
            },
            {
                key = "skillDecayIntelligenceFactor",
                default = 0,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 5 },
            },
            {
                key = "capSkillTraining",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "scaledTrainingDuration",
                default = true,
                renderer = "checkbox",
                default = { 2, 16 },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 48, log = mDef.logRangeTypes.scaledTrainingDuration, desc = false, percent = false },
            },
            {
                key = "skillIncreaseFromBooks",
                description = false,
                default = true,
                renderer = "checkbox",
            },
            {
                key = "carryOverExcessSkillGain",
                default = true,
                renderer = "checkbox",
            },
        }
    },
    [skillUsesScaledSettingsKey] = {
        order = 2,
        settings = {
            {
                key = "skillScalingDebugNotifsEnabled",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "magickaBasedSkillScalingEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "magickaBasedSkillScalingRange",
                description = false,
                default = { mCfg.minScaledSkillGainPercent, mCfg.maxScaledSkillGainPercent },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 200, percent = true },
            },
            {
                key = "weaponSkillScalingEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "weaponSkillScalingRange",
                description = false,
                default = { mCfg.minScaledSkillGainPercent, mCfg.maxScaledSkillGainPercent },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 200, percent = true },
            },
            {
                key = "armorSkillScalingEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "armorSkillScalingRange",
                description = false,
                default = { mCfg.minScaledSkillGainPercent, 400 },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 400, percent = true },
            },
            {
                key = "blockSkillScalingEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "blockSkillScalingRange",
                description = false,
                default = { mCfg.minScaledSkillGainPercent, 400 },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 400, percent = true },
            },
            {
                key = "securitySkillScalingEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "securitySkillScalingRange",
                description = false,
                default = { mCfg.minScaledSkillGainPercent, mCfg.maxScaledSkillGainPercent },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 200, percent = true },
            },
            {
                key = "acrobaticsSkillScalingEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "acrobaticsSkillScalingRange",
                description = false,
                default = { 0, 400 },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 400, percent = true },
            },
            {
                key = "athleticsSkillScalingEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "athleticsSkillScalingRange",
                description = false,
                default = { mCfg.minScaledSkillGainPercent, mCfg.maxScaledSkillGainPercent },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 200, percent = true },
            },
            {
                key = "alchemySkillScalingEnabled",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "alchemySkillScalingRange",
                description = false,
                default = { mCfg.minScaledSkillGainPercent, 250 },
                renderer = mDef.renderers.range,
                argument = { min = 0, max = 350, percent = true },
            },
        }
    },
    [skillUsesGainsSettingsKey] = {
        order = 3,
        settings = {}
    },
    [magickaSettingsKey] = {
        order = 4,
        settings = {
            {
                key = "refundEnabled",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "refundMult",
                default = "4",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "1", "2", "3", "4", "5" },
                },
            },
            {
                key = "refundStart",
                default = 35,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 1, max = 1000 },
            },
            {
                key = "mbspEnabled",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "mbspRate",
                default = 10,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 1, max = 100 },
            },
        }
    },
}

for key, group in pairs(settingGroups) do
    group.key = key
    group.page = mDef.MOD_NAME
    group.name = key .. "_name"
    group.description = key .. "_desc"
    group.l10n = mDef.MOD_NAME
    group.permanentStorage = false
    for _, setting in ipairs(group.settings) do
        setting.name = setting.key .. "_name"
        if setting.description ~= false then
            setting.description = setting.key .. "_desc"
        else
            setting.description = nil
        end
    end
end

local function getSkillUsesKey(skillId, useType)
    return string.format("skillUse-%s-%s", skillId, mCfg.skillUseTypes[skillId][useType].key)
end

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

local function getSettingSelectValue(groupKey, settingKey)
    local curr = getStorage(groupKey):get(settingKey)
    local setting = getSetting(groupKey, settingKey)
    if setting ~= nil then
        for i, value in ipairs(setting.argument.items) do
            if value == curr then
                return setting.argument.values[i], curr
            end
        end
    end
    return nil, nil
end

local getSkillMaxValue = function(statId, groupKey, settingKey)
    for _, item in ipairs(getStorage(groupKey):get(settingKey) or {}) do
        if item.key == statId then
            return tonumber(item.value)
        end
    end
    return getStorage(groupKey):get("skillUncapper")
end

local getPerSkillsMaxValues = function(groupKey, settingKey)
    local map = {}
    for _, item in ipairs(getStorage(groupKey):get(settingKey) or {}) do
        map[item.key] = tonumber(item.value)
    end
    return map
end

-- Select key to values converters
module.getSkillMaxValue = function(skillId)
    return getSkillMaxValue(skillId, skillsSettingsKey, "perSkillUncapper")
end
module.getPerSkillMaxValues = function()
    return getPerSkillsMaxValues(skillsSettingsKey, "perSkillUncapper")
end
module.getSkillUsesScaledRange = function(key)
    local range = getStorage(skillUsesScaledSettingsKey):get(key)
    return { min = range[1] / 100, max = range[2] / 100 }
end
module.getSkillUseGain = function(skillId, useType)
    return getStorage(skillUsesGainsSettingsKey):get(getSkillUsesKey(skillId, useType))
end
module.getSkillDecayRate = function()
    return getSettingSelectValue(skillsSettingsKey, "skillDecayRate")
end
module.getSkillDecayReductionRate = function()
    return getSettingSelectValue(skillsSettingsKey, "skillDecayReductionRate")
end

local function updateSkillScalingSettings()
    if getStorage(skillUsesScaledSettingsKey):get("magickaBasedSkillScalingEnabled") then
        getStorage(magickaSettingsKey):set("mbspEnabled", false)
    end
end

local function updateMagickaSettings()
    if getStorage(magickaSettingsKey):get("mbspEnabled") then
        getStorage(skillUsesScaledSettingsKey):set("magickaBasedSkillScalingEnabled", false)
    end
end

module.init = function()
    for _, skill in ipairs(core.stats.Skill.records) do
        for useType, useConfig in mH.spairs(mCfg.skillUseTypes[skill.id], function(_, a, b) return a < b end) do
            local key = getSkillUsesKey(skill.id, useType)
            table.insert(settingGroups[skillUsesGainsSettingsKey].settings, {
                key = key,
                name = L("skillUses_name", { skill = skill.name, useType = L(string.format("skillUseType_%s", useConfig.key)) }),
                description = mH.areFloatEqual(skill.skillGain[useType + 1], useConfig.vanilla)
                        and L("skillUsesVanilla_desc", { vanilla = useConfig.vanilla })
                        or L("skillUsesModded_desc", { vanilla = useConfig.vanilla, modded = skill.skillGain[useType + 1] }),
                default = useConfig.gain,
                renderer = mDef.renderers.number,
                argument = { min = 0, max = 100 },
            })
        end
    end

    module.globalStorage = getStorage(globalSettingsKey)
    module.skillsStorage = getStorage(skillsSettingsKey)
    module.skillUsesScaledStorage = getStorage(skillUsesScaledSettingsKey)
    module.skillUsesGainsStorage = getStorage(skillUsesGainsSettingsKey)
    module.magickaStorage = getStorage(magickaSettingsKey)

    I.Settings.registerPage {
        key = mDef.MOD_NAME,
        l10n = mDef.MOD_NAME,
        name = "name",
        description = "description"
    }

    I.Settings.registerGroup(settingGroups[globalSettingsKey])
    I.Settings.registerGroup(settingGroups[skillsSettingsKey])
    I.Settings.registerGroup(settingGroups[skillUsesScaledSettingsKey])
    I.Settings.registerGroup(settingGroups[skillUsesGainsSettingsKey])
    I.Settings.registerGroup(settingGroups[magickaSettingsKey])

    getStorage(skillsSettingsKey):subscribe(async:callback(function(_, key)
        if key == "skillDecayRate" then
            self:sendEvent(mDef.events.changeDecayRate)
        end
    end))

    getStorage(skillUsesScaledSettingsKey):subscribe(async:callback(function(_, _)
        updateSkillScalingSettings()
    end))

    getStorage(magickaSettingsKey):subscribe(async:callback(function(_, _)
        updateMagickaSettings()
    end))

    updateSkillScalingSettings()
    updateMagickaSettings()
end

return module