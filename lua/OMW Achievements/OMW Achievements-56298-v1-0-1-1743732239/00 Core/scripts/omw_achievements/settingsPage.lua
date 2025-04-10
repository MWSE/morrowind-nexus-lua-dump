local I = require('openmw.interfaces')
local storage = require('openmw.storage')

I.Settings.registerPage {
    key = "OmwAchievementsPage",
    l10n = "OmwAchievements",
    name = "setting_omwachievements_page",
    description = "setting_omwachievements_page_description"
}

I.Settings.registerGroup {
    key = 'SettingsPlayerOmwAchievements',
    page = 'OmwAchievementsPage',
    l10n = 'OmwAchievements',
    name = 'setting_omwachievements_group',
    description = 'setting_omwachievements_group_description',
    permanentStorage = true,
    settings = {
        {
            key = 'toggle',
            renderer = 'textLine',
            name = 'setting_toggle',
            description = 'setting_toggle_description',
            default = 'o'
        },
        {
            key = 'show_hidden',
            renderer = 'checkbox',
            name = 'setting_show_hidden',
            description = 'setting_show_hidden_description',
            default = false
        }
    },
}

local playerSettings = storage.playerSection('SettingsPlayerOmwAchievements')