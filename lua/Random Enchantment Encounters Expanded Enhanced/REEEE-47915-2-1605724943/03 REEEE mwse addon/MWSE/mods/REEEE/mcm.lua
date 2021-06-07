local config = require("REEEE.config")

local template = mwse.mcm.createTemplate("REEEE")
template:saveOnClose("REEEE", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"REEEE\n\n " ..
		"Random Enchantment Encounters Expanded Enhanced.\n\n" ..
		"Requires REEEE.esp\n\n" ..
		"REEEE is a plugin that adds new enchanted items to leveled lists.\n" ..
		"REEEE.esp itself does not require MWSE to be used, this MWSE addon is optional.\n\n" ..
		"This addon module will add by chance a random scroll, ring, amulet, belt, or soul gem to NPCs\n" ..
		"This chance happens every time a NPC is loaded, so best to set a low chance for game balance.\n" ..
		"NPCs with slave bracers are ignored. Dead NPCs are NOT ignored.\n" ..
		"With any luck you may find a goody by defeating a bandit, finding a corpse, or pick-pocketing someone."
	)
page.noScroll = false

local category = page:createCategory("Settings")

	category:createSlider({
	label = "Percent chance",
	description = "Option for a chance to dynamically add a random enchanted item to NPCs.\n\n" .. "Default setting 1",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "itemChance", table = config },
})


mwse.mcm.register(template)