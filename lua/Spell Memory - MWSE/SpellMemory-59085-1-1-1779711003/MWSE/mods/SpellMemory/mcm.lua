-- If you make edits to this file, you must delete the "Data Files\MWSE\config\SpellMemory.json file."

local config = require("SpellMemory.config")

local playerDataKey = "SpellMemory"

local function clearMemorizedSpells()
	if not tes3.player then
		return
	end

	tes3.player.data[playerDataKey] = tes3.player.data[playerDataKey] or {}
	tes3.player.data[playerDataKey].memorizedSpells = {}

	tes3.messageBox("Spell Memory: cleared all memorized spells from this save.")
	mwse.log("[Spell Memory] Cleared all memorized spells from current save.")
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Spell Memory",
	})

	template:saveOnClose(config.configPath, config.current)

	local page = template:createSideBarPage({
		label = "Settings",
		description = "Memorize a limited set of spells and quickly ready them from a hold-to-open menu. Stronger spells use more memory.",
	})

	local general = page:createCategory({
		label = "General",
	})

	general:createYesNoButton({
		label = "Enable Spell Memory",
		description = "Enables or disables the mod. Default: Yes.",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config.current,
		}),
	})

	general:createYesNoButton({
		label = "Show Messages",
		description = "Shows short messages when spells are memorized, forgotten, readied, or when you do not have enough memory. Default: Yes.",
		variable = mwse.mcm.createTableVariable({
			id = "showMessages",
			table = config.current,
		}),
	})

	general:createKeyBinder({
		label = "Open Spell Memory Menu",
		description = "Input used to open the memorized spell menu, and to memorize or forget hovered spells in the Magic menu. Default: Shift+R.",
		allowMouse = true,
		allowCombinations = true,
		keybindName = "Spell Memory Menu",
		variable = mwse.mcm.createTableVariable({
			id = "openCombo",
			table = config.current,
		}),
		defaultSetting = config.default.openCombo,
	})

	local memory = page:createCategory({
		label = "Memory Curve",
	})

	memory:createSlider({
		label = "Level 1 Memory Cap",
		description = "Maximum possible memory at level 1 before Intelligence and Willpower scaling. Default: 10.",
		min = 1,
		max = 255,
		step = 1,
		jump = 1,
		variable = mwse.mcm.createTableVariable({
			id = "levelOneMemoryCap",
			table = config.current,
		}),
	})

	memory:createSlider({
		label = "Level 100 Memory Cap",
		description = "Maximum possible memory at level 100. This is also the hard cap. Adjusting this automatically stretches the leveling curve. Going above level 100 has no extra effect. Default: 50. ",
		min = 1,
		max = 255,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable({
			id = "maxMemory",
			table = config.current,
		}),
	})

	memory:createSlider({
		label = "Level Curve Shape",
		description = "Lower values give more memory earlier. Higher values delay memory growth. Default: 0.65.",
		min = 0.25,
		max = 1.25,
		step = 0.05,
		jump = 0.1,
		variable = mwse.mcm.createTableVariable({
			id = "levelCurvePower",
			table = config.current,
		}),
	})

	memory:createSlider({
		label = "Minimum Attribute Factor",
		description = "How much of your level cap you keep with very low Intelligence and Willpower. 0.60 means 60%. Default: 0.60.",
		min = 0.25,
		max = 1.0,
		step = 0.05,
		jump = 0.1,
		variable = mwse.mcm.createTableVariable({
			id = "minimumAttributeFactor",
			table = config.current,
		}),
	})

	local memorization = page:createCategory({
		label = "Memorizing and Forgetting",
	})

	memorization:createYesNoButton({
		label = "Require Town or City",
		description = "If enabled, spells can only be memorized or forgotten in towns, cities, and other places where resting is not allowed. Default: Yes.",
		variable = mwse.mcm.createTableVariable({
			id = "requireTownOrCity",
			table = config.current,
		}),
	})

	memorization:createButton({
		label = "Clear Memorized Spells",
		buttonText = "Clear",
		description = "Clears all memorized spells from the current save. This does not remove spells from your spellbook. Only available in-game.",
		inGameOnly = true,
		callback = clearMemorizedSpells,
	})

	local bonus = page:createCategory({
		label = "Memorized Spell Bonus",
	})

	bonus:createYesNoButton({
		label = "Enable Cast Chance Bonus",
		description = "If enabled, memorized normal spells have increased cast chance. Default: Yes.",
		variable = mwse.mcm.createTableVariable({
			id = "memorizedBonusEnabled",
			table = config.current,
		}),
	})

	bonus:createSlider({
		label = "Cast Chance Bonus",
		description = "Flat percentage points added to memorized spell cast chance. Default: 25.",
		min = 0,
		max = 50,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable({
			id = "memorizedCastChanceBonus",
			table = config.current,
		}),
	})

	local penalty = page:createCategory({
		label = "Unmemorized Spell Penalty",
	})

	penalty:createYesNoButton({
		label = "Enable Cast Chance Penalty",
		description = "If enabled, normal spells that are not memorized have reduced cast chance. Default: Yes.",
		variable = mwse.mcm.createTableVariable({
			id = "unmemorizedPenaltyEnabled",
			table = config.current,
		}),
	})

	penalty:createSlider({
		label = "Cast Chance Penalty",
		description = "Flat percentage points removed from unmemorized spell cast chance. Default: 15.",
		min = 0,
		max = 50,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable({
			id = "unmemorizedCastChancePenalty",
			table = config.current,
		}),
	})

	local debugging = page:createCategory({
		label = "Debug",
	})

	debugging:createYesNoButton({
		label = "Debug Logging",
		description = "Writes Spell Memory debug lines to MWSE.log. Default: No.",
		variable = mwse.mcm.createTableVariable({
			id = "debugLog",
			table = config.current,
		}),
	})

	template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)