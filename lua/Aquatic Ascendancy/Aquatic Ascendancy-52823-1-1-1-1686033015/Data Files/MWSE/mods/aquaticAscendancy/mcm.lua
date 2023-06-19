local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("aquaticAscendancy.config")
local logger  = require("logging.logger")
local log     = logger.getLogger("Aquatic Ascendancy")

local modName = 'Aquatic Ascendancy';
local template = EasyMCM.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()




local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "                      ()Aquatic Ascendancy() \n\nThis mod allows Argonian players and NPCs to innately breathe underwater, swim faster, and rest underwater. \n\nOptionally, these benefits can also be given to all races."
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

----Settings----------------------------------------------------------------------------------------------------------

--Misc
--local settings = settings:createCategory("Settings")

settings:createOnOffButton {
    label = "Water Breathing",
    description = "Turn on or off Argonian water breathing.",
    variable = mwse.mcm.createTableVariable { id = "waterBreathing", table = config }
}

settings:createOnOffButton {
    label = "Underwater Resting",
    description = "Turn on or off Argonian underwater resting. \n\nArgonians can rest underwater, but other factors such as nearby enemies still prevent resting.",
    variable = mwse.mcm.createTableVariable { id = "restUnderwater", table = config }
}

settings:createOnOffButton {
    label = "Swift Swim",
    description = "Turn on or off Argonian swim speed bonus.",
    variable = mwse.mcm.createTableVariable { id = "swiftSwim", table = config }
}

settings:createSlider {
    label = "Swift Swim Value",
    description = "Set the value of Argonian swift swimming.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "swimValue",
        table = config
    }
}

settings:createOnOffButton {
    label = "Affect NPCs",
    description = "Turn on or off Argonian NPC bonuses. If this is turned on, Argonian NPCs will be affected by the above benefits.",
    variable = mwse.mcm.createTableVariable { id = "npcBenefits", table = config }
}

settings:createOnOffButton {
    label = "Argonians Only",
    description = "Turn on or off Argonian race requirement. If this is off, any race will be affected by the above benefits.",
    variable = mwse.mcm.createTableVariable { id = "onlyArgonians", table = config }
}

settings:createOnOffButton {
    label = "Affect Vampires",
    description = "Turn on or off Vampire bonuses. If this is on, vampires will breathe underwater if Water Breathing is on.\n\nVampires do not receive swim speed bonuses unless all races do.",
    variable = mwse.mcm.createTableVariable { id = "affectVampires", table = config }
}

settings:createDropdown {
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