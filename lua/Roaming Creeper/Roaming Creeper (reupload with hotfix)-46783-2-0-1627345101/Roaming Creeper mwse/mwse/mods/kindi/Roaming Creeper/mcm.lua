
local config = require("kindi.roaming creeper.config")

local EasyMCM = require("easyMCM.EasyMCM")

local template = EasyMCM.createTemplate {}
template.name = "Roaming Creeper"
template:saveOnClose("roaming_creeper", config)

local page =
    template:createSideBarPage {
    label = "Main",
    description = "Welcome to Roaming Creeper. \n\nCreeper will go around towns in Vvardenfell to trade wares and items with locals everyday. He now buys and sells more types of items including very rare ones. \n\nHe can be randomly found inside any Tradehouses, Inns or Taverns. Creeper will return to Ghorak Manor on every 1st day of the month. \n\n\n\n",
    noScroll = false
}

local general = page:createCategory("General")

local onoff =
    general:createOnOffButton {
    label = "Toggles the mod on or off",
    description = "When OFF, creeper will not roam and will stay at Ghorak Manor and his wares will not reset.",
    variable = EasyMCM.createTableVariable {id = "modActive", table = config},
    callback = function()
        if config.modActive == true then
            tes3.messageBox("Roaming Creeper is turned ON")
        else
            tes3.messageBox("Roaming Creeper is turned OFF")

        end
    end
}

local reveal =
	general:createButton{
	label = "Reveal the Creeper's current location",
	buttonText = "Reveal",
	description = "Don't use too much",
	callback = function () if not tes3.getReference("scamp_creeper") then return end tes3.messageBox(("Creeper is currently in %s"):format(tes3.getReference("scamp_creeper").cell)) end
	}


EasyMCM.register(template)


