local config = require("Save Means Save.config")

local function registerModConfig()

	local template = mwse.mcm.createTemplate({ name = ("Save Means Save") })
	template:saveOnClose("Save Means Save", config)

	local page = template:createSideBarPage({ label = "Sidebar Page Label" })
	page.sidebar:createInfo({ text = ("Save Means Save") .. " " .. ("1.0.0") .. "\n" .. ("By None") .. "\n\n" .. ("Adds additional save and load functionality.") })

	page:createOnOffButton({
		label = ("Enable"),
		description = (""),
		variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
	})

	template:register()
end

event.register("modConfigReady", registerModConfig)