---@omw-context menu
local modInfo   = require('scripts.canttouchthis.modinfo')
local core      = require("openmw.core")
local I         = require('openmw.interfaces')
local SettingsConstants = require('scripts.canttouchthis.helpers.settings_constants')
local l10n      = core.l10n(modInfo.l10n)



if I.Settings then
    I.Settings.registerPage({
        key = modInfo.modKey,
        l10n = modInfo.l10n,
        name = l10n('mod_name'), -- Display name of the page
        description = l10n('mod_description') .. "\n" ..
            l10n("general_info_text")
    })

    I.Settings.registerGroup({
        key = SettingsConstants.settingsStorageKey,
        page = modInfo.modKey,
        order = 0, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('settings_name'),
        description = "",
        permanentStorage = true,
        settings = {
            {
                key = SettingsConstants.playMissAnimationsForPlayerKey,
                renderer = 'checkbox',
                name = l10n('play_miss_animations_for_player_setting_name'),
                description = l10n('play_miss_animations_for_player_setting_desc'),
                default = SettingsConstants.playMissAnimationsForPlayerDefault,
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },
        },
    })
end
