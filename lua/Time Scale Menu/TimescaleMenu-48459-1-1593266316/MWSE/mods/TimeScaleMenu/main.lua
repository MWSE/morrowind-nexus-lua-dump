local function registerModConfig()
	local template = mwse.mcm.createTemplate("TimescaleMenu")
	local page = template:createSideBarPage()
	page.label = "Settings"
	page.description =
	(
		"Default timescale is 30. Timescale is saved in each save game."
	)
	page.noScroll = false
	local category = page:createCategory("Time Scale Menu")
		category:createSlider({
		label = "TimeScale",
		description = "The ratio of real time to game time",
		min = 1,
		max = 360,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createGlobal{id = "Timescale" },
	})
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)