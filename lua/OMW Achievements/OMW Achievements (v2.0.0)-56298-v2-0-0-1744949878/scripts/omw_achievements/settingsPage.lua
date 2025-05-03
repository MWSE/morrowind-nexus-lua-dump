local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local input = require('openmw.input')
local core = require('openmw.core')
local async = require('openmw.async')
local util = require('openmw.util')
local v2 = util.vector2

local l10n = core.l10n('OmwAchievements')

local positions = {"right_top", "left_top", "right_bottom", "left_bottom", "center_bottom", "center_top"}
local warning = require('scripts.omw_achievements.ui.warning_window')

-- inputKeySelection by Pharis (taken from PerfectPlacement)
I.Settings.registerRenderer('OmwAchievements/inputKeySelection', function(value, set)
	local name = 'No Key Set'
	if value then
		name = input.getKeyName(value)
	end
	return {
		template = I.MWUI.templates.box,
		content = ui.content {
			{
				template = I.MWUI.templates.padding,
				content = ui.content {
					{
						template = I.MWUI.templates.textEditLine,
						props = {
							text = name,
						},
						events = {
							keyPress = async:callback(function(e)
								if e.code == input.KEY.Escape then return end
								set(e.code)
							end),
						},
					},
				},
			},
		},
	}
end)

-- cleanStorageRenderer
I.Settings.registerRenderer('OmwAchievements/cleanStorageRenderer', function(value, set)
    warningWindow = nil
	return {
		template = I.MWUI.templates.box,
		content = ui.content {
			{
				template = I.MWUI.templates.padding,
				content = ui.content {
					{
						template = I.MWUI.templates.textNormal,
						props = {
							text = l10n("warning_setting_button"),
						},
						events = {
							mousePress = async:callback(function(e)
                                warningWindow = warning.createWindow()
							end),
                            keyPress = async:callback(function(e)
								if e.code == input.KEY.Escape then
                                    if warningWindow ~= nil then
                                        warningWindow:destroy()
                                    end
                                end
							end),
						},
					},
				},
			},
		},
	}
end)

I.Settings.registerPage {
    key = "OmwAchievements",
    l10n = "OmwAchievements",
    name = "setting_omwachievements_page",
    description = "setting_omwachievements_page_description"
}

I.Settings.registerGroup {
    key = 'Settings/OmwAchievements/ZCleanStorage',
    page = 'OmwAchievements',
    l10n = 'OmwAchievements',
    name = 'setting_omwachievements_clean_storage_group',
    description = 'setting_omwachievements_group_clean_storage_description',
    permanentStorage = true,
    settings = {
        {
            renderer = 'OmwAchievements/cleanStorageRenderer',
            key = 'storage_cleaner',
            name = 'setting_clean_storage'
        }
    },
}

I.Settings.registerGroup {
    key = 'Settings/OmwAchievements/Options',
    page = 'OmwAchievements',
    l10n = 'OmwAchievements',
    name = 'setting_omwachievements_group',
    description = 'setting_omwachievements_group_description',
    permanentStorage = true,
    settings = {
        {
            renderer = 'OmwAchievements/inputKeySelection',
            key = 'toggle_omwa',
            name = 'setting_toggle',
            description = 'setting_toggle_description',
            default = input.KEY.O
        },
        {
            key = 'show_hidden',
            renderer = 'checkbox',
            name = 'setting_show_hidden',
            description = 'setting_show_hidden_description',
            default = false
        },
        {
            key = 'notification_position',
            renderer = 'select',
            name = 'setting_notification_position',
            description = 'setting_notification_position_description',
            default = "right_top",
            argument = {
                disabled = false,
                l10n = 'OmwAchievements',
                items = positions
            }
        },
        {
            key = 'notification_duration',
            renderer = 'textLine',
            name = 'setting_notification_duration',
            description = 'setting_notification_duration_description',
            default = 3.5
        },
        {
            key = 'notification_scaling_factor',
            renderer = 'textLine',
            name = 'setting_notification_scaling_factor',
            description = 'setting_notification_scaling_factor_description',
            default = 1
        },
        {
            key = 'ui_scaling_factor',
            renderer = 'textLine',
            name = 'setting_ui_scaling_factor',
            description = 'setting_ui_scaling_factor_description',
            default = 1
        },
    },
}
