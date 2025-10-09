local core = require('openmw.core')
local async = require('openmw.async')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')
local self = require('openmw.self')

local mDef = require('scripts.NCGDMW.definition')
local mCfg = require('scripts.NCGDMW.configuration')
local mH = require('scripts.NCGDMW.helpers')

local L = core.l10n(mDef.MOD_NAME)

local globalSettingsKey = "SettingsPlayer" .. mDef.MOD_NAME
local attributesSettingsKey = "SettingsPlayerAttributes" .. mDef.MOD_NAME
local healthSettingsKey = "SettingsPlayerHealth" .. mDef.MOD_NAME
local magickaSettingsKey = "SettingsPlayerMagicka" .. mDef.MOD_NAME
local skillsSettingsKey = "SettingsPlayerSkills" .. mDef.MOD_NAME
local skillUsesScaledSettingsKey = "SettingsPlayerSkillUsesScaled" .. mDef.MOD_NAME
local skillUsesSettingsKey = "SettingsPlayerSkillUses" .. mDef.MOD_NAME

local module = {}

local settingGroups = {
    [globalSettingsKey] = {
        order = 0,
        settings = {
            {
                key = "statsMenuKey",
                default = nil,
                renderer = mDef.renderers.hotkey,
            },
            {
                key = "statsMenuWidth",
                default = 1100,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 800, max = 2000 },
            },
            {
                key = "showMessagesLog",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "showIntro",
                description = false,
                default = true,
                renderer = "checkbox"
            },
            {
                key = "debugMode",
                description = false,
                default = false,
                renderer = "checkbox"
            },
        }
    },
    [attributesSettingsKey] = {
        order = 1,
        settings = {
            {
                key = "startValuesRatio",
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
                default = 100,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
            {
                key = "growthFactorFromMinorSkills",
                default = 100,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
            {
                key = "growthFactorFromMiscSkills",
                default = 50,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
            {
                key = "uncapperMaxValue",
                description = false,
                default = 1000,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 5, max = 9999 },
            },
            {
                key = "perAttributeUncapper",
                default = nil,
                renderer = mDef.renderers.perAttributeUncapper,
                argument = { integer = true, min = 5, max = 9999 },
            },
        }
    },
    [healthSettingsKey] = {
        order = 2,
        settings = {
            {
                key = "stateBasedHP",
                default = false,
                renderer = "checkbox"
            },
            {
                key = "baseHPRatio",
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
                default = false,
                renderer = "checkbox"
            },
            {
                key = "luckModifierPerDeath",
                default = -1,
                renderer = mDef.renderers.number,
                argument = { min = -10, max = 10 },
            },
        }
    },
    [magickaSettingsKey] = {
        order = 3,
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
    [skillsSettingsKey] = {
        order = 4,
        settings = {
            {
                key = "classSkillPointsPerLevelUp",
                default = 10,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 1, max = 100 },
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
                key = "uncapperMaxValue",
                description = false,
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
                key = "skillGainFactorRange",
                default = { 125, 25 },
                renderer = mDef.renderers.range,
                argument = { min = 1, max = 1000, log = mDef.logRangeTypes.skillGainFactorRange, desc = true, percent = true },
            },
            {
                key = "carryOverExcessSkillGain",
                default = true,
                renderer = "checkbox",
            },
        }
    },
    [skillUsesScaledSettingsKey] = {
        order = 5,
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
    [skillUsesSettingsKey] = {
        order = 6,
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

module.getSkillUsesKey = function(skillId, useType)
    return string.format("skillUse-%s-%s", skillId, mCfg.skillUseTypes[skillId][useType].key)
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

module.globalStorage = getStorage(globalSettingsKey)
module.attributesStorage = getStorage(attributesSettingsKey)
module.healthStorage = getStorage(healthSettingsKey)
module.magickaStorage = getStorage(magickaSettingsKey)
module.skillsStorage = getStorage(skillsSettingsKey)
module.skillUsesScaledStorage = getStorage(skillUsesScaledSettingsKey)
module.skillUsesStorage = getStorage(skillUsesSettingsKey)

-- Select key to values converters
module.getSkillDecayRates = function(key)
    return getSettingSelectValue(skillsSettingsKey, "skillDecayRate", key)
end
module.getSkillDecayReductionRates = function(key)
    return getSettingSelectValue(skillsSettingsKey, "skillDecayReductionRate", key)
end
module.getAttributeStartValuesRatio = function(key)
    return getSettingSelectValue(attributesSettingsKey, "startValuesRatio", key)
end
module.getAttributeGrowthRates = function(key)
    return getSettingSelectValue(attributesSettingsKey, "attributeGrowthRate", key)
end
module.getLuckGrowthRate = function(key)
    return getSettingSelectValue(attributesSettingsKey, "luckGrowthRate", key)
end
module.getBaseHPRatioFactor = function(key)
    return getSettingSelectValue(healthSettingsKey, "baseHPRatio", key)
end
module.getPerLevelHPGainFactor = function(key)
    return getSettingSelectValue(healthSettingsKey, "perLevelHPGain", key)
end
module.getSkillMaxValue = function(skillId)
    return getStatMaxValue(skillId, skillsSettingsKey, "perSkillUncapper")
end
module.getPerSkillMaxValues = function()
    return getPerStatMaxValues(skillsSettingsKey, "perSkillUncapper")
end
module.getAttributeMaxValue = function(attrId)
    return getStatMaxValue(attrId, attributesSettingsKey, "perAttributeUncapper")
end
module.getPerAttributeMaxValues = function()
    return getPerStatMaxValues(attributesSettingsKey, "perAttributeUncapper")
end
module.getSkillGainScaledRange = function(key)
    local range = getStorage(skillUsesScaledSettingsKey):get(key)
    return { min = range[1] / 100, max = range[2] / 100 }
end
module.getSkillUseGain = function(skillId, useType)
    return getStorage(skillUsesSettingsKey):get(module.getSkillUsesKey(skillId, useType))
end

module.convertOldSettingValues = function()
    local conversions = {
        {
            storage = module.attributesStorage,
            key = "attributeGrowthRate",
            values = { slow = "attrGrowthSlow", standard = "attrGrowthStandard", fast = "attrGrowthFast" }
        },
        {
            storage = module.healthStorage,
            key = "perLevelHPGain",
            values = { high = "hpGrowthHigh", low = "hpGrowthMed" }
        },
    }
    for _, upgrade in ipairs(conversions) do
        local newValue = upgrade.values[upgrade.storage:get(upgrade.key)]
        if newValue then
            upgrade.storage:set(upgrade.key, newValue)
        end
    end
end

module.migrateOldSettings = function(oldVersion)
    if oldVersion < 4.11 then
        local convert = { none = "skillDecayNone", slow = "skillDecaySlow", standard = "skillDecayStandard", fast = "skillDecayFast" }
        local newValue = convert[module.skillsStorage:get("decayRate")]
        if newValue then
            module.skillsStorage:set("skillDecayRate", newValue)
        end
    end

    if oldVersion < 4.14 then
        local constFactor = module.skillsStorage:get("skillIncreaseConstantFactor")
        local expFactor = module.skillsStorage:get("skillIncreaseSquaredLevelFactor")
        if constFactor and expFactor then
            local convert = { vanilla = 1, half = 1 / 2, quarter = 1 / 4, disabled = 1, downToHalf = 1 / 2, downToAQuarter = 1 / 4, downToAEighth = 1 / 8 }
            module.skillsStorage:set("skillGainFactorRange", { convert[constFactor] * 100, convert[constFactor] * convert[expFactor] * 100 })
        end
    end

    if oldVersion < 4.3 then
        local mbsp = storage.playerSection("SettingsPlayerMBSPNCGDMW")
        module.magickaStorage:set("refundEnabled", mbsp:get("refundEnabled"))
        module.magickaStorage:set("refundMult", mbsp:get("refundMult"))
        module.magickaStorage:set("refundStart", mbsp:get("refundStart"))
    end

    return true
end

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

for _, skill in ipairs(core.stats.Skill.records) do
    for useType, useConfig in mH.spairs(mCfg.skillUseTypes[skill.id], function(_, a, b) return a < b end) do
        local key = module.getSkillUsesKey(skill.id, useType)
        table.insert(settingGroups[skillUsesSettingsKey].settings, {
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

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description"
}

I.Settings.registerGroup(settingGroups[globalSettingsKey])
I.Settings.registerGroup(settingGroups[attributesSettingsKey])
I.Settings.registerGroup(settingGroups[healthSettingsKey])
I.Settings.registerGroup(settingGroups[magickaSettingsKey])
I.Settings.registerGroup(settingGroups[skillsSettingsKey])
I.Settings.registerGroup(settingGroups[skillUsesScaledSettingsKey])
I.Settings.registerGroup(settingGroups[skillUsesSettingsKey])

local function updateHealthSettings()
    local hasDeathCounter = getStorage(healthSettingsKey):get("deathCounter")
    local argument = getSetting(healthSettingsKey, "luckModifierPerDeath").argument
    argument.disabled = not hasDeathCounter
    I.Settings.updateRendererArgument(healthSettingsKey, "luckModifierPerDeath", argument)
end

local function updateMagickaSettings()
    if getStorage(magickaSettingsKey):get("mbspEnabled") then
        getStorage(skillUsesScaledSettingsKey):set("magickaBasedSkillScalingEnabled", false)
    end
end

local function updateSkillScalingSettings()
    if getStorage(skillUsesScaledSettingsKey):get("magickaBasedSkillScalingEnabled") then
        getStorage(magickaSettingsKey):set("mbspEnabled", false)
    end
end

getStorage(attributesSettingsKey):subscribe(async:callback(function(_, key)
    if key == "startValuesRatio" then
        self:sendEvent(mDef.events.updateRequest, { type = mDef.requestTypes.startAttrsOnResume })
    else
        self:sendEvent(mDef.events.updateRequest, { type = mDef.requestTypes.refreshStatsOnResume })
    end
end))

getStorage(healthSettingsKey):subscribe(async:callback(function(_, key)
    self:sendEvent(mDef.events.updateRequest, { type = mDef.requestTypes.refreshStatsOnResume })
    if key == "deathCounter" then
        updateHealthSettings()
    end
end))

getStorage(magickaSettingsKey):subscribe(async:callback(function(_, _)
    updateMagickaSettings()
end))

getStorage(skillsSettingsKey):subscribe(async:callback(function(_, key)
    if key == "skillDecayRate" then
        self:sendEvent(mDef.events.changeDecayRate)
    else
        self:sendEvent(mDef.events.updateRequest, { type = mDef.requestTypes.refreshStatsOnResume })
    end
end))

getStorage(skillUsesScaledSettingsKey):subscribe(async:callback(function(_, _)
    updateSkillScalingSettings()
end))

updateHealthSettings()
updateSkillScalingSettings()
updateMagickaSettings()

return module