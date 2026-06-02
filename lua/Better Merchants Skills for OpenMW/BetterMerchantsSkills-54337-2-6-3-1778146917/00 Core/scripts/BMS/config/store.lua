local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require('openmw.async')

local mDef = require("scripts.BMS.config.definition")
local mH = require("scripts.BMS.util.helpers")

local trackerCallbacks = {}

local module = {
    sections = {
        main = { name = "Main", order = 0, description = false },
        dispScaling = { name = "DispScaling", order = 1 },
        compat = { name = "Compat", order = 2 },
    },
    arguments = {
        minPercent = {
            min = 0,
            max = 75,
            isPercent = true,
        },
        maxPercent = {
            min = 25,
            max = 75,
            isPercent = true,
        },
        difficulty = {
            playerLevel = 1,
            from = {
                integer = true,
                min = 0,
                max = 500,
            },
            to = {
                integer = true,
                min = 0,
                max = 500,
            },
            maxLvl = {
                integer = true,
                min = 2,
                max = 500,
            },
        }
    },
}

local sections = module.sections

module.settings = {
    -- MAIN
    enabled = {
        order = 0,
        section = sections.main,
        renderer = "checkbox",
        argument = { disabled = not mDef.isLuaApiRecentEnough },
        default = true,
        description = false,
    },
    debugMode = {
        order = 1,
        section = sections.main,
        renderer = "checkbox",
        default = false,
        description = false,
    },
    minItemSalePricePercent = {
        order = 2,
        section = sections.main,
        renderer = mDef.renderers.number,
        default = 5,
        argument = module.arguments.minPercent,
    },
    maxItemSalePricePercent = {
        order = 3,
        section = sections.main,
        renderer = mDef.renderers.number,
        default = 50,
        argument = module.arguments.maxPercent,
    },
    serviceDifficulty = {
        order = 4,
        section = sections.main,
        renderer = mDef.renderers.scalingPercent,
        default = { from = 75, to = 100, maxLvl = 20 },
        argument = module.arguments.difficulty,
    },
    hagglingDifficulty = {
        order = 5,
        section = sections.main,
        renderer = mDef.renderers.scalingPercent,
        default = { from = 25, to = 75, maxLvl = 20 },
        argument = module.arguments.difficulty,
    },
    persuasionDifficulty = {
        order = 6,
        section = sections.main,
        renderer = mDef.renderers.scalingPercent,
        default = { from = 50, to = 75, maxLvl = 20 },
        argument = module.arguments.difficulty,
    },
    dispositionImpactOnPricesPercent = {
        order = 7,
        section = sections.main,
        renderer = mDef.renderers.number,
        default = 50,
        argument = { min = 0, max = 100, isPercent = true },
    },
    dispositionImpactOnHagglingPercent = {
        order = 8,
        section = sections.main,
        renderer = mDef.renderers.number,
        default = 50,
        argument = { min = 0, max = 100, isPercent = true },
    },
    preventSkillsBelowOriginalValues = {
        order = 9,
        section = sections.main,
        renderer = "checkbox",
        default = false,
    },
    -- DISPOSITION SCALING
    dispScalingEnabled = {
        order = 0,
        section = sections.dispScaling,
        renderer = "checkbox",
        default = true,
        description = false,
    },
    dispScalingNotify = {
        order = 1,
        section = sections.dispScaling,
        renderer = "checkbox",
        default = false,
    },
    dispScalingMaxBuyGain = {
        order = 2,
        section = sections.dispScaling,
        renderer = mDef.renderers.number,
        default = 10,
        argument = { min = 0, max = 100, integer = true },
    },
    dispScalingMaxSellGain = {
        order = 3,
        section = sections.dispScaling,
        renderer = mDef.renderers.number,
        default = 4,
        argument = { min = 0, max = 100, integer = true },
    },
    dispScalingMinBaseGold = {
        order = 4,
        section = sections.dispScaling,
        renderer = mDef.renderers.number,
        default = 500,
        argument = { min = 1, max = 9999, integer = true },
    },
    dispScalingMaxLoss = {
        order = 5,
        section = sections.dispScaling,
        default = 4,
        renderer = mDef.renderers.number,
        argument = { min = 0, max = 100, integer = true },
    },
    -- COMPATIBILITY
    -- auto-generated
}
local settings = module.settings

local order = 0
for uiMode in mH.spairs(mDef.supportedUiModes, function(_, a, b) return a < b end) do
    settings[uiMode .. "UiModeEnabled"] = {
        order = order,
        section = sections.compat,
        renderer = "checkbox",
        default = true,
        description = false,
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
            for _, setting in mH.spairs(settings,
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

module.updateRendererArgument = function(setting, argument)
    I.Settings.updateRendererArgument(setting.section.key, setting.key, argument)
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
    setting.get = function()
        return setting.value
    end
    setting.set = function(value)
        return setting.section.get():set(key, serializeValue(setting, value))
    end
    if setting.enum then
        local items = {}
        setting.keys = {}
        setting.values = {}
        for vKey, value in mH.spairs(setting.enum, function(t, a, b) return t[a] < t[b] end) do
            local itemKey = key .. vKey
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