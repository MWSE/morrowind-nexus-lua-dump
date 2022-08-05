local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("friendlyIntervention.config")
local logger = require("logging.logger")
local log = logger.getLogger("Friendly Intervention")

local modName = 'Friendly Intervention';
local template = EasyMCM.createTemplate{ name = modName}
template:saveOnClose(modName, config)
template:register()



local function createPage(label)
	local page = template:createSideBarPage{
		label = label,
		noScroll = false,
	}
	page.sidebar:createInfo{
		text = "                      * Friendly Intervention *\n\nAllows companions to teleport with the player when using Recall/Intervention spells for free or with restrictions. \n\nCan be set to use magicka or scrolls. Can be set to only allow companions with enough Mysticism skill to teleport with you, or allow a player with high Mysticism to teleport everyone at once."
	}
	page.sidebar:createHyperLink {
		text = "Made by Kleidium",
		exec = "start https://www.nexusmods.com/users/5374229?tab=user+files",
		postCreate = function(self)
			self.elements.outerContainer.borderAllSides = self.indent
			self.elements.outerContainer.alignY = 1.0
			self.elements.info.layoutOriginFractionX = 0.5
		end,
	}
	return page
end

local settings = createPage("Settings")


----Global Settings-------------------------------------------------------------------------------------------------------------------------
local globalSettings = settings:createCategory("Settings")

globalSettings:createOnOffButton{
    label = "Mod Enabled",
    description = "Turn on or off companion intervention/recall.",
    variable = mwse.mcm.createTableVariable{ id = "modEnabled", table = config }
}

globalSettings:createOnOffButton{
    label = "Messages Enabled",
    description = "Turn on or off companion intervention/recall messages.",
    variable = mwse.mcm.createTableVariable{ id = "msgEnabled", table = config }
}

globalSettings:createOnOffButton{
    label = "Train Mysticism",
    description = "Turn on or off additional Mysticism experience when the player is transporting others. The experience gain is minimal and increases with the number of companions transported by the player. \n\nCompanions that transport themselves don't exercise the player's skill.",
    variable = mwse.mcm.createTableVariable{ id = "trainMyst", table = config }
}

globalSettings:createOnOffButton{
    label = "Summons Bypass Requirements",
    description = "Enable to allow summoned creatures to teleport with you no matter what other requirements are set in place. Summons transported this way do not train the player's Mysticism skill. \n\nOtherwise, summoned creatures are subject to the same requirements (skill checks, magicka cost, scroll use) as everyone else.",
    variable = mwse.mcm.createTableVariable{ id = "smnFree", table = config }
}

globalSettings:createOnOffButton{
    label = "Magicka Requirement",
    description = "Turn on or off magicka requirements.  Magicka consumed will decrease with greater Mysticism skill. \n\nCompanions that transport themselves use their own magicka and skill. If the companion doesn't have enough magicka, the player will cover the cost if they meet the skill requirement. \n\nIf there is no skill requirements, only the player's magicka will be used to transport companions. The player loses magicka for each companion they transport themselves.",
    variable = mwse.mcm.createTableVariable{ id = "magickaReq", table = config }
}

globalSettings:createSlider{
    label = "Magicka Modifier",
    description = "The magicka requirement needed for the caster to transport themselves/others.  Greater Mysticism skill reduces this (up to 50% at skill 100, 100% at skill 200, 1 Magicka minimum). Companions only pay for their own transport if they have enough skill. The player loses magicka for each companion they transport themselves. \n\nIf the companion tries to transport themselves but doesn't have enough magicka, they will use a scroll or be left behind. A player with enough magicka will cover the cost without using a scroll.",
    max = 200,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "magickaMod",
        table = config
    }
}

globalSettings:createOnOffButton{
    label = "Mysticism Skill Requirement",
    description = "Enable a Mysticism skill requirement. If the requirement is not met by either the player or the companion, the companion will not be teleported with you unless a scroll is used. This check will happen even when using scrolls or enchantments. \n\nIf this is on but neither player nor companion skill is set to be checked below, the companion will not be teleported with you unless you enable usage of scrolls. Creatures will never meet this requirement unless they are Daedra.",
    variable = mwse.mcm.createTableVariable{ id = "skillLimit", table = config }
}

globalSettings:createOnOffButton{
    label = "Enable Scroll Use",
    description = "Enable usage of scrolls only for when both you and your companion fail the Mysticism skill check or don't have enough magicka. Will use one scroll of the appropriate type from the player's inventory per companion that couldn't be transported through the use of Mysticism. \n\nIf no scrolls are left, the companion will be left behind. Using scrolls this way does not train the player's Mysticism.",
    variable = mwse.mcm.createTableVariable{ id = "useScroll", table = config }
}

globalSettings:createOnOffButton{
    label = "Check Player Skill",
    description = "Allows the player's Mysticism skill to count toward a successful teleport.",
    variable = mwse.mcm.createTableVariable{ id = "playerSkill", table = config }
}

globalSettings:createSlider{
    label = "Player Skill Requirement",
    description = "The Mysticism skill requirement needed for the player to transport companions alongside themselves.",
    max = 200,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "playerSkillReq",
        table = config
    }
}

globalSettings:createOnOffButton{
    label = "Check Companion Skill",
    description = "Allows the companion's Mysticism skill to count toward a successful teleport. Creatures (including summoned creatures) do not contribute, unless they are Daedra. ",
    variable = mwse.mcm.createTableVariable{ id = "npcSkill", table = config }
}

globalSettings:createSlider{
    label = "Companion Skill Requirement",
    description = "The Mysticism skill requirement needed for each companion to transport themselves.",
    max = 200,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "npcSkillReq",
        table = config
    }
}

globalSettings:createOnOffButton{
    label = "Play Teleport Sounds",
    description = "Toggle on or off teleportation sounds.",
    variable = mwse.mcm.createTableVariable{ id = "playSound", table = config }
}

globalSettings:createOnOffButton{
    label = "Play Teleport Effects",
    description = "Toggle on or off teleportation particle effects.",
    variable = mwse.mcm.createTableVariable{ id = "playEffect", table = config }
}

globalSettings:createOnOffButton{
    label = "Magicka Expanded Teleportation",
    description = "Toggle on or off support for Magicka Expanded's teleportation spell effects.",
    variable = mwse.mcm.createTableVariable{ id = "mExpanded", table = config }
}

globalSettings:createDropdown{
    label = "Debug Logging Level",
    description = "Set the log level.",
    options = {
      { label = "TRACE", value = "TRACE"},
      { label = "DEBUG", value = "DEBUG"},
      { label = "INFO", value = "INFO"},
      { label = "ERROR", value = "ERROR"},
      { label = "NONE", value = "NONE"},
    },
    variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
    callback = function(self)
      log:setLogLevel(self.variable.value)
    end
  }