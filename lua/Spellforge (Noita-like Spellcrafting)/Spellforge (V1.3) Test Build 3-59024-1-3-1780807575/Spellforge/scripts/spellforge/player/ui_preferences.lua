---@omw-context player
local storage = require("openmw.storage")

local ui_preferences = {}

local GROUP_KEY = "SettingsPlayerSpellforge"
local KEY_UI_SIZE = "ui_size"

local PRESETS = {
    Normal = 1.0,
    Large = 1.15,
    ["Extra Large"] = 1.3,
}

local section = nil

local function normalizePreset(value)
    if type(value) ~= "string" or value == "" then
        return "Normal"
    end
    if PRESETS[value] ~= nil then
        return value
    end
    local lowered = string.lower(value)
    lowered = string.gsub(lowered, "[%s_%-]+", "")
    if lowered == "large" then
        return "Large"
    end
    if lowered == "extralarge" or lowered == "xl" then
        return "Extra Large"
    end
    return "Normal"
end

local function settingsSection()
    if section ~= nil then
        return section
    end
    if type(storage.playerSection) == "function" then
        local ok, result = pcall(storage.playerSection, GROUP_KEY)
        if ok then
            section = result
        end
    end
    return section
end

function ui_preferences.uiSizePreset()
    local current = nil
    local current_section = settingsSection()
    if current_section and type(current_section.get) == "function" then
        local ok, value = pcall(function()
            return current_section:get(KEY_UI_SIZE)
        end)
        if ok then
            current = value
        end
    end
    return normalizePreset(current)
end

function ui_preferences.uiScale()
    local preset = ui_preferences.uiSizePreset()
    return PRESETS[preset] or PRESETS.Normal
end

function ui_preferences.uiScaleKey()
    return ui_preferences.uiSizePreset()
end

return ui_preferences
