local seph = require("seph")

local mcm = seph.Mcm:new()

function mcm:onCreate()
	local config = self.mod.config

	local function createSideBarPage(label)
		return self.template:createSideBarPage{
			label = label,
			description = "Hover over a setting for more information."
		}
	end

	local settingsPage = createSideBarPage("Settings")

	settingsPage:createSlider{
		label = "Blessing chance: %s%%",
		description = string.format("This sets the chance to receive a daily blessing instead of a curse. Setting this to 100%% will deactivate curses, whereas setting it to 0%% will deactivate blessings.\n\nDefault: %d", config.default.blessingChance),
		min = 0, max = 100, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "blessingChance", table = config.current, restartRequired = false}
	}
end

return mcm