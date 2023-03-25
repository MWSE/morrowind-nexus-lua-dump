local config = require("Skillful Sneaking.config")

local function registerModConfig()

	local template = mwse.mcm.createTemplate({ name = ("Skillful Sneaking") })
	template:saveOnClose("Skillful Sneaking", config)

	local page = template:createSideBarPage({ label = "Sidebar Page Label" })
	page.sidebar:createInfo({ text = ("Skillful Sneaking") .. " " .. ("1.0") .. "\n" .. ("By None") .. "\n\n" .. ("Allows jumping while sneaking and scales movement speed with skill level.") })

	page:createOnOffButton({
		label = ("Enable"),
		description = (""),
		variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
	})

	template:register()
end

event.register("modConfigReady", registerModConfig)