local I = require("openmw.interfaces")
local core = require('openmw.core')
local storage = require('openmw.storage')

local mDef = require('scripts.HBFS.definition')

local module = {
    l10n = core.l10n(mDef.MOD_NAME),
    globalKey = "SettingsGlobal" .. mDef.MOD_NAME,
    playerKey = "SettingsPlayer" .. mDef.MOD_NAME,
    actorsKey = "SettingsActors" .. mDef.MOD_NAME,
}

module.globalSection = function() return storage.globalSection(module.globalKey) end
module.playerSection = function() return storage.globalSection(module.playerKey) end
module.actorsSection = function() return storage.globalSection(module.actorsKey) end

local function presetValue(key)
    return "preset_" .. key
end
module.presetValue = presetValue

module.defaultPercent = 100
module.defaultPreset = "custom"

local function percentKey(prefix)
    return prefix .. "Percent"
end
module.percentKey = percentKey

local percentRenderer = "percentAndIncrease"

local function defaultPercentIncreaseValues(selected)
    return { selected = selected, l10n = mDef.MOD_NAME, base = module.defaultPercent, increase = 5, actual = module.defaultPercent }
end

local function percentIncreaseArgument(disabled, isGlobal, allowHeaders)
    return {
        l10n = mDef.MOD_NAME,
        disabled = disabled,
        isGlobal = isGlobal,
        withIncrease = false,
        allowHeaders = allowHeaders,
        base = {
            min = 1,
            max = 9999,
        },
        increase = {
            min = 0,
            max = 100,
        }
    }
end

local defaultPresetsArgument = {}
for key, value in pairs(percentIncreaseArgument(false, true, true)) do
    defaultPresetsArgument[key] = value
end
defaultPresetsArgument.items = {}
defaultPresetsArgument.defaultValue = presetValue(module.defaultPreset)
defaultPresetsArgument.values = {
    { name = "easy", base = 50, increase = 0 },
    { name = "scalingEasy", base = 50, increase = 5 },
    { name = module.defaultPreset, base = 100, increase = 0 },
    { name = "scalingNormal", base = 100, increase = 5 },
    { name = "hard", base = 150, increase = 0 },
    { name = "scalingHard", base = 150, increase = 5 },
    { name = "harder", base = 200, increase = 0 },
    { name = "scalingHarder", base = 200, increase = 5 },
}

local cfg = {
    enabled = {
        section = module.globalKey,
        order = 0,
        renderer = "checkbox",
        default = true,
    },
    debugMode = {
        section = module.globalKey,
        order = 1,
        renderer = "checkbox",
        default = false,
    },
    presets = {
        section = module.globalKey,
        order = 2,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues(presetValue(module.defaultPreset)),
        argument = defaultPresetsArgument,
    },
    difficultyScaling = {
        section = module.globalKey,
        order = 3,
        renderer = "checkbox",
        default = false,
        argument = { disabled = false },
    },
    globalPercent = {
        section = module.globalKey,
        order = 4,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues(true),
        argument = percentIncreaseArgument(false, true, true),
    },
    physicalDamagePercent = {
        section = module.playerKey,
        order = 0,
        renderer = "textLine",
        default = "",
        argument = { disabled = true },
    },
    magicDamagePercent = {
        section = module.playerKey,
        order = 1,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues(true),
        argument = percentIncreaseArgument(true, false, true),
    },
    sunDamagePercent = {
        section = module.playerKey,
        order = 2,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues(true),
        argument = percentIncreaseArgument(true, false, true),
    },
    attributesGlobalPercent = {
        section = module.actorsKey,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues(true),
        argument = percentIncreaseArgument(true, true, true),
    },
    dynamicStatsGlobalPercent = {
        section = module.actorsKey,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues(true),
        argument = percentIncreaseArgument(true, true, true),
    },
}

local valueMap = {}
for _, value in ipairs(cfg.presets.argument.values) do
    local valueKey = presetValue(value.name)
    table.insert(cfg.presets.argument.items, valueKey)
    valueMap[valueKey] = value
end
cfg.presets.argument.valueMap = valueMap

cfg.attributesGlobalPercent.order = 0
local i = 1
-- core stats to get ordered stats
for _, attribute in ipairs(core.stats.Attribute.records) do
    cfg[percentKey(attribute.id)] = {
        section = module.actorsKey,
        order = i,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues(true),
        argument = percentIncreaseArgument(true, false, i == 1),
    }
    i = i + 1
end

module.orderedDynamicStats = { "health", "magicka", "fatigue" }

cfg.dynamicStatsGlobalPercent.order = i
local j = 1
for _, statId in pairs(module.orderedDynamicStats) do
    cfg[percentKey(statId)] = {
        section = module.actorsKey,
        order = i + j,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues(true),
        argument = percentIncreaseArgument(true, false, j == 1),
    }
    j = j + 1
end
for key, value in pairs(cfg) do
    value.key = key
    value.name = key .. "_name"
    value.description = key .. "_description"
end
module.cfg = cfg

local function getSection(settingKey)
    return storage.globalSection(cfg[settingKey].section)
end
module.getSection = getSection

module.updateCheckBoxArgument = function(key, disabled)
    I.Settings.updateRendererArgument(cfg[key].section, key, { disabled = disabled })
end

module.updatePercentArgument = function(key, disabled, withIncrease)
    cfg[key].argument.disabled = disabled
    cfg[key].argument.withIncrease = withIncrease
    I.Settings.updateRendererArgument(cfg[key].section, key, cfg[key].argument)
end

return module