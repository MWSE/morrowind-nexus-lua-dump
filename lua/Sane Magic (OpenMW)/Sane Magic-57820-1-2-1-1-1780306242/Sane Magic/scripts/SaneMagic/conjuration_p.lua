local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')

local storage = require('openmw.storage')
local conjData = storage.globalSection('SaneMagicConjuration')
local playerSettingsSummons = storage.playerSection('SettingsPlayerSaneMagic04_Summons')

local function updateGlobalSettings()

    core.sendGlobalEvent("smSetConjurationData", {
        key = "smConjurationMode",
        value = playerSettingsSummons:get("smConjurationMode")
    })
    core.sendGlobalEvent("smSetConjurationData", {
        key = "smConjurationDamage",
        value = playerSettingsSummons:get("smConjurationDamage")
    })
    core.sendGlobalEvent("smSetConjurationData", {
        key = "smConjurationDamageType",
        value = playerSettingsSummons:get("smConjurationDamageType")
    })

    core.sendGlobalEvent("smSetConjurationData", {
        key = "smConjurationOnlyPlayerDamage",
        value = playerSettingsSummons:get("smConjurationOnlyPlayerDamage")
    })    
end

local function UiModeChanged(data)
    if data.newMode == nil and data.oldMode ~= nil then
        updateGlobalSettings()
    end
end

return {
    engineHandlers = {
        onInit = updateGlobalSettings
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    }
}
