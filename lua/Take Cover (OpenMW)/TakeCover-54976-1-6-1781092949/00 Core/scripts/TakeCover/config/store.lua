local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require("openmw.interfaces")

local mDef = require('scripts.TakeCover.config.definition')
local mHelpers = require('scripts.TakeCover.util.helpers')

local trackerCallbacks = {}

local module = {}

module.sections = {
    main = { name = "Main", order = 0 },
}

local sections = module.sections

module.settings = {
    enabled = {
        order = 0,
        section = sections.main,
        description = false,
        renderer = "checkbox",
        argument = {
            disabled = not mDef.isLuaApiRecentEnough,
        },
        default = true,
    },
    debugMode = {
        order = 1,
        section = sections.main,
        description = false,
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
            for _, setting in mHelpers.spairs(settings,
                    function(t, a, b) return t[a].order < t[b].order end,
                    function(item) return item.section == section end) do
                setting.name = setting.key .. "_name"
                if setting.description ~= false then
                    setting.description = setting.key .. "_desc"
                else
                    setting.description = nil
                end
                section.settings[#section.settings + 1] = setting
            end
        end
        I.Settings.registerGroup(section)
    end

    if not mDef.isLuaApiRecentEnough then
        settings.enabled.set(false)
    end
end

module.addTrackerCallback = function(callback)
    trackerCallbacks[#trackerCallbacks + 1] = callback
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
        for vKey, value in mHelpers.spairs(setting.enum, function(t, a, b) return t[a] < t[b] end) do
            local itemKey = setting.isGlobalEnum and vKey or (key .. vKey)
            items[#items + 1] = itemKey
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
