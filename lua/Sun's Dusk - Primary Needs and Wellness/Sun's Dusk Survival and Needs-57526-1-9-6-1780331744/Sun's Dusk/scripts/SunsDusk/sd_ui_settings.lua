local I = require('openmw.interfaces')
local TextColor = getColorFromGameSettings("FontColor_color_normal")

local RENDERER_COLOR = "SuperColorPicker2"
local RENDERER_NUMBER = "SuperSlider4"
local RENDERER_SELECT = "SuperSelect2"

-- build value -> texture path lookup for a need's icon packs
local function needIcons(needId)
	local icons = {}
	for _, packName in ipairs(G_iconPacks[needId].availablePacks) do
		local data = G_iconPacks[needId][packName]
		icons[packName] = data.base..needId..(data.stages > 1 and "_0" or "")..data.extension
	end
	return icons
end

-- populated after HUDPresets is defined further down
local HUDPresetIcons = {}

uiSettingsTemplate = {}

uiSettingsTemplate.UI = {
	key = "Settings"..MODNAME.."UI",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Sun's Dusk UI                                               ", -- lol
	description = "Change icon styles, when icons appear, when the HUD appears, and more.",
	permanentStorage = true,
	order = 0,
	settings = {
		{
			key = "HUD_PRESET",
			name = "Preset",
			description = "Changes Icon pack, background, color and Transparency",
			default = "Velothi3 (T)",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Velothi (T)", "Velothi2 (S)", "Velothi2 (T)", "Velothi3 (T)", "Velothi (S)", "Daedric (T)", "Modern2 (S)", "Modern (S)", "Starwind (T)", "Starwind (S)", "Hidden", },
				width = 160,
				icon = HUDPresetIcons,
			},
		},
		{
			key = "HUD_ALPHA",
			name = "Transparency Indicator",
			description = "Stages of needs are indicated by icon transparency",
			default = "Gradual + better visible", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = {"Gradual + better visible", "Smooth", "Gradual", "Static" },
				width = 220,
			},
		},
		{
			key = "HUD_INVERT_ALPHA",
			name = "Invert transparency curve",
			description = "Icons become more visible when their need is low instead of high.\n\nUseful if you only enabled positive buffs (no debuffs).",
			renderer = "checkbox",
			default = false,
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
			renderer = RENDERER_NUMBER,
			default = 30,
			argument = {
				min = 1,
				max = 750,
				step = 1,
				default = 30,
				unit = "px",
				minLabel = "Small",
				maxLabel = "Large",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "HUD_X_POS",
			name = "X Position",
			description = "",
			renderer = RENDERER_NUMBER,
			default = math.floor(G_hudLayerSize.x * 0.005),
			argument = {
				min = 0,
				max = G_hudLayerSize.x,
				step = 1,
				default = math.floor(G_hudLayerSize.x * 0.005),
				unit = "px",
				minLabel = "Left",
				maxLabel = "Right",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "HUD_Y_POS",
			name = "Y Position",
			description = "",
			renderer = RENDERER_NUMBER,
			default = math.floor(G_hudLayerSize.y * 0.005),
			argument = {
				min = 0,
				max = G_hudLayerSize.y,
				step = 1,
				default = math.floor(G_hudLayerSize.y * 0.005),
				unit = "px",
				minLabel = "Top",
				maxLabel = "Bottom",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "HUD_LEFT_SHIFT_PER_BUFF",
			name = "Left shift per buff",
			description = "Move HUD widget to the left for each spell effect active on the HUD. Do not multiply by display scaling\n\nVanilla is 16 pixels.",
			renderer = RENDERER_NUMBER,
			default = 0,
			argument = {
				min = 0,
				max = 100,
				step = 1,
				default = 0,
				unit = "px",
				minLabel = "None",
				maxLabel = "Wide",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "HUD_LEFT_SHIFT_FAST_UPDATE",
			name = "Faster left shift updating",
			description = "Comes with a big performance impact because it needs to analyze your buffs every frame",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "HUD_SORT_BY_VISIBILITY",
			name = "Sort visible icons toward the edge",
			description = "Active icons are pulled toward the screen edge, faded ones toward the center.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "HUD_DISPLAY",
			name = "HUD Display",
			description = "When to display the HUD/widget element. Interface = when menus are pulled up",
			default = "Always", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Always", "Interface Only", "Hide on Interface", "Hide on Dialogue Only", "Never" },
				width = 220,
			},
		},
		{
			key = "HUD_ORIENTATION",
			name = "Orientation",
			description = "",
			default = "Horizontal", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Horizontal", "Vertical" },
			},
		},
	}
}

------------------------------ TOOLTIPS ------------------------------

uiSettingsTemplate.OTHER = {
	key = "Settings"..MODNAME.."OTHER",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Tooltips and Notifications",
	permanentStorage = true,
	order = 1,
	settings = {
		{
			key = "ENABLE_TOOLTIPS",
			name = "Enable Tooltips for UI",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "WORLD_TOOLTIP_DELAY",
			name = "Tooltip Delay",
			description = "Makes the tooltips fade in after a few seconds",
			renderer = RENDERER_NUMBER,
			default = 0.1,
			argument = {
				min = 0,
				max = 5,
				step = 0.1,
				default = 0.1,
				unit = "s",
				minLabel = "Instant",
				maxLabel = "Slow",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "WIDGET_TOOLTIP_FONT_COLOR",
			name = "Widget Tooltip text color",
			description = "",
			disabled = false,
			renderer = RENDERER_COLOR,
			default = util.color.hex(TextColor:asHex()),
			argument = { presetColors = presetColors },
		},
		{
			key = "WIDGET_TOOLTIP_FONT_SIZE",
			name = "Widget Tooltip font size",
			description = "Average text size",
			renderer = RENDERER_NUMBER,
			default = 20,
			argument = {
				min = 8,
				max = 48,
				step = 1,
				default = 20,
				unit = "px",
				minLabel = "Small",
				maxLabel = "Large",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "TOOLTIP_RELATIVE_X",
			name = "Relative X Position (%)",
			description = "x=50, y=50 is crosshair",
			renderer = RENDERER_NUMBER,
			default = 51,
			argument = {
				min = 0,
				max = 100,
				step = 1,
				default = 51,
				unit = "%",
				minLabel = "Left",
				maxLabel = "Right",
				centerLabel = "Center",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},		
		{
			key = "TOOLTIP_RELATIVE_Y",
			name = "Relative Y Position (%)",
			description = "x=50, y=50 is crosshair",
			renderer = RENDERER_NUMBER,
			default = 50,
			argument = {
				min = 0,
				max = 100,
				step = 1,
				default = 50,
				unit = "%",
				minLabel = "Top",
				maxLabel = "Bottom",
				centerLabel = "Center",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},		
		{
			key = "WORLD_TOOLTIP_FONT_COLOR",
			name = "Refill Tooltip text color",
			description = "",
			disabled = false,
			renderer = RENDERER_COLOR,
			default = util.color.hex(TextColor:asHex()),
			argument = { presetColors = presetColors },
		},
		{
			key = "WORLD_TOOLTIP_FONT_SIZE",
			name = "World Tooltip font size",
			description = "Average text size\nSetting to 0 disables the text",
			renderer = RENDERER_NUMBER,
			default = 24,
			argument = {
				min = 0,
				max = 48,
				step = 1,
				default = 24,
				unit = "px",
				minLabel = "Off",
				maxLabel = "Large",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "WORLD_TOOLTIP_ICON_SIZE",
			name = "World Tooltip icon size",
			description = "Average text size\nSetting to 0 disables the icon",
			renderer = RENDERER_NUMBER,
			default = 24,
			argument = {
				min = 0,
				max = 48,
				step = 1,
				default = 24,
				unit = "px",
				minLabel = "Off",
				maxLabel = "Large",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "WORLD_TOOLTIP_SKIN",
			name = "World Tooltip Icon Styles",
			description = "Attack/Spellcast interact icons",
			disabled = false,
			default = "Modern",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Modern", "Velothi", "F+R", "Daedric F+R" },
				icon = {
					["Modern"]      = "textures/sunsdusk/worldTooltips/Modern/f.dds",
					["Velothi"]     = "textures/sunsdusk/worldTooltips/Velothi/f.dds",
					["F+R"]         = "textures/sunsdusk/worldTooltips/F+R/f.dds",
					["Daedric F+R"] = "textures/sunsdusk/worldTooltips/Daedric F+R/f.dds",
				},
			},
		},
		{
			key = "WORLD_CONSUME_TOOLTIPS",
			name = "Directly consume Food, Ingredients, Potions and Drinks from the world",
			description = "Select 'Hide' to disable.",
			disabled = false,
			default = "Short", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Detailed", "Short", "Hide" },
			},
		},
		{
			key = "INSTRUMENT_VOLUME",
			name = "Instrument Volume (%)",
			description = "Values above 100 only have an effect if total effect volume is <100%",
			renderer = RENDERER_NUMBER,
			default = 150,
			argument = {
				min = 0,
				max = 300,
				step = 5,
				default = 150,
				unit = "%",
				minLabel = "Silent",
				maxLabel = "Loud",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "MESSAGE_BOX_LEVEL_NAME",
			name = "Message Boxes",
			description = "How many message boxes do you want?",
			renderer = RENDERER_SELECT,
			default = "Chatty",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Silent", "Quiet", "Chatty", "Deep"}
			}	
		},
	},
}

------------------------------ SLEEP ------------------------------

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
			key = "S_HIDE_NO_BUFF",
			name = "Hide tiredness icon when no effect is active",
			description = "Fades the icon to fully transparent while there is no tiredness buff or debuff applied.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "S_SP_HIDE_WR",
			name = "Hide Well-Rested Status",
			description = "Indicated with a dot",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "S_SKIN",
			name = "Tiredness Icon Styles",
			description = "",
			default = "Velothi (Staged)",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = G_iconPacks.sleep.availablePacks,
				width = 235,
				icon = needIcons("sleep"),
			},
		},
		{
			key = "S_COLOR",
			name = "Color of Tiredness",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			renderer = RENDERER_COLOR,
			default = util.color.hex("FFFFFF"),
			argument = { presetColors = presetColors },
		},
		{
			key = "S_BACKGROUND",
			name = "Background style",
			description = "",
			default = "Shadow", 
			renderer = RENDERER_SELECT,
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
			renderer = RENDERER_COLOR,
			default = util.color.hex("ffcd7b"),
			argument = { presetColors = presetColors },
		},
	},
}

------------------------------ HUNGER ------------------------------

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
			key = "H_HIDE_NO_BUFF",
			name = "Hide hunger icon when no effect is active",
			description = "Fades the icon to fully transparent while there is no hunger buff or debuff applied.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "H_SKIN",
			name = "Hunger Icon Styles",
			description = "",
			default = "Velothi (Staged)",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = G_iconPacks.hunger.availablePacks,
				width = 235,
				icon = needIcons("hunger"),
			},
		},
		{
			key = "H_COLOR",
			name = "Color of Hunger",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			default = util.color.hex("FFFFFF"), 
			renderer = RENDERER_COLOR,
			argument = { presetColors = presetColors },
		},		
		{
			key = "H_BACKGROUND",
			name = "Background style",
			description = "",
			default = "Shadow", 
			renderer = RENDERER_SELECT,
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
			renderer = RENDERER_COLOR,
			default = util.color.hex("ffcd7b"),
			argument = { presetColors = presetColors },
		},	
	},
}

------------------------------ THIRST ------------------------------
		
uiSettingsTemplate.UI_THIRST = {
	key = "Settings"..MODNAME.."UI_THIRST",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Thirst Icons and Display",
	permanentStorage = true,
	order = 4,
	settings = {
		{
			key = "T_HIDE_NO_BUFF",
			name = "Hide thirst icon when no effect is active",
			description = "Fades the icon to fully transparent while there is no thirst buff or debuff applied.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "T_SKIN",
			name = "Thirst Icon Styles",
			description = "",
			default = "Velothi (Staged)",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = G_iconPacks.thirst.availablePacks,
				width = 235,
				icon = needIcons("thirst"),
			},
		},
		{
			key = "T_COLOR",
			name = "Color of Thirst",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			default = util.color.hex("FFFFFF"), 
			renderer = RENDERER_COLOR,
			argument = {presetColors = presetColors},
		},		
		{
			key = "T_BACKGROUND",
			name = "Background style for icon",
			description = "",
			default = "Shadow", 
			renderer = RENDERER_SELECT,
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
			renderer = RENDERER_COLOR,
			default = util.color.hex("ffcd7b"),
			argument = {presetColors = presetColors},
		},	
	},
}

------------------------------ BATHING ------------------------------

uiSettingsTemplate.UI_CLEAN = {
	key = "Settings"..MODNAME.."UI_CLEAN",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Bathing Icon and Display",
	permanentStorage = true,
	order = 5,
	settings = {
		{
			key = "C_HIDE_NO_BUFF",
			name = "Hide bathing icon when no effect is active",
			description = "Fades the icon to fully transparent while there is no cleanliness buff or debuff applied.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "C_SKIN",
			name = "Bath Icon Styles",
			description = "",
			default = "Velothi (Staged)",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = G_iconPacks.clean.availablePacks,
				width = 235,
				icon = needIcons("clean"),
			},
		},
		{
			key = "C_COLOR",
			name = "Color of Cleanliness",
			description = "Change the color of the icon. Black (recommended for Classic background style) is 000000.\nDefault is white (FFFFFF).",
			disabled = false,
			default = util.color.hex("FFFFFF"), 
			renderer = RENDERER_COLOR,
			argument = {presetColors = presetColors},
		},
		{
			key = "C_BACKGROUND",
			name = "Background style",
			description = "",
			default = "Shadow", 
			renderer = RENDERER_SELECT,
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
			renderer = RENDERER_COLOR,
			default = util.color.hex("ffcd7b"),
			argument = {presetColors = presetColors},
		},
	}
}

------------------------------ MOD INTEGRATION ------------------------------

uiSettingsTemplate.MOD_INTEGRATION = {
	key = "Settings"..MODNAME.."MOD_INTEGRATION",
	page = MODNAME.."UI",
	l10n = "none",
	name = "Mod Integration",
	description = "Toggle UI additions that depend on other mods.",
	permanentStorage = true,
	order = 6,
	settings = {
		{
			key = "INV_EXTENDER_TOOLTIPS",
			name = "Inventory Extender tooltips",
			description = "Show Sun's Dusk tooltip lines on items: survival values, backpack buffs, vessels, bathing charges, armor resistances, books, lights.\n\nRequires Inventory Extender.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "STATS_WINDOW_SECTION",
			name = "Stats Window section",
			description = "Show the Sun's Dusk needs section (hunger, thirst, tiredness, dirtiness, temperature) in the Stats Window.\n\nRequires Stats Window Extender.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "CRAFTING_FW_TOOLTIPS",
			name = "Crafting Framework tooltips",
			description = "Show temperature resistance lines on armor and clothing recipe previews.\n\nRequires Crafting Framework.",
			renderer = "checkbox",
			default = true,
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
		HUD_ALPHA = "Smooth",
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
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
		HUD_ALPHA = "Smooth",
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
	},
	["Velothi2 (S)"] = {
		S_SKIN			 = "Velothi2 (Staged)",
		S_BACKGROUND	   = "No Background",
		S_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		S_COLOR			= util.color.hex("FFFFFF"),
		T_SKIN			 = "Velothi2 (Staged)",
		T_BACKGROUND	   = "No Background",
		T_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		T_COLOR			= util.color.hex("FFFFFF"),
		H_SKIN			 = "Velothi2 (Staged)",
		H_BACKGROUND	   = "No Background",
		H_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		H_COLOR			= util.color.hex("FFFFFF"),
		C_SKIN			 = "Velothi2 (Staged)",
		C_BACKGROUND	   = "No Background",
		C_BACKGROUND_COLOR = util.color.hex("ffcd7b"),
		C_COLOR			= util.color.hex("FFFFFF"),
		HUD_ALPHA		  = "Static",
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
	},
	["Velothi3 (T)"] = {
		S_SKIN = "Velothi (Staged)",
		S_BACKGROUND = "Shadow",
		S_BACKGROUND_COLOR = util.color.hex("cfbddb"),
		S_COLOR = util.color.hex("FFFFFF"),
		T_SKIN = "Velothi (Staged)",
		T_BACKGROUND = "Shadow",
		T_BACKGROUND_COLOR = util.color.hex("d4edfc"),
		T_COLOR = util.color.hex("FFFFFF"),
		H_SKIN = "Velothi (Staged)",
		H_BACKGROUND = "Shadow",
		H_BACKGROUND_COLOR = util.color.hex("bfd4bc"),
		H_COLOR = util.color.hex("FFFFFF"),
		C_SKIN = "Velothi (Staged)",
		C_BACKGROUND = "Shadow",
		C_BACKGROUND_COLOR = util.color.hex("c7c3fa"),
		C_COLOR = util.color.hex("FFFFFF"),
		HUD_ALPHA = "Gradual + better visible",
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
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
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
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
		HUD_ALPHA = "Smooth",
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
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
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
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
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
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
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
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
		HUD_DISPLAY = "Always",
		WORLD_TOOLTIP_FONT_SIZE = 24,
		WORLD_TOOLTIP_ICON_SIZE = 24,
		WORLD_CONSUME_TOOLTIPS = "Short",
		MESSAGE_BOX_LEVEL_NAME = "Chatty",
	},
	["Hidden"] = {
		HUD_DISPLAY = "Never",
		WORLD_TOOLTIP_FONT_SIZE = 0,
		WORLD_TOOLTIP_ICON_SIZE = 0,
		WORLD_CONSUME_TOOLTIPS = "Hide",
		MESSAGE_BOX_LEVEL_NAME = "Deep",
	},
}

-- populate the HUD_PRESET icon lookup using each preset's hunger skin
local HUDPresetIconOverrides = {
 ["Velothi (T)"] = "textures/SunsDusk/settings/Velothi (T).png",
 ["Velothi2 (T)"] = "textures/SunsDusk/settings/Velothi2 (T).png",
 ["Velothi2 (S)"] = "textures/SunsDusk/settings/Velothi2 (S).png",
 ["Velothi3 (T)"] = "textures/SunsDusk/settings/Velothi3 (T).png",
 ["Velothi (S)"] = "textures/SunsDusk/settings/Velothi (S).png",
 ["Daedric (T)"] = "textures/SunsDusk/settings/Daedric (T).png",
 ["Modern (S)"] = "textures/SunsDusk/settings/Modern (S).png",
 ["Modern2 (S)"] = "textures/SunsDusk/settings/Modern2 (S).png",
 ["Starwind (T)"] = "textures/SunsDusk/settings/Starwind (T).png",
 ["Starwind (S)"] = "textures/SunsDusk/settings/Starwind (S).png",
}

for presetName, preset in pairs(HUDPresets) do
	local data = preset.H_SKIN and G_iconPacks.hunger[preset.H_SKIN]
	if data then
		HUDPresetIcons[presetName] = HUDPresetIconOverrides[presetName] or data.base.."hunger"..(data.stages > 1 and "_0" or "")..data.extension
	end
end

-- writes one player-section key, locating its group in uiSettingsTemplate
local function setPlayerSetting(key, value)
	for _, template in pairs(uiSettingsTemplate) do
		for _, entry in pairs(template.settings) do
			if entry.key == key then
				storage.playerSection(template.key):set(key, value)
				return
			end
		end
	end
end

-- expands a global preset's player half into its final flat key set: the hud
-- preset first, then the preset's own player keys on top so explicit extras win
local function composePlayerState(presetName)
	local result = {}
	local preset = GlobalPresets[presetName]
	if preset and preset.player then
		local hud = preset.player.HUD_PRESET
		if hud and HUDPresets[hud] then
			for key, value in pairs(HUDPresets[hud]) do result[key] = value end
		end
		for key, value in pairs(preset.player) do result[key] = value end
	end
	return result
end

local function presetJob(_, setting)
	--if not SDHUD then return end
	-- suppressed while p_settingsIO applies an imported snapshot (see sd_settings)
	if G_importingSettings then return end
	-- skip the hud cascade while a global preset composes its own player half,
	-- otherwise it would overwrite the preset's explicit player keys
	if setting == "HUD_PRESET" and not G_applyingGlobalPreset then
		G_onFrameJobs["applyPreset"] = function()
			for newSettingId, newSettingValue in pairs(HUDPresets[HUD_PRESET]) do
				setPlayerSetting(newSettingId, newSettingValue)
			end
			G_onFrameJobs["applyPreset"] = nil
		end
	end
	-- global preset's player half; the global half is applied in sd_settings
	if setting == "GLOBAL_PRESET" and GLOBAL_PRESET ~= "Custom"
	and GlobalPresets[GLOBAL_PRESET] and GlobalPresets[GLOBAL_PRESET].player then
		G_onFrameJobs["applyGlobalPreset"] = function()
			-- write the composed result directly with the hud cascade suppressed,
			-- so the sub-preset cannot overwrite the global preset's explicit keys
			G_applyingGlobalPreset = true
			if GLOBAL_PRESET == "Default" then
				-- factory reset: sweep every registered player key to its default,
				-- skipping keys already at default (a redundant set still fires
				-- subscriptions that can tear down widgets)
				for _, template in pairs(uiSettingsTemplate) do
					local section = storage.playerSection(template.key)
					for _, entry in pairs(template.settings) do
						local current = section:get(entry.key)
						if current ~= nil and current ~= entry.default then
							section:set(entry.key, entry.default)
						end
					end
				end
			else
				for key, value in pairs(composePlayerState(GLOBAL_PRESET)) do
					setPlayerSetting(key, value)
				end
			end
			-- change notifications are deferred, so lift suppression after a short delay
			local clearTime = core.getRealTime() + 0.5
			G_onFrameJobs["clearApplyGlobalPreset"] = function()
				if core.getRealTime() >= clearTime then
					G_applyingGlobalPreset = false
					G_onFrameJobs["clearApplyGlobalPreset"] = nil
				end
			end
			G_onFrameJobs["applyGlobalPreset"] = nil
		end
	end
end
table.insert(G_settingsChangedJobs, presetJob)

for id, template in pairs(uiSettingsTemplate) do
	I.Settings.registerGroup(template)
end

local debugLevelNames = { "Silent", "Quiet", "Chatty", "Deep", "Trace", "Spammy" }
local function applyDebugLevel(levelName)
	for i, name in ipairs(debugLevelNames) do
		if name == levelName then
			MESSAGE_BOX_LEVEL = i
			return
		end
	end
	MESSAGE_BOX_LEVEL = 1 -- fallback to Silent
end

local function readAllSettings()
	for _, template in pairs(uiSettingsTemplate) do
		local settingsSection = storage.playerSection(template.key)
		for i, entry in pairs(template.settings) do
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			_G[entry.key] = newValue
		end
	end
	applyDebugLevel(MESSAGE_BOX_LEVEL_NAME)
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
		if setting == "MESSAGE_BOX_LEVEL_NAME" then
			applyDebugLevel(MESSAGE_BOX_LEVEL_NAME)
		end
		
		if setting ~= "HUD_ICON_SIZE"
		and setting ~= "HUD_X_POS"
		and setting ~= "HUD_Y_POS"
		and setting ~= "HUD_SORT_BY_VISIBILITY"
		and setting ~= "HUD_INVERT_ALPHA"
		and setting ~= "H_HIDE_NO_BUFF"
		and setting ~= "T_HIDE_NO_BUFF"
		and setting ~= "S_HIDE_NO_BUFF"
		and setting ~= "C_HIDE_NO_BUFF"
		then
			for _, job in pairs(G_destroyHudJobs) do
				job()
			end
			G_destroySDHUD()
		else
			G_rowsNeedUpdate = true
			G_iconSizeNeedsUpdate = true
			G_columnsNeedUpdate = true
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