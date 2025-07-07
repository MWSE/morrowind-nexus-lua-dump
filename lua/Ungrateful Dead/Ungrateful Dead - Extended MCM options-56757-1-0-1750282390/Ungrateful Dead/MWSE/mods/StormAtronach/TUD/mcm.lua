local config = require("StormAtronach.TUD.config")

local authors = {
	{
		name = "StormAtronach",
		url = "https://next.nexusmods.com/profile/StormAtronach0",
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
		text = "When you summon an Ancestral Ghost, you are summoning... an ancestor, with all their personality and little quirks. A blessing or a curse? Well, all families have their own... interesting characters :)\n\nMade by:",
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
		name = "The Ungrateful Dead",
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
        label = "Enable Mod",
        description = "Toggle the ancestral wisdom mechanic on or off.",
        configKey = "enabled",
    }

    page:createSlider{
        label = "Wisdom Effect Duration (seconds)",
        description = "How long the ancestral wisdom effects last (default: 600 seconds = 10 minutes).",
        min = 10,
        max = 3600,
        step = 10,
        jump = 60,
        configKey = "duration"
    }
    
    page:createOnOffButton{
        label = "Enable Blessings",
        description = "Toggle the blessings mechanic on or off.",
        configKey = "blessingsEnabled",
    }

    page:createSlider{
        label = "Blessings Chance (%)",
        description = "Chance of a blessing being applied when an ancestral ghost is summoned (default: 100%).",
        min = 0,
        max = 100,
        step = 1,
        configKey = "blessingsChance"
    }
    page:createOnOffButton{
        label = "Enable Magnitude Variation",
        description = "Toggle the magnitude variation mechanic on or off.",
        configKey = "magnitudeVarEnabled",
    }
    page:createSlider{
        label = "Magnitude Variation (%)",
        description = "How much the magnitude of the blessing effects can vary (default: 0 = no variation).",
        min = 0,
        max = 100,
        step = 1,
        configKey = "magnitudeVar"
    }
    	page:createLogLevelOptions({
		configKey = "logLevel",
	})

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)