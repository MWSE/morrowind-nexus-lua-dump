local I = require("openmw.interfaces")
local T = require('openmw.types')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mData = require('scripts.FairCare.data')
local mTools = require('scripts.FairCare.tools')

local function getDescriptionIfOpenMWTooOld(key)
    if not mSettings.isLuaApiRecentEnough then
        if mSettings.isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

local settingGroups = {
    [mSettings.globalKey] = {
        key = mSettings.globalKey,
        page = mSettings.MOD_NAME,
        l10n = mSettings.MOD_NAME,
        name = "settingsTitle",
        description = getDescriptionIfOpenMWTooOld("settingsDesc"),
        permanentStorage = false,
        order = 0,
        settings = {
            {
                key = "selfHealingEnabled",
                name = "selfHealingEnabled_name",
                description = "selfHealingEnabled_description",
                default = true,
                renderer = "checkbox",
                argument = {
                    disabled = not mSettings.isLuaApiRecentEnough,
                }
            },
            {
                key = "touchHealingEnabled",
                name = "touchHealingEnabled_name",
                description = "touchHealingEnabled_description",
                default = true,
                renderer = "checkbox",
                argument = {
                    disabled = not mSettings.isLuaApiRecentEnough,
                }
            },
            {
                key = "healthRegenEnabled",
                name = "healthRegenEnabled_name",
                description = "healthRegenEnabled_description",
                default = true,
                renderer = "checkbox",
                argument = {
                    disabled = not mSettings.isLuaApiRecentEnough,
                }
            },
            {
                key = "addingPotionsEnabled",
                name = "addingPotionsEnabled_name",
                description = "addingPotionsEnabled_description",
                default = true,
                renderer = "checkbox",
                argument = {
                    disabled = not mSettings.isLuaApiRecentEnough,
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
    [mSettings.creaturesKey] = {
        key = mSettings.creaturesKey,
        page = mSettings.MOD_NAME,
        l10n = mSettings.MOD_NAME,
        name = "creaturesSettingsTitle",
        description = "creaturesSettingsDescription",
        permanentStorage = false,
        order = 1,
        settings = {},
    },
    [mSettings.healingTweaksKey] = {
        key = mSettings.healingTweaksKey,
        page = mSettings.MOD_NAME,
        l10n = mSettings.MOD_NAME,
        name = "healingSettingsTitle",
        description = "healingSettingsDesc",
        permanentStorage = false,
        order = 2,
        settings = {
            {
                key = "timeBeforeHealAgainMaxChances",
                name = "timeBeforeHealAgainMaxChances_name",
                description = "timeBeforeAgainMaxChances_description",
                default = 20,
                renderer = "number",
                argument = {
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
                    integer = true,
                    min = 0,
                    max = 100,
                },
            },
        },
    },
    [mSettings.regenSettingsKey] = {
        key = mSettings.regenSettingsKey,
        page = mSettings.MOD_NAME,
        l10n = mSettings.MOD_NAME,
        name = "healthRegenSettingsTitle",
        description = "healthRegenSettingsDesc",
        permanentStorage = false,
        order = 3,
        settings = {
            {
                key = "healthRegenRatio",
                name = "healthRegenRatio_name",
                description = "healthRegenRatio_description",
                default = "1",
                renderer = "select",
                argument = {
                    l10n = mSettings.MOD_NAME,
                    items = { "1/4", "1/2", "1", "2", "4" },
                },
            },
            {
                key = "healthRegenForHealers",
                name = "healthRegenForHealers_name",
                description = "healthRegenForHealers_description",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "Player_regen",
                name = "Player_regen_name",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "NPC_regen",
                name = "NPC_regen_name",
                default = false,
                renderer = "checkbox",
            },
        },
    },
    [mSettings.potionSettingsKey] = {
        key = mSettings.potionSettingsKey,
        page = mSettings.MOD_NAME,
        l10n = mSettings.MOD_NAME,
        name = "potionSettingsTitle",
        description = "potionSettingsDesc",
        permanentStorage = false,
        order = 4,
        settings = {
            {
                key = "potionsForHealers",
                name = "potionsForHealers_name",
                description = "potionsForHealers_description",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "minRestoredHealthByPotions",
                name = "minRestoredHealthByPotions_name",
                description = "minRestoredHealthByPotions_description",
                default = 75,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 1000,
                },
            },
            {
                key = "maxRestoredHealthByPotions",
                name = "maxRestoredHealthByPotions_name",
                description = "maxRestoredHealthByPotions_description",
                default = 125,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 1000,
                },
            },
            {
                key = "maxPotionsTotalValueOverNpcWealth",
                name = "maxPotionsTotalValueOverNpcWealth_name",
                description = "maxPotionsTotalValueOverNpcWealth_description",
                default = 50,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 1000,
                },
            },
            {
                key = "potionRestockDelayHours",
                name = "potionRestockDelayHours_name",
                description = "potionRestockDelayHours_description",
                default = 4,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 1000,
                },
            },
        }
    },
    [mSettings.woundedImpactsKey] = {
        key = mSettings.woundedImpactsKey,
        page = mSettings.MOD_NAME,
        l10n = mSettings.MOD_NAME,
        name = "woundedImpactsSettingsTitle",
        description = "woundedImpactsSettingsDesc",
        permanentStorage = false,
        order = 5,
        settings = {},
    },
    [mSettings.healerImpactsKey] = {
        key = mSettings.healerImpactsKey,
        page = mSettings.MOD_NAME,
        l10n = mSettings.MOD_NAME,
        name = "healerImpactsSettingsTitle",
        description = "healerImpactsSettingsDesc",
        permanentStorage = false,
        order = 6,
        settings = {},
    },
}

for _, creatureTypeName in pairs(mData.creatureTypes) do
    table.insert(settingGroups[mSettings.creaturesKey].settings, {
        key = creatureTypeName .. "_heal",
        name = creatureTypeName .. "_heal_name",
        description = creatureTypeName .. "_heal_description",
        default = true,
        renderer = "checkbox",
    })
    table.insert(settingGroups[mSettings.regenSettingsKey].settings, {
        key = tostring(T.Creature) .. creatureTypeName .. "_regen",
        name = tostring(T.Creature) .. creatureTypeName .. "_regen_name",
        default = true,
        renderer = "checkbox",
    })
end

local impactKeys = {}
for impactKey in pairs(mCfg.chanceImpacts) do
    table.insert(impactKeys, impactKey)
end

for _, chanceType in mTools.spairs(mData.chanceTypes, function(t, a, b) return t[a].order < t[b].order end) do
    if chanceType.action == mData.actions.selfHeal then
        local key = mSettings.getHealChanceImpactKey(chanceType.key)
        table.insert(settingGroups[mSettings.woundedImpactsKey].settings, {
            key = key,
            name = key .. "_name",
            description = key .. "_description",
            default = chanceType.impact.key,
            renderer = "select",
            argument = {
                l10n = mSettings.MOD_NAME,
                items = impactKeys,
            },
        })
    end
end

for _, chanceType in mTools.spairs(mData.chanceTypes, function(t, a, b) return t[a].order < t[b].order end) do
    if chanceType.action == mData.actions.touchHeal then
        local key = mSettings.getHealChanceImpactKey(chanceType.key)
        table.insert(settingGroups[mSettings.healerImpactsKey].settings, {
            key = key,
            name = key .. "_name",
            description = key .. "_description",
            default = chanceType.impact.key,
            renderer = "select",
            argument = {
                l10n = mSettings.MOD_NAME,
                items = impactKeys,
            },
        })
    end
end

I.Settings.registerGroup(settingGroups[mSettings.globalKey])
I.Settings.registerGroup(settingGroups[mSettings.creaturesKey])
I.Settings.registerGroup(settingGroups[mSettings.woundedImpactsKey])
I.Settings.registerGroup(settingGroups[mSettings.healerImpactsKey])
I.Settings.registerGroup(settingGroups[mSettings.healingTweaksKey])
I.Settings.registerGroup(settingGroups[mSettings.regenSettingsKey])
I.Settings.registerGroup(settingGroups[mSettings.potionSettingsKey])

if not mSettings.isLuaApiRecentEnough then
    mSettings.getSection(mSettings.globalKey):set("selfHealingEnabled", false)
    mSettings.getSection(mSettings.globalKey):set("touchHealingEnabled", false)
    mSettings.getSection(mSettings.globalKey):set("healthRegenEnabled", false)
    mSettings.getSection(mSettings.globalKey):set("addingPotionsEnabled", false)
end