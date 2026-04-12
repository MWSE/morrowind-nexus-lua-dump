local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require('openmw.async')

local mDef = require("scripts.SBMR.config.definition")
local mH = require("scripts.SBMR.util.helpers")

local trackerCallbacks = {}

local module = {
    sections = {
        main = { name = "Main", order = 0 },
        factors = { name = "Factors", order = 1 },
    },
    regenMainStats = { Intelligence = 1, Magicka = 2, Willpower = 3 },
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
    },
    debugMode = {
        order = 1,
        section = sections.main,
        renderer = "checkbox",
        default = false,
    },
    regenMainStat = {
        order = 2,
        section = sections.main,
        renderer = "select",
        enum = module.regenMainStats,
        default = module.regenMainStats.Willpower
    },
    playerMainStatRegenPerMinPercent = {
        order = 3,
        section = sections.main,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000, isPercent = true },
        default = 20,
    },
    actorsMainStatRegenPerMinPercent = {
        order = 4,
        section = sections.main,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000, isPercent = true },
        default = 50,
    },
    timescaleForLongPeriodsOfTimePassed = {
        order = 5,
        section = sections.main,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 1, max = 1000 },
        default = 30,
    },
    -- FACTORS
    intelligenceRegenImpactPercent = {
        order = 0,
        section = sections.factors,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 1000, isPercent = true },
        default = { from = 50, to = 150 },
    },
    willpowerRegenImpactPercent = {
        order = 1,
        section = sections.factors,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 1000, isPercent = true },
        default = { from = 100, to = 100 },
    },
    fatigueRegenImpactPercent = {
        order = 2,
        section = sections.factors,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 1000, isPercent = true },
        default = { from = 50, to = 100 },
    },
    encumbranceRegenImpactPercent = {
        order = 3,
        section = sections.factors,
        renderer = mDef.renderers.range,
        argument = { min = 0, max = 1000, isPercent = true },
        default = { from = 50, to = 100 },
    },
    walkRegenPercent = {
        order = 4,
        section = sections.factors,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        default = 75,
    },
    runRegenPercent = {
        order = 5,
        section = sections.factors,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        default = 50,
    },
    regeneratingActorsRegenPercent = {
        order = 6,
        section = sections.factors,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        default = 0,
    },
    stuntedMagickaRegenPercent = {
        order = 7,
        section = sections.factors,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 100, isPercent = true },
        default = 0,
    },
    restInBedRegenPercent = {
        order = 8,
        section = sections.factors,
        renderer = mDef.renderers.number,
        argument = { integer = true, min = 0, max = 1000, isPercent = true },
        default = 200,
    },
}
local settings = module.settings

module.registerGroups = function()
    for _, section in pairs(sections) do
        section.page = mDef.MOD_NAME
        section.l10n = mDef.MOD_NAME
        local name = section.name
        section.name = name .. "SectionTitle"
        section.description = mDef.getMessageKeyIfOpenMWTooOld(name .. "SectionDesc")
        section.permanentStorage = false
        section.settings = {}
        if mDef.isLuaApiRecentEnough then
            for _, setting in mH.spairs(settings,
                    function(t, a, b) return t[a].order < t[b].order end,
                    function(item) return item.section == section end) do
                setting.name = setting.key .. "_name"
                setting.description = setting.key .. "_desc"
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