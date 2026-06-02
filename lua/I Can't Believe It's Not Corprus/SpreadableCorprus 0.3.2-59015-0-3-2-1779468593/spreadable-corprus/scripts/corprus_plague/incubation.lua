local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local config = require('scripts.corprus_plague.config')
local settingsValues = require('scripts.corprus_plague.settings_values')
local settingsMirror = require('scripts.corprus_plague.settings_mirror')

local M = {}

function M.getDays()
    local mirrored = settingsMirror.getIncubationDays()
    if mirrored ~= nil then
        return settingsValues.resolveIncubationDays(mirrored)
    end

    local days = storage.globalSection(config.settingsGroupKey):get('incubationDays')
    return settingsValues.resolveIncubationDays(days)
end

function M.getSeconds()
    return M.getDays() * time.day
end

return M
