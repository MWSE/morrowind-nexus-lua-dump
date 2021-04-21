local config = require("Huntress Companion.config")

local template = mwse.mcm.createTemplate("Huntress Companion")
template:saveOnClose("Huntress Companion", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description = ("Huntress Companion")
page.noScroll = false

local category = page:createCategory("Settings")

	category:createOnOffButton({
	label = "Disable plants on harvest",
	description = "Plants will re-appear on cell change",
	variable = mwse.mcm:createTableVariable{id = "harvestDisable", table = config},
})


mwse.mcm.register(template)