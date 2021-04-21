local config = require("TES6Stats.config")

local template = mwse.mcm.createTemplate("TES6Stats")
template:saveOnClose("TES6Stats", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"TES 6 Stats \n\n " ..
		"Equalizes health, magicka, and fatigue. \n\n " ..
		"WARNING this will make changes to your character that can't be reverted\n\n " ..
		"Back up your saves before enabling\n\n "
	)
page.noScroll = false

local category = page:createCategory("Settings")

	category:createOnOffButton({
	label = "Enable/Disable Mod",
	description = "WARNING this will make changes to your character that can't be reverted",
	variable = mwse.mcm:createTableVariable{id = "enabled", table = config},
})

mwse.mcm.register(template)