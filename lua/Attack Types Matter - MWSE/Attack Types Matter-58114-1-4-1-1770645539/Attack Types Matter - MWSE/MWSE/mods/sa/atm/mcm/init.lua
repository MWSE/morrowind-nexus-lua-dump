local config = require("sa.atm.config")
local log = mwse.Logger.new()

local authors = {
	{
		name = "Storm Atronach",
		url = "https://www.nexusmods.com/profile/StormAtronach0",
	},
	{
		name = "Varlothen",
		url = "https://www.nexusmods.com/profile/varlothen",
	},
	{
		name = "Joeyjoejoeshabidoo",
		url = "",
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
		text = "\nAttack Types Matter Configuration\n\nAttack Types Matter overhauls Morrowind's combat by making weapon attack types and enemy resistances meaningful." ..  
		"Creatures and constructs now have unique vulnerabilities and resistances to slashing, piercing, and bludgeoning damage. " ..
		"Your weapon's attack type and material will affect your effectiveness against different creatures." ..
		"Optional feedback features include on-screen effectiveness messages and a crosshair color effect to indicate when your attacks are especially effective or ineffective.\n\n" .. 
		"Made by:",
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
		name = "Attack Types Matter",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	local page = template:createSideBarPage({
		label = "Settings",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	page:createOnOffButton{
		label = "Mod enabled?",
		configKey = "enabled"
	}

	page:createOnOffButton{
		label = "Crosshair effect",
		configKey = "crosshair",
		description = "This controls whether the red and blue 'X' additions to the crosshair are displayed or not."
	}

	page:createOnOffButton{
		label = "Effectiveness messages",
		configKey = "messages",
		description = "This would make popup messages display when the attack is effective or not. Since this was a little repetitive, it is disabled by default"
	}


	page:createLogLevelOptions({
		configKey = "logLevel",
	})
end

event.register(tes3.event.modConfigReady, registerModConfig)
