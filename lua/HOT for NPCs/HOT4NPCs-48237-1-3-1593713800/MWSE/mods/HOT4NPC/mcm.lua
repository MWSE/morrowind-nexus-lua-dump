local config = require("HOT4NPC.config")

local template = mwse.mcm.createTemplate("HOT4NPC")
template:saveOnClose("HOT4NPC", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description = 
	(
		"HOT for NPCs: Heal Over Time for all NPCs and creatures. "
	)
page.noScroll = false

local category = page:createCategory("Settings")

	category:createSlider({
	label = "Neutral Actor Heal Delay",
	description = "Time in seconds between regeneration of heal amount.",
	min = 1,
	max = 300,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "hotNeutralRate", table = config },
})


	category:createSlider({
	label = "Neutral Actor Heal Amount",
	description = "Amount of health regenerated.",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "hotNeutralHeal", table = config },
})

	category:createSlider({
	label = "Friendly Actor Heal Delay",
	description = "Time in seconds between regeneration of heal amount.",
	min = 1,
	max = 300,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "hotCompanionRate", table = config },
})

	category:createSlider({
	label = "Friendly Actor Heal Amount",
	description = "Amount of health regenerated.",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "hotCompanionHeal", table = config },
})

	category:createSlider({
	label = "Hostile Actor Heal Delay",
	description = "Time in seconds between regeneration of heal amount.",
	min = 1,
	max = 300,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "hotHostileRate", table = config },
})

	category:createSlider({
	label = "Hostile Actor Heal Amount",
	description = "Amount of health regenerated.",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "hotHostileHeal", table = config },
})


mwse.mcm.register(template)