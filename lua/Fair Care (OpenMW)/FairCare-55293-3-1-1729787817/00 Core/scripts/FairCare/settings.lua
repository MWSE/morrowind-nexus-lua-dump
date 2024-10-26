local core = require('openmw.core')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')

local mCfg = require('scripts.FairCare.configuration')
local mTools = require('scripts.FairCare.tools')
local mData = require('scripts.FairCare.data')

local module = {}

local MOD_NAME = "FairCare"
module.MOD_NAME = MOD_NAME

local isLuaApiRecentEnough = core.API_REVISION >= 68
module.isLuaApiRecentEnough = isLuaApiRecentEnough

local isOpenMW049 = core.API_REVISION > 29
module.isOpenMW049 = isOpenMW049

local globalSettingsKey = "SettingsGlobal" .. MOD_NAME
local creaturesSettingsKey = "SettingsCreatures" .. MOD_NAME
local woundedImpactsSettingsKey = "SettingsWoundedImpacts" .. MOD_NAME
local healerImpactsSettingsKey = "SettingsHealerImpacts" .. MOD_NAME
local healingTweaksSettingsKey = "SettingsHealingTweaks" .. MOD_NAME

local function getStorage(key)
    return storage.globalSection(key)
end
module.globalStorage = getStorage(globalSettingsKey)
module.creaturesStorage = getStorage(creaturesSettingsKey)
module.woundedImpactsStorage = getStorage(woundedImpactsSettingsKey)
module.healerImpactsStorage = getStorage(healerImpactsSettingsKey)
module.healingTweaksStorage = getStorage(healingTweaksSettingsKey)

local function debugPrint(str)
    if module.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end
module.debugPrint = debugPrint

local function getHealChanceImpactKey(chanceTypeKey)
    return "healChanceImpact_" .. chanceTypeKey
end
module.getHealChanceImpactKey = getHealChanceImpactKey

local function getDescriptionIfOpenMWTooOld(key)
    if not isLuaApiRecentEnough then
        if isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

local function initSettings()
    local settingGroups = {
        [globalSettingsKey] = {
            key = globalSettingsKey,
            l10n = MOD_NAME,
            name = "settingsTitle",
            page = MOD_NAME,
            order = 0,
            description = getDescriptionIfOpenMWTooOld("settingsDesc"),
            permanentStorage = false,
            settings = {
                {
                    key = "selfHealingEnabled",
                    name = "selfHealingEnabled_name",
                    default = true,
                    renderer = "checkbox",
                    argument = {
                        disabled = not isLuaApiRecentEnough,
                    }
                },
                {
                    key = "touchHealingEnabled",
                    name = "touchHealingEnabled_name",
                    description = "",
                    default = true,
                    renderer = "checkbox",
                    argument = {
                        disabled = not isLuaApiRecentEnough,
                    }
                },
                {
                    key = "debugMode",
                    name = "debugMode_name",
                    default = false,
                    renderer = "checkbox",
                },
            },
        },
        [creaturesSettingsKey] = {
            key = creaturesSettingsKey,
            l10n = MOD_NAME,
            name = "creaturesSettingsTitle",
            page = MOD_NAME,
            order = 1,
            description = "creaturesSettingsDescription",
            permanentStorage = false,
            settings = {},
        },
        [woundedImpactsSettingsKey] = {
            key = woundedImpactsSettingsKey,
            l10n = MOD_NAME,
            name = "woundedImpactsSettingsTitle",
            page = MOD_NAME,
            order = 2,
            description = "woundedImpactsSettingsDesc",
            permanentStorage = false,
            settings = {},
        },
        [healerImpactsSettingsKey] = {
            key = healerImpactsSettingsKey,
            l10n = MOD_NAME,
            name = "healerImpactsSettingsTitle",
            page = MOD_NAME,
            order = 3,
            description = "healerImpactsSettingsDesc",
            permanentStorage = false,
            settings = {},
        },
        [healingTweaksSettingsKey] = {
            key = healingTweaksSettingsKey,
            l10n = MOD_NAME,
            name = "healingTweaksSettingsTitle",
            page = MOD_NAME,
            order = 4,
            description = "healingTweaksSettingsDesc",
            permanentStorage = false,
            settings = {
                {
                    key = "timeBeforeHealAgainMaxChances",
                    name = "timeBeforeHealAgainMaxChances_name",
                    description = "timeBeforeAgainMaxChances_description",
                    default = 10,
                    renderer = "number",
                    argument = {
                        disabled = not isLuaApiRecentEnough,
                        integer = true,
                        min = 0,
                        max = 100,
                    },
                },
                {
                    key = "travelTimeToHealMinChances",
                    name = "travelTimeToHealMinChances_name",
                    description = "travelTimeToHealMinChances_description",
                    default = 10,
                    renderer = "number",
                    argument = {
                        disabled = not isLuaApiRecentEnough,
                        integer = true,
                        min = 0,
                        max = 100,
                    },
                },
                {
                    key = "creatureTypeDispositionBoost",
                    name = "creatureTypeDispositionBoost_name",
                    description = "creatureTypeDispositionBoost_description",
                    default = 25,
                    renderer = "number",
                    argument = {
                        disabled = not isLuaApiRecentEnough,
                        integer = true,
                        min = 0,
                        max = 100,
                    },
                },
            },
        },
    }

    for _, creatureTypeName in pairs(mData.creatureTypes) do
        table.insert(settingGroups[creaturesSettingsKey].settings, {
            key = creatureTypeName,
            name = creatureTypeName .. "_name",
            description = creatureTypeName .. "_description",
            -- Exclude creatures of type Creature by default
            default = creatureTypeName ~= "Creatures",
            renderer = "checkbox",
            argument = {
                disabled = not isLuaApiRecentEnough,
            }
        })
    end

    local impactKeys = {}
    for impactKey in pairs(mCfg.chanceImpacts) do
        table.insert(impactKeys, impactKey)
    end

    for _, chanceType in mTools.spairs(mData.chanceTypes, function(t, a, b) return t[a].order < t[b].order end) do
        if chanceType.action == mData.actions.selfHeal then
            local key = getHealChanceImpactKey(chanceType.key)
            table.insert(settingGroups[woundedImpactsSettingsKey].settings, {
                key = key,
                name = key .. "_name",
                description = key .. "_description",
                default = chanceType.impact.key,
                renderer = "select",
                argument = {
                    l10n = MOD_NAME,
                    items = impactKeys,
                    disabled = not isLuaApiRecentEnough,
                },
            })
        end
    end

    for _, chanceType in mTools.spairs(mData.chanceTypes, function(t, a, b) return t[a].order < t[b].order end) do
        if chanceType.action == mData.actions.touchHeal then
            local key = getHealChanceImpactKey(chanceType.key)
            table.insert(settingGroups[healerImpactsSettingsKey].settings, {
                key = key,
                name = key .. "_name",
                description = key .. "_description",
                default = chanceType.impact.key,
                renderer = "select",
                argument = {
                    l10n = MOD_NAME,
                    items = impactKeys,
                    disabled = not isLuaApiRecentEnough,
                },
            })
        end
    end

    I.Settings.registerGroup(settingGroups[globalSettingsKey])
    I.Settings.registerGroup(settingGroups[creaturesSettingsKey])
    I.Settings.registerGroup(settingGroups[woundedImpactsSettingsKey])
    I.Settings.registerGroup(settingGroups[healerImpactsSettingsKey])
    I.Settings.registerGroup(settingGroups[healingTweaksSettingsKey])

    if not isLuaApiRecentEnough then
        getStorage(globalSettingsKey):set("touchHealingEnabled", false)
    end
end
module.initSettings = initSettings

return module
