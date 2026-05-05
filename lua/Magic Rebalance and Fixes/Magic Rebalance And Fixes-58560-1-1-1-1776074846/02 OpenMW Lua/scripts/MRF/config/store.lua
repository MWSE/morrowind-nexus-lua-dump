local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local async = require('openmw.async')

local mDef = require("scripts.MRF.config.definition")
local mH = require("scripts.MRF.util.helpers")

local trackerCallbacks = {}

local module = {
    sections = {
        main = { name = "Main", order = 0, description = false },
    },
    showSpellModes = { Disabled = 0, Known = 1, Active = 2 },
}

local sections = module.sections

module.settings = {
    -- MAIN
    enforceConstantEnchantmentDebuffs = {
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
}
local settings = module.settings

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
                setting.description = setting.key .. "_desc"
                table.insert(section.settings, setting)
            end
        end
        I.Settings.registerGroup(section)
    end

    if not mDef.isLuaApiRecentEnough then
        settings.enforceConstantEnchantmentDebuffs.set(false)
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