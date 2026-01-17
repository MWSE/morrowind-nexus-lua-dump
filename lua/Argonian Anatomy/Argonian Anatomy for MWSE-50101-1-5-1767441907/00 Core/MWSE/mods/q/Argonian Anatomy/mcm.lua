local config = require("q.Argonian Anatomy.config")
local log = mwse.Logger.new()

local authors = {
	{
		name = "Made by Qwerty",
		url = "https://www.nexusmods.com/profile/qwertyquit/mods",
	},
	{
		name = "Programming by C3pa",
		url = "https://www.nexusmods.com/profile/C3pa/mods"
	},
	{
		name = "Help with animations from EJ-12",
		url = "https://www.nexusmods.com/profile/HedgeHog12/mods"
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
		text = "\nWelcome to Argonian Anatomy!",
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
		name = "Argonian Anatomy",
		headerImagePath = "MWSE/mods/q/Argonian Anatomy/Title.tga",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	local settingsPage = template:createSideBarPage({
		label = "Preferences",
		noScroll = true,
		showReset = true
	})
	createSidebar(settingsPage)

	settingsPage:createCategory({ label = "Which races should have the new skeleton?" })

	settingsPage:createOnOffButton({
		label = "The Argonians",
		description = "This will enable new skeleton for all members of the Argonian race.",
		leftSide = false,
		configKey = "argonian",
		restartRequired = true
	})

	settingsPage:createOnOffButton({
		label = "The Naga Breed",
		description = "This will enable new skeleton for all members of the Naga Breed mod.",
		leftSide = false,
		configKey = "godzilla",
		restartRequired = true
	})

	settingsPage:createOnOffButton({
		label = "The Shadowscales",
		description = "This will enable new skeleton for the Shadowscales mod.",
		leftSide = false,
		configKey = "shadowscale",
		restartRequired = true
	})

	settingsPage:createLogLevelOptions({
		configKey = "logLevel"
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
