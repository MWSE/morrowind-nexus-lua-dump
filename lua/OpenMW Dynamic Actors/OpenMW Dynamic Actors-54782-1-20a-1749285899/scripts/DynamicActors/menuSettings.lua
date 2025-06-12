local ui = require('openmw.ui')
local input = require("openmw.input")
local async = require('openmw.async')
local I = require("openmw.interfaces")


I.Settings.registerRenderer("inputKeyBox", function(v, set)
	local name = "none"
	if v then name = input.getKeyName(v) end
	return { template = I.MWUI.templates.box, content = ui.content {
		{ template = I.MWUI.templates.padding, content = ui.content {
			{ template = I.MWUI.templates.textEditLine,
				props = { text = name, },
				events = {
					keyPress = async:callback(function(e)
						if e.code == input.KEY.Escape then return end
						set(e.code)
					end),
					},
			},
		}, },
	}, }
end)

I.Settings.registerRenderer("hiddenKey", function() return {content = ui.content {}} end)


I.Settings.registerPage {
   key = "dynamicactors_camera",
   l10n = "DynamicActors",
   name = "settings_camera_modName",
   description = "settings_camera_modDesc",
}

I.Settings.registerGroup({
   key = "Settings_dynactors_camera",
   page = "dynamicactors_camera",
   l10n = "DynamicActors",
   name = "settings_camera_name",
   permanentStorage = true,
   settings = {

-- Camera Settings

	{key = "dialog_disableHud",
	default = true,
	renderer = "checkbox",
	name = "settings_camera_01_name",
	},
	{key = "dialog_1stperson",
	default = true,
	renderer = "checkbox",
	name = "settings_camera_02_name",
	},
	{key = "dialog_1st_zoom",
	default = true,
	renderer = "checkbox",
	name = "settings_camera_03_name",
	},
	{key = "dialog_1st_zoomdist",
	default = 70,
	renderer = "number",
	name = "settings_camera_04_name",
	argument = { min = 40, max = 300 },
	},
	{key = "dialog_1st_dof_str",
	default = 20,
	renderer = "number",
	name = "settings_camera_05_name",
	description = "settings_camera_05_desc",
	argument = { min = 0, max = 100 },
	},
	{key = "dialog_1st_ratio",
	default = 2.2,
	renderer = "number",
	name = "settings_camera_06_name",
	description = "settings_camera_06_desc",
	argument = { min = 0, max = 10 },
	},
	{key = "dialog_1st_zoom_speed",
	default = 50,
	renderer = "number",
	name = "settings_camera_07_name",
	argument = { min = 10, max = 200 },
	},
	{key = "dialog_1st_zoom_offset",
	default = 0,
	renderer = "number",
	name = "settings_camera_08_name",
	description = "settings_camera_08_desc",
	argument = { min = -90, max = 90 },
	},

   },
})


I.Settings.registerPage {
   key = "dynamicactors",
   l10n = "DynamicActors",
   name = "settings_modName",
   description = "settings_modDesc",
}

I.Settings.registerGroup({
   key = "Settings_dynactors_player",
   page = "dynamicactors",
   l10n = "DynamicActors",
   name = "settings_player_name",
   permanentStorage = true,
   settings = {

--[[
-- Camera Settings

	{key = "dialog_disableHud",
	default = true,
	renderer = "checkbox",
	name = "settings_camera_01_name",
	},
	{key = "dialog_1stperson",
	default = true,
	renderer = "checkbox",
	name = "settings_camera_02_name",
	},
	{key = "dialog_1st_zoom",
	default = true,
	renderer = "checkbox",
	name = "settings_camera_03_name",
	},
	{key = "dialog_1st_zoomdist",
	default = 70,
	renderer = "number",
	name = "settings_camera_04_name",
	argument = { min = 40, max = 300 },
	},
	{key = "dialog_1st_dof_str",
	default = 20,
	renderer = "number",
	name = "settings_camera_05_name",
	description = "settings_camera_05_desc",
	argument = { min = 0, max = 100 },
	},
	{key = "dialog_1st_ratio",
	default = 2.2,
	renderer = "number",
	name = "settings_camera_06_name",
	description = "settings_camera_06_desc",
	argument = { min = 0, max = 10 },
	},
	{key = "dialog_1st_zoom_speed",
	default = 50,
	renderer = "number",
	name = "settings_camera_07_name",
	argument = { min = 10, max = 200 },
	},
	{key = "dialog_1st_zoom_offset",
	default = 0,
	renderer = "number",
	name = "settings_camera_08_name",
	description = "settings_camera_08_desc",
	argument = { min = -90, max = 90 },
	},
--]]

-- Player Settings

	{key = "actionHotkey",
	default = input.KEY.P,
	renderer = "inputKeyBox",
	name = "settings_player_setting06_name",
	description = "settings_player_setting06_desc",
	},
        {key = "baseIdleAnim_main",
	name = "settings_player_setting07_name",
	description = "settings_player_setting07_desc",
	default = "Ready Pose",
	renderer = "select",
	argument = {
		disabled = false,
		l10n = "DynamicActors", 
		items = { "None", "Ready Pose", "Hand on Hip contrapose", "Idle2" },
		},
	},
        {key = "baseIdleAnim_upper",
	name = "settings_player_setting08_name",
	description = "settings_player_setting08_desc",
	default = "Arms Folded",
	renderer = "select",
	argument = {
		disabled = false,
		l10n = "DynamicActors", 
		items = { "None", "Arms Folded", "anim_akimbo", "Arms Back Clasp", "Ready Pose" },
		},
	},
	{key = "rndIdleAnim",
	default = true,
	renderer = "checkbox",
	name = "settings_player_setting09_name",
	},
	{key = "autoHelm",
	default = true,
	renderer = "checkbox",
	name = "settings_player_setting10_name",
	},
	{key = "autoHelmItemID",
	default = nil,
	renderer = "textLine",
	name = "settings_player_setting12_name",
	},
	{key = "autoHelmItemID2",
	default = nil,
	renderer = "textLine",
	name = "settings_player_setting13_name",
	},
   },
})


return
