local I = require('openmw.interfaces')
local core = require('openmw.core')
local constants = require('scripts.holidaysandbirthdays.constants')

-- Load localization
local modInfo = require('scripts.holidaysandbirthdays.modinfo')
local l10n = core.l10n(modInfo.name)

----------------------------------------------------------------------------------
-- SETTINGS PAGE TRIGGERS AND GROUPS REGISTRATION | Player context
----------------------------------------------------------------------------------

local API = I.StatsWindow
if API then
    print("[HolidasAndBirthDays] Registering Stats Window Integration Settings")
    I.Settings.registerGroup({
        key = constants.statsWindowIntegrationStorageKey,
        page = modInfo.name,
        order = 0, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('stats_window_settings_name'),
        description = l10n('stats_window_settings_desc'),
        permanentStorage = true,
        settings = {
            {
                key = constants.statsWindowPaneKey,
                default = constants.statsWindowPaneDefault,
                renderer = 'select',
                name = l10n('stats_window_pane_setting_name'),
                description = l10n('stats_window_pane_setting_desc'),
                argument = {
                    disabled = false,
                    l10n = modInfo.l10n,
                    items = { "left", "right" }
                }
            },
            {
                key = constants.statsWindowPlacementSettingKey,
                default = constants.statsWindowPlacementSettingDefault,
                renderer = 'select',
                name = l10n('stats_window_placement_setting_name'),
                description = l10n('stats_window_placement_setting_desc'),
                argument = {
                    disabled = false,
                    l10n = modInfo.l10n,
                    items = { "top", "bottom" }
                }
            },
            {
                key = constants.indentValuesKey,
                default = constants.indentValuesDefault,
                renderer = 'checkbox',
                name = l10n('intent_values_setting_name'),
                description = l10n('intent_values_setting_desc'),
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },

        }
    })
end
