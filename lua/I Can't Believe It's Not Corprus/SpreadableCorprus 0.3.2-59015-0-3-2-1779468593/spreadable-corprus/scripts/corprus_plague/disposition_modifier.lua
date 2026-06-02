local storage = require('openmw.storage')
local config = require('scripts.corprus_plague.config')
local settingsValues = require('scripts.corprus_plague.settings_values')
local settingsMirror = require('scripts.corprus_plague.settings_mirror')

local M = {}

function M.getPerInfection(override)
    if override ~= nil then
        return settingsValues.resolveDispositionModifier(override)
    end

    local mirrored = settingsMirror.getDispositionModifier()
    if mirrored ~= nil then
        return settingsValues.resolveDispositionModifier(mirrored)
    end

    -- Fallback if global runs before the player has synced (should not affect normal play).
    local value = storage.globalSection(config.settingsGroupKey):get('dispositionModifier')
    if value == nil then
        return config.defaultDispositionModifier
    end
    return settingsValues.resolveDispositionModifier(value)
end

return M
