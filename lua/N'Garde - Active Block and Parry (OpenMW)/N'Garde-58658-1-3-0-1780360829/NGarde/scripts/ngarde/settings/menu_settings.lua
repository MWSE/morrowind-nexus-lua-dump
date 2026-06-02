---@omw-context menu
local modInfo           = require('scripts.ngarde.modinfo')
local core              = require("openmw.core")
local input             = require('openmw.input')
local I                 = require('openmw.interfaces')
local SettingsConstants = require('scripts.ngarde.helpers.settings_constants')
local l10n = core.l10n(modInfo.l10n)

local RENDERER_SLIDER = "SuperSlider3"

if I.Settings then
    input.registerAction {
        key = SettingsConstants.parryActionKey,
        type = input.ACTION_TYPE.Boolean,
        l10n = modInfo.l10n,
        name = '',
        description = '',
        defaultValue = false,
    }


    I.Settings.registerPage({
        key = modInfo.name,
        l10n = modInfo.l10n,
        name = l10n('mod_name'), -- Display name of the page
        description = l10n('mod_description') .. "\n" ..
            l10n("general_info_text")
    })

    I.Settings.registerGroup({
        key = SettingsConstants.generalSettingsStorageKey,
        page = modInfo.name,
        order = 0, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('settings_name'),
        description = "",
        permanentStorage = true,
        settings = {
            {
                key = SettingsConstants.settingsParryKeyBindKey,
                renderer = 'inputBinding',
                name = l10n('parry_keybind_setting_name'),
                description = l10n('parry_keybind_setting_desc'),
                default = SettingsConstants.settingsParryKeyBindKey,
                argument = {
                    type = "action",
                    key = SettingsConstants.parryActionKey
                },
            },
            {
                key = SettingsConstants.controllerTriggerKey,
                renderer = 'select',
                name = l10n('controller_trigger_name'),
                description = l10n('controller_trigger_desc'),
                default = SettingsConstants.controllerTriggerDefault,
                argument = {
                    disabled = false,
                    l10n = modInfo.l10n,
                    items = SettingsConstants.controllerTriggerValues
                }
            },
            {
                key = SettingsConstants.triggerSensitivityKey,
                name =  l10n('trigger_sensitivity_name'),
                description = l10n('trigger_sensitivity_desc'),
                renderer = RENDERER_SLIDER,
                default = SettingsConstants.triggerSensitivityDefault,
                argument = { -- NOTE: maybe argument can't be a reused table
                    min = 0, -- default: 0
                    max = 100, -- default: 100
                    step = 1, -- default: 1
                    default = SettingsConstants.triggerSensitivityDefault, -- default: some features disabled // NOTE: default needs to be defined here too for the default mark and reset button to show up
                    showDefaultMark = true, -- default: false
                    showResetButton = false, -- default: false
                    bottomRow = true, -- default: false // 
                    minLabel = "Min", -- default: hidden
                    maxLabel = "Max", -- default: hidden
                    labelSize = 12, -- default: max(thickness-2, 10)
                    width = 150, -- default: 200
                    thickness = 14, -- default: 15
                    unit = "%", -- default: none
                },
            },
        },
    })
end
