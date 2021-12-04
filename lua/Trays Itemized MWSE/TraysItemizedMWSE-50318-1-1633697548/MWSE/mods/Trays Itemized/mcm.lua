local config = require("Trays Itemized.config")

local template = mwse.mcm.createTemplate("Trays Itemized")
template:saveOnClose("Trays Itemized", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description =
	(
		"Trays Itemized "
	)
page.noScroll = false

local category = page:createCategory("Settings")
category:createOnOffButton({
	label = "Uninstall Mode",
	description = "Enables disabled statics",
	variable = mwse.mcm:createTableVariable{id = "uninstall", table = config},
})


mwse.mcm.register(template)