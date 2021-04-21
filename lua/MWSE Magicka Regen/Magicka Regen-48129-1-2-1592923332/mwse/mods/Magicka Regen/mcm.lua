local config = require("Magicka Regen.config")

local template = mwse.mcm.createTemplate("Magicka Regen")
template:saveOnClose("Magicka Regen", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description = 
	(
		"MWSE Magicka Regen provides functional and configurable magicka regeneration " ..
		"both to players and NPCs within Morrowind. This mod works regardless of race " ..
		"or birthsign, and takes into consideration the effects of the Atronach sign. " ..
		"In addition, magicka gain is calculated based on time waited/passed. "
	)
page.noScroll = false

local category = page:createCategory("Settings")

local pcRegenButton = category:createOnOffButton({
	label = "Enable Player Magicka Regen",
	description = "Determines whether the player's magicka will regenerate over time based on their Intelligence and Willpower stats.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "pcRegen", table = config}
})

local npcRegenButton = category:createOnOffButton({
	label = "Enable NPC Magicka Regen",
	description = "Determines whether the magicka of NPCs will regenerate over time based on their Intelligence and Willpower stats.\n\nDefault: On",
	variable = mwse.mcm:createTableVariable{id = "npcRegen", table = config}
})

local vanillaButton = category:createOnOffButton({
	label = "Enable Vanilla Regen Formula",
	description = "Determines whether magicka regen is calculated based on the vanilla rest formula rather than the rebalanced, more stat-based default.\n\nDefault: Off",
	variable = mwse.mcm:createTableVariable{id = "vanillaRate", table = config}
})

local vanillaButton = category:createOnOffButton({
	label = "Enable Magicka Decay",
	description = "Determines whether magicka regen slows the closer a player's current magicka gets to the maximum.\n\nDefault: Off",
	variable = mwse.mcm:createTableVariable{id = "magickaDecay", table = config}
})

local pcRegenSlider = category:createSlider({
	label = "Player Magicka Regen Rate: %s%%",
	description = "Determines the rate at which the player's magicka will regenerate over time.\n\nDefault: 100%",
	min = 0,
	max = 200,
	step = 1,
	jump = 24,
	variable = mwse.mcm.createTableVariable{id = "pcRate", table = config },
})

local npcRegenSlider = category:createSlider({
	label = "NPC Magicka Regen Rate: %s%%",
	description = "Determines the rate at which the magicka of NPCs will regenerate over time.\n\nDefault: 100%",
	min = 0,
	max = 200,
	step = 1,
	jump = 24,
	variable = mwse.mcm.createTableVariable{id = "npcRate", table = config },
})

mwse.mcm.register(template)