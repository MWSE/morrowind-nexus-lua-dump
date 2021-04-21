local function registerModConfig()
	local template = mwse.mcm.createTemplate("HARM")
	local page = template:createSideBarPage()
	page.label = "Settings"
	page.description =
	(
		"Health Affects Recovering Magicka"
	)
	page.noScroll = false
	local category = page:createCategory("HARM")
		category:createSlider({
		label = "Regeneration Rate",
		description = "The larger the number the slower the Regeneration",
		min = 1,
		max = 60,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createGlobal{id = "HARM_delay" },
	})
	
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)