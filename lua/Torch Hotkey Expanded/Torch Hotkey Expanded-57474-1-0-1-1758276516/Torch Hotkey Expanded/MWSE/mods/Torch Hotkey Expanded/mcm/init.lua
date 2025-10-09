local config = require("Torch Hotkey Expanded.config")
local log = mwse.Logger.new()

local i18n = mwse.loadTranslations("Torch Hotkey Expanded")


local originalCredits = {
	{
		text = i18n("mcm.Torch Hotkey by Remiros"),
		url = "https://next.nexusmods.com/profile/Remiros",
	},
	{
		text = i18n("mcm.Scripting help from Greatness7"),
		url = "https://next.nexusmods.com/profile/Greatness7",
	},
	{
		text = i18n("mcm.Scripting help from NullCascade"),
		url = "https://next.nexusmods.com/profile/NullCascade",
	},
	{
		text = i18n("mcm.Users of Torch Hotkey for providing feedback"),
		url = "https://www.nexusmods.com/morrowind/mods/45747?tab=posts"
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
	local madeBy = container.sidebar:createCategory({ label = i18n("mcm.Made by") })
	madeBy:createHyperlink({
		text = "C3pa",
		url = "https://next.nexusmods.com/profile/C3pa/mods",
	})
	local originalCreditsCategory = container.sidebar:createCategory({
		label = i18n("mcm.Credits from original Torch Hotkey:")
	})
	for _, author in ipairs(originalCredits) do
		originalCreditsCategory:createHyperlink({
			text = author.text,
			url = author.url,
		})
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = i18n("Torch Hotkey Extended"),
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	local page = template:createSideBarPage({
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	page:createKeyBinder({
		label = i18n("mcm.hotkey.label"),
		description = i18n("mcm.hotkey.description"),
		configKey = "hotkey",
		allowMouse = true,
		leftSide = false,
	})
	page:createLogLevelOptions({
		configKey = "configKey"
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
