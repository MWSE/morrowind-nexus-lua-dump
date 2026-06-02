local settingsTemplate = {}

local RENDERER_SELECT = "SuperSelect2"
local RENDERER_NUMBER = "SuperSlider4"

settingsTemplate.TOGGLE = {
	key = "Settings"..MODNAME.."TOGGLE",
	page = MODNAME,
	l10n = "none",
	name = "Enable Needs                                                     ", -- lol
	permanentStorage = true,
	order = 0,
	settings = {
		{
			key = "GLOBAL_PRESET",
			name = "Global Preset",
			description = "Applies a difficulty preset, a UI preset and other settings all at once.\nPicking 'Custom' will not change anything",
			default = "Default",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Custom", "Default", "Minimalist", "Skyrim", "Only Buffs", "Only Debuffs" },
				width = 170,
				buttons = {
					{ width = 28, icon = "textures/SunsDusk/export.png", side = "left",
					  event = "SunsDusk_SettingsIO", eventData = { action = "export" } },
					{ width = 28, icon = "textures/SunsDusk/import.png", side = "left",
					  event = "SunsDusk_SettingsIO", eventData = { action = "import" } },
				},
			},
		},
		{
			key = "DIFFICULTY_PRESET",
			name = "Difficulty Preset",
			description = "",
			default = "Default",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Default", "Hard", "Hardcore", "Ownly", "Minimalist" },
			},
		},
		{
			key = "NEEDS_TIREDNESS",
			name = "Enable Tiredness",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_HUNGER",
			name = "Enable Hunger",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_THIRST",
			name = "Enable Thirst",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "DEBUG_LEVEL_NAME",
			name = "Debug level",
			description = "Enable debug messages in the console",
			renderer = RENDERER_SELECT,
			default = "Quiet",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Silent", "Quiet", "Chatty", "Deep", "Trace", "Spammy" }
			}	
		},
	}
}

-- ------------------------------ SLEEP ------------------------------

settingsTemplate.SLEEP = {
	key = "Settings"..MODNAME.."SLEEP",
	page = MODNAME,
	l10n = "none",
	name = "Sleep and Tiredness",
	permanentStorage = true,
	order = 1,
	settings = {
		{
			key = "HOURS_PER_RESTED_STATE",
			name = "Hours until you loose 1 stage of restedness",
			description = "There are 6 stages. 8 hours is recommended for a timescale of 30 (default timescale).\n\nLower number = faster rate of change",
			renderer = RENDERER_NUMBER,
			default = 8,
			argument = {
				min = 0.1,
				max = 100,
				step = 0.5,
				default = 8,
				unit = " hrs",
				minLabel = "Fast",
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
			key = "HOURS_PER_SLEEP",
			name = "Rest Multiplier",
			description = "By default, resting reduces tiredness by twice as much as you lose when you're awake.\nIncrease this number to restore more tiredness when sleeping",
			renderer = RENDERER_NUMBER,
			default = 2,
			argument = {
				min = 0.1,
				max = 100,
				step = 0.1,
				default = 2,
				unit = "x",
				minLabel = "Weak",
				maxLabel = "Strong",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},		
		{
			key = "NEEDS_TIREDNESS_BUFFS_DEBUFFS",
			name = "Disable Tiredness Penalties",
			description = "Enable if you only want buffs from resting.",
			default = "Buffs and debuffs", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Buffs and debuffs", "Only buffs", "Only debuffs" },
				width = 170,
			},
		},
		{
			key = "NEEDS_SEVERITY_TIREDNESS",
			name = "Difficulty Presets",
			description = "Increase the degree of penalties from being drowsy, tired, and exhausted, and disable the companion mechanic for debuffs.\nDoes not change the buffs.",
			default = "Default", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Default", "Hard", "Hardcore" },
			},
		},
		{
			key = "SLEEP_PERSONALITY",
			name = "Enable Sleep Personality",
			description = "Enable sleep cycle tracking which leads to one of three abilities : Morning Lark, Night Owl, or Insomniac. Only one sleep personality can be active and must be maintained. Having the Insomniac sleep personality removes penalties from being tired.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_TIREDNESS_COMPANION",
			name = "Enable Companion Mechanics",
			description = "Adventuring with a companion makes life easier and gives you different buffs and penalties.",
			renderer = "checkbox",
			default = false,
		},
	}
}

-- ------------------------------ HUNGER ------------------------------

settingsTemplate.HUNGER = {
	key = "Settings"..MODNAME.."HUNGER",
	page = MODNAME,
	l10n = "none",
	name = "Hunger",
	permanentStorage = true,
	order = 2,
	settings = {
		{
			key = "HOURS_PER_HUNGER_STATE",
			name = "Hours until you loose 1 stage of hunger",
			description = "Increase the rate of hunger. There are 6 stages. 7 hours is recommended for a timescale of 30 (default timescale).\n\nLower number = faster rate of change",
			renderer = RENDERER_NUMBER,
			default = 7.5,
			argument = {
				min = 0.1,
				max = 100,
				step = 0.5,
				default = 7.5,
				unit = " hrs",
				minLabel = "Fast",
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
			key = "NEEDS_HUNGER_BUFFS_DEBUFFS",
			name = "Disable Hunger Penalties",
			description = "Enable if you only want buffs for eating food.",
			default = "Buffs and debuffs", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Buffs and debuffs", "Only buffs", "Only debuffs" },
				width = 170,
			},
		},
		{
			key = "NEEDS_SEVERITY_HUNGER",
			name = "Difficulty Presets",
			description = "Increase the degree of penalties from being peckish, hungry, and starving, and disable the companion mechanic for debuffs.",
			default = "Default",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Default", "Hard", "Hardcore" }
			},
		},
		{
			key = "NEEDS_RACES_HUNGER",
			name = "Enable Racial Effects",
			description = "Modifiers are applied based on race when eating food.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_HUNGER_NOURISHMENT",
			name = "Enable Nourishment", 
			description = "Enable food habit tracking which leads to one of three abilities: Well-Nourished, Corprus-Eater, or the Green Pact. Only one Nourishment ability can be active and must be maintained.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_HUNGER_VW",
			name = "Enable Vampire and Werewolf modifiers and mechanics",
			description = "Vampires and werewolves are immune to diseases from raw meat if enabled.\n\nSupernatural : Vampires are able to restore some hunger from using Absorb Health spells. Werewolves (OpenMW 0.50 only) are able to restore hunger from eating animal products and using melee attacks in beast form.\n\nImmortal : Vampires can only restore hunger from eating Raw Meat and using spells with Absorb Health. Werewolves (0.50 only) only restore hunger from eating animal products and using melee attacks in beast form.",
			default = "Supernatural",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Disable", "Supernatural", "Immortal" },
			}
		},
		{
			key = "RAW_MEAT_DISEASE_CHANCE",
			name = "Raw Meat Disease Chance (%)",
			description = "Chance of contracting a common disease from eating raw meat.",
			renderer = RENDERER_NUMBER,
			default = 20,
			argument = {
				min = 0,
				max = 1000,
				step = 5,
				default = 20,
				unit = "%",
				minLabel = "Never",
				maxLabel = "Always",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "NEEDS_HUNGER_TOXICITY",
			name = "Enable Food poisoning",
			description = "Eating items categorized as 'Toxic' give a poison debuff.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "NEEDS_HUNGER_COMPANION",
			name = "Enable Companion Mechanics",
			description = "Adventuring with a companion makes life easier and gives you different buffs and penalties.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "DEATH_BY_STARVATION",
			name = "Death by Starvation",
			description = "Take severe damage when completely starving.\nMakes it impossible to get the Fasting ability",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "FOOD_HEALS",
			name = "Eating restores health",
			description = "Food and ingredients restore a small amount of health.",
			default = "Disable", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Disable", "Only ingredients", "Only cooked", "All food" },
			},
		},
	}
}

-- ------------------------------ THIRST ------------------------------

settingsTemplate.THIRST = {
	key = "Settings"..MODNAME.."THIRST",
	page = MODNAME,
	l10n = "none",
	name = "Thirst",
	permanentStorage = true,
	order = 3,
	settings = {
		{
			key = "HOURS_PER_THIRST_STATE",
			name = "Hours until you loose 1 stage of thirst",
			description = "There are 6 stages. 6 hours is recommended for a timescale of 30 (default timescale).\n\nLower number = faster rate of change",
			renderer = RENDERER_NUMBER,
			default = 7,
			argument = {
				min = 0.1,
				max = 100,
				step = 0.5,
				default = 7,
				unit = " hrs",
				minLabel = "Fast",
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
			key = "NEEDS_THIRST_BUFFS_DEBUFFS",
			name = "Disable Thirst Penalties",
			description = "Enable if you only want buffs for drinking water.",
			default = "Buffs and debuffs", 
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Buffs and debuffs", "Only buffs", "Only debuffs" },
				width = 170,
			},
		},
		{
			key = "NEEDS_SEVERITY_THIRST",
			name = "Difficulty Presets",
			description = "Increase the degree of penalties from being parched, thirsty, and dehydrated, and disable the companion mechanic for debuffs.",
			default = "Default",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Default", "Hard", "Hardcore" }
			},
		},
		{
			key = "NEEDS_RACES_THIRST",
			name = "Enable Racial Effects",
			description ="Modifiers are applied based on race when drinking water.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_THIRST_VW",
			name = "Enable Vampire and Werewolf modifiers and mechanics",
			description = "Vampires and werewolves are immune to diseases from suspicious water if enabled.\n\nSupernatural : Vampires are able to restore some thirst from using Absorb Health spells.\n\nImmortal : Vampires can only restore thirst from drinking blood. Werewolves can drink suspicious water without ill effects.",
			default = "Supernatural",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Disable", "Supernatural", "Immortal" },
			}
		},		
		{
			key = "WATER_SPAWN_CHANCE",
			name = "Water Spawn Chance (%)",
			description = "Chance of adding water to any container in the world",
			renderer = RENDERER_NUMBER,
			default = 30,
			argument = {
				min = 0,
				max = 1000,
				step = 5,
				default = 30,
				unit = "%",
				minLabel = "Never",
				maxLabel = "Always",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		-- {
		--	key = "SUJAMMA_SPAWN_CHANCE",
		--	name = "Sujamma Spawn Chance (%)",
		--	description = "Chance of adding sujamma to any container in the world",
		--	renderer = RENDERER_NUMBER,
		--	default = 15, -- sujamma spawns more near an innkeeper - has in their inventory
		--	argument = { min = 0, max = 100 },
		-- },
		{
			key = "NEEDS_THIRST_ALCOHOL_R",
			name = "Alcohol makes you thirsty.",
			description = "",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "ATRONACH_WATER_MULT",
			name = "Atronach Water mechanics",
			description = "Water restores a small amount of magicka. Anything other than 'Full' reduces this.",
			renderer = RENDERER_SELECT,
			default = "Half",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "None", "Half", "Full" }
			},
		},
		{
			key = "ATRONACH_WATER_MULT_AFFECTS_ALL",
			name = "Atronach Water mechanics affect everyone",
			description = "Toggle this to make the setting above apply to you, even if you don't have the atronach birthsign",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "NEEDS_THIRST_COMPANION",
			name = "Enable Companion Mechanics",
			description = "Adventuring with a companion makes life easier and gives you different buffs and penalties.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "DEATH_BY_DEHYDRATION",
			name = "Death by Dehydration",
			description = "Enable severe damage when dehydration reaches 100%",
			renderer = "checkbox",
			default = false,
		},
	}
}

settingsTemplate.COOKING = {
	key = "Settings"..MODNAME.."COOKING",
	page = MODNAME,
	l10n = "none",
	name = "Cooking and Tea Brewing",
	permanentStorage = true,
	order = 4,
	settings = {
		{
			key = "INNKEEPER_FOOD_PLACEMENT",
			name = "Excellent Service",
			description = "Publicans have good food service and place meals in front of you.\nIf no table or counter is detected, your meal is added to your inventory.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "INNKEEPER_COOKING_SKILLS",
			name = "Publicans can cook too!",
			description = "Publicans have a Cooking skill which levels when requesting a Homecooked meal.\nOtherwise you will use their kitchen.\nYou still have to pay for each meal but have infinite water and foodware.",
			renderer = "checkbox",
			default = true,
		},		
		{
			key = "NEEDS_TEA",
			name = "Enable brewing tea",
			description = "Brew heather or stoneflower tea by having a teacup and teapot.\n\nTo brew tea, interact with a teapot (found at general merchants) while having a tea cup in your inventory.\nA redware cup counts as a tea cup in vanilla",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "COOKING_MODE",
			name = "Cooking Mode",
			description = "",
			default = "Immersive",
			renderer = RENDERER_SELECT,
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Immersive", "Arcane Cooking (12 Hours)", "Arcane Cooking (24 Hours)" },
				width = 250,
			},
		},
		{
			key = "FOOD_NAME_INFO_BRACKETS",
			name = "Food and Drink Display",
			description = "Cooked foods have their Food, Drink and Wake Values in names.\nExp: Cooked Mushrooms [123,8,0]",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "COOKING_MAGNITUDE_MULT",
			name = "Effect Magnitude Multiplier",
			description = "",
			renderer = RENDERER_NUMBER,
			default = 0.8,
			argument = {
				min = 0.01,
				max = 100,
				step = 0.05,
				default = 0.8,
				unit = "x",
				minLabel = "Weak",
				maxLabel = "Strong",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "COOKING_WATER_MULT",
			name = "Used Water Multiplier",
			description = "How many quarter liters needed for cooking",
			renderer = RENDERER_NUMBER,
			default = 1,
			argument = {
				min = 0,
				max = 1000,
				step = 1,
				default = 1,
				unit = "",
				minLabel = "None",
				maxLabel = "More",
				labelSize = 13,
				width = 120,
				thickness = 15,
				showDefaultMark = true,
				showResetButton = false,
				bottomRow = true,
			},
		},
		{
			key = "COOKING_FOODWARE_REQUIRED",
			name = "Cooking requires foodware",
			description = "",
			renderer = "checkbox",
			default = true,
		},
	}
}

settingsTemplate.COMPATIBILITY = {
	key = "Settings"..MODNAME.."COMPATIBILITY",
	page = MODNAME,
	l10n = "none",
	name = "Compatibility",
	permanentStorage = true,
	order = 5,
	settings = {
		{
			key = "WHISPER_FIX",
			name = "Whisper fix",
			description = "Disables whispering from Dynamic Sounds.\nDon't think this is an incompatibility but people blame this mod.",
			renderer = "checkbox",
			default = false,
		},
	}
}
------------------------------ Difficulty Presets ------------------------------

DifficultyPresets = {
	["Default"] = {
		NEEDS_SEVERITY_THIRST = "Default",
		NEEDS_SEVERITY_HUNGER = "Default",
		NEEDS_SEVERITY_TIREDNESS = "Default",
		ATRONACH_WATER_MULT = "Half",
		WATER_SPAWN_CHANCE = 30,
		NEEDS_HUNGER_TOXICITY = false,
		RAW_MEAT_DISEASE_CHANCE = 20,
		DEATH_BY_STARVATION = false,
		DEATH_BY_DEHYDRATION = false,
		HOURS_PER_RESTED_STATE = 8,
		HOURS_PER_HUNGER_STATE = 7.5,
		HOURS_PER_THIRST_STATE = 7,
		NEEDS_THIRST_ALCOHOL_R = false,
		WATER_REFILL = true,
		WATER_REFILL_SWIMMING = true,
		COOKING_MAGNITUDE_MULT = 1,
	},
	["Hard"] = {
		NEEDS_SEVERITY_THIRST = "Hard",
		NEEDS_SEVERITY_HUNGER = "Hard",
		NEEDS_SEVERITY_TIREDNESS = "Hard",
		ATRONACH_WATER_MULT = "None",
		WATER_SPAWN_CHANCE = 20,
		NEEDS_HUNGER_TOXICITY = true,
		RAW_MEAT_DISEASE_CHANCE = 50,
		DEATH_BY_STARVATION = false,
		DEATH_BY_DEHYDRATION = false,
		HOURS_PER_RESTED_STATE = 6,
		HOURS_PER_HUNGER_STATE = 5.5,
		HOURS_PER_THIRST_STATE = 5,
		NEEDS_THIRST_ALCOHOL_R = false,
		WATER_REFILL = true,
		WATER_REFILL_SWIMMING = true,
		COOKING_MAGNITUDE_MULT = 0.85,
	},
	["Hardcore"] = {
		NEEDS_SEVERITY_THIRST = "Hardcore",
		NEEDS_SEVERITY_HUNGER = "Hardcore",
		NEEDS_SEVERITY_TIREDNESS = "Hardcore",
		ATRONACH_WATER_MULT = "None",
		WATER_SPAWN_CHANCE = 10,
		NEEDS_HUNGER_TOXICITY = true,
		RAW_MEAT_DISEASE_CHANCE = 100,
		DEATH_BY_STARVATION = true,
		DEATH_BY_DEHYDRATION = true,
		HOURS_PER_RESTED_STATE = 4,
		HOURS_PER_HUNGER_STATE = 3.5,
		HOURS_PER_THIRST_STATE = 3,
		NEEDS_THIRST_ALCOHOL_R = true,
		WATER_REFILL = false,
		WATER_REFILL_SWIMMING = true,
		COOKING_MAGNITUDE_MULT = 0.7,
	},
	["Ownly"] = {
		COOKING_MODE = "Arcane Cooking (12 Hours)",
		INNKEEPER_COOKING_SKILLS = false,
		WATER_SPAWN_CHANCE = 20,
		FOOD_HEALS = "All food",
		NEEDS_HUNGER_TOXICITY = true,
		RAW_MEAT_DISEASE_CHANCE = 50,
	},
	["Minimalist"] = {
        NEEDS_SEVERITY_THIRST = "Default",
        NEEDS_SEVERITY_HUNGER = "Default",
        NEEDS_SEVERITY_TIREDNESS = "Default",
        HOURS_PER_SLEEP = 4,
        SLEEP_PERSONALITY = false,    
        NEEDS_RACES_HUNGER = false,
        NEEDS_HUNGER_NOURISHMENT = false,
        NEEDS_HUNGER_VW = "Disable",
        RAW_MEAT_DISEASE_CHANCE = 0,
        NEEDS_RACES_THIRST = false,
        NEEDS_THIRST_VW = "Disable",
        WATER_SPAWN_CHANCE = 0,
        ATRONACH_WATER_MULT = "None",
        ATRONACH_WATER_MULT_AFFECTS_ALL = true,
        NEEDS_TEA = false,
    },
}

------------------------------ Global Presets ------------------------------

-- each entry bundles a difficulty preset, a ui preset and extra overrides
-- global = needs-page settings (this file), player = ui-page settings (sd_ui_settings)
-- DIFFICULTY_PRESET and HUD_PRESET cascade into their own sub-settings, so list extras only
GlobalPresets = {
	-- factory reset: the live apply sweeps every registered key to its default
	-- (see globalPresetJob / presetJob); the keys below only seed sparse Default imports
	["Default"] = {
		global = {
			DIFFICULTY_PRESET = "Default",
			NEEDS_TIREDNESS_COMPANION = false,
			NEEDS_HUNGER_COMPANION = false,
			NEEDS_THIRST_COMPANION = false,
			NEEDS_TEMP = true,
			NEEDS_CLEAN = true,
		},
		player = {
			HUD_PRESET = "Velothi3 (T)",
			ENABLE_TOOLTIPS = true,
		},
	},
	["Minimalist"] = {
		global = {
			DIFFICULTY_PRESET = "Minimalist",
			NEEDS_TEMP = false,
			NEEDS_CLEAN = false,
		},
		player = {
			HUD_PRESET = "Hidden",
			ENABLE_TOOLTIPS = false,
		},
	},
	["Skyrim"] = {
		global = {
			DIFFICULTY_PRESET = "Hard",
			NEEDS_TEMP = true,
			NEEDS_CLEAN = false,
			HOURS_PER_SLEEP = 4,
			SLEEP_PERSONALITY = false,    
			NEEDS_RACES_HUNGER = false,
			NEEDS_HUNGER_NOURISHMENT = false,
			NEEDS_HUNGER_VW = "Supernatural",
			RAW_MEAT_DISEASE_CHANCE = 50,
			NEEDS_RACES_THIRST = false,
			NEEDS_THIRST_VW = "Supernatural",
			WATER_SPAWN_CHANCE = 0,
			ATRONACH_WATER_MULT = "None",
			ATRONACH_WATER_MULT_AFFECTS_ALL = true,
			NEEDS_TEA = false,
			TEMP_RM = false,
			WATER_DURABILITY_DAMAGE = 0,
			WATER_REFILL_SWIMMING = false,
			WATER_CLEAN_ALWAYS = true,
		},
		player = {
			HUD_PRESET = "Hidden",
			ENABLE_TOOLTIPS = false,
			STATS_WINDOW_SECTION = false,
		},
	},
	["Only Buffs"] = {
		global = {
			DIFFICULTY_PRESET = "Default",
			NEEDS_HUNGER_BUFFS_DEBUFFS = "Only buffs",
			NEEDS_THIRST_BUFFS_DEBUFFS = "Only buffs",
			NEEDS_TIREDNESS_BUFFS_DEBUFFS = "Only buffs",
			NEEDS_CLEAN_BUFFS_DEBUFFS = "Only buffs",
			TEMP_BUFFS_DEBUFFS = "Only buffs",
			TEMP_HIDE_NO_BUFF = true,
		},
		player = {
			HUD_PRESET = "Velothi3 (T)",
			H_HIDE_NO_BUFF = true,
			T_HIDE_NO_BUFF = true,
			S_HIDE_NO_BUFF = true,
			C_HIDE_NO_BUFF = true,
			HUD_SORT_BY_VISIBILITY = true,
		},
	},
	["Only Debuffs"] = {
		global = {
			DIFFICULTY_PRESET = "Default",
			NEEDS_HUNGER_BUFFS_DEBUFFS = "Only debuffs",
			NEEDS_THIRST_BUFFS_DEBUFFS = "Only debuffs",
			NEEDS_TIREDNESS_BUFFS_DEBUFFS = "Only debuffs",
			NEEDS_CLEAN_BUFFS_DEBUFFS = "Only debuffs",
			TEMP_BUFFS_DEBUFFS = "Only debuffs",
			TEMP_HIDE_NO_BUFF = true,
		},
		player = {
			HUD_PRESET = "Velothi3 (T)",
			H_HIDE_NO_BUFF = true,
			T_HIDE_NO_BUFF = true,
			S_HIDE_NO_BUFF = true,
			C_HIDE_NO_BUFF = true,
			HUD_SORT_BY_VISIBILITY = true,
		},
	},
}

------------------------------ Register Settings ------------------------------

if world then
	for id, template in pairs(settingsTemplate) do
		I.Settings.registerGroup(template)
	end
else
	I.Settings.registerPage {
		key = MODNAME,
		l10n = "none",
		name = "Sun's Dusk: Primary Needs",
		description = "By ownlyme and lhyacinth\nVersion 1.9\n\nEnable and disable needs, buffs and debuffs, enable death, racial abilities and more."
	}
end

------------------------------ Read Settings ------------------------------

local debugLevelNames = { "Silent", "Quiet", "Chatty", "Deep", "Trace", "Spammy" }

local function applyDebugLevel(levelName)
	for i, name in ipairs(debugLevelNames) do
		if name == levelName then
			DEBUG_LEVEL = i
			return
		end
	end
	DEBUG_LEVEL = 1 -- fallback to Silent
end

local function applyHiddenDifficultySettings(diff)
	if diff == "Default" then
		WAKEVALUE_MULT = 1
		FOODVALUE_MULT = 1
		DRINKVALUE_MULT = 1
	elseif diff == "Hard" then
		WAKEVALUE_MULT = 0.75
		FOODVALUE_MULT = 0.75
		DRINKVALUE_MULT = 0.75
	elseif diff == "Hardcore" then
		WAKEVALUE_MULT = 0.5
		FOODVALUE_MULT = 0.5
		DRINKVALUE_MULT = 0.5
	end
end

-- shared across every global settings file so presets can reach any global key
G_globalSettingDefaults = G_globalSettingDefaults or {}

local function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.globalSection(template.key)
		for i, entry in pairs(template.settings) do
			local newValue = settingsSection:get(entry.key)
			if newValue == nil then
				newValue = entry.default
			end
			_G[entry.key] = newValue
			G_globalSettingDefaults[entry.key] = { section = template.key, default = entry.default }
			if entry.key == "DIFFICULTY_PRESET" then
				applyHiddenDifficultySettings(settingsSection:get("DIFFICULTY_PRESET"))
			end
		end
	end
	applyDebugLevel(DEBUG_LEVEL_NAME)
end

readAllSettings()

------------------------------ Settings Event ------------------------------

-- revert old preset keys to their registered defaults (except those the new preset sets), then apply new
-- G_globalSettingDefaults spans every global settings file, so env and bathing keys resolve too
local function applyGlobalSettingsPreset(oldPreset, newPreset)
	if oldPreset then
		for key, _ in pairs(oldPreset) do
			local info = G_globalSettingDefaults[key]
			if info and not (newPreset and newPreset[key] ~= nil) then
				storage.globalSection(info.section):set(key, info.default)
			end
		end
	end
	if newPreset then
		for key, value in pairs(newPreset) do
			local info = G_globalSettingDefaults[key]
			if info then
				storage.globalSection(info.section):set(key, value)
			end
		end
	end
end

local function difficultyPresetJob(oldValue, newValue)
	if not saveData then return end
	G_onUpdateJobs["applyPreset"] = function()
		applyGlobalSettingsPreset(DifficultyPresets[oldValue], DifficultyPresets[newValue])
		G_onUpdateJobs["applyPreset"] = nil
	end
end

-- expands a global preset into its final flat key set: the referenced difficulty
-- preset first, then the preset's own keys on top so explicit extras always win
local function composeGlobalState(presetName)
	local result = {}
	local preset = GlobalPresets[presetName]
	if preset and preset.global then
		local difficulty = preset.global.DIFFICULTY_PRESET
		if difficulty and DifficultyPresets[difficulty] then
			for key, value in pairs(DifficultyPresets[difficulty]) do result[key] = value end
		end
		for key, value in pairs(preset.global) do result[key] = value end
	end
	return result
end

-- applies only the global half here; the player half rides the same setting change in sd_ui_settings
local function globalPresetJob(oldValue, newValue)
	if not saveData then return end
	if newValue == "Custom" then return end -- leave everything as-is
	G_onUpdateJobs["applyGlobalPreset"] = function()
		-- write the composed result directly with the difficulty cascade suppressed,
		-- so the sub-preset cannot overwrite the global preset's explicit keys
		G_applyingGlobalPreset = true
		if newValue == "Default" then
			-- factory reset: sweep every registered global key to its default
			-- skip GLOBAL_PRESET (keeps the selector put) and keys already at default,
			-- since a redundant set still fires subscriptions that can tear down widgets
			for key, info in pairs(G_globalSettingDefaults) do
				local current = storage.globalSection(info.section):get(key)
				if key ~= "GLOBAL_PRESET" and current ~= nil and current ~= info.default then
					storage.globalSection(info.section):set(key, info.default)
				end
			end
		else
			applyGlobalSettingsPreset(composeGlobalState(oldValue), composeGlobalState(newValue))
		end
		-- change notifications are deferred, so lift suppression after a short delay
		local clearTime = core.getRealTime() + 0.5
		G_onUpdateJobs["clearApplyGlobalPreset"] = function()
			if core.getRealTime() >= clearTime then
				G_applyingGlobalPreset = false
				G_onUpdateJobs["clearApplyGlobalPreset"] = nil
			end
		end
		G_onUpdateJobs["applyGlobalPreset"] = nil
	end
end

for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.globalSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
		
		-- G_importingSettings is held true while p_settingsIO writes an imported snapshot,
		-- so the preset cascades do not overwrite the individual values that follow
		if world and setting == "DIFFICULTY_PRESET" and not G_importingSettings and not G_applyingGlobalPreset then
			difficultyPresetJob(oldValue, _G[setting])
		end
		if world and setting == "GLOBAL_PRESET" and not G_importingSettings then
			globalPresetJob(oldValue, _G[setting])
		end

		if setting == "DEBUG_LEVEL_NAME" then
			applyDebugLevel(DEBUG_LEVEL_NAME)
		end
		if setting == "DIFFICULTY_PRESET" then
			applyHiddenDifficultySettings(settingsSection:get("DIFFICULTY_PRESET"))
		end
		for _, func in pairs(G_settingsChangedJobs or {}) do
			func(sectionName, setting, oldValue)
		end
		if G_refreshWidgetJobs then
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