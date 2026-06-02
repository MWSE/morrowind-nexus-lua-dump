ES = ES or {}
ES.S = ES.S or {}

local esSettingsTemplate = {}

esSettingsTemplate.ES_MAIN = {
	key = "Settings"..MODNAME.."ES",
	page = MODNAME.."ES",
	l10n = "none",
	name = "Gameplay                                ",
	description = "Configure deity worship and favor.",
	permanentStorage = true,
	order = 0,
	settings = {
		{
			key = "TOGGLE_ENABLED",
			name = "Enable Deity Worship",
			description = "Enable or disable the deity worship system.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TOGGLE_PASSIVE_REGEN",
			name = "Passive Favor Regeneration",
			description = "Allow favor to regenerate passively if race, class, or faction tenets are followed.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TOGGLE_FAVOR_DECAY",
			name = "Favor Decay",
			description = "Allow favor to decay over time if you don't pray or meet a condition of tenets.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TOGGLE_DEITY_SHRINE_MENU",
			name = "Shrine activation prompts deity selection",
			description = "Enables the deity selection menu when receiving shrine blessings associated with one.\nDisable to hide this.",
			renderer = "checkbox",
			default = true,
		},
		--{
		--	key = "TOGGLE_PENALTIES",
		--	name = "Shrine activation prompts deity selection",
		--	description = "Enables the deity selection menu when receiving shrine blessings associated with one.\nDisable to hide this.",
		--	renderer = "checkbox",
		--	default = true,
		--},
		--{
		--	key = "TOGGLE_HIDDEN",
		--	name = "Shrine activation prompts deity selection",
		--	description = "Enables the deity selection menu when receiving shrine blessings associated with one.\nDisable to hide this.",
		--	renderer = "checkbox",
		--	default = true,
		--},		
	},
}

esSettingsTemplate.ES_UI = {
	key = "Settings"..MODNAME.."ES_UI",
	page = MODNAME.."ES",
	l10n = "none",
	name = "Deity UI",
	description = "Configure the deity worship UI elements.",
	permanentStorage = true,
	order = 3,
	settings = {
		{
			key = "BORDER_STYLE",
			name = "Window Border Style",
			description = "Border thickness for Evening Star windows (deity selection, tenets).",
			default = "thick",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "thin", "normal", "thick", "verythick" },
			},
		},
		{
			key = "BORDER_COLOR",
			name = "Window Border Color",
			description = "Tint for Evening Star window borders.",
			disabled = false,
			renderer = "SuperColorPicker2",
			default = util.color.hex("FFFFFF"),
			argument = { presetColors = presetColors },
		},
		{
			key = "FAVOR_BAR_DISPLAY",
			name = "Prayer Bar Display",
			description = "When to show the favor bar while praying at shrines.",
			default = "Always",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Always", "Never" },
			},
		},
		{
			key = "FAVOR_BAR_COLOR",
			name = "Favor Bar Color",
			description = "Base color for the favor bar.",
			disabled = false,
			renderer = "SuperColorPicker2",
			default = util.color.hex("d4a020"),
			argument = { presetColors = presetColors },
		},
	},
}

esSettingsTemplate.ES_INTEROP_SD = {
	key = "Settings"..MODNAME.."ES_INTEROP_SD",
	page = MODNAME.."ES",
	l10n = "none",
	name = "Sun's Dusk Interop",
	description = "Interop with Sun's Dusk.",
	permanentStorage = true,
	order = 5,
	settings = {
		{
			key = "TOGGLE_SHOW_ICON",
			name = "Show Deity Icon",
			description = "Display the deity icon on the Sun's Dusk HUD widget.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "ICON_DISPLAY",
			name = "Deity Icon Display",
			description = "When to display the deity icon on the Sun's Dusk widget.",
			default = "Always",
			renderer = "select",
			argument = {
				disabled = true,
				l10n = "none",
				items = { "Always", "Interface Only", "Hide on Interface", "Hide on Dialogue Only", "Never" },
			},
		},
		{
			key = "ICON_COLOR",
			name = "Deity Icon Color",
			description = "Color tint for the deity icon.",
			disabled = true,
			renderer = "SuperColorPicker2",
			default = util.color.hex("FFFFFF"),
			argument = { presetColors = presetColors },
		},
		{
			key = "ICON_BACKGROUND",
			name = "Deity Icon Background",
			description = "Background style for the deity icon.",
			default = "Shadow",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Shadow", "Classic", "No Background" },
			},
		},
		{
			key = "ICON_BACKGROUND_COLOR",
			name = "Deity Icon Background Color",
			description = "Background color for the Classic style.",
			disabled = true,
			renderer = "SuperColorPicker2",
			default = util.color.hex("d4b77f"),
			argument = { presetColors = presetColors },
		},
	},
}

esSettingsTemplate.ES_INTEROP_CB = {
	key = "Settings"..MODNAME.."ES_INTEROP_CB",
	page = MODNAME.."ES",
	l10n = "none",
	name = "Character Backgrounds Interop",
	description = "Interop with Bor's Character Backgrounds (Character Traits framework).",
	permanentStorage = true,
	order = 6,
	settings = {
		{
			key = "TOGGLE_USE_CB",
			name = "Enable Character Backgrounds Integration",
			description = "When Character Backgrounds is installed: place the Religion line between Belief and Culture in the stats window, and skip the first-sleep deity prompt (deity choice runs through chargen instead).",
			renderer = "checkbox",
			default = true,
		},
	},
}

esSettingsTemplate.ES_INTEROP_SWE = {
	key = "Settings"..MODNAME.."ES_INTEROP_SWE",
	page = MODNAME.."ES",
	l10n = "none",
	name = "Stats Window Extender Interop",
	description = "Interop with Ralts' Stats Window Extender.",
	permanentStorage = true,
	order = 7,
	settings = {
		{
			key = "TOGGLE_USE_SWE",
			name = "Show Religion in Stats Window",
			description = "Adds a \"Religion\" line to the stats window showing your current deity. Hover for favor, devotion tier, and a deity description.",
			renderer = "checkbox",
			default = true,
		},
	},
}

esSettingsTemplate.ES_INTEROP_IE = {
	key = "Settings"..MODNAME.."ES_INTEROP_IE",
	page = MODNAME.."ES",
	l10n = "none",
	name = "Inventory Extender Interop",
	description = "Interop with Ralts' Inventory Extender.",
	permanentStorage = true,
	order = 8,
	settings = {
		{
			key = "TOGGLE_USE_IE",
			name = "Show Deity Button in Inventory",
			description = "Adds a tribunal icon to the inventory info bar that opens your deity's tenets when clicked.",
			renderer = "checkbox",
			default = true,
		},
	},
}

I.Settings.registerPage {
	key = MODNAME.."ES",
	l10n = "none",
	name = "Evening Star: Faiths of Morrowind",
	description = "Configure deity worship settings and UI.",
}

for _, template in pairs(esSettingsTemplate) do
	I.Settings.registerGroup(template)
end

local function readESSettings()
	for _, template in pairs(esSettingsTemplate) do
		local section = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local val = section:get(entry.key)
			if val == nil then
				val = entry.default
			end
			ES.S[entry.key] = val
		end
	end
end

readESSettings()

for _, template in pairs(esSettingsTemplate) do
	local sectionName = template.key
	local section = storage.playerSection(template.key)
	section:subscribe(async:callback(function(_, setting)
		local oldValue = ES.S[setting]
		readESSettings()
		for _, func in pairs(G_settingsChangedJobs) do
			func(sectionName, setting, oldValue)
		end
		for _, func in pairs(G_refreshWidgetJobs) do
			func()
		end
	end))
end