local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local constants = require('scripts.holidaysandbirthdays.constants')

-- Load localization
local modInfo = require('scripts.holidaysandbirthdays.modinfo')
local l10n = core.l10n(modInfo.name)

----------------------------------------------------------------------------------
-- SETTINGS PAGE TRIGGERS AND GROUPS REGISTRATION | Menu context
----------------------------------------------------------------------------------
if I.Settings then
    input.registerTrigger {
        key = constants.showMessageTriggerKey,
        l10n = modInfo.l10n,
        name = "",
        description = "",
    }

    I.Settings.registerPage({
        key = modInfo.name,
        l10n = modInfo.l10n,
        name = l10n('mod_name'), -- Display name of the page
        description = l10n('mod_description') .. "\n" ..
            l10n("general_info_text")
    })

    print("[HolidasAndBirthDays] Registering General Settings")
    I.Settings.registerGroup({
        key = constants.generalSettingsStorageKey,
        page = modInfo.name,
        order = 0, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('settings_name'),
        permanentStorage = true,
        settings = {

            {
                key = constants.getBirthDayGiftsKey,
                default = constants.getGiftsDefaultSetting,
                renderer = 'checkbox',
                name = l10n('get_bd_gift_setting_name'),
                description = l10n('get_bd_gift_setting_desc'),
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },
            {
                key = constants.showHMessageKeybindStorageKey,
                default = modInfo.name .. "showMessageTriggerKey",
                renderer = 'inputBinding',
                name = l10n('show_message_keybind_setting_name'),
                description = l10n('show_message_keybind_setting_desc'),
                argument = {
                    key = constants.showMessageTriggerKey,
                    type = "trigger"
                }
            },
            {
                key = constants.displayMessageStartKey,
                default = constants.defaultDisplayMessageStart,
                renderer = 'number',
                name = l10n('auto_message_range_start_setting_name'),
                description = l10n('auto_message_range_start_setting_desc'):gsub(
                    "{default}", constants.defaultDisplayMessageStart):gsub(
                    "{min}", 0):gsub("{max}", 22),
                argument = { integer = true, min = 0, max = 22 }
            },
            {
                key = constants.displayMessageUntilKey,
                default = constants.defaultDisplayMessageUntil,
                renderer = 'number',
                name = l10n('auto_message_range_end_setting_name'),
                description = l10n('auto_message_range_end_setting_desc'):gsub(
                    "{default}", constants.defaultDisplayMessageUntil):gsub(
                    "{min}", 1):gsub("{max}", 23),
                argument = { integer = true, min = 1, max = 23 }
            },
            {
                key = constants.combineHolidayMessagesKey,
                default = constants.combineHolidayMessagesDefault,
                renderer = 'checkbox',
                name = l10n('combine_holiday_messages_name'),
                description = l10n('combine_holiday_messages_desc'),
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
