local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("companionLeveler.config")
local logger  = require("logging.logger")
local log     = logger.getLogger("Companion Leveler")

local modName = 'Companion Leveler';
local template = EasyMCM.createTemplate { name = modName }
template:saveOnClose(modName, config)
template:register()


local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "                        [Companion Leveler]\n\nThis mod allows both NPC and Creature companions to level up based on their Class/Creature Type (Class Mode) or specific player selected build settings (Build Mode). \n\nCompanions level up when the player does (Default) or through experience gain (Experience Mode). \n\nIn Class Mode, you also have the choice of changing the Class/Creature Type your companions level as, or gaining Faction/Mentor and Specialization/Racial bonuses at a small chance. In Build Mode, the player chooses which attributes and skills their followers level and by how much.\n\nNPCs also have a chance of learning new spells when they train a spell school skill. Creatures have a lower chance to learn spells every level up."
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
local pageEXP = createPage("Experience Settings")
local pageAbility = createPage("Spell/Ability Settings")


----Global Settings-------------------------------------------------------------------------------------------------------------------------
local globalSettings = settings:createCategory("Global Settings")

globalSettings:createOnOffButton {
    label = "Mod Enabled",
    description = "Turn Companion Leveler on or off.",
    variable = mwse.mcm.createTableVariable { id = "modEnabled", table = config }
}

globalSettings:createOnOffButton {
    label = "Level-Up Summary",
    description = "Enable a level up summary menu when companions level up.\n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "levelSummary", table = config }
}

globalSettings:createOnOffButton {
    label = "Build Mode",
    description = "If Build Mode is enabled, allows you to select the skills and attributes your companions train in at level-up, rather than relying on their assigned class/bonuses. \n\nModifiers must be set BEFORE level up!\n\nDefault: Off",
    variable = mwse.mcm.createTableVariable { id = "buildMode", table = config }
}

globalSettings:createOnOffButton {
    label = "Experience Mode",
    description = "If Experience Mode is enabled, companions level up through experience rather than when the player levels up. \n\nDefault: Off",
    variable = mwse.mcm.createTableVariable { id = "expMode", table = config }
}

globalSettings:createOnOffButton {
    label = "Enable Skills Above 100",
    description = "If this is enabled, allows companion skills to go above 100.\n\nDefault: Off",
    variable = mwse.mcm.createTableVariable { id = "aboveMaxSkill", table = config }
}

globalSettings:createOnOffButton {
    label = "Enable Attributes Above 100",
    description = "If this is enabled, allows companion attributes to go above 100.\n\nDefault: Off",
    variable = mwse.mcm.createTableVariable { id = "aboveMaxAtt", table = config }
}

globalSettings:createOnOffButton {
    label = "Health Increase on Level-Up",
    description = "If this is enabled, companions gain a percentage of endurance as health, similar to the player.\n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "levelHealth", table = config }
}

-- globalSettings:createOnOffButton {
--     label = "NPC Spell-Learning on Level-Up",
--     description = "If this is enabled, whenever your NPC companion trains a magic school, they have a chance at learning a spell of that school within their abilities.\n\nDefault: On",
--     variable = mwse.mcm.createTableVariable { id = "spellLearning", table = config }
-- }

-- globalSettings:createOnOffButton {
--     label = "NPC Ability-Learning on Level-Up",
--     description = "If this is enabled, NPC companions learn an Ability specific to their current class at every 5th level. Each class has only one Ability. \n\nOnly vanilla classes and certain 'Ahead of the Classes' classes have abilities.\n\nDefault: On",
--     variable = mwse.mcm.createTableVariable { id = "abilityLearningNPC", table = config }
-- }

-- globalSettings:createOnOffButton {
--     label = "Creature Spell-Learning on Level-Up",
--     description = "If this is enabled, whenever your creature companion levels up, they have a chance at learning a spell suitable to their creature type.\n\nDefault: On",
--     variable = mwse.mcm.createTableVariable { id = "spellLearningC", table = config }
-- }

-- globalSettings:createOnOffButton {
--     label = "Creature Ability-Learning on Level-Up",
--     description = "If this is enabled, whenever your creature companions level up and reach certain level thresholds, they will learn Abilities specific to their creature type.\n\nDefault: On",
--     variable = mwse.mcm.createTableVariable { id = "abilityLearning", table = config }
-- }

-- globalSettings:createOnOffButton {
--     label = "Triggered Abilities",
--     description = "If this is enabled, certain NPC and creature abilities with special effects are able to be triggered. \n\nFor example: Alchemists will sometimes create potions. \n\nDefault: On",
--     variable = mwse.mcm.createTableVariable { id = "triggeredAbilities", table = config }
-- }

-- globalSettings:createOnOffButton {
--     label = "Show Unlearned Abilities",
--     description = "If this is enabled, all abilities will be shown in the character sheet regardless of whether or not the companion has learned them. Unlearned abilities are darker in color.\n\nDefault: Off",
--     variable = mwse.mcm.createTableVariable { id = "showUnlearned", table = config }
-- }

globalSettings:createOnOffButton {
    label = "Ignore Summoned Creatures",
    description = "If this is enabled, summoned creatures in the party are not counted as valid companions and will be ignored.\n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "ignoreSummon", table = config }
}

globalSettings:createDropdown {
    label = "Debug Logging Level",
    description = "Set the log level.\n\nDefault: INFO",
    options = {
        { label = "TRACE", value = "TRACE" },
        { label = "DEBUG", value = "DEBUG" },
        { label = "INFO", value = "INFO" },
        { label = "ERROR", value = "ERROR" },
        { label = "NONE", value = "NONE" },
    },
    variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
    callback = function(self)
        log:setLogLevel(self.variable.value)
    end
}

globalSettings:createKeyBinder {
    label = "Menu Hotkey",
    description = "Press this key when looking at a companion to open the companion menu.\n\nDefault: k",
    variable = mwse.mcm.createTableVariable { id = "typeBind", table = config },
    allowCombinations = false,
}

-- globalSettings:createOnOffButton {
--     label = "Battle Messages",
--     description = "Enable or disable messages from triggered battle abilities. \n\nDefault: On",
--     variable = mwse.mcm.createTableVariable { id = "bMessages", table = config }
-- }

----Global Modifiers---------------------------------------------------------------------------------------------------------------------------------------
local globalMod = settings:createCategory("Global Modifiers")


globalMod:createSlider {
    label = "Health Percentage",
    description = "The percentage of endurance a follower gains as health at level-up. \n\nDefault: 10% of endurance gained as health at level-up.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "healthMod",
        table = config
    }
}

-- globalMod:createSlider {
--     label = "NPC Spell-Learning Chance",
--     description = "Sets the percentage chance of NPC companions learning a spell when training a school of magic, within their casting ability. \n\nDefault: 50% chance to learn a spell of the trained school.",
--     max = 100,
--     min = 1,
--     variable = EasyMCM:createTableVariable {
--         id = "spellChance",
--         table = config
--     }
-- }

-- globalMod:createSlider {
--     label = "Creature Spell-Learning Chance",
--     description = "Sets the percentage chance of learning a spell when your creature companion levels up. \n\nDefault: 30% chance to learn a spell suitable to creature type.",
--     max = 100,
--     min = 1,
--     variable = EasyMCM:createTableVariable {
--         id = "spellChanceC",
--         table = config
--     }
-- }

----Class Mode Page--------------------------------------------------------------------------------------------------------------------------
local listMod = pageClass:createCategory("Class List Settings")

listMod:createOnOffButton {
    label = "All Classes Available",
    description = "If this is enabled, all classes in the game (including from mods) become available for companions to choose from in the Class Change Menu. May contain duplicates depending on what mods you have installed.",
    variable = mwse.mcm.createTableVariable { id = "allClasses", table = config }
}

listMod:createOnOffButton {
    label = "Ahead of the Classes...classes",
    description = "If this is enabled and Danae's Ahead of the Classes is installed, the classes added by that mod become available for companions to choose from in the Class Change Menu.",
    variable = mwse.mcm.createTableVariable { id = "aheadClasses", table = config }
}

local specMod = pageClass:createCategory("Bonus Modifier Settings")

specMod:createOnOffButton {
    label = "Guaranteed Magicka Increase on Level-Up",
    description = "If this is enabled, companions gain Intelligence to guarantee an increase in Magicka on level-up regardless of class attributes.",
    variable = mwse.mcm.createTableVariable { id = "levelMagicka", table = config }
}

specMod:createSlider {
    label = "Guaranteed Magicka Gain",
    description = "The amount of Intelligence gained at level-up to ensure magicka gain. \n\nDefault: 1 Intelligence worth of magicka gained at level-up.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "magickaMod",
        table = config
    }
}

specMod:createOnOffButton {
    label = "NPC Racial Bonus",
    description = "Turn on or off NPC companion racial skill bonus.",
    variable = mwse.mcm.createTableVariable { id = "racialBonus", table = config }
}

specMod:createSlider {
    label = "Racial Bonus Chance",
    description = "Sets the percentage chance of receiving a racial bonus in a skill related to your companion's heritage. \n\nDefault: 50% chance to receive a bonus.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "racialChance",
        table = config
    }
}

specMod:createSlider {
    label = "Racial Bonus Amount",
    description = "Sets bonus point amount when receiving a racial bonus in a skill related to your companion's heritage. \n\nDefault: 1 point bonus in relevant skill.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "racialBonusMod",
        table = config
    }
}

specMod:createOnOffButton {
    label = "NPC Specialization Bonus",
    description = "Turn on or off NPC companion class specialization bonus.",
    variable = mwse.mcm.createTableVariable { id = "specialBonus", table = config }
}

specMod:createSlider {
    label = "Specialization Bonus Chance",
    description = "Sets the percentage chance of receiving a specialization bonus in an attribute and skill related to your companion's default class specialization. \n\nDefault: 50% chance to receive a bonus.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "specialChance",
        table = config
    }
}

specMod:createSlider {
    label = "Specialization Bonus Amount",
    description = "Sets bonus point amount when receiving a specialization bonus in an attribute and skill related to your companion's default class specialization. \n\nDefault: 1 point bonus in relevant attribute and skill.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "specialBonusMod",
        table = config
    }
}

specMod:createOnOffButton {
    label = "NPC Faction Bonus",
    description = "Turn on or off NPC companion faction bonus. If an NPC companion belongs to a faction, they will occasionally train in that faction's favored attributes and skills as a bonus.",
    variable = mwse.mcm.createTableVariable { id = "factionBonus", table = config }
}

specMod:createSlider {
    label = "Faction Bonus Chance",
    description = "Sets the percentage chance of receiving a faction bonus in an attribute and skill related to your companion's faction affiliation. \n\nDefault: 25% chance to receive a bonus.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "factionChance",
        table = config
    }
}

specMod:createSlider {
    label = "Faction Bonus Amount",
    description = "Sets bonus point amount when receiving a faction bonus in an attribute and skill related to your companion's faction affiliation. \n\nDefault: 1 point bonus in relevant attribute and skill.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "factionBonusMod",
        table = config
    }
}

specMod:createOnOffButton {
    label = "NPC Mentor Bonus",
    description = "Turn on or off NPC companion mentor skill bonus, which allows the player to sometimes mentor their companion in a skill related to the player's own class skills.",
    variable = mwse.mcm.createTableVariable { id = "mentorBonus", table = config }
}

specMod:createSlider {
    label = "Mentor Bonus Chance",
    description = "Sets the percentage chance of receiving a mentor bonus in a skill related to the player major skills. \n\nDefault: 25% chance to receive a bonus.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "mentorChance",
        table = config
    }
}

specMod:createSlider {
    label = "Mentor Bonus Amount",
    description = "Sets bonus point amount when receiving a mentor bonus in a skill related to the player's major skills. \n\nDefault: 1 point bonus in relevant skill.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "mentorBonusMod",
        table = config
    }
}

local skillMod = pageClass:createCategory("Major Skill Modifiers")

skillMod:createSlider {
    label = "1st Major Skill Range Minimum",
    description = "Minimum amount of skill points received for 1st Major Skill trained. \n\nDefault: 3 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minMajor1",
        table = config
    }
}

skillMod:createSlider {
    label = "1st Major Skill Range Maximum",
    description = "Maximum amount of skill points received for 1st Major Skill trained. \n\nDefault: 3 points.",
    min = 0,
    max = 10,
    variable = EasyMCM:createTableVariable {
        id = "maxMajor1",
        table = config
    }
}

skillMod:createSlider {
    label = "2nd Major Skill Range Minimum",
    description = "Minimum amount of skill points received for 2nd Major Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minMajor2",
        table = config
    }
}

skillMod:createSlider {
    label = "2nd Major Skill Range Maximum",
    description = "Maximum amount of skill points received for 2nd Major Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxMajor2",
        table = config
    }
}

skillMod:createSlider {
    label = "3rd Major Skill Range Minimum",
    description = "Minimum amount of skill points received for 3rd Major Skill trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minMajor3",
        table = config
    }
}

skillMod:createSlider {
    label = "3rd Major Skill Range Maximum",
    description = "Maximum amount of skill points received for 3rd Major Skill trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxMajor3",
        table = config
    }
}


local skillMod2 = pageClass:createCategory("Minor Skill Modifiers")

skillMod2:createSlider {
    label = "1st Minor Skill Range Minimum",
    description = "Minimum amount of skill points received for 1st Minor Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minMinor1",
        table = config
    }
}

skillMod2:createSlider {
    label = "1st Minor Skill Range Maximum",
    description = "Maximum amount of skill points received for 1st Minor Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxMinor1",
        table = config
    }
}

skillMod2:createSlider {
    label = "2nd Minor Skill Range Minimum",
    description = "Minimum amount of skill points received for 2nd Minor Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minMinor2",
        table = config
    }
}

skillMod2:createSlider {
    label = "2nd Minor Skill Range Maximum",
    description = "Maximum amount of skill points received for 2nd Minor Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxMinor2",
        table = config
    }
}


local skillMod3 = pageClass:createCategory("Random Skill Modifiers")

skillMod3:createSlider {
    label = "1st Random Skill Range Minimum",
    description = "Minimum amount of skill points received for 1st Random Skill trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minRandom1",
        table = config
    }
}

skillMod3:createSlider {
    label = "1st Random Skill Range Maximum",
    description = "Maximum amount of skill points received for 1st Random Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxRandom1",
        table = config
    }
}

skillMod3:createSlider {
    label = "2nd Random Skill Range Minimum",
    description = "Minimum amount of skill points received for 2nd Random Skill trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minRandom2",
        table = config
    }
}

skillMod3:createSlider {
    label = "2nd Random Skill Range Maximum",
    description = "Maximum amount of skill points received for 2nd Random Skill trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxRandom2",
        table = config
    }
}


local attMod = pageClass:createCategory("Attribute Modifiers")

attMod:createSlider {
    label = "1st Favored Attribute Range Minimum",
    description = "Minimum amount of attribute points received for 1st Favored Attribute trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minMajorAtt1",
        table = config
    }
}

attMod:createSlider {
    label = "1st Favored Attribute Range Maximum",
    description = "Maximum amount of attribute points received for 1st Favored Attribute trained. \n\nDefault: 4 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxMajorAtt1",
        table = config
    }
}

attMod:createSlider {
    label = "2nd Favored Attribute Range Minimum",
    description = "Minimum amount of attribute points received for 2nd Favored Attribute trained. \n\nDefault: 2 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minMajorAtt2",
        table = config
    }
}

attMod:createSlider {
    label = "2nd Favored Attribute Range Maximum",
    description = "Maximum amount of attribute points received for 2nd Favored Attribute trained. \n\nDefault: 4 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxMajorAtt2",
        table = config
    }
}

attMod:createSlider {
    label = "Random Attribute Range Minimum",
    description = "Minimum amount of attribute points received for the Random Attribute trained. \n\nDefault: 1 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "minRandAtt",
        table = config
    }
}

attMod:createSlider {
    label = "Random Attribute Range Maximum",
    description = "Maximum amount of attribute points received for the Random Attribute trained. \n\nDefault: 4 points.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "maxRandAtt",
        table = config
    }
}


----Experience Mode Page--------------------------------------------------------------------------------------------------------------------------
local expMod = pageEXP:createCategory("Experience Modifiers")


expMod:createSlider {
    label = "Base Experience Requirement",
    description = "The base amount of experience a follower requires to level up. \n\nDefault: 120",
    max = 2000,
    min = 10,
    variable = EasyMCM:createTableVariable {
        id = "expRequirement",
        table = config
    }
}

expMod:createSlider {
    label = "Experience Increment",
    description = "The amount of additional experience a follower requires to level up per level gained. \n\nDefault: 10",
    max = 200,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "expRate",
        table = config
    }
}

expMod:createSlider {
    label = "Major/Minor Skill Experience",
    description = "The amount of experience a follower gains when the player trains a Major or Minor Skill. \n\nDefault: 10",
    max = 100,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "expClassSkill",
        table = config
    }
}

expMod:createSlider {
    label = "Misc Skill Experience",
    description = "The amount of experience a follower gains when the player trains a Miscellaneous Skill. \n\nDefault: 2",
    max = 100,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "expMiscSkill",
        table = config
    }
}

expMod:createSlider {
    label = "Battle Experience",
    description = "The amount of experience a follower gains when an enemy is killed. \n\nDefault: 2",
    max = 100,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "expKill",
        table = config
    }
}

expMod:createSlider {
    label = "Quest Experience",
    description = "The amount of experience a follower gains when quest progress is made. \n\nDefault: 3",
    max = 100,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "expQuest",
        table = config
    }
}


----Spell/Ability Page--------------------------------------------------------------------------------------------------------------------------
local spMod = pageAbility:createCategory("Spell Settings")

spMod:createOnOffButton {
    label = "NPC Spell-Learning on Level-Up",
    description = "If this is enabled, whenever your NPC companion trains a magic school, they have a chance at learning a spell of that school within their abilities.\n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "spellLearning", table = config }
}

spMod:createSlider {
    label = "NPC Spell-Learning Chance",
    description = "Sets the percentage chance of NPC companions learning a spell when training a school of magic, within their casting ability. \n\nDefault: 50% chance to learn a spell of the trained school.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "spellChance",
        table = config
    }
}

spMod:createOnOffButton {
    label = "Creature Spell-Learning on Level-Up",
    description = "If this is enabled, whenever your creature companion levels up, they have a chance at learning a spell suitable to their creature type.\n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "spellLearningC", table = config }
}

spMod:createSlider {
    label = "Creature Spell-Learning Chance",
    description = "Sets the percentage chance of learning a spell when your creature companion levels up. \n\nDefault: 30% chance to learn a spell suitable to creature type.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "spellChanceC",
        table = config
    }
}


local abMod = pageAbility:createCategory("Ability Settings")

abMod:createOnOffButton {
    label = "NPC Ability-Learning on Level-Up",
    description = "If this is enabled, NPC companions learn an Ability specific to their current class at every 5th level. Each class has only one Ability. \n\nOnly vanilla classes and certain 'Ahead of the Classes' classes have abilities.\n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "abilityLearningNPC", table = config }
}

abMod:createOnOffButton {
    label = "Creature Ability-Learning on Level-Up",
    description = "If this is enabled, whenever your creature companions level up and reach certain level thresholds, they will learn Abilities specific to their creature type.\n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "abilityLearning", table = config }
}

abMod:createOnOffButton {
    label = "Triggered Abilities: Non-Combat",
    description = "If this is enabled, certain NPC and creature abilities with non-combat special effects are able to be triggered. \n\nFor example: Alchemists will sometimes create potions. \n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "triggeredAbilities", table = config }
}

abMod:createSlider {
    label = "Trigger Frequency: Non-Combat",
    description = "Sets the frequency at which non-combat triggered abilities can trigger. Higher values mean abilities trigger more often. \n\nDefault: 35% frequency.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "triggerChance",
        table = config
    }
}

abMod:createOnOffButton {
    label = "Triggered Abilities: Combat",
    description = "If this is enabled, certain NPC and creature abilities with combat special effects are able to be triggered. \n\nFor example: Jesters will sometimes provoke NPC enemies, reducing their Agility and Luck. \n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "combatAbilities", table = config }
}

abMod:createSlider {
    label = "Trigger Frequency: Combat",
    description = "Sets the frequency at which combat abilities can trigger. Higher values mean combat abilities trigger more often. \n\nDefault: 35% frequency.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "combatChance",
        table = config
    }
}

abMod:createOnOffButton {
    label = "Ability Battle Messages",
    description = "Enable or disable messages from triggered battle abilities. \n\nDefault: On",
    variable = mwse.mcm.createTableVariable { id = "bMessages", table = config }
}

abMod:createOnOffButton {
    label = "Show Unlearned Abilities",
    description = "If this is enabled, all abilities will be shown in the character sheet regardless of whether or not the companion has learned them. Unlearned abilities are darker in color.\n\nDefault: Off",
    variable = mwse.mcm.createTableVariable { id = "showUnlearned", table = config }
}