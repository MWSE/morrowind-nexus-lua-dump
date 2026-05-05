local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require("openmw.interfaces")
local T = require('openmw.types')

local mDef = require('scripts.FairCare.config.definition')
local mTypes = require('scripts.FairCare.config.types')
local mTools = require('scripts.FairCare.util.tools')

local trackerCallbacks = {}

local module = {}

module.sections = {
    global = { name = "Global", order = 0, description = false },
    creatures = { name = "Creatures", order = 1 },
    healing = { name = "Healing", order = 2 },
    healthRegen = { name = "HealthRegen", order = 3 },
    potions = { name = "Potions", order = 4 },
    woundedImpacts = { name = "WoundedImpacts", order = 5 },
    healerImpacts = { name = "HealerImpacts", order = 6 },
}

local sections = module.sections

module.settings = {
    selfHealingEnabled = {
        order = 0,
        section = sections.global,
        renderer = "checkbox",
        argument = { disabled = not mDef.isLuaApiRecentEnough },
        default = true,
    },
    touchHealingEnabled = {
        order = 1,
        section = sections.global,
        renderer = "checkbox",
        argument = { disabled = not mDef.isLuaApiRecentEnough },
        default = true,
    },
    healthRegenEnabled = {
        order = 2,
        section = sections.global,
        renderer = "checkbox",
        argument = { disabled = not mDef.isLuaApiRecentEnough },
        default = true,
    },
    addingPotionsEnabled = {
        order = 3,
        section = sections.global,
        renderer = "checkbox",
        argument = { disabled = not mDef.isLuaApiRecentEnough },
        default = true,
        clearCategory = mTypes.globalDataTypes.potions,
    },
    debugMode = {
        order = 4,
        section = sections.global,
        description = false,
        renderer = "checkbox",
        default = false,
    },
    timeBeforeHealAgainMaxChances = {
        order = 0,
        section = sections.healing,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100 },
        default = 10,
    },
    travelTimeToHealMinChances = {
        order = 1,
        section = sections.healing,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100 },
        default = 10,
    },
    creatureTypeDispositionBoost = {
        order = 2,
        section = sections.healing,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100 },
        default = 25,
    },
    healthRegenRatio = {
        order = 0,
        section = sections.healthRegen,
        renderer = "select",
        enum = mTypes.healthRegenRatios,
        default = mTypes.healthRegenRatios.Medium,
    },
    healthRegenForHealers = {
        order = 1,
        section = sections.healthRegen,
        renderer = "checkbox",
        default = false,
    },
    Player_regen = {
        order = 2,
        section = sections.healthRegen,
        description = false,
        renderer = "checkbox",
        default = false,
    },
    NPC_regen = {
        order = 3,
        section = sections.healthRegen,
        description = false,
        renderer = "checkbox",
        default = false,
    },
    potionsForHealers = {
        order = 0,
        section = sections.potions,
        renderer = "checkbox",
        default = false,
        clearCategory = mTypes.globalDataTypes.potions,
    },
    minRestoredHealthByPotions = {
        order = 1,
        section = sections.potions,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000, isPercent = true },
        default = 50,
        clearCategory = mTypes.globalDataTypes.potions,
    },
    maxRestoredHealthByPotions = {
        order = 2,
        section = sections.potions,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000, isPercent = true },
        default = 100,
        clearCategory = mTypes.globalDataTypes.potions,
    },
    maxPotionsTotalValueOverNpcWealth = {
        order = 3,
        section = sections.potions,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000, isPercent = true },
        default = 50,
        clearCategory = mTypes.globalDataTypes.potions,
    },
    potionRestockDelayHours = {
        order = 4,
        section = sections.potions,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000 },
        default = 4,
    },
}
local settings = module.settings

module.getCreatureHealKey = function(creatureType)
    return string.format("%s%s_heal", T.Creature, mTypes.creatureTypes[creatureType])
end

module.getActorTypeRegenKey = function(actorType, recordType)
    return string.format("%s%s_regen", actorType, actorType == T.Creature and mTypes.creatureTypes[recordType] or "")
end

module.getHealChanceImpactKey = function(section, chanceTypeKey)
    return string.format("%s_%s", section.name, chanceTypeKey)
end

local order = 0
for creatureType in pairs(mTypes.creatureTypes) do
    settings[module.getCreatureHealKey(creatureType)] = {
        order = order,
        section = sections.creatures,
        default = creatureType ~= T.Creature.TYPE.Creatures,
        renderer = "checkbox",
    }
    settings[module.getActorTypeRegenKey(T.Creature, creatureType)] = {
        order = order + 4,
        section = sections.healthRegen,
        default = true,
        description = false,
        renderer = "checkbox",
    }
    order = order + 1
end

local impactKeys = {}
for impactKey in pairs(mTypes.chanceImpacts) do
    table.insert(impactKeys, impactKey)
end

order = 0
for _, chanceType in mTools.spairs(mTypes.chanceTypes,
        function(t, a, b) return t[a].order < t[b].order end,
        function(item) return item.action == mTypes.actions.selfHeal end) do
    settings[module.getHealChanceImpactKey(sections.woundedImpacts, chanceType.key)] = {
        order = order,
        section = sections.woundedImpacts,
        renderer = "select",
        enum = mTypes.chanceImpacts,
        isGlobalEnum = true,
        default = chanceType.impact,
    }
    order = order + 1
end

order = 0
for _, chanceType in mTools.spairs(mTypes.chanceTypes,
        function(t, a, b) return t[a].order < t[b].order end,
        function(item) return item.action == mTypes.actions.touchHeal end) do
    settings[module.getHealChanceImpactKey(sections.healerImpacts, chanceType.key)] = {
        order = order,
        section = sections.healerImpacts,
        renderer = "select",
        enum = mTypes.chanceImpacts,
        isGlobalEnum = true,
        default = chanceType.impact,
    }
    order = order + 1
end

module.registerGroups = function()
    for _, section in pairs(sections) do
        section.page = mDef.MOD_NAME
        section.l10n = mDef.MOD_NAME
        local name = section.name
        section.name = name .. "SectionTitle"
        if section.description ~= false then
            section.description = mDef.getMessageKeyIfOpenMWTooOld(name .. "SectionDesc")
        else
            section.description = nil
        end
        section.permanentStorage = false
        section.settings = {}
        if mDef.isLuaApiRecentEnough then
            for _, setting in mTools.spairs(settings,
                    function(t, a, b) return t[a].order < t[b].order end,
                    function(item) return item.section == section end) do
                setting.name = setting.key .. "_name"
                if setting.description ~= false then
                    setting.description = setting.key .. "_desc"
                else
                    setting.description = nil
                end
                table.insert(section.settings, setting)
            end
        end
        I.Settings.registerGroup(section)
    end

    if not mDef.isLuaApiRecentEnough then
        settings.enabled.set(false)
    end
end

module.addTrackerCallback = function(callback)
    table.insert(trackerCallbacks, callback)
end

local function serializeValue(setting, value)
    return setting.enum and setting.keys[value] or value
end

local function deserializeValue(setting, value)
    return setting.enum and setting.values[value] or value
end

for _, section in pairs(sections) do
    section.key = "Settings" .. section.name .. mDef.MOD_NAME
    section.get = function()
        return storage.globalSection(section.key)
    end
end

for key, setting in pairs(settings) do
    setting.key = key
    setting.set = function(value)
        return setting.section.get():set(key, serializeValue(setting, value))
    end
    if setting.enum then
        local items = {}
        setting.keys = {}
        setting.values = {}
        for vKey, value in mTools.spairs(setting.enum, function(t, a, b) return t[a] < t[b] end) do
            local itemKey = setting.isGlobalEnum and vKey or (key .. vKey)
            table.insert(items, itemKey)
            setting.keys[value] = itemKey
            setting.values[itemKey] = value
        end
        setting.default = setting.keys[setting.default]
        setting.argument = { l10n = mDef.MOD_NAME, items = items }
    else
        setting.argument = setting.argument or {}
    end
    setting.argument.disabled = setting.argument.disabled or false
    setting.value = deserializeValue(setting, setting.default)
end

for _, section in pairs(sections) do
    for key, value in pairs(section.get():asTable()) do
        local setting = settings[key]
        if not setting then
            -- key used in an older mod version: Remove the entry
            if I.Activation then
                -- only set the setting from a global script
                section.get():set(key, nil)
            end
        else
            if value == nil
                    or setting.default and type(value) ~= type(setting.default)
                    or setting.enum and not setting.values[value] then
                -- broken storage: Restore the default value
                value = setting.default
                if I.Activation then
                    -- only set the setting from a global script
                    section.get():set(key, value)
                end
            end

            setting.value = deserializeValue(setting, value)
        end
    end
end

for _, section in pairs(sections) do
    section.get():subscribe(async:callback(function(_, key)
        local setting = settings[key]
        if not setting then return end
        local oldValue = setting.value
        setting.value = deserializeValue(setting, section.get():getCopy(key))
        for _, callback in ipairs(trackerCallbacks) do
            callback(key, oldValue)
        end
    end))
end

return module
