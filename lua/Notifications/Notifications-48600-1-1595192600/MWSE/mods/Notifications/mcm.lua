local config = require("Notifications.config")

local template = mwse.mcm.createTemplate("Notifications")
template:saveOnClose("Notifications", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description = ("Messagebox Notifications ")
page.noScroll = false

local category = page:createCategory("Notification Settings")

	category:createOnOffButton({
	label = "Death Notifications",
	description = "Displays name of actor that has died.",
	variable = mwse.mcm:createTableVariable{id = "deathnote", table = config},
})

	category:createOnOffButton({
	label = "Crime Notifications",
	description = "Displays names of witnesses and type of crime.",
	variable = mwse.mcm:createTableVariable{id = "crimenote", table = config},
})

	category:createOnOffButton({
	label = "Fight Notifications",
	description = "Displays names of attacker and target.",
	variable = mwse.mcm:createTableVariable{id = "fightnote", table = config},
})

	category:createOnOffButton({
	label = "Cell Notifications",
	description = "Displays name of cell entered if different from previous cell.",
	variable = mwse.mcm:createTableVariable{id = "cellnote", table = config},
})

mwse.mcm.register(template)