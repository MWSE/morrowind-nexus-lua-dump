ES = ES or {}
ES.S = ES.S or {}

local esSettingsTemplate = {}
local RENDERER_SELECT = RENDERER_SELECT or GLOBAL_PRESET and "SuperSelect2" or RENDERER_SELECT
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
			key = "DIFFICULTY_PRESET",
			name = "Difficulty Preset",
			description = "Bundles the grace window, decay rate, and per-source favor multipliers. The individual values are derived from the chosen preset.",
			default = "Default",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Default", "Slow" },
			},
		},
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
			key = "FAVOR_DECAY",
			name = "Favor Decay",
			description = "How fast favor decays when you neglect a deity. Off disables it entirely; Slow is a longer grace period and a gentler rate.",
			default = "Normal",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Off", "Normal", "Slow" },
			},
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

esSettingsTemplate.ES_OWNLY = {
	key = "Settings"..MODNAME.."ES_OWNLY",
	page = MODNAME.."ES",
	l10n = "none",
	name = "Tweaks                                ",
	description = "Remix",
	permanentStorage = true,
	order = 1,
	settings = {
		{
			key = "FAVOR_GAIN_MULT",
			name = "Favor Gain Multiplier",
			description = "Global multiplier on all favor you gain, stacked on top of the difficulty preset. 1.0 leaves the preset untouched; lower is slower, higher is faster.",
			default = 1.0,
			renderer = "number",
			argument = {
				min = 0,
			},
		},
		{
			key = "SHRINE_WORLD_INTERACTION",
			name = "Shrine World Interaction",
			description = "Special mouseover interaction to pray at shrines (less favor than buying a blessing)",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "SHRINE_WORLD_INTERACTION_CHANGE",
			name = "Shrine World Interaction: Change Deity",
			description = "Mouseover interaction for changing your deities at a shrine",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "PRAYER_POWER",
			name = "Prayer Power",
			description = "Your prayer power grants favor for all deities, only one deity or should it be entirely disabled?",
			default = "Power per Deity",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "No Power", "Power per Deity", "All-Deity Power" },
				width = 160,
			},
		},
		{
			key = "MAX_DEITIES",
			name = "Maximum Deities",
			description = "Adopting a new deity while all slots are full offers you to drop one.",
			renderer = "number",
			default = 1,
			argument = {
				min = 1,
				integer = true,
			},
		},
	}
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
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "thin", "normal", "thick", "verythick" },
			},
		},
		--{
		--	key = "BORDER_COLOR",
		--	name = "Window Border Color",
		--	description = "Tint for Evening Star window borders.",
		--	disabled = false,
		--	renderer = "SuperColorPicker2",
		--	default = util.color.hex("FFFFFF"),
		--	argument = { presetColors = presetColors },
		--},
		{
			key = "FAVOR_BAR_DISPLAY",
			name = "Prayer Bar Display",
			description = "When to show the favor bar while praying at shrines.",
			default = "Always",
			renderer = RENDERER_SELECT,
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
			default = util.color.hex("8FD5E0"),
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
			renderer = RENDERER_SELECT,
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
			key = "ICON_URGENCY_STYLE",
			name = "Prayer Urgency Indicator",
			description = "How the deity icon signals that the deity it shows (the one most overdue for prayer) is nearing favor decay.\nStaged tints it green through red; Transparent ramps its opacity up; Off keeps it static.",
			default = "Staged",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Staged", "Transparent", "Off" },
			},
		},
		{
			key = "ICON_BACKGROUND",
			name = "Deity Icon Background",
			description = "Background style for the deity icon.",
			default = "Shadow",
			renderer = RENDERER_SELECT,
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
			default = G_lightText,--util.color.hex("d4b77f"),
			argument = { presetColors = presetColors },
		},
	},
}

esSettingsTemplate.INTEROP = {
	key = "Settings"..MODNAME.."INTEROP",
	page = MODNAME.."ES",
	l10n = "none",
	name = "Interop with Ralts' mods",
	description = "",
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

-- Default is needed for the hidden settings, every normal setting already has a default
local DIFFICULTY_PRESETS = {
	Default = {
		-- all the hidden settings except decay mode
		FAVOR_PRAYER_SHRINE_MULT = 1.0,
		FAVOR_PRAYER_WORLD_MULT  = 1.0,
		FAVOR_PRAYER_POWER_MULT  = 1.0,
		FAVOR_BOOK_MULT          = 1.0,
		FAVOR_JOURNAL_MULT       = 1.0,
		FAVOR_KILL_MULT          = 1.0,
		FAVOR_SPELL_MULT         = 1.0,
		FAVOR_EXPLORE_MULT       = 1.0,
		FAVOR_PASSIVE_MULT       = 1.0,
		FAVOR_PENALTY_MULT       = 1.0,
	},
	Slow = {
		FAVOR_GAIN_MULT          = 0.5,
		FAVOR_DECAY              = "Slow",
		SHRINE_WORLD_INTERACTION = true,
		SHRINE_WORLD_INTERACTION_CHANGE = true,
		MAX_DEITIES              = 9999,
		TOGGLE_SHOW_ICON         = false,
		TOGGLE_DEITY_SHRINE_MENU = false,
		PRAYER_POWER             = "No Power",
		-- hidden settings:
		FAVOR_KILL_MULT          = 0.6,
		FAVOR_SPELL_MULT         = 0.5,
		FAVOR_PASSIVE_MULT       = 0.2,
	},
}

-- favor decay select -> the two numeric values the per-hour decay reads
local DECAY_MODES = {
	Normal = { FAVOR_DECAY_GRACE_HOURS = 12, FAVOR_DECAY_MULT = 1.0 },
	Slow   = { FAVOR_DECAY_GRACE_HOURS = 24, FAVOR_DECAY_MULT = 0.1 },
}

local function applyDecayMode()
	local mode = DECAY_MODES[ES.S.FAVOR_DECAY] or DECAY_MODES.Normal
	ES.S.FAVOR_DECAY_GRACE_HOURS = mode.FAVOR_DECAY_GRACE_HOURS
	ES.S.FAVOR_DECAY_MULT        = mode.FAVOR_DECAY_MULT
end

-- derive the active preset into ES.S;
-- "preserve" keeps the player's current value, a missing key falls back to Default.
-- nil-checked so false/0 is kept.
local function applyDifficultyPreset()
	local section = storage.playerSection("Settings"..MODNAME.."ES")
	local preset = DIFFICULTY_PRESETS[section:get("DIFFICULTY_PRESET") or ""] or {}
	for key, baseValue in pairs(DIFFICULTY_PRESETS.Default) do
		local presetValue = preset[key]
		if presetValue == "preserve" then
			if ES.S[key] == nil then ES.S[key] = baseValue end
		elseif presetValue ~= nil then
			ES.S[key] = presetValue
		else
			ES.S[key] = baseValue
		end
	end
end

applyDifficultyPreset()

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

applyDecayMode()



for _, template in pairs(esSettingsTemplate) do
	local sectionName = template.key
	local section = storage.playerSection(template.key)
	section:subscribe(async:callback(function(_, setting)
		local oldValue = ES.S[setting]
		local newValue = section:get(setting)
		ES.S[setting] = newValue
		if setting == "FAVOR_DECAY" then applyDecayMode() end
		for _, func in pairs(G_settingsChangedJobs) do
			func(sectionName, setting, oldValue)
		end
		for _, func in pairs(G_refreshWidgetJobs) do
			func()
		end
		if oldValue and setting == "DIFFICULTY_PRESET" and DIFFICULTY_PRESETS[newValue] then
			G_onFrameJobs.ES_applyDifficultyPreset = function()
				for _, template in pairs(esSettingsTemplate) do
					local section = storage.playerSection(template.key)
					for _, entry in pairs(template.settings) do
						local presetValue = DIFFICULTY_PRESETS[newValue][entry.key]
						if presetValue == "preserve" then
							-- intentionally skipped
						elseif presetValue ~= nil then
							section:set(entry.key, presetValue)
						elseif entry.key ~= "DIFFICULTY_PRESET" then
							section:set(entry.key, entry.default)
						end
					end
				end
				G_onFrameJobs.ES_applyDifficultyPreset = nil
			end
			applyDifficultyPreset()
		end
	end))
end