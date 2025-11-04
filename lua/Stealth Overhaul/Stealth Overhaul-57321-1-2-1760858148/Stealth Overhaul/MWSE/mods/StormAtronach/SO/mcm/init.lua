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
		text = "\nWelcome to Stealth Overhaul!\n\nHover over a feature for more info.\n\nMade by:",
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
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	local page = template:createSideBarPage({
		label = "General",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

    local detection = template:createSideBarPage({
		label = "Detection",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(detection)

    local investigation = template:createSideBarPage({
		label = "Investigation",
		showReset = true,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(investigation)

	page:createYesNoButton({
        label = "Enable Mod",
        description = "Enable or disable Stealth Overhaul.",
        configKey = "modEnabled",
    })

    page:createLogLevelOptions({
        configKey = "logLevel",
    })

    detection:createSlider({
        label = "Detection Angle",
        description = "The angle at which the player can be detected by NPCs. 180 means they have perfect 360 vision.",
        min = 0,
        max = 180,
        step = 1,
        configKey = "detectionAngle",
    })
   
    page:createSlider({
        label = "Bounty threshold",
        description = "Bounty above which the guards will eye you suspiciously",
        min = 0,
        max = 1000,
        step = 10,
        configKey = "bountyThreshold",
    })
    
    page:createSlider({
        label = "Guard maximum detection distance",
        description = "How close you have to be to the guards to trigger the detection of stolen items. Each unit corresponds approximately to 25 feet (approx 7.5 meters)",
        min = 1,
        max = 10,
        step = 1,
        configKey = "guardMaxDistance",
    })
    
    page:createSlider({
        label = "Disposition Drop",
        description = "How much disposition drops when found with stolen items by the owner.",
        min = 0,
        max = 100,
        step = 1,
        configKey = "dispositionDropOnDiscovery",
    })

    detection:createSlider({
        label = "Detection Cooldown (seconds)",
        description = "Cooldown for stolen item checks.",
        min = 1,
        max = 30,
        step = 1,
        configKey = "detectionCooldown",
    })

    page:createSlider({
        label = "Guard Cooldown Time (seconds)",
        description = "Cooldown before guards can scan you for stolen items.",
        min = 1,
        max = 30,
        step = 1,
        configKey = "guardCooldownTime",
    })

    page:createSlider({
        label = "Owner Cooldown Time (seconds)",
        description = "Cooldown before owners can scan you for stolen items.",
        min = 1,
        max = 30,
        step = 1,
        configKey = "ownerCooldownTime",
    })
    
    detection:createSlider({
        label = "Sneak Difficulty",
        description = "Difficulty threshold for sneaking.",
        min = 0,
        max = 200,
        step = 1,
        configKey = "sneakDifficulty",
    })
    detection:createSlider({
        label = "Sneak Skill Multiplier",
        description = "Multiplier for sneak skill in detection calculations.",
        min = 50,
        max = 200,
        step = 5,
        configKey = "sneakSkillMult",
    })

    detection:createSlider({
        label = "Boot Multiplier",
        description = "Penalty for wearing heavier boots.",
        min = 0,
        max = 50,
        step = 1,
        configKey = "bootMultiplier",
    })

    detection:createSlider({
        label = "Sneak Distance Base",
        description = "Base value for sneak distance calculations.",
        min = 0,
        max = 200,
        step = 1,
        configKey = "sneakDistanceBase",
    })

    detection:createSlider({
        label = "Sneak Distance Multiplier",
        description = "Multiplier for sneak distance calculations.",
        min = 100,
        max = 2000,
        step = 50,
        configKey = "sneakDistanceMultiplier",
    })

    detection:createSlider({
        label = "Invisibility Bonus",
        description = "Bonus to sneaking while invisible.",
        min = 0,
        max = 100,
        step = 1,
        configKey = "invisibilityBonus",
    })

    detection:createSlider({
        label = "NPC Sneak Bonus",
        description = "Bonus to NPCs' sneak detection.",
        min = 0,
        max = 100,
        step = 1,
        configKey = "npcSneakBonus",
    })

    detection:createSlider({
        label = "View Multiplier",
        description = "Multiplier for NPC visual detection.",
        min = 1,
        max = 5,
        step = 1,
        configKey = "viewMultiplier",
    })

    detection:createSlider({
        label = "Hearing Multiplier",
        description = "Multiplier for NPC hearing detection.",
        min = 1,
        max = 10,
        step = 1,
        configKey = "hearingMultiplier",
    })

    investigation:createSlider({
        label = "Min Travel Time (seconds)",
        description = "Minimum time NPCs travel while investigating.",
        min = 1,
        max = 30,
        step = 1,
        configKey = "minTravelTime",
    })

    investigation:createSlider({
        label = "Max Travel Time (seconds)",
        description = "Maximum time NPCs travel while investigating.",
        min = 5,
        max = 60,
        step = 1,
        configKey = "maxTravelTime",
    })

    investigation:createSlider({
        label = "Wander Range (Interior)",
        description = "How far NPCs wander when investigating (interior).",
        min = 100,
        max = 2000,
        step = 50,
        configKey = "wanderRangeInterior",
    })

    investigation:createSlider({
        label = "Wander Range (Exterior)",
        description = "How far NPCs wander when investigating (exterior).",
        min = 500,
        max = 5000,
        step = 100,
        configKey = "wanderRangeExterior",
    })

end

event.register(tes3.event.modConfigReady, registerModConfig)
