local core = require('openmw.core')

local mDef = require('scripts.HBFS.config.definition')
local mTools = require('scripts.HBFS.util.tools')

local module = {
    presetsBase = { Easy = 1, Normal = 2, Hard = 3, Harder = 4 },
    presetsIncrease = { None = 1, Slow = 2, Normal = 3, Fast = 4 },
    defaultPercent = 100,
}

local attributes = core.stats.Attribute.records
module.attributes = attributes
local dynamicStats = {
    health = { order = 0, id = "health" },
    magicka = { order = 1, id = "magicka" },
    fatigue = { order = 2, id = "fatigue" },
}
module.dynamicStats = dynamicStats

local sections = {
    global = { order = 0, name = "Global" },
    player = { order = 1, name = "Player" },
    actors = { order = 2, name = "Actors" },
}
module.sections = sections

for _, section in pairs(sections) do
    section.key = "Settings" .. section.name .. mDef.MOD_NAME
end

local function defaultPercentIncreaseValues()
    return { l10n = mDef.MOD_NAME, base = module.defaultPercent, increase = 0, actual = module.defaultPercent }
end

local function percentIncreaseArgument(disabled, allowHeaders)
    return {
        l10n = mDef.MOD_NAME,
        disabled = disabled,
        withIncrease = false,
        allowHeaders = allowHeaders,
        base = { min = 1, max = 9999 },
        increase = { min = 0, max = 100 }
    }
end

module.settings = {
    presetsEnabled = {
        order = 0,
        section = sections.global,
        renderer = "checkbox",
        default = true,
        updatePercents = true,
    },
    presetBase = {
        order = 1,
        section = sections.global,
        renderer = "select",
        enum = module.presetsBase,
        default = module.presetsBase.Hard,
        updatePercents = true,
    },
    presetIncrease = {
        order = 2,
        section = sections.global,
        renderer = "select",
        enum = module.presetsIncrease,
        default = module.presetsIncrease.Normal,
        updatePercents = true,
    },
    difficultyScaling = {
        order = 3,
        section = sections.global,
        renderer = "checkbox",
        default = false,
        updatePercents = true,
    },
    debugMode = {
        order = 4,
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
    physicalDamagePercent = {
        order = 1,
        section = sections.player,
        renderer = mDef.renderers.empty,
    },
    magicDamagePercent = {
        order = 2,
        section = sections.player,
        renderer = mDef.renderers.percentAndIncrease,
        default = defaultPercentIncreaseValues(),
        argument = percentIncreaseArgument(false, true),
    },
    sunDamagePercent = {
        order = 3,
        section = sections.player,
        renderer = mDef.renderers.percentAndIncrease,
        default = defaultPercentIncreaseValues(),
        argument = percentIncreaseArgument(false, true),
    },
}

local function percentKey(stat)
    return stat.id .. "Percent"
end
module.percentKey = percentKey

local order = 0
local header = true
for _, attribute in ipairs(attributes) do
    module.settings[percentKey(attribute)] = {
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
for _, stat in mTools.spairs(dynamicStats, function(t, a, b) return t[a].order < t[b].order end) do
    module.settings[percentKey(stat)] = {
        order = order,
        section = sections.actors,
        renderer = mDef.renderers.percentAndIncrease,
        default = defaultPercentIncreaseValues(),
        argument = percentIncreaseArgument(false, header),
    }
    header = false
    order = order + 1
end

for key, setting in pairs(module.settings) do
    if setting.enum then
        local items = {}
        setting.keys = {}
        setting.values = {}
        for vKey, value in mTools.spairs(setting.enum, function(t, a, b) return t[a] < t[b] end) do
            local itemKey = key .. vKey
            table.insert(items, itemKey)
            setting.keys[value] = itemKey
            setting.values[itemKey] = value
        end
        setting.default = setting.keys[setting.default]
        setting.argument = { l10n = mDef.MOD_NAME, items = items }
    else
        setting.argument = setting.argument or { disabled = false }
    end
end

for key, setting in pairs(module.settings) do
    setting.key = key
end

module.presetBaseRatios = {
    [module.presetsBase.Easy] = -0.5,
    [module.presetsBase.Normal] = 0,
    [module.presetsBase.Hard] = 0.5,
    [module.presetsBase.Harder] = 1.0,
}

module.presetIncreaseRatios = {
    [module.presetsIncrease.None] = 0.0,
    [module.presetsIncrease.Slow] = 0.01,
    [module.presetsIncrease.Normal] = 0.02,
    [module.presetsIncrease.Fast] = 0.04,
}

module.presetPercentRatios = {
    [module.settings.magicDamagePercent.key] = 1.0,
    [module.settings.sunDamagePercent.key] = 0.2,
    [percentKey(attributes.strength)] = 1.0,
    [percentKey(attributes.agility)] = 1.0,
    [percentKey(attributes.endurance)] = 1.0,
    [percentKey(attributes.willpower)] = 1.0,
    [percentKey(attributes.intelligence)] = 1.0,
    [percentKey(attributes.personality)] = 0.5,
    [percentKey(attributes.speed)] = 0.2,
    [percentKey(attributes.luck)] = 0.5,
    [percentKey(dynamicStats.health)] = 0.5,
    [percentKey(dynamicStats.magicka)] = 0.0,
    [percentKey(dynamicStats.fatigue)] = 0.5,
}

return module