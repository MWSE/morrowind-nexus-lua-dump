local log = require("logging.logger").getLogger("Command Menu") --[[@as mwseLogger]]

local configlib = require("Command Menu.config")


local i18n = mwse.loadTranslations("Command Menu")
local mcmConfig = configlib.getConfig()

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
		config = mcmConfig,
		defaultConfig = configlib.default,
		headerImagePath = "MWSE/mods/Command Menu/mcm/Header.tga",
		onClose = function()
			configlib.saveConfig(mcmConfig)
		end,
		showDefaultSetting = true,
	})
	template:register()

	do -- General
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
	end
end

event.register(tes3.event.modConfigReady, registerModConfig)
