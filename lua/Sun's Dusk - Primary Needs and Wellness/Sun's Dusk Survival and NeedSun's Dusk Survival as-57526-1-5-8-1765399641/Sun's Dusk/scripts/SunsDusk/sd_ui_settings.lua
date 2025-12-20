local I = require('openmw.interfaces')
local TextColor   = getColorFromGameSettings("FontColor_color_normal")

uiSettingsTemplate = {}

uiSettingsTemplate.UI = {
	key = "Settings"..MODNAME.."UI",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Sun's Dusk UI                                                           ", -- lol
	description = "Change icon styles, when icons appear, when the HUD appears, and more.",
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
				items = { "Velothi (T)", "Velothi2 (T)", "Velothi (S)", "Daedric (T)", "Modern2 (S)", "Modern (S)", "Starwind (T)", "Starwind (S)", --[["JBN"]] },
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
			default = math.floor(G_hudLayerSize.x * 0.01),
		},
		{
			key = "HUD_Y_POS",
			name = "Y Position",
			description = "",
			renderer = "number",
			integer = true,
			default = math.floor(G_hudLayerSize.y * (1 - 0.065 * G_uiScale)),
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
				items = { "Always", "Interface Only", "Hide on Interface", "Hide on Dialogue Only", "Never" },
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

-- ───────────────────────────────────────────────────────────────────────────── TOOLTIPS ──────────────────────────────────────────────────────────────────────────────


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
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex()),
			argument = { presetColors = presetColors },
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
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex()),
			argument = { presetColors = presetColors },
		},
--[[	{
			key = "TOOLTIP_SKIN",
			name = "Tooltip Icon Styles",
			description = "Attack/Spellcast interact icons",
			disabled = false,
			default = "Modern", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Modern", "Velothi", "F/R", "Daedric F/R" },
			},]]
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
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex(FFFFFF)),
			argument = { presetColors = presetColors },
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
				items = { "No Background", "Classic", "Shadow" },
			},
		},
		{
			key = "S_BACKGROUND_COLOR",
			name = "Classic background color",
			description = "Background icon color if using Classic background style.\n\nDefault Morrowind colors include caa560 and dfc99f but I recommend ffcd7b for a 'vanilla' feel.",
			disabled = false,
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex(ffcd7b)),
			argument = { presetColors = presetColors },
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
			renderer = "SuperColorPicker2",
			argument = { presetColors = presetColors },
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
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex(ffcd7b)),
			argument = { presetColors = presetColors },
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
			renderer = "SuperColorPicker2",
			argument = {presetColors = presetColors},
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
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex(ffcd7b)),
			argument = {presetColors = presetColors},
		},	
	},
}

-- ─────────────────────────────────────────────────────────────────────────────── BATHING ───────────────────────────────────────────────────────────────────────────────

uiSettingsTemplate.UI_CLEAN = {
	key = "Settings"..MODNAME.."UI_CLEAN",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Bathing Icon and Display",
	permanentStorage = true,
	order = 5,
	settings = {
		{
			key = "C_SKIN",
			name = "Bath Icon Styles",
			description = "",
			default = "Velothi (Transparent)", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = iconPacks.clean.availablePacks,
			},
		},
		{
			key = "C_COLOR",
			name = "Color of Cleanliness",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			default = util.color.hex("FFFFFF"), 
			renderer = "SuperColorPicker2",
			argument = {presetColors = presetColors},
		},
		{
			key = "C_BACKGROUND",
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
			key = "C_BACKGROUND_COLOR",
			name = "Classic background color",
			description = "Background icon color if using Classic background style.\n\nDefault Morrowind colors include caa560 and dfc99f but I recommend ffcd7b for a 'vanilla' feel.",
			disabled = false,
			renderer = "SuperColorPicker2",
			default = util.color.hex(TextColor:asHex(ffcd7b)),
			argument = {presetColors = presetColors},
		},			
	}
}

I.Settings.registerPage {
	key = MODNAME.."UI",
	l10n = "none",
	name = "Sun's Dusk: UI",
	description = "", -- UI settings for Sun's Dusk
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
		C_SKIN = "Velothi (Transparent)",
		C_BACKGROUND = "Classic",
		C_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		C_COLOR = util.color.hex("000000"),
		HUD_ALPHA = "Static",
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
		C_SKIN = "Velothi (Transparent)",
		C_BACKGROUND = "Classic",
		C_BACKGROUND_COLOR = util.color.hex("c7c3fa"),
		C_COLOR = util.color.hex("000000"),		
		HUD_ALPHA = "Static",
	},
	["Velothi (S)"] = {
		S_SKIN = "Velothi (Staged)",
		S_BACKGROUND = "Shadow",
		S_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		S_COLOR = util.color.hex("FFFFFF"),
		T_SKIN = "Velothi (Staged)",
		T_BACKGROUND = "Shadow",
		T_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		T_COLOR = util.color.hex("FFFFFF"),
		H_SKIN = "Velothi (Staged)",
		H_BACKGROUND = "Shadow",
		H_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		H_COLOR = util.color.hex("FFFFFF"),
		C_SKIN = "Velothi (Staged)",
		C_BACKGROUND = "Shadow",
		C_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		C_COLOR = util.color.hex("FFFFFF"),
		HUD_ALPHA = "Static",
	},
	["Daedric (T)"] = {
		S_SKIN = "Daedric (Transparent)",
		S_BACKGROUND = "Classic",
		S_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		S_COLOR = util.color.hex("000000"),
		T_SKIN = "Daedric (Transparent)",
		T_BACKGROUND = "Classic",
		T_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		T_COLOR = util.color.hex("000000"),
		H_SKIN = "Daedric (Transparent)",
		H_BACKGROUND = "Classic",
		H_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		H_COLOR = util.color.hex("000000"),
		C_SKIN = "Daedric (Transparent)",
		C_BACKGROUND = "Classic",
		C_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		C_COLOR = util.color.hex("000000"),		
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
		C_SKIN = "Modern (Staged)",
		C_BACKGROUND = "Shadow",
		C_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		C_COLOR = util.color.hex("FFFFFF"),
		HUD_ALPHA = "Static",
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
		C_SKIN = "Modern2 (Staged)",
		C_BACKGROUND = "Shadow",
		C_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		C_COLOR = util.color.hex("FFFFFF"),		
		HUD_ALPHA = "Static",
	},
	["Starwind (T)"] = {
		S_SKIN = "Starwind (Transparent)",
		S_BACKGROUND = "Shadow",
		S_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		S_COLOR = util.color.hex("FFFFFF"),
		T_SKIN = "Starwind (Transparent)",
		T_BACKGROUND = "Shadow",
		T_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		T_COLOR = util.color.hex("FFFFFF"),
		H_SKIN = "Starwind (Transparent)",
		H_BACKGROUND = "Shadow",
		H_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		H_COLOR = util.color.hex("FFFFFF"),
		C_SKIN = "Starwind (Transparent)",
		C_BACKGROUND = "Shadow",
		C_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		C_COLOR = util.color.hex("FFFFFF"),		
		HUD_ALPHA = "Smooth",
	},
	["Starwind (S)"] = {
		S_SKIN = "Starwind (Staged)",
		S_BACKGROUND = "Shadow",
		S_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		S_COLOR = util.color.hex("FFFFFF"),
		T_SKIN = "Starwind (Staged)",
		T_BACKGROUND = "Shadow",
		T_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		T_COLOR = util.color.hex("FFFFFF"),
		H_SKIN = "Starwind (Staged)",
		H_BACKGROUND = "Shadow",
		H_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		H_COLOR = util.color.hex("FFFFFF"),
		C_SKIN = "Starwind (Staged)",
		C_BACKGROUND = "Shadow",
		C_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		C_COLOR = util.color.hex("FFFFFF"),			
		HUD_ALPHA = "Static",
	},
}

local function presetJob(_, setting)
	--if not SDHUD then return end
	if setting == "HUD_PRESET" then
		G_onFrameJobs["applyPreset"] = function()
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
			G_onFrameJobs["applyPreset"] = nil
		end
	end
end
table.insert(G_settingsChangedJobs, presetJob)

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
			G_destroyCleanUi()
			G_destroySDHUD()
		else
			G_rowsNeedUpdate = true
			G_iconSizeNeedsUpdate = true
		end
		
		for _, func in pairs(G_settingsChangedJobs) do
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
