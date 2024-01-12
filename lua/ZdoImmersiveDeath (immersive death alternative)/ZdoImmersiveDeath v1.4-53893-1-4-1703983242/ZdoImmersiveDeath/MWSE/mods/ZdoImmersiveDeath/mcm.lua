local config = require("ZdoImmersiveDeath.config")

local template = mwse.mcm.createTemplate("ZdoImmersiveDeath")
template:saveOnClose("ZdoImmersiveDeath", config)

local page = template:createSideBarPage()
page.label = "General Settings"
page.description = "ZdoImmersiveDeath," .. config.version .. "\nby zdo"
page.noScroll = false

local category = page

local enableButton = category:createYesNoButton()
enableButton.label = "Enable"
enableButton.description = "Toggle to turn this mod on and off."
enableButton.variable = mwse.mcm:createTableVariable{id = "enable", table = config}

category:createYesNoButton({
	label = "Confirmation",
	description = "Asks if you want to accept the teleport before proceeding.",
	variable = mwse.mcm:createTableVariable{id = "confirmation", table = config}
})

category:createYesNoButton({
	label = "Save before death",
	description = "Should create a new save just before teleporting.",
	variable = mwse.mcm:createTableVariable{id = "saveBeforeDeath", table = config}
})

category:createYesNoButton({
	label = "Death Animation",
	description = "Mimics the vanilla death behavior before teleporting.",
	variable = mwse.mcm:createTableVariable{id = "deathAnimation", table = config}
})

category:createSlider({
	label = "Recovery Time (hours)",
	description = "How many hours you wake up after being left for dead. Higher numbers incur a longer wait on the fadeout, to advance the time.",
	min = 1,
	max = 24,
	variable = mwse.mcm:createTableVariable{id = "recoveryTime", table = config}
})

category:createSlider({
	label = "Probability of dropping an item",
	description = "Probability of dropping an item",
	min = 0,
	max = 100,
	variable = mwse.mcm:createTableVariable{id = "itemDropProbability", table = config}
})

category:createSlider({
	label = "Probability of worsening item's condition",
	description = "Probability of worsening item's condition to zero",
	min = 0,
	max = 100,
	variable = mwse.mcm:createTableVariable{id = "itemWorsenConditionProbability", table = config}
})

category:createYesNoButton({
	label = "Report lost items",
	description = "Add info to journal with the list of dropped and broken items",
	variable = mwse.mcm:createTableVariable{id = "reportLostItems", table = config}
})

category:createSlider({
	label = "Invisibility duration (sec)",
	description = "Effect to apply after teleporting so you can actually escape the danger. 0 to disable",
	min = 0,
	max = 100,
	variable = mwse.mcm:createTableVariable{id = "invisibilityDuration", table = config}
})

category:createSlider({
	label = "Chameleon duration (sec)",
	description = "Effect to apply after teleporting so you can actually escape the danger. 0 to disable",
	min = 0,
	max = 100,
	variable = mwse.mcm:createTableVariable{id = "chameleonDuration", table = config}
})

category:createSlider({
	label = "Chameleon magnitude",
	description = "Quality of the chameleon effect after teleporting",
	min = 1,
	max = 100,
	variable = mwse.mcm:createTableVariable{id = "chameleonMagnitude", table = config}
})

mwse.mcm.register(template)