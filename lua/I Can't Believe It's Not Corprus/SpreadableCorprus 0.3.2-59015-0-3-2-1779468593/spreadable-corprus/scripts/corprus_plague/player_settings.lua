-- Read mod settings from playerSection (player script only).
local storage = require('openmw.storage')
local core = require('openmw.core')
local config = require('scripts.corprus_plague.config')
local settingsValues = require('scripts.corprus_plague.settings_values')

local M = {}

function M.readFromStorage()
    local section = storage.playerSection(config.settingsGroupKey)
    return {
        dispositionModifier = settingsValues.resolveDispositionModifier(section:get('dispositionModifier')),
        incubationDays = settingsValues.resolveIncubationDays(section:get('incubationDays')),
    }
end

function M.syncToGlobal()
    core.sendGlobalEvent('CorprusPlagueSyncSettings', M.readFromStorage())
end

return M
