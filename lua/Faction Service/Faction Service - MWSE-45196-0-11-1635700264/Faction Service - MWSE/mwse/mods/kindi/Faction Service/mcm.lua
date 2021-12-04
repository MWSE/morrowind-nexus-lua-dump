local config = require("kindi.faction service.config")
local EasyMCM = require("easyMCM.EasyMCM")
local pageDescription = "Factions services cannot be used for free. Now, players need to become a member and raise their ranks within the faction to use the services.\n\nGuild members that are present inside the building can check your eligibility for services."
local template = EasyMCM.createTemplate {}
template.name = "Faction Service"
template:saveOnClose("faction_service", config)


local services = {"barter", "spells", "training", "enchanting", "repair", "spellmaking", "bed"}

local page =
    template:createSideBarPage {
    label = "Main",
    description = pageDescription,
    noScroll = false
}

local general = page:createCategory("General")

local onoff =
    general:createOnOffButton {
    label = "Toggles the mod on or off",
    description = "Faction service mod on/off",
    variable = EasyMCM.createTableVariable {id = "modActive", table = config},
    callback = function()
        if config.modActive == true then
            tes3.messageBox("Faction Service is turned ON")
        else
            tes3.messageBox("Faction Service is turned OFF")

        end
    end
}

local rankDifference =
	general:createTextField{
	label = "Rank difference with speaker to use faction service",
	description = "Negative number(N): Must have N rank higher or equal to the speaker\n\nPositive number(N): At least N lower rank to the speaker",
	variable = EasyMCM.createTableVariable {id = "rankDiff", table = config},
	numbersOnly = true,
	callback = function () tes3.messageBox(config.rankDiff) end
	}



for _, service in pairs(services) do
    general:createYesNoButton {
    label = service:gsub("%a", string.upper, 1),
    description = service:gsub("%a", string.upper, 1),
    variable = EasyMCM.createTableVariable {id = service, table = config},
    callback = function()
            tes3.messageBox(service:gsub("%a", string.upper, 1) .." Service")
    end}
end
EasyMCM.register(template)


