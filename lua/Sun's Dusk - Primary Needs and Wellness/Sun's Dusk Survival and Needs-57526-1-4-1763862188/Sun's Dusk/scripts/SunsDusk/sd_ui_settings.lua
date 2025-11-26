local I = require('openmw.interfaces')
local layerId = ui.layers.indexOf("Modal")
local hudLayerSize = ui.layers[layerId].size
local screenres = ui.screenSize()
local uiScale = screenres.x / hudLayerSize.x

uiSettingsTemplate = {}

uiSettingsTemplate.UI = {
	key = "Settings"..MODNAME.."UI",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Sun's Dusk UI                                                ", -- lol
	permanentStorage = true,
	order = 0,
	settings = {
		{
			key = "HUD_PRESET",
			name = "Preset",
			description = "Changes Icon pack, background, color and Transparency",
			default = "Velothi (T)", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Velothi (T)", "Velothi2 (T)", "Modern (S)", "Modern2 (S)" },
			},
		},
		{
			key = "HUD_ALPHA",
			name = "Transparency Indicator",
			description = "Stages of needs are indicated by icon transparency",
			default = "Smooth", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Smooth", "Gradual", "Static" },
			},
		},
		{
			key = "HUD_LOCK",
			name = "Lock Position. Tooltips are disabled if the position is locked.",
			description = "",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "HUD_ICON_SIZE",
			name = "Icon size",
			description = "Increase or decrease icon size.\n\nDefault is 30.",
			renderer = "number",
			default = 30,
			argument = { min = 1, max = 750, },
		},		
		{
			key = "HUD_X_POS",
			name = "X Position",
			description = "",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.x*0.01),
		},		
		{
			key = "HUD_Y_POS",
			name = "Y Position",
			description = "",
			renderer = "number",
			integer = true,
			default = math.floor(hudLayerSize.y * (1 - 0.065 * uiScale)),
		},		
		{
			key = "HUD_LEFT_SHIFT_PER_BUFF",
			name = "Left shift per buff",
			description = "Move HUD widget to the left for each spell effect active on the HUD. Do not multiply by display scaling\n\nVanilla is 16 pixels.",
			renderer = "number",
			integer = true,
			default = 0,
		},			
		{
			key = "HUD_DISPLAY",
			name = "HUD Display",
			description = "When to display the HUD/widget element. Interface = when menus are pulled up",
			default = "Always", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Always", "Interface Only", "Hide on Interface","Hide on Dialogue Only","Never" },
			},
		},		
		{
			key = "HUD_ORIENTATION",
			name = "Orientation",
			description = "",
			default = "Horizontal", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Horizontal", "Vertical" },
			},
		},			
	}
}

uiSettingsTemplate.OTHER = {
	key = "Settings"..MODNAME.."OTHER",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Tooltips and Notifications",
	permanentStorage = true,
	order = 1,
	settings = {
		-- {
		-- 	key = "ENABLE_NOTIFICATIONS",
		-- 	name = "Enable Message Box notifications",
		-- 	description = "",
		-- 	renderer = "select",
		-- 	default = "Yes",
		-- 	argument = {
		-- 		disabled = false,
		-- 		l10n = "none", 
		-- 		items = {"Yes", "Only on special events", "No"}
		-- 	},
		-- },
		{
			key = "ENABLE_TOOLTIPS",
			name = "Enable Tooltips for UI",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TOOLTIP_RELATIVE_X",
			name = "Relative X Position (%)",
			description = "x=50, y=50 is crosshair",
			renderer = "number",
			integer = false,
			default = 51,
		},		
		{
			key = "TOOLTIP_RELATIVE_Y",
			name = "Relative Y Position (%)",
			description = "x=50, y=50 is crosshair",
			renderer = "number",
			integer = false,
			default = 50,
		},		
		{
			key = "TOOLTIP_FONT_COLOR",
			name = "Refill Tooltip text color",
			description = "",
			disabled = false,
			default = getColorFromGameSettings("fontColor_color_normal"), 
			renderer = "color",
		},
		{
			key = "TOOLTIP_FONT_SIZE",
			name = "Refill Tooltip font size",
			description = "Average text size",
			renderer = "number",
			integer = false,
			default = 24,
		},		
		{
			key = "MOUSE_TOOLTIP_FONT_COLOR",
			name = "UI Tooltip text color",
			description = "",
			disabled = false,
			default = getColorFromGameSettings("fontColor_color_normal"), 
			renderer = "color",
		},		
				{
			key = "MOUSE_TOOLTIP_FONT_SIZE",
			name = "UI Tooltip font size",
			description = "Average text size",
			renderer = "number",
			integer = false,
			default = 20,
		},
	},
}

-- ─────────────────────────────────────────────────────────────────────────────── SLEEP ───────────────────────────────────────────────────────────────────────────────

uiSettingsTemplate.UI_SLEEP = {
	key = "Settings"..MODNAME.."UI_SLEEP",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Sleep Icons and Display",
	permanentStorage = true,
	order = 2,
	settings = {
		{
			key = "S_SP_DISPLAY",
			name = "Sleep Personality Display",
			description = "Display the cooresponding HUD element if Sleep Personality is enabled.",
			renderer = "checkbox",
			default = true,
		},	
		{
			key = "S_SKIN",
			name = "Tiredness Icon Styles",
			description = "",
			default = "Velothi (Transparent)", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = iconPacks.sleep.availablePacks,
			},
		},	
		{
			key = "S_COLOR",
			name = "Color of Tiredness",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			default = util.color.hex("FFFFFF"), 
			renderer = "color",
		},		
		{
			key = "S_BACKGROUND",
			name = "Background style",
			description = "",
			default = "No Background", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = {"No Background", "Classic", "Shadow"},
			},
		},
		{
			key = "S_BACKGROUND_COLOR",
			name = "Classic background color",
			description = "Background icon color if using Classic background style.\n\nDefault Morrowind colors include caa560 and dfc99f but I recommend ffcd7b for a 'vanilla' feel.",
			disabled = false,
			default = util.color.hex("ffcd7b"), 
			renderer = "color",
		},	
	},
}

-- ─────────────────────────────────────────────────────────────────────────────── HUNGER ───────────────────────────────────────────────────────────────────────────────

uiSettingsTemplate.UI_HUNGER = {
	key = "Settings"..MODNAME.."UI_HUNGER",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Hunger Icons and Display",
	permanentStorage = true,
	order = 3,
	settings = {
		{
			key = "H_SP_DISPLAY",
			name = "Nourishment Display",
			description = "Display the cooresponding HUD element if Nourishment is enabled,.",
			renderer = "checkbox",
			default = true,
		},	
		{
			key = "H_SKIN",
			name = "Hunger Icon Styles",
			description = "",
			default = "Velothi (Transparent)", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = iconPacks.hunger.availablePacks,
			},
		},	
		{
			key = "H_COLOR",
			name = "Color of Hunger",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			default = util.color.hex("FFFFFF"), 
			renderer = "color",
		},		
		{
			key = "H_BACKGROUND",
			name = "Background style",
			description = "",
			default = "No Background", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "No Background", "Classic", "Shadow" },
			},
		},
		{
			key = "H_BACKGROUND_COLOR",
			name = "Classic background color",
			description = "Background icon color if using Classic background style.\n\nDefault Morrowind colors include caa560 and dfc99f but I recommend ffcd7b for a 'vanilla' feel.",
			disabled = false,
			default = util.color.hex("ffcd7b"), 
			renderer = "color",
		},	
	},
}

-- ─────────────────────────────────────────────────────────────────────────────── THIRST ───────────────────────────────────────────────────────────────────────────────
		
uiSettingsTemplate.UI_THIRST = {
	key = "Settings"..MODNAME.."UI_THIRST",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Thirst Icons and Display",
	permanentStorage = true,
	order = 4,
	settings = {
		{
			key = "T_SKIN",
			name = "Thirst Icon Styles",
			description = "",
			default = "Velothi (Transparent)", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = iconPacks.thirst.availablePacks,
			},
		},		
		{
			key = "T_COLOR",
			name = "Color of Thirst",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			default = util.color.hex("FFFFFF"), 
			renderer = "color",
		},		
		{
			key = "T_BACKGROUND",
			name = "Background style for icon",
			description = "",
			default = "No Background", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "No Background", "Classic", "Shadow" },
			},
		},

		{
			key = "T_BACKGROUND_COLOR",
			name = "Background style",
			description = "Background icon color if using Classic background style.\n\nDefault Morrowind colors include caa560 and dfc99f but I recommend ffcd7b for a 'vanilla' feel.",
			disabled = false,
			default = util.color.hex("ffcd7b"), 
			renderer = "color",
		},	
	},
}

-- ─────────────────────────────────────────────────────────────────────────────── TEMPERATURE ───────────────────────────────────────────────────────────────────────────────

-- uiSettingsTemplate.UI_TEMP = {
-- 	key = "Settings"..MODNAME.."UI_TEMP",
-- 	page = MODNAME.."UI",
-- 	l10n = "none",
-- 	name = "Temperature Display",
-- 	permanentStorage = true,
-- 	order = 5,
-- 	settings = {
-- 		{
-- 			key = "TEMP_SKIN",
-- 			name = "Thirst Icon Styles",
-- 			description = "",
-- 			default = "Velothi (Transparent)", 
-- 			renderer = "select",
-- 			argument = {
-- 				disabled = false,
-- 				l10n = "none",
-- 				items = iconPacks.thirst.availablePacks, -- one option would to add your icon to existing widget, one would enable my new widget, one would display text, 
-- 			},
-- 		},		
-- 		{
-- 			key = "TEMP_COLOR_1",
-- 			name = "Left Gradient Color",
-- 			description = "",
-- 			disabled = false,
-- 			default = util.color.hex("FFFFFF"), 
-- 			renderer = "color",
-- 		},	
-- 		{
-- 			key = "TEMP_COLOR_2",
-- 			name = "Middle Gradient Color",
-- 			description = "",
-- 			disabled = false,
-- 			default = util.color.hex("FFFFFF"), 
-- 			renderer = "color",
-- 		},
-- 		{
-- 			key = "TEMP_COLOR_3",
-- 			name = "Right Gradient Color",
-- 			description = "",
-- 			disabled = false,
-- 			default = util.color.hex("FFFFFF"), 
-- 			renderer = "color",
-- 		},			
-- 		{
-- 			key = "TEMP_BACKGROUND",
-- 			name = "Background style for bar",
-- 			description = "",
-- 			default = "No Background", 
-- 			renderer = "select",
-- 			argument = {
-- 				disabled = false,
-- 				l10n = "none",
-- 				items = { "No Background", "Classic", "Shadow" }, -- vanilla borders, skyrim border, 'clean' border (shape like skyrim's HUD with a slight offset on right side)
-- 			},
-- 		},
--		{
--			key = "TEMP_PADDING",
--			name = "Padding",
--			description = "",
--			renderer = "number",
--			default = 30,
--			argument = { min = 0, max = 1, },
--		},			
-- 	},
-- }

I.Settings.registerPage {
	key = MODNAME.."UI",
	l10n = "none",
	name = "Sun's Dusk: UI",
	description = "" -- UI settings for Sun's Dusk
}

HUDPresets = {
	["Velothi (T)"] = {
		S_SKIN = "Velothi (Transparent)",
		S_BACKGROUND = "Classic",
		S_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		S_COLOR = util.color.hex("000000"),
		T_SKIN = "Velothi (Transparent)",
		T_BACKGROUND = "Classic",
		T_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		T_COLOR = util.color.hex("000000"),
		H_SKIN = "Velothi (Transparent)",
		H_BACKGROUND = "Classic",
		H_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		H_COLOR = util.color.hex("000000"),
		HUD_ALPHA = "Smooth",
	},
	["Velothi2 (T)"] = {
		S_SKIN = "Velothi (Transparent)",
		S_BACKGROUND = "Classic",
		S_BACKGROUND_COLOR = util.color.hex("cfbddb"),
		S_COLOR = util.color.hex("000000"),
		T_SKIN = "Velothi (Transparent)",
		T_BACKGROUND = "Classic",
		T_BACKGROUND_COLOR = util.color.hex("d4edfc"),
		T_COLOR = util.color.hex("000000"),
		H_SKIN = "Velothi (Transparent)",
		H_BACKGROUND = "Classic",
		H_BACKGROUND_COLOR = util.color.hex("bfd4bc"),
		H_COLOR = util.color.hex("000000"),
		HUD_ALPHA = "Smooth",
	},
	["Modern2 (S)"] = {
		S_SKIN = "Modern2 (Staged)",
		S_BACKGROUND = "Shadow",
		S_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		S_COLOR = util.color.hex("FFFFFF"),
		T_SKIN = "Modern2 (Staged)",
		T_BACKGROUND = "Shadow",
		T_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		T_COLOR = util.color.hex("FFFFFF"),
		H_SKIN = "Modern2 (Staged)",
		H_BACKGROUND = "Shadow",
		H_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		H_COLOR = util.color.hex("FFFFFF"),
		HUD_ALPHA = "Static",
	},
	["Modern (S)"] = {
		S_SKIN = "Modern (Staged)",
		S_BACKGROUND = "Shadow",
		S_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		S_COLOR = util.color.hex("FFFFFF"),
		T_SKIN = "Modern (Staged)",
		T_BACKGROUND = "Shadow",
		T_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		T_COLOR = util.color.hex("FFFFFF"),
		H_SKIN = "Modern (Staged)",
		H_BACKGROUND = "Shadow",
		H_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		H_COLOR = util.color.hex("FFFFFF"),
		HUD_ALPHA = "Static",
	},
}

local function presetJob(_, setting)
	--if not SDHUD then return end
	if setting == "HUD_PRESET" then
		onFrameJobs["applyPreset"] = function()
			for newSettingId, newSettingValue in pairs(HUDPresets[HUD_PRESET]) do
				for _, template in pairs(uiSettingsTemplate) do
					for _, setting in pairs(template.settings) do
						if setting.key == newSettingId then
							local settingsSection = storage.playerSection(template.key)
							settingsSection:set(newSettingId, newSettingValue)
						end
					end
				end
			end
			onFrameJobs["applyPreset"] = nil
		end
	end
end
table.insert(settingsChangedJobs, presetJob)


for id, template in pairs(uiSettingsTemplate) do
	I.Settings.registerGroup(template)
end

local function readAllSettings()
	for _, template in pairs(uiSettingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			_G[entry.key] = settingsSection:get(entry.key)
		end
	end

end

readAllSettings()

for _, template in pairs(uiSettingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.playerSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		readAllSettings()
		if not SDHUD then return end
		SDHUD.layout.layer = HUD_LOCK and 'Scene' or 'Modal'
		SDHUD_rows.props.horizontal = HUD_ORIENTATION ~= "Horizontal"
		SDHUD_columns.layout.props.horizontal = HUD_ORIENTATION == "Horizontal"
		
		if setting ~= "HUD_ICON_SIZE"
		and setting ~= "HUD_X_POS" 
		and setting ~= "HUD_Y_POS" 
		then
			for _, job in pairs(G_destroyHudJobs) do
				job()
			end
			G_destroyThirstUi()
			G_destroyHungerUi()
			G_destroyTemperatureUis()
			G_destroySleepUi()
			G_destroySDHUD()
		else
			G_rowsNeedUpdate = true
			G_iconSizeNeedsUpdate = true
		end
		
		for _, func in pairs(settingsChangedJobs) do
			func(sectionName, setting, oldValue)
		end
		for _, func in pairs(G_refreshWidgetJobs) do
			func()
		end
		G_updateSDHUD()
		for _, func in pairs(G_refreshWidgetJobs) do
			func()
		end
	end))
end
