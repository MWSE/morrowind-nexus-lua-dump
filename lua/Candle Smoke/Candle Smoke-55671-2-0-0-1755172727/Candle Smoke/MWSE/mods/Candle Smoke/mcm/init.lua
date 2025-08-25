local config = require("Candle Smoke.config")


local i18n = mwse.loadTranslations("Candle Smoke")
local log = mwse.Logger.new()

local authors = {
	{
		name = "C3pa",
		url = "https://www.nexusmods.com/morrowind/users/37172285?tab=user+files",
	}
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
		name = i18n("Candle Smoke"),
		headerImagePath = "MWSE/mods/Candle Smoke/mcm/Header.tga",
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

	page:createSlider({
		label = i18n("mcm.smokeIntensity.label"),
		description = i18n("mcm.smokeIntensity.description"),
		decimalPlaces = 2,
		min = 0.01,
		max = 1.0,
		step = 0.05,
		jump = 0.1,
		configKey = "intensity",
		callback = function(self)
			event.trigger("Candle Smoke: intensity updated")
		end
	})

	page:createYesNoButton({
		label = i18n("mcm.disableCarriable.label"),
		description = i18n("mcm.disableCarriable.description"),
		configKey = "disableCarriable",
	})

	page:createLogLevelOptions({
		configKey = "logLevel"
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
