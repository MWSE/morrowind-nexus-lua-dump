local I = require("openmw.interfaces")
local T = require('openmw.types')

local mDef = require('scripts.FairCare.config.definition')
local mStore = require('scripts.FairCare.config.store')
local mCfg = require('scripts.FairCare.config.config')
local mTypes = require('scripts.FairCare.config.types')
local mTools = require('scripts.FairCare.util.tools')

local function getDescriptionIfOpenMWTooOld(key)
    if not mDef.isLuaApiRecentEnough then
        if mDef.isOpenMW049 then
            return "requiresNewerOpenmw49"
        else
            return "requiresOpenmw49"
        end
    end
    return key
end

local settingGroups = {
    [mStore.groups.global] = {
        order = 0,
        settings = {
            {
                key = "selfHealingEnabled",
                default = true,
                renderer = "checkbox",
                argument = { disabled = not mDef.isLuaApiRecentEnough }
            },
            {
                key = "touchHealingEnabled",
                default = true,
                renderer = "checkbox",
                argument = { disabled = not mDef.isLuaApiRecentEnough }
            },
            {
                key = "healthRegenEnabled",
                default = true,
                renderer = "checkbox",
                argument = { disabled = not mDef.isLuaApiRecentEnough }
            },
            {
                key = "addingPotionsEnabled",
                default = true,
                renderer = "checkbox",
                argument = { disabled = not mDef.isLuaApiRecentEnough }
            },
            {
                key = "debugMode",
                default = false,
                renderer = "checkbox",
            },
        },
    },
    [mStore.groups.creatures] = {
        order = 1,
        settings = {},
    },
    [mStore.groups.healing] = {
        order = 2,
        settings = {
            {
                key = "timeBeforeHealAgainMaxChances",
                default = 20,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "travelTimeToHealMinChances",
                default = 10,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
            {
                key = "creatureTypeDispositionBoost",
                default = 25,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 100 },
            },
        },
    },
    [mStore.groups.healthRegen] = {
        order = 3,
        settings = {
            {
                key = "healthRegenRatio",
                default = "1",
                renderer = "select",
                argument = {
                    l10n = mDef.MOD_NAME,
                    items = { "1/4", "1/2", "1", "2", "4" },
                },
            },
            {
                key = "healthRegenForHealers",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "Player_regen",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "NPC_regen",
                default = false,
                renderer = "checkbox",
            },
        },
    },
    [mStore.groups.potions] = {
        order = 4,
        settings = {
            {
                key = "potionsForHealers",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "minRestoredHealthByPotions",
                default = 75,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
            {
                key = "maxRestoredHealthByPotions",
                default = 125,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
            {
                key = "maxPotionsTotalValueOverNpcWealth",
                default = 50,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
            {
                key = "potionRestockDelayHours",
                default = 4,
                renderer = mDef.renderers.number,
                argument = { integer = true, min = 0, max = 1000 },
            },
        }
    },
    [mStore.groups.woundedImpacts] = {
        order = 5,
        settings = {},
    },
    [mStore.groups.healerImpacts] = {
        order = 6,
        settings = {},
    },
}

for _, creatureTypeName in pairs(mTypes.creatureTypes) do
    table.insert(settingGroups[mStore.groups.creatures].settings, {
        key = creatureTypeName .. "_heal",
        default = true,
        renderer = "checkbox",
    })
    table.insert(settingGroups[mStore.groups.healthRegen].settings, {
        key = tostring(T.Creature) .. creatureTypeName .. "_regen",
        default = true,
        renderer = "checkbox",
    })
end

local impactKeys = {}
for impactKey in pairs(mCfg.chanceImpacts) do
    table.insert(impactKeys, impactKey)
end

for _, chanceType in mTools.spairs(mTypes.chanceTypes, function(t, a, b) return t[a].order < t[b].order end) do
    if chanceType.action == mTypes.actions.selfHeal then
        table.insert(settingGroups[mStore.groups.woundedImpacts].settings, {
            key = mStore.getHealChanceImpactKey(chanceType.key),
            default = chanceType.impact.key,
            renderer = "select",
            argument = { l10n = mDef.MOD_NAME, items = impactKeys },
        })
    end
end

for _, chanceType in mTools.spairs(mTypes.chanceTypes, function(t, a, b) return t[a].order < t[b].order end) do
    if chanceType.action == mTypes.actions.touchHeal then
        table.insert(settingGroups[mStore.groups.healerImpacts].settings, {
            key = mStore.getHealChanceImpactKey(chanceType.key),
            default = chanceType.impact.key,
            renderer = "select",
            argument = { l10n = mDef.MOD_NAME, items = impactKeys },
        })
    end
end

for storeGroup, group in pairs(settingGroups) do
    group.key = storeGroup.key
    group.page = mDef.MOD_NAME
    group.name = storeGroup.name .. "SectionTitle"
    group.description = getDescriptionIfOpenMWTooOld(storeGroup.name .. "SectionDesc")
    group.l10n = mDef.MOD_NAME
    group.permanentStorage = false
    for _, setting in ipairs(group.settings) do
        setting.name = setting.key .. "_name"
        setting.description = setting.key .. "_desc"
    end
end

for _, group in pairs(mStore.groups) do
    I.Settings.registerGroup(settingGroups[group])
end

if not mDef.isLuaApiRecentEnough then
    for _, setting in ipairs(settingGroups[mStore.groups.global].settings) do
        if setting.renderer == "checkbox" then
            mStore.groups.global.set(setting.key, false)
        end
    end
end