local config = require("Click to Draw.config")
local log = mwse.Logger.new()

local i18n = mwse.loadTranslations("Click to Draw")

local authors = {
	{
		name = "C3pa",
		url = "https://next.nexusmods.com/profile/C3pa/mods",
	},
}


--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

--- Adds default text to sidebar. Has a list of all the authors that contributed to the mod.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text = i18n("mcm.sidebar"),
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperlink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = i18n("Click to Draw"),
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	local page = template:createSideBarPage({
		label = i18n("mcm.settings"),
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	page:createMouseBinder({
		label = i18n("mcm.draw.label"),
		description = i18n("mcm.draw.description"),
		leftSide = false,
		allowCombinations = false,
		configKey = "draw"
	})

	page:createMouseBinder({
		label = i18n("mcm.sheath.label"),
		description = i18n("mcm.sheath.description"),
		leftSide = false,
		allowCombinations = false,
		configKey = "sheath"
	})

	page:createMouseBinder({
		label = i18n("mcm.raiseHands.label"),
		description = i18n("mcm.raiseHands.description"),
		leftSide = false,
		allowCombinations = false,
		configKey = "raiseHands"
	})

	-- Not needed yet
	-- page:createLogLevelOptions({
	-- 	configKey = "logLevel"
	-- })
end

event.register(tes3.event.modConfigReady, registerModConfig)
