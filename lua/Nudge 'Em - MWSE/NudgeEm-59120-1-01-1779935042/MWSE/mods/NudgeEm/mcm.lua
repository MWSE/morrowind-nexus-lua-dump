--[[
	Nudge 'Em
	mcm.lua

	Mod Config Menu setup.

	This file creates the MCM page, sliders, toggles, dropdowns, and keybinds used to configure Nudge 'Em in-game.
]]

local config = require("NudgeEm.config")

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = config.modName,
	})

	template:saveOnClose(config.configPath, config.current)

	local page = template:createSideBarPage({
		label = "Settings",
		description = [[
		Nudge 'Em
		
		A small MWSE mod that lets you nudge NPCs and creatures out of the way. Doesn't put you in combat.]],
	})

	page:createYesNoButton({
		label = "Enable Nudge 'Em",
		description = "Allows you to nudge the NPC or creature under your cursor.",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config.current,
		}),
	})

	page:createKeyBinder({
		label = "Nudge Key",
		description = "Press this key to nudge the NPC or creature under your cursor.",
		allowCombinations = false,
		variable = mwse.mcm.createTableVariable({
			id = "keyCombo",
			table = config.current,
		}),
	})

	page:createSlider({
		label = "Nudge Distance",
		description = "How far to move the targeted NPC or creature. Default: 128.",
		min = 16,
		max = 512,
		step = 1,
		jump = 32,
		decimalPlaces = 0,
		variable = mwse.mcm.createTableVariable({
			id = "nudgeDistance",
			table = config.current,
		}),
	})

	page:createSlider({
		label = "Nudge Range",
		description = "How close you must be to nudge an NPC or creature. Default: 100.",
		min = 64,
		max = 1024,
		step = 1,
		jump = 32,
		decimalPlaces = 0,
		variable = mwse.mcm.createTableVariable({
			id = "nudgeRange",
			table = config.current,
		}),
	})

	page:createYesNoButton({
		label = "Instant Nudge",
		description = "Skips the casting animation and nudges the target instantly. Default: No",
		variable = mwse.mcm.createTableVariable({
			id = "instantNudge",
			table = config.current,
		}),
	})

	page:createDropdown({
		label = "NPC Reaction Voice",
		description = "Voice line played when an NPC is nudged. Default: Flee.",
		options = {
			{ label = "None", value = -1 }, -- -1
			{ label = "Random", value = -2 }, -- -2
			{ label = "Hello", value = 0 }, -- 0
			{ label = "Idle", value = 1 }, -- 1
			{ label = "Intruder", value = 2 }, -- 2
			{ label = "Thief", value = 3 }, -- 3
			{ label = "Hit", value = 4 }, -- 4
			{ label = "Attack", value = 5 }, -- 5
			{ label = "Flee", value = 6 }, -- 6
		},
		variable = mwse.mcm.createTableVariable({
			id = "reactionVoice",
			table = config.current,
		}),
	})

	page:createDropdown({
		label = "Creature Reaction Sound",
		description = "Creature sound played when a creature is nudged. Default: Moan.",
		options = {
			{ label = "None", value = -1 }, -- -1
			{ label = "Random", value = -2 }, -- -2
			{ label = "Moan", value = 0 }, -- 0
			{ label = "Roar", value = 1 }, -- 1
			{ label = "Scream", value = 2 }, -- 2
		},
		variable = mwse.mcm.createTableVariable({
			id = "creatureReactionSound",
			table = config.current,
		}),
	})

	page:createYesNoButton({
		label = "Play NPC Hit Animation",
		description = "Plays a random valid hit animation when an NPC is nudged. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "playNpcReactionAnimation",
			table = config.current,
		}),
	})

	page:createYesNoButton({
		label = "Play Creature Hit Animation",
		description = "Plays a random valid hit animation when a creature is nudged. Default: Yes",
		variable = mwse.mcm.createTableVariable({
			id = "playCreatureReactionAnimation",
			table = config.current,
		}),
	})

	page:createYesNoButton({
		label = "Show Messages",
		description = "Shows a small message when you nudge something. Default: No",
		variable = mwse.mcm.createTableVariable({
			id = "showMessages",
			table = config.current,
		}),
	})

	page:createYesNoButton({
		label = "Debug Logging",
		description = "Writes extra information to MWSE.log. Default: No",
		variable = mwse.mcm.createTableVariable({
			id = "debugLog",
			table = config.current,
		}),
	})

	mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)