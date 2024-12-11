local config = require("Huntress Companion.config")

local template = mwse.mcm.createTemplate("Friends and Frens")
template:saveOnClose("Huntress Companion", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description = ("Friends and Frens - Huntress Companion addon by Stripes")
page.noScroll = false

local category = page:createCategory("Settings")

	category:createOnOffButton({
	label = "Disable plants on harvest",
	description = "Plants will re-appear on cell change",
	variable = mwse.mcm:createTableVariable{id = "harvestDisable", table = config},
})


mwse.mcm.register(template)