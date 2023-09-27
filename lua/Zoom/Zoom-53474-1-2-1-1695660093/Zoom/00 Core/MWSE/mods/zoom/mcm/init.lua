local config = require("zoom.config")
local log = require("logging.logger").getLogger("zoom") --[[@as mwseLogger]]
local defaultDrawDistance = require("zoom.util").distantConfig.default.drawDistance

local i18n = mwse.loadTranslations("zoom")
local mcmConfig = config.getConfig()



--- Creates some empty horizontal space.
local function newline(container)
	container:createInfo({ text = "\n" })
end

local function center(self)
	self.elements.info.layoutOriginFractionX = 0.5
end

--- Returns the localized description for given setting. It should be available as "mcm.settingName.description" table.
---@param settingName string
---@param defaultValue any The default value to append to description string.
---@return string
local function getDescription(settingName, defaultValue)
	local default = ""
	if defaultValue then
		default = ("\n\n%s: %s."):format(
			i18n("mcm.default"),
			defaultValue
		)
	end
	return ("\n%s%s"):format(
		i18n("mcm." .. settingName .. ".description"),
		default
	)
end

local authors = {{
	name = "C3pa",
	url = "https://www.nexusmods.com/morrowind/users/37172285?tab=user+files",
}}

local function createSidebar(container)
	container.sidebar:createInfo({
		text = i18n("mcm.sidebar"),
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperLink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Zoom",
		headerImagePath = "MWSE/mods/zoom/mcm/Header.tga",
		onClose = function()
			config.saveConfig(mcmConfig)
		end
	})
	template:register()


	local page = template:createSideBarPage({ label = i18n("mcm.settings") })
	createSidebar(page)

	newline(page)
	page:createDropdown({
		label = i18n("mcm.zoomType.label"),
		description = getDescription("zoomType", i18n("mcm.zoomType.options.hold")),
		options = {
			{ label = i18n("mcm.zoomType.options.press"),  value = "press" },
			{ label = i18n("mcm.zoomType.options.hold"),   value = "hold" },
			{ label = i18n("mcm.zoomType.options.scroll"), value = "scroll" },
		},
		variable = mwse.mcm.createTableVariable({
			id = "zoomType",
			table = mcmConfig,
			restartRequired = true,
		}),
	})

	newline(page)
	page:createKeyBinder({
		label = i18n("mcm.zoomKey.label"),
		description = getDescription("zoomKey", "I"),
		allowCombinations = true,
		allowMouse = true,
		variable = mwse.mcm.createTableVariable({
			id = "zoomKey",
			table = mcmConfig,
		}),
	})

	newline(page)
	page:createDecimalSlider({
		label = i18n("mcm.maxZoom.label"),
		description = getDescription("maxZoom", config.default.maxZoom),
		min = 1.10,
		max = 5.00,
		step = 0.5,
		jump = 1.00,
		decimalPlaces = 2,
		variable = mwse.mcm.createTableVariable({ id = "maxZoom", table = mcmConfig }),
	})

	newline(page)
	page:createDecimalSlider({
		label = i18n("mcm.zoomStrength.label"),
		description = getDescription("zoomStrength", config.default.zoomStrength),
		min = 0.01,
		max = 0.20,
		step = 0.01,
		jump = 0.05,
		decimalPlaces = 2,
		variable = mwse.mcm.createTableVariable({ id = "zoomStrength", table = mcmConfig }),
	})

	newline(page)
	page:createOnOffButton({
		label = i18n("mcm.faderOn.label"),
		description = i18n("mcm.faderOn.description"),
		variable = mwse.mcm.createTableVariable({ id = "faderOn", table = mcmConfig }),
	})

	newline(page)
	page:createOnOffButton({
		label = i18n("mcm.changeDrawDistance.label"),
		description = i18n("mcm.changeDrawDistance.description"),
		variable = mwse.mcm.createTableVariable({ id = "changeDrawDistance", table = mcmConfig })
	})

	newline(page)
	page:createSlider({
		label = i18n("mcm.maxDrawDistance.label"),
		description = i18n("mcm.maxDrawDistance.description"),
		variable = mwse.mcm.createTableVariable({ id = "maxDrawDistance", table = mcmConfig }),
		min = defaultDrawDistance,
		max = 40,
	})

	newline(page)
	page:createDropdown({
		label = i18n("mcm.logLevel.label"),
		description = getDescription("logLevel"),
		options = {
			{ label = "Trace", value = "TRACE" },
			{ label = "Debug", value = "DEBUG" },
			{ label = "Info",  value = "INFO" },
			{ label = "Warn",  value = "WARN" },
			{ label = "Error", value = "ERROR" },
			{ label = "None",  value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable({ id = "logLevel", table = mcmConfig }),
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
