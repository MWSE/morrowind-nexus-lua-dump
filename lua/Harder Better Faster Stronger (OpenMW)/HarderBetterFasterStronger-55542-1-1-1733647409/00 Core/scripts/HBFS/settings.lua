local I = require("openmw.interfaces")
local core = require('openmw.core')
local storage = require('openmw.storage')

local module = {
    MOD_NAME = "HBFS",
    isLuaApiRecentEnough = core.API_REVISION >= 68,
    isOpenMW049 = core.API_REVISION > 29,
    saveVersion = 1.1,
}

module.l10n = core.l10n(module.MOD_NAME)

module.globalKey = "SettingsGlobal" .. module.MOD_NAME
module.globalSection = function() return storage.globalSection(module.globalKey) end
module.playerKey = "SettingsPlayer" .. module.MOD_NAME
module.playerSection = function() return storage.globalSection(module.playerKey) end
module.actorsKey = "SettingsActors" .. module.MOD_NAME
module.actorsSection = function() return storage.globalSection(module.actorsKey) end

module.defaultPercent = 100

local percentRenderer = "percentAndIncrease"
local defaultPercentIncreaseValues = { checked = true, base = module.defaultPercent, increase = 5, actual = module.defaultPercent }

local percentIncreaseArgument = function(disabled, isGlobal, allowHeaders)
    return {
        l10n = module.MOD_NAME,
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

local cfg = {
    enabled = {
        section = module.globalKey,
        order = 0,
        renderer = "checkbox",
        default = true,
    },
    globalPercent = {
        section = module.globalKey,
        order = 1,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues,
        argument = percentIncreaseArgument(false, true, true),
    },
    dynamicIncrease = {
        section = module.globalKey,
        order = 2,
        renderer = "checkbox",
        default = false,
    },
    debugMode = {
        section = module.globalKey,
        order = 3,
        renderer = "checkbox",
        default = false,
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
        default = defaultPercentIncreaseValues,
        argument = percentIncreaseArgument(true, false, true),
    },
    attributesGlobalPercent = {
        section = module.actorsKey,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues,
        argument = percentIncreaseArgument(true, true, true),
    },
    dynamicStatsGlobalPercent = {
        section = module.actorsKey,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues,
        argument = percentIncreaseArgument(true, true, true),
    },
}
local function percentKey(prefix)
    return prefix .. "Percent"
end
module.percentKey = percentKey

cfg.attributesGlobalPercent.order = 0
local i = 1
-- core stats to get ordered stats
for _, attribute in ipairs(core.stats.Attribute.records) do
    cfg[percentKey(attribute.id)] = {
        section = module.actorsKey,
        order = i,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues,
        argument = percentIncreaseArgument(true, false, i == 1),
    }
    i = i + 1
end

module.dynamicStatsOrder = { "health", "magicka", "fatigue" }

cfg.dynamicStatsGlobalPercent.order = i
local j = 1
for _, statId in pairs(module.dynamicStatsOrder) do
    cfg[percentKey(statId)] = {
        section = module.actorsKey,
        order = i + j,
        renderer = percentRenderer,
        default = defaultPercentIncreaseValues,
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

module.updatePercentArgument = function(key, disabled, withIncrease)
    cfg[key].argument.disabled = disabled
    cfg[key].argument.withIncrease = withIncrease
    I.Settings.updateRendererArgument(cfg[key].section, key, cfg[key].argument)
end

return module