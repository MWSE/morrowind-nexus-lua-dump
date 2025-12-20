local settingsTemplate = {}

settingsTemplate.TOGGLE = {
	key = "Settings"..MODNAME.."TEMP",
	page = "Settings"..MODNAME.."ENV",
	l10n = "none",
	name = "Temperature and Weather                                                 ", -- lol
	description = "Enable and disable temperature, change the bar appearance\nand enable fire damage while near lava or on Red Mountain",
	permanentStorage = true,
	order = 0,
	settings = {
		--{
		--	key = "DIFFICULTY_PRESET",
		--	name = "Preset",
		--	description = "",
		--	default = "Default", 
		--	renderer = "select",
		--	argument = {
		--		disabled = false,
		--		l10n = "none",
		--		items = { "Default", "Hard", "Hardcore" },
		--	},
		--},
		{
			key = "NEEDS_TEMP",
			name = "Enable Temperature",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		--[[{
			key = "TEMP_WEATHER",
			name = "Enable Weather (Coming Soon)",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		]]
	}
}

-- ─────────────────────────────────────────────────────────────────────────────── TEMPERATURE ───────────────────────────────────────────────────────────────────────────────

settingsTemplate.TEMP = {
	key = "Settings"..MODNAME.."TEMP2",
	page = "Settings"..MODNAME.."ENV",
	l10n = "none",
	name = "Temperature UI and Gameplay",
	permanentStorage = true,
	order = 1,
	settings = {
		{
			key = "TEMPERATURE_WIDGET",
			name = "Extend the temperature bar to display exact temperatures",
			description = "",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "TEMP_BAR_STYLE",
			name = "Temperature Bar Style",
			description = "",
			default = "Simple Bar", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Thermometer", "Stylized Bar", "Simple Bar" },
			},
		},{
			key = "TEMP_BUFFS_DEBUFFS",
			name = "Disable Temperature Penalties",
			description = "Enable if you only want buffs for ideal temperatures",
			default = "Buffs and debuffs", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Buffs and debuffs", "Only buffs", "Only debuffs" },
			},
		},
		{
			key = "TEMP_EXTREMES",
			name = "Overheating and Hypothermia",
			description = "Scorching causes fire damage and Freezing causes cold damage.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TEMP_ZELDA",
			name = "Lava and Freezing Water",
			description = "Being near lava or climbing to the top of Red Mountain causes fire damage\nSwimming in cold water (Solstheim, Sheogorad) causes frozen damage\n\nTo be immune to this fire debuff, equip Bound Armor, Bonemold, Dwemer, Daedric, Ebony, or Indoril Armor.\nFor the cold, equip Stahlrim, Bonemold, or Ebonweave Armor.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "TEMP_RM",
			name = "Climbing Red Mountain sets you on fire",
			description = "Wear at least one piece of heat-proof armor (see above) to pass through Red Mountain safely. Above setting must be enabled.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "TEMP_WETNESS_DEBUFFS",
			name = "Wetness debuffs",
			description = "-2-10 speed and personality, +3-15% weakness to common disease and shock",
			renderer = "checkbox",
			default = true,
		},
		-- {
		-- 	key = "TEMP_MW_COLD",
		-- 	name = "Morrowind is cold",
		-- 	description = "Enable if you want Vvardenfell to be cold - no warmth or heat mechanics, everything -20 basically",
		-- 	renderer = "checkbox",
		-- 	default = false,
		-- },
		-- {
		-- 	key = "TEMP_SEVERITY",
		-- 	name = "Difficulty Presets",
		-- 	description = "Increase the degree of penalties from temperature and disable the companion mechanic for debuffs.\nDoes not change the buffs.",
		-- 	default = "Default", 
		-- 	renderer = "select",
		-- 	argument = {
		-- 		disabled = false,
		-- 		l10n = "none", 
		-- 		items = { "Default", "Hard", "Hardcore" },
		-- 	},
		-- },
		{
			key = "TEMP_RACES",
			name = "Enable Racial Abilities",
			description = "Each race has temperature modifiers.",
			renderer = "checkbox",
			default = true,
		},
		--{
		-- 	key = "TEMP_COMPANION",
		-- 	name = "Enable Companion Mechanics",
		-- 	description = "Adventuring with a companion makes life easier and gives you different buffs and penalties.",
		-- 	renderer = "checkbox",
		-- 	default = true,
		--},
		{
            key = "TEMP_TOTSP",
            name = "Solstheim is colder",
            description = "Enable if you use a mod that moves Solstheim further north\n(such as Tomb of the Snow Prince) or just want Solstheim to be colder",
            renderer = "checkbox",
            default = true,
        },
		{
			key = "TESTING_WIDGET",
			name = "Enable Debug UI Mode for the temperature",
			description = "",
			renderer = "checkbox",
			default = false,
		},	
		{
			key = "TEMP_DEBUG_LEVEL_NAME",
			name = "Temp Debug level",
			description = "set level of information in the tooltip and console",
			renderer = "select",
			default = "Chatty",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Silent", "Quiet", "Chatty", "Deep", "Trace" }
			}	
		},
		{
			key = "TEMP_CELSIUS_FAHRENHEIT",
			name = "Temp unit",
			description = "note: changing it to Fahrenheit also changes 'watt' to horsepower",
			renderer = "select",
			default = "°C",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "°F", "°C" }
			}	
		},
		{
			key = "TEMP_PRINT_CONSOLE",
			name = "Print to console",
			description = "",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "TEMP_SEGMENTS",
			name = "Enable segments on the stylized and simple bar",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TEMP_WETNESS_BAR",
			name = "Enable wetness bar",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TEMP_TEXT_COLOR",
			name = "Temperature Text color",
			description = "Color of the temperature widget text",
			disabled = false,
			default = util.color.hex("caa560"),
			renderer = "SuperColorPicker2",
			argument = {presetColors = presetColors},
		},
		{
			key = "TEMP_FONT_FIX",
			name = "Replace degrees symbol by space",
			description = "In case you dont use a truetype font",
			renderer = "checkbox",
			default = false,
		},
		--{
		--	key = "NERF_FIRE_SHIELD",
		--	name = "Nerf fires hield",
		--	description = "Make the water protection of fire shield based on magnitude and never 100%",
		--	renderer = "checkbox",
		--	default = false,
		--},
	}
}

settingsTemplate.WOODCUTTING = {
	key = "Settings"..MODNAME.."WOODCUTTING",
	page = "Settings"..MODNAME.."ENV",
	l10n = "none",
	name = "Woodcutting",
	permanentStorage = true,
	order = 4,
	settings = {
		{
			key = "TREES_DESPAWN",
			name = "Trees despawn",
			description = "",
			renderer = "checkbox",
			default = true,
		},
	}
}

-- ─────────────────────────────────────────────────────────────────────────────── Register Settings ───────────────────────────────────────────────────────────────────────────────

if world then
	for id, template in pairs(settingsTemplate) do
		I.Settings.registerGroup(template)
	end
else
	I.Settings.registerPage {
		key = "Settings"..MODNAME.."ENV",
		l10n = "none",
		name = "Sun's Dusk: Environment",
		description = ""
	}
end

-- ─────────────────────────────────────────────────────────────────────────────── Read Settings ───────────────────────────────────────────────────────────────────────────────

local debugLevelNames = { "Silent", "Quiet", "Chatty", "Deep", "Trace" }

local function applyDebugLevel(levelName)
	for i, name in ipairs(debugLevelNames) do
		if name == levelName then
			TEMP_DEBUG_LEVEL = i
			return
		end
	end
	TEMP_DEBUG_LEVEL = 1 -- fallback to Silent
end

local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.globalSection(template.key)
		for i, entry in pairs(template.settings) do
			_G[entry.key] = settingsSection:get(entry.key)
		end
	end
	applyDebugLevel(TEMP_DEBUG_LEVEL_NAME)
end

readAllSettings()

-- ─────────────────────────────────────────────────────────────────────────────── Settings Event ───────────────────────────────────────────────────────────────────────────────

for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.globalSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		-- will be in local context:
		-- local sectionName = ... 
		-- local settingsSection = ...
		
		--print(sectionName.."\\"..setting.." changed to "..tostring(settingsSection:get(setting)))
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
		
		if setting == "TEMP_DEBUG_LEVEL_NAME" then
			applyDebugLevel(TEMP_DEBUG_LEVEL_NAME)
		end
		
		for _, func in pairs(G_settingsChangedJobs or {}) do
			func(sectionName, setting, oldValue)
		end
		if G_refreshWidgetJobs and setting == "TEMP_TEXT_COLOR" then  -- probably only necessary here
			for _, func in pairs(G_refreshWidgetJobs) do
				func()
			end
			G_updateSDHUD()
			for _, func in pairs(G_refreshWidgetJobs) do
				func()
			end
		end
	end))
end