local config = require("StormAtronach.SO.config")

local authors = {
	{
		name = "Storm Atronach",
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
		text = "\nWelcome to Stealth Overhaul!\n\nI will make a proper MCM soon(TM)! \n\nHover over a feature for more info.\n\nMade by:",
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
		name = "Stealth Overhaul",
		--headerImagePath = "MWSE/mods/template/mcm/Header.tga",
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

	page:createYesNoButton({
        label = "Enable Mod",
        description = "Enable or disable Stealth Overhaul.",
        configKey = "modEnabled",
    })

    page:createLogLevelOptions({
        configKey = "logLevel",
    })

    page:createSlider({
        label = "Detection Angle",
        description = "The angle at which the player can be detected by NPCs. 180 means they have perfect 360 vision.",
        min = 0,
        max = 180,
        step = 1,
        configKey = "detectionAngle",
    })

    page:createSlider({
        label = "Detection Cooldown (seconds)",
        description = "Cooldown for stolen item checks.",
        min = 1,
        max = 30,
        step = 1,
        configKey = "detectionCooldown",
    })

    page:createSlider({
        label = "Disposition Drop on Discovery",
        description = "How much disposition drops when discovered.",
        min = 0,
        max = 100,
        step = 1,
        configKey = "dispositionDropOnDiscovery",
    })

    page:createSlider({
        label = "Wander Range (Interior)",
        description = "How far NPCs wander when investigating (interior).",
        min = 100,
        max = 2000,
        step = 50,
        configKey = "wanderRangeInterior",
    })

    page:createSlider({
        label = "Wander Range (Exterior)",
        description = "How far NPCs wander when investigating (exterior).",
        min = 500,
        max = 5000,
        step = 100,
        configKey = "wanderRangeExterior",
    })

    page:createSlider({
        label = "Guard Cooldown Time (seconds)",
        description = "Cooldown before guards can detect you again.",
        min = 1,
        max = 30,
        step = 1,
        configKey = "guardCooldownTime",
    })

    page:createSlider({
        label = "Owner Cooldown Time (seconds)",
        description = "Cooldown before owners can detect you again.",
        min = 1,
        max = 30,
        step = 1,
        configKey = "ownerCooldownTime",
    })

    page:createSlider({
        label = "Sneak Skill Multiplier",
        description = "Multiplier for sneak skill in detection calculations.",
        min = 50,
        max = 200,
        step = 5,
        configKey = "sneakSkillMult",
    })

    page:createSlider({
        label = "Boot Multiplier",
        description = "Penalty for wearing heavier boots.",
        min = 0,
        max = 50,
        step = 1,
        configKey = "bootMultiplier",
    })

    page:createSlider({
        label = "Sneak Distance Base",
        description = "Base value for sneak distance calculations.",
        min = 0,
        max = 200,
        step = 1,
        configKey = "sneakDistanceBase",
    })

    page:createSlider({
        label = "Sneak Distance Multiplier",
        description = "Multiplier for sneak distance calculations.",
        min = 100,
        max = 2000,
        step = 50,
        configKey = "sneakDistanceMultiplier",
    })

    page:createSlider({
        label = "Invisibility Bonus",
        description = "Bonus to sneaking while invisible.",
        min = 0,
        max = 100,
        step = 1,
        configKey = "invisibilityBonus",
    })

    page:createSlider({
        label = "NPC Sneak Bonus",
        description = "Bonus to NPCs' sneak detection.",
        min = 0,
        max = 100,
        step = 1,
        configKey = "npcSneakBonus",
    })

    page:createSlider({
        label = "View Multiplier",
        description = "Multiplier for NPC visual detection.",
        min = 1,
        max = 10,
        step = 1,
        configKey = "viewMultiplier",
    })

    page:createSlider({
        label = "Hearing Multiplier",
        description = "Multiplier for NPC hearing detection.",
        min = 1,
        max = 10,
        step = 1,
        configKey = "hearingMultiplier",
    })

    page:createSlider({
        label = "Sneak Difficulty",
        description = "Difficulty threshold for sneaking.",
        min = 0,
        max = 200,
        step = 1,
        configKey = "sneakDifficulty",
    })

    page:createSlider({
        label = "Min Travel Time (seconds)",
        description = "Minimum time NPCs travel while investigating.",
        min = 1,
        max = 30,
        step = 1,
        configKey = "minTravelTime",
    })

    page:createSlider({
        label = "Max Travel Time (seconds)",
        description = "Maximum time NPCs travel while investigating.",
        min = 5,
        max = 60,
        step = 1,
        configKey = "maxTravelTime",
    })

end

event.register(tes3.event.modConfigReady, registerModConfig)
