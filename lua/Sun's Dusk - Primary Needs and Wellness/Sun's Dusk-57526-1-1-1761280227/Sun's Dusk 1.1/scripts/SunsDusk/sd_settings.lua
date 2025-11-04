-- local settings = require("scripts.SunsDusk.sd_settings.ui")

settingsTemplate = {}

settingsTemplate.TOGGLE = {
	key = "Settings"..MODNAME.."TOGGLE",
	page = MODNAME,
	l10n = "none",
	name = "Enable Needs                                                            ", -- lol
	permanentStorage = true,
	order = 0,
	settings = {
		{
			key = "DIFFICULTY_PRESET",
			name = "Preset",
			description = "",
			default = "Default", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Default", "Hard", "Hardcore"  },
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
			renderer = "select",
			default = "Quiet",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Silent", "Quiet", "Chatty", "Deep", "Trace" }
			}	
		},
	}
}

-- ─────────────────────────────────────────────────────────────────────────────── SLEEP ───────────────────────────────────────────────────────────────────────────────

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
			description = "There are 6 stages. 8 hours is recommended for a timescale of 30 (default timescale).",
			renderer = "number",
			default = 8,
			argument = { min = 0.1, max = 100 },
		},
		{
			key = "NEEDS_TIREDNESS_BUFFS",
			name = "Disable Tiredness Penalties",
			description = "Enable if you only want buffs from resting.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "NEEDS_SEVERITY_TIREDNESS",
			name = "Difficulty Presets",
			description = "Increase the degree of penalties from being drowsy, tired, and exhausted, and disable the companion mechanic for debuffs.\nDoes not change the buffs.",
			default = "Default", 
			renderer = "select",
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
			default = true,
		},
	}
}

-- ─────────────────────────────────────────────────────────────────────────────── HUNGER ───────────────────────────────────────────────────────────────────────────────

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
			description = "There are 6 stages. 7 hours is recommended for a timescale of 30 (default timescale).",
			renderer = "number",
			default = 7,
			argument = { min = 0.1, max = 100 },
		},
		{
			key = "NEEDS_HUNGER_BUFFS",
			name = "Disable Hunger Penalties",
			description = "Enable if you only want buffs for eating food.",
			renderer = "checkbox",
			default = false,
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
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none",
				items = { "Disable", "Supernatural", "Immortal" },
			}
		},
		{
			key = "NEEDS_SEVERITY_HUNGER",
			name = "Difficulty Presets",
			description = "Increase the degree of penalties from being peckish, hungry, and starving, and disable the companion mechanic for debuffs.",
			default = "Default",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Default", "Hard", "Hardcore" }
			},
		},
		{
			key = "RAW_MEAT_DISEASE_CHANCE",
			name = "Raw Meat Disease Chance (%)",
			description = "Chance of contracting a common disease from eating raw meat.",
			renderer = "number",
			default = 20,
			argument = { min = 0, max = 1000 },
		},
		{
			key = "NEEDS_HUNGER_TOXICITY",
			name = "Enable Food poisoning",
			description = "Eating items categorized as 'toxic' give a poison debuff.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "NEEDS_HUNGER_COMPANION",
			name = "Enable Companion Mechanics",
			description = "Adventuring with a companion makes life easier and gives you different buffs and penalties.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "DEATH_BY_STARVATION",
			name = "Death by Starvation",
			description = "Enable severe damage when hunger reaches 100%",
			renderer = "checkbox",
			default = false,
		},
	}
}

-- ─────────────────────────────────────────────────────────────────────────────── THIRST ───────────────────────────────────────────────────────────────────────────────

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
			description = "There are 6 stages. 6 hours is recommended for a timescale of 30 (default timescale).",
			renderer = "number",
			default = 6,
			argument = { min = 0.1, max = 100 },
		},
		{
			key = "NEEDS_THIRST_BUFFS",
			name = "Disable Thirst Penalties",
			description = "Enable if you only want buffs for drinking water.",
			renderer = "checkbox",
			default = false,
		},
		{
			key = "NEEDS_RACES_THIRST",
			name = "Enable Racial Effects",
			description ="Modifiers are applied based on race when drinking water.",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_SEVERITY_THIRST",
			name = "Difficulty Presets",
			description = "Increase the degree of penalties from being parched, thirsty, and dehydrated, and disable the companion mechanic for debuffs.",
			default = "Default",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Default", "Hard", "Hardcore" }
			},
		},
		{
			key = "WATER_SPAWN_CHANCE",
			name = "Water Spawn Chance (%)",
			description = "Chance of adding water to any container in the world",
			renderer = "number",
			default = 30,
			argument = { min = 0, max = 100 },
		},
		-- {
		-- 	key = "SUJAMMA_SPAWN_CHANCE",
		-- 	name = "Sujamma Spawn Chance (%)",
		-- 	description = "Chance of adding sujamma to any container in the world",
		-- 	renderer = "number",
		-- 	default = 15, -- sujamma spawns more near an innkeeper - has in their inventory
		-- 	argument = { min = 0, max = 100 },
		-- },
		{
			key = "NEEDS_THIRST_REFILL",
			name = "Refill water at wells?",
			description = "",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "NEEDS_THIRST_REFILL_SWIMMING",
			name = "Refill open vessels when taking a dip in water?",
			description = "",
			renderer = "checkbox",
			default = true,
		},
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
			description = "Water restores a small amount of magicka. Anything other than 'none' reduces this.",
			renderer = "select",
			default = "Half",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "None", "Half", "Full" }
			},
		},
		{
			key = "NEEDS_THIRST_COMPANION",
			name = "Enable Companion Mechanics",
			description = "Adventuring with a companion makes life easier and gives you different buffs and penalties.",
			renderer = "checkbox",
			default = true,
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
	name = "COOKING",
	permanentStorage = true,
	order = 4,
	settings = {
		{
			key = "COOKING_MODE",
			name = "Cooking Mode",
			description = "",
			default = "Immersive",
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = { "Immersive", "Arcane Cooking (12 Hours)", "Arcane Cooking (24 Hours)" }
			},
		},
		{
			key = "COOKING_MAGNITUDE_MULT",
			name = "Effect Magnitude Mult",
			description = "",
			renderer = "number",
			default = 1,
			argument = { min = 0.01, max = 100 },
		},
	}
}


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
		HOURS_PER_HUNGER_STATE = 7,
		HOURS_PER_THIRST_STATE = 6,
		NEEDS_THIRST_ALCOHOL_R = false,
		NEEDS_THIRST_REFILL = true,
		NEEDS_THIRST_REFILL_SWIMMING = true,
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
		HOURS_PER_RESTED_STATE = 4,
		HOURS_PER_HUNGER_STATE = 3,
		HOURS_PER_THIRST_STATE = 3,
		NEEDS_THIRST_ALCOHOL_R = false,
		NEEDS_THIRST_REFILL = true,
		NEEDS_THIRST_REFILL_SWIMMING = true,
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
		HOURS_PER_RESTED_STATE = 2.5,
		HOURS_PER_HUNGER_STATE = 1.5,
		HOURS_PER_THIRST_STATE = 1.5,
		NEEDS_THIRST_ALCOHOL_R = true,
		NEEDS_THIRST_REFILL = false,
		NEEDS_THIRST_REFILL_SWIMMING = true,
		COOKING_MAGNITUDE_MULT = 0.7,
	},
}