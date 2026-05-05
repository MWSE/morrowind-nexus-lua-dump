local modInfo           = require('scripts.ngarde.modinfo')
local core              = require("openmw.core")
local input             = require('openmw.input')
local I                 = require('openmw.interfaces')
local SettingsConstants = require('scripts.ngarde.helpers.settings_constants')
local logging           = require('scripts.ngarde.helpers.logger').new()
logging:setLoglevel(logging.LOG_LEVELS.OFF)
local l10n = core.l10n(modInfo.l10n)

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

    logging:info("Registering General Settings")
    I.Settings.registerGroup({
        key = SettingsConstants.generalSettingsStorageKey,
        page = modInfo.name,
        order = 0, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('settings_name'),
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
        },
    })
else
    logging:error("I.Settings is not available.")
end
