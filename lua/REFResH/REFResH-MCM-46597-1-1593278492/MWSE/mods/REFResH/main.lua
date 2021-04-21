local function registerModConfig()
	local template = mwse.mcm.createTemplate("REFResH")
	local page = template:createSideBarPage()
	page.label = "Settings"
	page.description =
	(
		"Restoration Effect:Fatigue REStores Health"
	)
	page.noScroll = false
	local category = page:createCategory("REFResH")
		category:createSlider({
		label = "Regeneration Rate",
		description = "The larger the number the slower the Regeneration",
		min = 1,
		max = 60,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createGlobal{id = "REFRESH_SPEED" },
	})
	
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)