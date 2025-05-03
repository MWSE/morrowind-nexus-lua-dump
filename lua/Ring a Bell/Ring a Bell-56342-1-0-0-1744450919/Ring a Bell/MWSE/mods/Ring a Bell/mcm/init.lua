local config = require("Ring a Bell.config")
local log = require("logging.logger").getLogger("Ring a Bell") --[[@as mwseLogger]]


local i18n = mwse.loadTranslations("Ring a Bell")

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
		name = i18n("Ring a Bell"),
		headerImagePath = "MWSE/mods/Ring a bell/mcm/Header.tga",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()

	local page = template:createSideBarPage({
		label = i18n("mcm.settings"),
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	page:createSlider({
		label = i18n("mcm.semitones.label"),
		description = i18n("mcm.semitones.description"),
		min = 0,
		max = 12,
		step = 1,
		jump = 1,
		configKey = "semitones",
	})

	-- page:createDropdown({
	-- 	label = i18n("mcm.logLevel.label"),
	-- 	description = i18n("mcm.logLevel.description"),
	-- 	options = {
	-- 		{ label = "Trace", value = "TRACE" },
	-- 		{ label = "Debug", value = "DEBUG" },
	-- 		{ label = "Info",  value = "INFO" },
	-- 		{ label = "Warn",  value = "WARN" },
	-- 		{ label = "Error", value = "ERROR" },
	-- 		{ label = "None",  value = "NONE" },
	-- 	},
	-- 	configKey = "logLevel",
	-- 	callback = function(self)
	-- 		log:setLogLevel(self.variable.value)
	-- 	end
	-- })
end

event.register(tes3.event.modConfigReady, registerModConfig)
