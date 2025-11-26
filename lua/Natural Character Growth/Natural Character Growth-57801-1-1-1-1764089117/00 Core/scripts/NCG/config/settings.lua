local async = require('openmw.async')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')
local input = require("openmw.input")
local self = require('openmw.self')

local mDef = require('scripts.NCG.config.definition')

local globalSettingsKey = "SettingsPlayer" .. mDef.MOD_NAME
local attributesSettingsKey = "SettingsPlayerAttributes" .. mDef.MOD_NAME
local healthSettingsKey = "SettingsPlayerHealth" .. mDef.MOD_NAME

local module = {}

local settingGroups = {
    [globalSettingsKey] = {
        order = 0,
        settings = {
            {
                key = "classSkillPointsPerLevelUp",
                default = 10,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 1, max = 100 },
            },
            {
                key = "messagesLogKey",
                default = mDef.inputKeys.defaultLogsKey,
                renderer = "inputBinding",
                argument = { key = mDef.actions.showLogs, type = "action" },
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
                default = "startAttrRatioHalf",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "startAttrRatioNone", "startAttrRatioQuarter", "startAttrRatioHalf", "startAttrRatioThreeQuarters", "startAttrRatioFull" },
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
                    values = { 0, 1, 2 },
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
                key = "attributeUncapper",
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
            {
                key = "showAttributeChangeNotifications",
                default = true,
                renderer = "checkbox"
            },
            {
                key = "showAttributeValueDetails",
                default = false,
                renderer = "checkbox"
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
                key = "baseHPFactor",
                default = "baseHPFull",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "baseHPFull", "baseHPHigh", "baseHPMedium", "baseHPLow" },
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
            {
                key = "showHealthValueDetails",
                default = false,
                renderer = "checkbox"
            },
        }
    },
}

local function getStorage(key)
    return storage.playerSection(key)
end

module.globalStorage = getStorage(globalSettingsKey)
module.attributesStorage = getStorage(attributesSettingsKey)
module.healthStorage = getStorage(healthSettingsKey)

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

local getPerStatMaxValues = function(groupKey, settingKey)
    local map = {}
    for _, item in ipairs(getStorage(groupKey):get(settingKey) or {}) do
        map[item.key] = tonumber(item.value)
    end
    return map
end

-- Select key to values converters
module.getAttributeStartValuesRatio = function()
    return getSettingSelectValue(attributesSettingsKey, "startValuesRatio")
end
module.getAttributeGrowthRate = function()
    return getSettingSelectValue(attributesSettingsKey, "attributeGrowthRate")
end
module.getLuckGrowthRate = function()
    return getSettingSelectValue(attributesSettingsKey, "luckGrowthRate")
end
module.getBaseHPFactor = function()
    return getSettingSelectValue(healthSettingsKey, "baseHPFactor")
end
module.getPerLevelHPGainFactor = function()
    return getSettingSelectValue(healthSettingsKey, "perLevelHPGain")
end
module.getPerAttributeMaxValues = function()
    return getPerStatMaxValues(attributesSettingsKey, "perAttributeUncapper")
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

local function updateHealthSettings()
    local hasDeathCounter = getStorage(healthSettingsKey):get("deathCounter")
    local argument = getSetting(healthSettingsKey, "luckModifierPerDeath").argument
    argument.disabled = not hasDeathCounter
    I.Settings.updateRendererArgument(healthSettingsKey, "luckModifierPerDeath", argument)
end

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

input.registerAction {
    key = mDef.actions.showLogs,
    type = input.ACTION_TYPE.Boolean,
    l10n = mDef.MOD_NAME,
    defaultValue = false,
}

I.Settings.registerGroup(settingGroups[globalSettingsKey])
I.Settings.registerGroup(settingGroups[attributesSettingsKey])
I.Settings.registerGroup(settingGroups[healthSettingsKey])

getStorage(globalSettingsKey):subscribe(async:callback(function(_, key)
    if key == "classSkillPointsPerLevelUp" then
        self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.refreshStatsOnResume)
    end
end))

getStorage(attributesSettingsKey):subscribe(async:callback(function(_, key)
    if key == "startValuesRatio" or key == "attributeGrowthRate" then
        self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.startAttrsOnResume)
    else
        self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.refreshStatsOnResume)
    end
end))

getStorage(healthSettingsKey):subscribe(async:callback(function(_, key)
    self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.refreshStatsOnResume)
    if key == "deathCounter" then
        updateHealthSettings()
    end
end))

updateHealthSettings()

return module