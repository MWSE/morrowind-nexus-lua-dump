local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("companionLeveler.config")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")

local modName = 'Companion Leveler';
local template = EasyMCM.createTemplate{name = modName}
template:saveOnClose(modName, config)
template:register()


local function createPage(label)
	local page = template:createSideBarPage{
		label = label,
		noScroll = false,
	}
	page.sidebar:createInfo{
		text = "                        [Companion Leveler]\n\nThis mod allows both NPC and Creature companions to level up with the player based on their Class/Creature Type (Class Mode) or specific player selected build settings (Build Mode). \n\nIn Class Mode, you also have the choice of changing the Class/Creature Type your companions level as, or gaining Faction/Mentor and Specialization/Racial bonuses at a small chance. In Build Mode, the player chooses which attributes and skills their followers level and by how much.\n\nNPCS also have a chance of learning new spells when they train a spell school skill. Creatures have a lower chance to learn spells every level up."
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
local pageClass = createPage("Class Mode Settings")


----Global Settings-------------------------------------------------------------------------------------------------------------------------
local globalSettings = settings:createCategory("Global Settings")

globalSettings:createOnOffButton{
    label = "Mod Enabled",
    description = "Turn on or off companion leveling.",
    variable = mwse.mcm.createTableVariable{ id = "modEnabled", table = config }
}

globalSettings:createOnOffButton{
    label = "Level-Up Summary",
    description = "Enable a level up summary menu when companions level up.",
    variable = mwse.mcm.createTableVariable{ id = "levelSummary", table = config }
}

globalSettings:createOnOffButton{
    label = "Enable Build Mode",
    description = "If Build Mode is enabled, allows you to select the skills and attributes your companions train in at level-up by using the class key (Default: K), rather than relying on their assigned class/bonuses.",
    variable = mwse.mcm.createTableVariable{ id = "buildMode", table = config }
}

globalSettings:createOnOffButton{
    label = "Enable Skills Above 100",
    description = "If this is enabled, allows companion skills to go above 100.",
    variable = mwse.mcm.createTableVariable{ id = "aboveMaxSkill", table = config }
}

globalSettings:createOnOffButton{
    label = "Enable Attributes Above 100",
    description = "If this is enabled, allows companion attributes to go above 100.",
    variable = mwse.mcm.createTableVariable{ id = "aboveMaxAtt", table = config }
}

globalSettings:createOnOffButton{
    label = "Enable Health Increase on Level-Up",
    description = "If this is enabled, companions gain a percentage of endurance as health, similar to the player.",
    variable = mwse.mcm.createTableVariable{ id = "levelHealth", table = config }
}

globalSettings:createOnOffButton{
    label = "Enable NPC Spell-Learning on Level-Up",
    description = "If this is enabled, whenever your NPC companion trains a magic school, they have a chance at learning a spell of that school within their abilities.",
    variable = mwse.mcm.createTableVariable{ id = "spellLearning", table = config }
}

globalSettings:createOnOffButton{
    label = "Enable Creature Spell-Learning on Level-Up",
    description = "If this is enabled, whenever your creature companion levels up, they have a chance at learning a spell suitable to their creature type.",
    variable = mwse.mcm.createTableVariable{ id = "spellLearningC", table = config }
}

globalSettings:createOnOffButton{
    label = "Enable Creature Ability-Learning on Level-Up",
    description = "If this is enabled, whenever your creature companion levels up and reaches certain level thresholds, they will learn Abilities specific to their creature type.",
    variable = mwse.mcm.createTableVariable{ id = "abilityLearning", table = config }
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

globalSettings:createKeyBinder{
    label = "Class Change/Build Mode Hotkey",
    description = "Press this key when looking at a companion to change its Class/Type in Class Mode, or growth in Build Mode.",
    variable = mwse.mcm.createTableVariable{ id = "typeBind", table = config},
    allowCombinations = false,
}

----Global Modifiers---------------------------------------------------------------------------------------------------------------------------------------
local globalMod = settings:createCategory("Global Modifiers")

globalMod:createSlider{
    label = "Health Percentage",
    description = "The percentage of endurance a follower gains as health at level-up. \n\nDefault: 10% of endurance gained as health at level-up.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "healthMod",
        table = config
    }
}

globalMod:createSlider{
    label = "NPC Spell-Learning Chance",
    description = "Sets the percentage chance of NPC companions learning a spell when training a school of magic, within their casting ability. \n\nDefault: 50% chance to learn a spell of the trained school.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "spellChance",
        table = config
    }
}

globalMod:createSlider{
    label = "Creature Spell-Learning Chance",
    description = "Sets the percentage chance of learning a spell when your creature companion levels up. \n\nDefault: 30% chance to learn a spell suitable to creature type.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "spellChanceC",
        table = config
    }
}

----Class Mode Page--------------------------------------------------------------------------------------------------------------------------
local specMod = pageClass:createCategory("Bonus Modifier Settings")

specMod:createOnOffButton{
    label = "Guaranteed Magicka Increase on Level-Up",
    description = "If this is enabled, companions gain Intelligence to guarantee an increase in Magicka on level-up regardless of class attributes.",
    variable = mwse.mcm.createTableVariable{ id = "levelMagicka", table = config }
}

specMod:createSlider{
    label = "Guaranteed Magicka Gain",
    description = "The amount of Intelligence gained at level-up to ensure magicka gain. \n\nDefault: 1 Intelligence worth of magicka gained at level-up.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "magickaMod",
        table = config
    }
}

specMod:createOnOffButton{
    label = "NPC Racial Bonus",
    description = "Turn on or off NPC companion racial skill bonus.",
    variable = mwse.mcm.createTableVariable{ id = "racialBonus", table = config }
}

specMod:createSlider{
    label = "Racial Bonus Chance",
    description = "Sets the percentage chance of receiving a racial bonus in a skill related to your companion's heritage. \n\nDefault: 50% chance to receive a bonus.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "racialChance",
        table = config
    }
}

specMod:createSlider{
    label = "Racial Bonus Amount",
    description = "Sets bonus point amount when receiving a racial bonus in a skill related to your companion's heritage. \n\nDefault: 1 point bonus in relevant skill.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "racialBonusMod",
        table = config
    }
}

specMod:createOnOffButton{
    label = "NPC Specialization Bonus",
    description = "Turn on or off NPC companion class specialization bonus.",
    variable = mwse.mcm.createTableVariable{ id = "specialBonus", table = config }
}

specMod:createSlider{
    label = "Specialization Bonus Chance",
    description = "Sets the percentage chance of receiving a specialization bonus in an attribute and skill related to your companion's class specialization. \n\nDefault: 50% chance to receive a bonus.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "specialChance",
        table = config
    }
}

specMod:createSlider{
    label = "Specialization Bonus Amount",
    description = "Sets bonus point amount when receiving a specialization bonus in an attribute and skill related to your companion's class specialization. \n\nDefault: 1 point bonus in relevant attribute and skill.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "specialBonusMod",
        table = config
    }
}

specMod:createOnOffButton{
    label = "NPC Faction Bonus",
    description = "Turn on or off NPC companion faction bonus. If an NPC companion belongs to a faction, they will occasionally train in that faction's favored attributes and skills as a bonus.",
    variable = mwse.mcm.createTableVariable{ id = "factionBonus", table = config }
}

specMod:createSlider{
    label = "Faction Bonus Chance",
    description = "Sets the percentage chance of receiving a faction bonus in an attribute and skill related to your companion's faction affiliation. \n\nDefault: 25% chance to receive a bonus.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "factionChance",
        table = config
    }
}

specMod:createSlider{
    label = "Faction Bonus Amount",
    description = "Sets bonus point amount when receiving a faction bonus in an attribute and skill related to your companion's faction affiliation. \n\nDefault: 1 point bonus in relevant attribute and skill.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "factionBonusMod",
        table = config
    }
}

specMod:createOnOffButton{
    label = "NPC Mentor Bonus",
    description = "Turn on or off NPC companion mentor skill bonus, which allows the player to sometimes mentor their companion in a skill related to the player's own class skills.",
    variable = mwse.mcm.createTableVariable{ id = "mentorBonus", table = config }
}

specMod:createSlider{
    label = "Mentor Bonus Chance",
    description = "Sets the percentage chance of receiving a mentor bonus in a skill related to the player major skills. \n\nDefault: 25% chance to receive a bonus.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "mentorChance",
        table = config
    }
}

specMod:createSlider{
    label = "Mentor Bonus Amount",
    description = "Sets bonus point amount when receiving a mentor bonus in a skill related to the player's major skills. \n\nDefault: 1 point bonus in relevant skill.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "mentorBonusMod",
        table = config
    }
}

local skillMod = pageClass:createCategory("Major Skill Modifiers")

skillMod:createSlider{
    label = "1st Major Skill Range Minimum",
    description = "Minimum amount of skill points received for 1st Major Skill trained. \n\nDefault: 3 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minMajor1",
        table = config
    }
}

skillMod:createSlider{
    label = "1st Major Skill Range Maximum",
    description = "Maximum amount of skill points received for 1st Major Skill trained. \n\nDefault: 3 points.",
    min = 0,
    max = 10,
    variable = EasyMCM:createTableVariable{
        id = "maxMajor1",
        table = config
    }
}

skillMod:createSlider{
    label = "2nd Major Skill Range Minimum",
    description = "Minimum amount of skill points received for 2nd Major Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minMajor2",
        table = config
    }
}

skillMod:createSlider{
    label = "2nd Major Skill Range Maximum",
    description = "Maximum amount of skill points received for 2nd Major Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxMajor2",
        table = config
    }
}

skillMod:createSlider{
    label = "3rd Major Skill Range Minimum",
    description = "Minimum amount of skill points received for 3rd Major Skill trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minMajor3",
        table = config
    }
}

skillMod:createSlider{
    label = "3rd Major Skill Range Maximum",
    description = "Maximum amount of skill points received for 3rd Major Skill trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxMajor3",
        table = config
    }
}


local skillMod2 = pageClass:createCategory("Minor Skill Modifiers")

skillMod2:createSlider{
    label = "1st Minor Skill Range Minimum",
    description = "Minimum amount of skill points received for 1st Minor Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minMinor1",
        table = config
    }
}

skillMod2:createSlider{
    label = "1st Minor Skill Range Maximum",
    description = "Maximum amount of skill points received for 1st Minor Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxMinor1",
        table = config
    }
}

skillMod2:createSlider{
    label = "2nd Minor Skill Range Minimum",
    description = "Minimum amount of skill points received for 2nd Minor Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minMinor2",
        table = config
    }
}

skillMod2:createSlider{
    label = "2nd Minor Skill Range Maximum",
    description = "Maximum amount of skill points received for 2nd Minor Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxMinor2",
        table = config
    }
}


local skillMod3 = pageClass:createCategory("Random Skill Modifiers")

skillMod3:createSlider{
    label = "1st Random Skill Range Minimum",
    description = "Minimum amount of skill points received for 1st Random Skill trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minRandom1",
        table = config
    }
}

skillMod3:createSlider{
    label = "1st Random Skill Range Maximum",
    description = "Maximum amount of skill points received for 1st Random Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxRandom1",
        table = config
    }
}

skillMod3:createSlider{
    label = "2nd Random Skill Range Minimum",
    description = "Minimum amount of skill points received for 2nd Random Skill trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minRandom2",
        table = config
    }
}

skillMod3:createSlider{
    label = "2nd Random Skill Range Maximum",
    description = "Maximum amount of skill points received for 2nd Random Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxRandom2",
        table = config
    }
}


local attMod = pageClass:createCategory("Attribute Modifiers")

attMod:createSlider{
    label = "1st Favored Attribute Range Minimum",
    description = "Minimum amount of attribute points received for 1st Favored Attribute trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minMajorAtt1",
        table = config
    }
}

attMod:createSlider{
    label = "1st Favored Attribute Range Maximum",
    description = "Maximum amount of attribute points received for 1st Favored Attribute trained. \n\nDefault: 4 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxMajorAtt1",
        table = config
    }
}

attMod:createSlider{
    label = "2nd Favored Attribute Range Minimum",
    description = "Minimum amount of attribute points received for 2nd Favored Attribute trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minMajorAtt2",
        table = config
    }
}

attMod:createSlider{
    label = "2nd Favored Attribute Range Maximum",
    description = "Maximum amount of attribute points received for 2nd Favored Attribute trained. \n\nDefault: 4 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxMajorAtt2",
        table = config
    }
}

attMod:createSlider{
    label = "Random Attribute Range Minimum",
    description = "Minimum amount of attribute points received for the Random Attribute trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minRandAtt",
        table = config
    }
}

attMod:createSlider{
    label = "Random Attribute Range Maximum",
    description = "Maximum amount of attribute points received for the Random Attribute trained. \n\nDefault: 4 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "maxRandAtt",
        table = config
    }
}