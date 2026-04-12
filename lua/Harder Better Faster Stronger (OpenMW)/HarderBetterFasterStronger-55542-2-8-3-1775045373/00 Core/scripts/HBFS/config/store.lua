local core = require('openmw.core')
local I = require("openmw.interfaces")
local async = require('openmw.async')
local storage = require('openmw.storage')

local mDef = require('scripts.HBFS.config.definition')
local mTools = require('scripts.HBFS.util.tools')

local module = {
    sections = {
        global = { order = 0, name = "Global" },
        player = { order = 1, name = "Player" },
        followers = { order = 2, name = "Followers" },
        actors = { order = 3, name = "Actors" },
    },
    presetsBase = { Easier = 1, Easy = 2, Normal = 3, Hard = 4, Harder = 5 },
    presetsIncrease = { None = 1, Slow = 2, Normal = 3, Fast = 4 },
    defaultPercent = 100,
    attributes = core.stats.Attribute.records,
    dynamicStats = {
        health = { order = 0, id = "health" },
        magicka = { order = 1, id = "magicka" },
        fatigue = { order = 2, id = "fatigue" },
    },
}

local sections = module.sections
local trackerCallbacks = {}

local function defaultPercentIncreaseValues()
    return { base = module.defaultPercent, increase = 0, actual = module.defaultPercent }
end

local function percentIncreaseArgument(disabled, allowHeaders)
    return {
        disabled = disabled,
        allowHeaders = allowHeaders,
        withIncrease = false,
        perActor = false,
        base = { min = 0, max = 9999 },
        increase = { min = 0, max = 100 }
    }
end

module.percentKey = function(stat)
    return stat.id .. "Percent"
end

module.settings = {
    presetsEnabled = {
        order = 0,
        section = sections.global,
        renderer = "checkbox",
        default = true,
        impactsPercents = true,
    },
    presetBase = {
        order = 1,
        section = sections.global,
        renderer = "select",
        enum = module.presetsBase,
        default = module.presetsBase.Hard,
        impactsPercents = true,
    },
    presetIncrease = {
        order = 2,
        section = sections.global,
        renderer = "select",
        enum = module.presetsIncrease,
        default = module.presetsIncrease.Normal,
        impactsPercents = true,
    },
    difficultyScaling = {
        order = 3,
        section = sections.global,
        renderer = "checkbox",
        default = false,
        impactsPercents = true,
    },
    actorLevelBasedBoost = {
        order = 4,
        section = sections.global,
        renderer = "checkbox",
        default = true,
        impactsPercents = true,
    },
    boostOnlyWeakerActors = {
        order = 5,
        section = sections.global,
        renderer = "checkbox",
        default = false,
        impactsPercents = true,
    },
    debugMode = {
        order = 6,
        section = sections.global,
        renderer = "checkbox",
        default = false,
    },
    noBackRunning = {
        section = sections.player,
        order = 0,
        renderer = "checkbox",
        default = true,
    },
    deadGuardItemPickingIsCrime = {
        section = sections.player,
        order = 1,
        renderer = "checkbox",
        default = true,
    },
    minimumConditionRepairRequirement = {
        order = 2,
        section = sections.player,
        renderer = "checkbox",
        default = true,
    },
    physicalDamagePercent = {
        order = 3,
        section = sections.player,
        renderer = mDef.renderers.percentAndIncrease,
        default = defaultPercentIncreaseValues(),
        requiresOpenMW50 = true,
        argument = percentIncreaseArgument(false, true),
    },
    magicDamagePercent = {
        order = 4,
        section = sections.player,
        renderer = mDef.renderers.percentAndIncrease,
        default = defaultPercentIncreaseValues(),
        argument = percentIncreaseArgument(false, true),
    },
    sunDamagePercent = {
        order = 5,
        section = sections.player,
        renderer = mDef.renderers.percentAndIncrease,
        default = defaultPercentIncreaseValues(),
        argument = percentIncreaseArgument(false, true),
    },
    followerPercent = {
        order = 0,
        section = sections.followers,
        renderer = mDef.renderers.number,
        default = 50,
        argument = { min = 0, max = 1000, isPercent = true },
    },
    summonScrollPercent = {
        order = 1,
        section = sections.followers,
        renderer = mDef.renderers.number,
        default = 50,
        argument = { min = 0, max = 1000, isPercent = true },
    },
    summonConjurationPercentRange = {
        order = 2,
        section = sections.followers,
        renderer = mDef.renderers.range,
        default = { from = 0, to = 75, actual = module.defaultPercent },
        argument = { min = 0, max = 1000 },
    },
    summonEnchantPercentRange = {
        order = 3,
        section = sections.followers,
        renderer = mDef.renderers.range,
        default = { from = 0, to = 50, actual = module.defaultPercent },
        argument = { min = 0, max = 1000 },
    },
    maxSummonRangePercent = {
        order = 4,
        section = sections.followers,
        renderer = mDef.renderers.number,
        default = 100,
        argument = { min = 0, max = 1000, isPercent = true },
    },
    noBackRunningActors = {
        order = 0,
        section = sections.actors,
        renderer = "checkbox",
        default = true,
    },
    conditionalItemDegradation = {
        order = 1,
        section = sections.actors,
        renderer = "checkbox",
        default = true,
    },
}
local settings = module.settings

local order = 2
local header = true
for _, attribute in ipairs(module.attributes) do
    settings[module.percentKey(attribute)] = {
        order = order,
        section = sections.actors,
        renderer = mDef.renderers.percentAndIncrease,
        default = defaultPercentIncreaseValues(),
        argument = percentIncreaseArgument(false, header),
    }
    header = false
    order = order + 1
end

header = true
for _, stat in mTools.spairs(module.dynamicStats, function(t, a, b) return t[a].order < t[b].order end) do
    settings[module.percentKey(stat)] = {
        order = order,
        section = sections.actors,
        renderer = mDef.renderers.percentAndIncrease,
        default = defaultPercentIncreaseValues(),
        argument = percentIncreaseArgument(false, header),
    }
    header = false
    order = order + 1
end

module.registerGroups = function()
    for _, section in mTools.spairs(sections, function(t, a, b) return t[a].order < t[b].order end) do
        local group = { settings = {} }
        group.key = section.key
        group.page = mDef.MOD_NAME
        group.l10n = mDef.MOD_NAME
        group.name = section.name .. "SectionTitle"
        group.description = section.name .. "SectionDesc"
        group.permanentStorage = false
        group.order = section.order
        for _, setting in mTools.spairs(
                settings,
                function(t, a, b) return t[a].order < t[b].order end,
                function(a) return a.section.key == section.key end) do
            setting.name = setting.key .. "_name"
            setting.description = setting.key .. "_desc"
            table.insert(group.settings, setting)
        end
        I.Settings.registerGroup(group)
    end
end

module.setDisabled = function(key, disabled)
    settings[key].argument.disabled = disabled
    I.Settings.updateRendererArgument(settings[key].section.key, key, settings[key].argument)
end

module.updatePercentArgument = function(key, disabled, withIncrease, perActor)
    settings[key].argument.disabled = disabled
    settings[key].argument.requiresOpenMW50 = settings[key].requiresOpenMW50 and not mDef.isOpenMW50OrAbove
    settings[key].argument.withIncrease = withIncrease
    settings[key].argument.perActor = perActor
    I.Settings.updateRendererArgument(settings[key].section.key, key, settings[key].argument)
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
        for k, v in mTools.spairs(setting.enum, function(t, a, b) return t[a] < t[b] end) do
            local itemKey = key .. k
            table.insert(items, itemKey)
            setting.keys[v] = itemKey
            setting.values[itemKey] = v
        end
        setting.default = setting.keys[setting.default]
        setting.argument = { l10n = mDef.MOD_NAME, items = items }
    else
        setting.argument = setting.argument or {}
    end
    setting.argument.disabled = setting.argument.disabled or false
    setting.isPercentAndIncrease = setting.renderer == mDef.renderers.percentAndIncrease
    setting.isRange = setting.renderer == mDef.renderers.range
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