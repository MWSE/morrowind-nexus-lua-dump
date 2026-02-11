local settingsTemplate = {}

settingsTemplate.TOGGLE = {
	key = "Settings"..MODNAME.."TEMP",
	page = "Settings"..MODNAME.."ENV",
	l10n = "none",
	name = "Temperature and Weather                                                 ", -- lol
	description = "Enable and disable temperature, change the UI, change woodcutting, and change how refilling and water types work.",
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
	name = "Environment Gameplay",
	permanentStorage = true,
	order = 1,
	settings = {
		{
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
			description = "Scorching causes fire damage and Freezing causes frost damage.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TEMP_ZELDA",
			name = "Lava and Freezing Water",
			description = "Being near lava or climbing to the top of Red Mountain causes fire damage\nSwimming in cold water (Solstheim, Sheogorad) causes frozen damage\n\nTo be immune to this fire debuff, equip Bound Armor, Bonemold, Dwemer, Daedric, Ebony, or Indoril Armor.\nFor the cold, equip Stahlrim, Bonemold, or Ebonweave Armor.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TEMP_RM",
			name = "Climbing Red Mountain sets you on fire",
			description = "Wear at least one piece of heat-proof armor (see above) to pass through Red Mountain safely. Above setting must be enabled.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TEMP_WETNESS_DEBUFFS",
			name = "Wetness debuffs",
			description = "-2-10 speed and personality, +3-15% weakness to common disease and shock",
			renderer = "checkbox",
			default = false,
		},
		-- {
		-- 	key = "TEMP_MW_COLD",
		-- 	name = "Morrowind is cold",
		-- 	description = "Enable if you want Vvardenfell to be cold - no warmth or heat mechanics, everything -20 basically",
		-- 	renderer = "checkbox",
		-- 	default = false,
		-- },
		{
			key = "TEMP_RACES",
			name = "Enable Racial Abilities",
			description = "Each race has temperature modifiers.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_TEMP_VW",
			name = "Enable Vampire and Werewolf mechanics",
			description = "Vampires and werewolves have different temperature tolerances.\n\nSupernatural : Vampires and werewolves are immune to cold and have higher tolerance for cold.\n\nImmortal : Vampires are completely immune to cold but more vulnerable to heat. Werewolves are immune to cold in beast form.",
			default = "Supernatural",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Disable", "Supernatural", "Immortal" },
			}
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
			key = "NERF_FIRE_SHIELD",
			name = "Nerf fire shield",
			description = "Water resistance from fire shield is based on how strong the spell is", --"Make the water protection of fire shield based on magnitude (100% protection at mag 10)",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "WATER_DURABILITY_DAMAGE",
            name = "Armor durability is damaged when swimming",
            description = "When swimming, your armor durability loses a percent of its durability every in-game minute.\nSet this to 0 to disable",
			renderer = "number",
			default = 0.15,
		},
	}
}

settingsTemplate.TEMP_UI = {
	key = "Settings"..MODNAME.."TEMP_UI",
	page = "Settings"..MODNAME.."ENV",
	l10n = "none",
	name = "Environment UI",
	permanentStorage = true,
	order = 1,
	settings = {	
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
		},
		{
			key = "TEMP_WETNESS_BAR",
			name = "Enable wetness bar",
			description = "",
			renderer = "checkbox",
			default = true,
		},		
		{
			key = "TEMP_SEGMENTS",
			name = "Enable segments on the stylized and simple bar",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "TEMPERATURE_WIDGET",
			name = "Extend the temperature bar to display exact temperatures",
			description = "",
			renderer = "checkbox",
			default = false,
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
			name = "Add degrees symbol",
			description = "In case you have a truetype font",
			renderer = "checkbox",
			default = true,
		},			
		{
			key = "TEMP_DEBUG_LEVEL_NAME",
			name = "Temp Debug level",
			description = "Set level of information in the tooltip, widget and console",
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
			key = "TESTING_WIDGET",
			name = "Enable Debug UI Mode for the temperature",
			description = "",
			renderer = "checkbox",
			default = false,
		},				
	}
}

settingsTemplate.WOODCUTTING = {
	key = "Settings"..MODNAME.."WOODCUTTING",
	page = "Settings"..MODNAME.."ENV",
	l10n = "none",
	name = "Woodcutting",
	permanentStorage = true,
	order = 5,
	settings= {
		{
			key = "TREES_DESPAWN",
			name = "Trees despawn",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "WOOD_SPARKLES",
			name = "Chopped wood VFX",
			description = "Wood sparkles so that it's easier to see on the ground",
			renderer = "checkbox",
			default = true,
		},
	}
}

settingsTemplate.WATER = {
	key = "Settings"..MODNAME.."WATER",
	page = "Settings"..MODNAME.."ENV",
	l10n = "none",
	name = "Refilling, Saltwater and Suspicious Water",
	permanentStorage = true,
	order = 4,
	settings = {
		{
			key = "WATER_REFILL",
			name = "Refill water at wells",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "WATER_REFILL_SWIMMING",
			name = "Refill open vessels when taking a dip in water",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "WATER_SPILL_ON_JUMP",
			name = "Spill water when jumping",
			description = "When enabled, jumping causes open water containers to spill water.",
			renderer = "checkbox",
			default = true,
		},	
		{
			key = "WATER_CLEAN_ALWAYS",
			name = "Refill water is always clean",
			description = "Enable this to disable saltwater and suspicious water",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "WATER_CLEAN_DUNGEONS",
			name = "Dungeons (mines, caves, tombs) have clean water",
			description = "Excludes water found in sewers",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "WATER_CLEAN_WELLS",
			name = "Wells have clean water",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "WATER_CLEAN_BODIES",
			name = "Rivers and lakes have clean water",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "WATER_CLEAN_VIVEC",
			name = "Vivec has clean water",
			description = "",
			renderer = "checkbox",
			default = false,
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
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			_G[entry.key] = newValue
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