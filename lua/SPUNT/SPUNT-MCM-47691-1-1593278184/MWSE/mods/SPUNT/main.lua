local function registerModConfig()
	local template = mwse.mcm.createTemplate("SPUNT")
	local page = template:createSideBarPage()
	page.label = "Settings"
	page.description =
	(
		"Sleep Prevents UNwanted Tiredness"
	)
	page.noScroll = false
	local category = page:createCategory("SPUNT")
		category:createSlider({
		label = "Regeneration Rate",
		description = "The larger the number the slower the Regeneration",
		min = 1,
		max = 60,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createGlobal{id = "SPUNT_DELAY" },
	})

		category:createSlider({
		label = "Sleep Needed",
		description = "The number of hours slept per day required",
		min = 1,
		max = 12,
		step = 1,
		jump = 3,
		variable = mwse.mcm.createGlobal{id = "SPUNT_sleep" },
	})
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)