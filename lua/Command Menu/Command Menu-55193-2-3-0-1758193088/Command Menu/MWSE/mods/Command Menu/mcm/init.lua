local config = require("Command Menu.config")

local i18n = mwse.loadTranslations("Command Menu")
local log = mwse.Logger.new()

--- @param self mwseMCMComponent
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

local authors = {
	{
		name = "C3pa",
		url = "https://www.nexusmods.com/morrowind/users/37172285?tab=user+files",
	},
}

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
		name = i18n("Command Menu"),
		headerImagePath = "MWSE/mods/Command Menu/mcm/Header.tga",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	local general = template:createSideBarPage({
		label = i18n("General"),
		showReset = true,
		postCreate = function(self)
			self.sidebar.elements.subcomponentsContainer.paddingAllSides = 8
		end
	})
	createSidebar(general)

	general:createKeyBinder({
		label = i18n("mcm.openMenuKey.label"),
		description = i18n("mcm.openMenuKey.description"),
		configKey = "openMenuKey",
		allowMouse = true,
	})

	general:createKeyBinder({
		label = i18n("mcm.sampleLandscapeKey.label"),
		description = i18n("mcm.sampleLandscapeKey.description"),
		configKey = "sampleLandscapeKey",
		allowMouse = true,
	})

	general:createOnOffButton({
		label = i18n("mcm.filterOutDeprecated.label"),
		description = i18n("mcm.filterOutDeprecated.description"),
		configKey = "filterOutDeprecated",
		restartRequired = true,
	})

	general:createLogLevelOptions({
		configKey = "logLevel"
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
