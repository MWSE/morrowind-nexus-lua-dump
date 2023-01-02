local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("friendlyIntervention.config")
local logger  = require("logging.logger")
local log     = logger.getLogger("Friendly Intervention")

local modName = 'Friendly Intervention';
local template = EasyMCM.createTemplate { name = modName }
template:saveOnClose(modName, config)
template:register()



local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "                      * Friendly Intervention *\n\n(Normal Teleportation): Allows companions to teleport with the player when using Recall/Intervention spells for free or with restrictions. \n\nCan be set to use enchantment charges, magicka, or scrolls. Can be set to only allow companions with enough Mysticism skill to teleport with you, or allow a player with high Mysticism to teleport everyone at once. \n\n(Teleport Menu): Ask companions to teleport anyone in the party using Intervention, Recall, or Magicka Expanded teleport spells (player must know the spell if an ME spell). You may also ask companions to set their own mark."
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
local globalSettings = settings:createCategory("Global Settings")

globalSettings:createOnOffButton {
    label = "Normal Teleportation",
    description = "Turn on or off companion teleportation when the player teleports themselves. Anything in this menu that refers to \"Normal Teleportation\" refers to this mode of teleportation.",
    variable = mwse.mcm.createTableVariable { id = "modEnabled", table = config }
}

globalSettings:createOnOffButton {
    label = "Teleport Menu",
    description = "Turn on or off the ability to ask companions to teleport. Choose as many targets as the companion has magicka for (if magicka requirements are enabled), as well as a destination. \n\nIf skill requirements are enabled, companions require 50 Mysticism to teleport themselves and 75 Mysticism to teleport others by default; if the companion does not meet either requirement, you cannot ask them to teleport. \n\nCompanions may be enabled to set their own marks or not.",
    variable = mwse.mcm.createTableVariable { id = "teleportMenu", table = config }
}

globalSettings:createOnOffButton {
    label = "NPC Marks",
    description = "Turn on or off the ability to ask companions to set their mark. Each individual companion has their own mark. Teleport Menu must be enabled and usable by the companion.",
    variable = mwse.mcm.createTableVariable { id = "npcMark", table = config }
}

globalSettings:createOnOffButton {
    label = "Train Mysticism",
    description = "Turn on or off additional Mysticism experience when the player is transporting others. The experience gain is minimal and increases with the number of companions transported by the player. Companions that transport themselves or use enchantment charges do not exercise the player's skill. \n\nHas no effect on the Teleport Menu.",
    variable = mwse.mcm.createTableVariable { id = "trainMyst", table = config }
}

local miscSettings = settings:createCategory("Misc. Settings")

miscSettings:createOnOffButton {
    label = "Play Teleport Sounds",
    description = "Toggle on or off teleportation sounds.",
    variable = mwse.mcm.createTableVariable { id = "playSound", table = config }
}

miscSettings:createOnOffButton {
    label = "Play Teleport Effects",
    description = "Toggle on or off teleportation particle effects.",
    variable = mwse.mcm.createTableVariable { id = "playEffect", table = config }
}

miscSettings:createOnOffButton {
    label = "Enable Messages",
    description = "Turn on or off companion teleportation messages.",
    variable = mwse.mcm.createTableVariable { id = "msgEnabled", table = config }
}

miscSettings:createOnOffButton {
    label = "Magicka Expanded Teleportation",
    description = "Toggle on or off support for Magicka Expanded's teleportation spell effects.",
    variable = mwse.mcm.createTableVariable { id = "mExpanded", table = config }
}

miscSettings:createOnOffButton {
    label = "Disable Teleport Menu Colors",
    description = "If this is turned on, all teleport menu text reverts to default text/selection colors.",
    variable = mwse.mcm.createTableVariable { id = "noColor", table = config }
}

miscSettings:createDropdown {
    label = "Debug Logging Level",
    description = "Set the log level.",
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

----Cost/Restriction Settings-------------------------------------------------------------------------------------------------------------
local costs = createPage("Costs/Restrictions")

local skillCosts = costs:createCategory("Skill Restrictions")

skillCosts:createOnOffButton {
    label = "Mysticism Skill Requirement",
    description = "Toggle on/off the Mysticism requirement for both Normal Teleportation and the Teleport Menu. \n\n(Normal Teleportation): If the requirement is not met by either the player or the companion, the companion will not be teleported with you unless a scroll or enchantment charge is used. \n\nIf this is on but neither player nor companion skill is set to be checked below, the companion will not be teleported with you unless you enable usage of scrolls or enchantment charges. Creatures will never meet this requirement unless they are Daedra.",
    variable = mwse.mcm.createTableVariable { id = "skillLimit", table = config }
}

skillCosts:createOnOffButton {
    label = "Check Player Skill",
    description = "Allows the player's Mysticism skill to count toward a successful teleport. Has no effect on the Teleport Menu.",
    variable = mwse.mcm.createTableVariable { id = "playerSkill", table = config }
}

skillCosts:createSlider {
    label = "Player Skill Requirement",
    description = "The Mysticism skill requirement needed for the player to transport companions alongside themselves. Has no effect on the Teleport Menu.",
    max = 200,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "playerSkillReq",
        table = config
    }
}

skillCosts:createOnOffButton {
    label = "Check Companion Skill",
    description = "Allows the companion's Mysticism skill to count toward a successful teleport. Creatures (including summoned creatures) do not contribute, unless they are Daedra. Has no effect on the Teleport Menu.",
    variable = mwse.mcm.createTableVariable { id = "npcSkill", table = config }
}

skillCosts:createSlider {
    label = "Companion Skill Requirement: Self",
    description = "The Mysticism skill requirement needed for each companion to transport themselves. (Normal Teleportation and Teleport Menu)",
    max = 200,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "npcSkillReqS",
        table = config
    }
}

skillCosts:createSlider {
    label = "Companion Skill Requirement: Others",
    description = "The Mysticism skill requirement needed for each companion to transport others. (Teleport Menu)",
    max = 200,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "npcSkillReqO",
        table = config
    }
}

local mgkCosts = costs:createCategory("Costs")

mgkCosts:createOnOffButton {
    label = "Enable Enchantment Charge Use",
    description = "Enable usage of additional enchantment charges before any magicka/scrolls are used. Companions only use enchantment charges when the player uses an enchantment to teleport, and only charges from that same item are used. \n\nEnchantments cannot be used in the Teleport Menu.",
    variable = mwse.mcm.createTableVariable { id = "useEnchant", table = config }
}

mgkCosts:createOnOffButton {
    label = "Magicka Requirement",
    description = "Toggle on/off magicka requirements for both Normal Teleportation and the Teleport Menu.  \n\nMagicka consumed will decrease with greater Mysticism skill. Companions that transport themselves/others use their own magicka and skill. \n\n(Normal Teleportation): If the companion doesn't have enough magicka, the player will cover the cost if they meet the skill requirement. If there are no skill requirements, only the player's magicka will be used to transport companions. The player loses magicka for each companion they transport themselves.",
    variable = mwse.mcm.createTableVariable { id = "magickaReq", table = config }
}

mgkCosts:createSlider {
    label = "Magicka Modifier",
    description = "The magicka requirement needed for the caster to transport themselves/others.  Greater Mysticism skill reduces this (up to 50% at skill 100, 100% at skill 200, 1 Magicka minimum). \n\n(Normal Teleportation): Companions only pay for their own transport if they have enough skill. The player loses magicka for each companion they transport themselves. If the companion tries to transport themselves but doesn't have enough magicka, they will use a scroll or be left behind. A player with enough magicka will cover the cost without using a scroll.",
    max = 200,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "magickaMod",
        table = config
    }
}

mgkCosts:createOnOffButton {
    label = "Enable Scroll Use",
    description = "Enable usage of scrolls only for when both you and your companion fail the Mysticism skill check or don't have enough magicka. Will use one scroll of the appropriate type from the player's inventory per companion that couldn't be transported through the use of Mysticism. \n\nIf no scrolls are left, the companion will be left behind. Using scrolls this way does not train the player's Mysticism. \n\nScrolls cannot be used in the Teleport Menu.",
    variable = mwse.mcm.createTableVariable { id = "useScroll", table = config }
}

mgkCosts:createOnOffButton {
    label = "Summons Bypass Requirements",
    description = "Enable to allow summoned creatures to teleport with you no matter what other requirements are set in place for both Normal Teleportation and the Teleport Menu. Summons transported this way do not train the player's Mysticism skill. \n\nOtherwise, summoned creatures are subject to the same requirements (skill checks, magicka cost, scroll use) as everyone else.",
    variable = mwse.mcm.createTableVariable { id = "smnFree", table = config }
}
