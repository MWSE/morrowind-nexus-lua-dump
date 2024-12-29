local configlib = require("Candle Smoke.config")
local log = require("logging.logger").getLogger("Candle Smoke") --[[@as mwseLogger]]


local i18n = mwse.loadTranslations("Candle Smoke")
local mcmConfig = configlib.getConfig()

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
		onClose = function()
			configlib.saveConfig(mcmConfig)
		end,
		config = mcmConfig,
		defaultConfig = configlib.default,
		showDefaultSetting = true,
	})
	template:register()

	local page = template:createSideBarPage({
		label = i18n("mcm.settings"),
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	page:createDropdown({
		label = i18n("mcm.smokeIntensity.label"),
		description = i18n("mcm.smokeIntensity.description"),
		options = {
			{ label = i18n("mcm.smokeIntensity.Very faint"), value = 30 },
			{ label = i18n("mcm.smokeIntensity.Faint"), value = 45 },
			{ label = i18n("mcm.smokeIntensity.Medium"), value = 60 },
			{ label = i18n("mcm.smokeIntensity.Dense"), value = 90 },
		},
		configKey = "smokeIntensity",
	})

	page:createYesNoButton({
		label = i18n("mcm.disableCarriable.label"),
		description = i18n("mcm.disableCarriable.description"),
		configKey = "disableCarriable",
	})

	page:createDropdown({
		label = i18n("mcm.logLevel.label"),
		description = i18n("mcm.logLevel.description"),
		options = {
			{ label = "Trace", value = "TRACE" },
			{ label = "Debug", value = "DEBUG" },
			{ label = "Info",  value = "INFO" },
			{ label = "Warn",  value = "WARN" },
			{ label = "Error", value = "ERROR" },
			{ label = "None",  value = "NONE" },
		},
		configKey = "logLevel",
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
