local core = require('openmw.core')
local I = require('openmw.interfaces')
local constants = require('scripts.holidaysandbirthdays.constants')

-- Load localization
local modInfo = require('scripts.holidaysandbirthdays.modinfo')
local l10n = core.l10n(modInfo.name)

----------------------------------------------------------------------------------
-- SETTINGS PAGE TRIGGERS AND GROUPS REGISTRATION | Global context
----------------------------------------------------------------------------------
if I.Settings then

    print("[HolidasAndBirthDays] Registering Global Settings")
    I.Settings.registerGroup({
        key = constants.globalSettingsStorageKey,
        page = modInfo.name,
        order = 0, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('daedric_settings_name'),
        permanentStorage = true,
        settings = {
            {
                key = constants.enableDaedricLimitersKey,
                default = constants.enableDaedricLimitersDefault,
                renderer = 'checkbox',
                name = l10n('enable_daedric_limiters_name'),
                description = l10n('enable_daedric_limiters_desc'),
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },

        }
    })
end
--    print("[HolidasAndBirthDays Settings] Registered settings page and groups for " .. modInfo.name)
-- else
--     print("[HolidasAndBirthDays Settings] ERROR: I.Settings interface not available. Settings registration skipped.")

-- This script's sole purpose is to register settings UI.
-- No game logic or engine handlers here.
