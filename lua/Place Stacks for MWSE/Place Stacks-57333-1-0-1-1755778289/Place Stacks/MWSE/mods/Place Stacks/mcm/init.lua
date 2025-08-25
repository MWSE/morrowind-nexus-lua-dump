local config = require("Place Stacks.config")
local log = mwse.Logger.new()

local i18n = mwse.loadTranslations("Place Stacks")

local authors = {
	{
		name = "C3pa",
		url = "https://next.nexusmods.com/profile/C3pa/mods",
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

local function getActivateKeyName()
	local map = tes3.worldController.inputController.inputMaps
	local code = map[tes3.keybind.activate + 1].code
	return mwse.mcm.getKeyComboName({ keyCode = code })
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = i18n("Place Stacks"),
		headerImagePath = "MWSE/mods/Place Stacks/mcm/Header.tga",
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

	page:createOnOffButton({
		label = i18n("mcm.buttonEnabled.label"),
		description = i18n("mcm.buttonEnabled.description"),
		leftSide = false,
		configKey = "buttonEnabled"
	})

	page:createYesNoButton({
		label = i18n("mcm.transferGold.label"),
		description = i18n("mcm.transferGold.description"),
		leftSide = false,
		configKey = "transferGold"
	})

	page:createYesNoButton({
		label = i18n("mcm.closeMenu.label"),
		description = i18n("mcm.closeMenu.description"),
		leftSide = false,
		configKey = "closeMenu"
	})

	page:createYesNoButton({
		label = i18n("mcm.filterOwned.label"),
		leftSide = false,
		configKey = "filterOwned"
	})

	local activate = page:createCategory({ label = i18n("mcm.Activate Key") })
	activate:createOnOffButton({
		label = i18n("mcm.activateEnabled.label"),
		description = string.format(i18n("mcm.activateEnabled.description"), getActivateKeyName()),
		leftSide = false,
		configKey = "activateEnabled",
	})

	activate:createSlider({
		label = i18n("mcm.activateDelay.label"),
		description = i18n("mcm.activateDelay.description"),
		min = 0.1,
		max = 2.0,
		decimalPlaces = 3,
		configKey = "activateDelay",
		convertToLabelValue = function(self, seconds)
			return seconds * 1000
		end
	})

	local keybind = page:createCategory({ label = i18n("mcm.Custom Keybind") })
	keybind:createKeyBinder({
		label = i18n("mcm.keybind.label"),
		description = i18n("mcm.keybind.description"),
		configKey = "keybind",
	})

	keybind:createOnOffButton({
		label = i18n("mcm.placeStacksOutOfMenu.label"),
		description = i18n("mcm.placeStacksOutOfMenu.description"),
		leftSide = false,
		configKey = "placeStacksOutOfMenu"
	})

	keybind:createSlider({
		label = i18n("mcm.distanceMax.label"),
		description = i18n("mcm.distanceMax.description"),
		configKey = "distanceMax",
		min = 128,
		max = 512,
		decimalPlaces = 1,
		convertToLabelValue = function(self, variableValue)
			local feet = variableValue / 22.1
			local meters = 0.3048 * feet
			if self.decimalPlaces == 0 then
				return string.format("%i ft (%.2f m)", feet, meters)
			end
			return string.format(
				-- if `decimalPlaces == 1, then this string will simplify to
				-- "%.1f ft (%.3f m)"
				string.format("%%.%uf ft (%%.%uf m)", self.decimalPlaces, self.decimalPlaces + 2),
				feet, meters
			)
		end
	})

	keybind:createYesNoButton({
		label = i18n("mcm.shortTransferReport.label"),
		description = i18n("mcm.shortTransferReport.description"),
		leftSide = false,
		configKey = "shortTransferReport"
	})

	keybind:createYesNoButton({
		label = i18n("mcm.detailedTransferReport.label"),
		description = i18n("mcm.detailedTransferReport.description"),
		leftSide = false,
		configKey = "detailedTransferReport"
	})

	page:createLogLevelOptions({
		configKey = "logLevel"
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
