--- Setup MCM.
local function registerModConfig()
	local config = require("rfuzzo.CompareTooltip.config")
	local template = mwse.mcm.createTemplate(config.mod)
	template:saveOnClose(config.file, config)
	template:register()

	local page = template:createSideBarPage({ label = "Settings" })
	page.sidebar:createInfo{ text = ("%s v%.1f\n\nBy %s"):format(config.mod, config.version, config.author) }

	local settingsPage = page:createCategory("Settings")
	local generalCategory = settingsPage:createCategory("General")

	generalCategory:createOnOffButton({
		label = "Enable Mod",
		description = "Enable the mod.",
		variable = mwse.mcm.createTableVariable { id = "enableMod", table = config },
	})

	generalCategory:createOnOffButton({
		label = "Only display comparion on key press",
		description = "Only display comparion on key press (default: alt).",
		variable = mwse.mcm.createTableVariable { id = "useKey", table = config },
	})

	-- Key binding: show comparison
	generalCategory:createKeyBinder({
		label = "Keybind to show comparison.",
		description = "This key combination will show the comparison",
		allowCombinations = true,
		variable = mwse.mcm.createTableVariable({ id = "comparisonKey", table = config }),
	})

	local styleCategory = page:createCategory("Style")

	-- settings:createOnOffButton({
	-- 	label = "Use Inline Tooltips",
	-- 	description = "Use inline tooltips instead of a full compare popup.",
	-- 	variable = mwse.mcm.createTableVariable { id = "useInlineTooltips", table = config },
	-- })

	styleCategory:createOnOffButton({
		label = "Display colored comparisons",
		description = "Use colored comparisons.",
		variable = mwse.mcm.createTableVariable { id = "useColors", table = config },
	})

	styleCategory:createOnOffButton({
		label = "Display parentheses",
		description = "Display parenthese in comparisons",
		variable = mwse.mcm.createTableVariable { id = "useParens", table = config },
	})

	styleCategory:createOnOffButton({
		label = "Display arrows",
		description = "Display arrows in comparisons.",
		variable = mwse.mcm.createTableVariable { id = "useArrows", table = config },
	})

end

event.register("modConfigReady", registerModConfig)
