local config = require("kindi.Cursed Item Adjuster.config")
local EasyMCM = require("easyMCM.EasyMCM")

local summoningTypeDetail =
    {"[Matching]:\nThis will summon a daedra matching the daedric prince, ie. Sheogorath will summon a Golden Saint",
     "[Randomised]:\nThis will summon a random daedra", 
     "[Item Value]:\nSummon a daedra based on the cursed item's worth\n Less than 100 gold = Lesser Daedra\n From 100 to 250 gold = Greater Daedra \n More than 250 gold = Powerful Daedra",
     "[Nothing]:\nPicking up a cursed item will not summon a hostile daedra",
     "[Default]:\nOriginal game behaviour"}

local template =
    EasyMCM.createTemplate {
    name = "Cursed Item Adjuster",
    onClose = function()
        mwse.saveConfig("cursed_item_adjuster_kindi", config)
    end
}

local page =
    template:createSideBarPage {
    label = "Main",
    description = "Welcome to Cursed Item Adjuster\n\nHover over the options for more details",
    noScroll = false
}

local general = page:createCategory("General")

local onoff =
    general:createOnOffButton {
    label = "Toggle the mod status",
    description = "",
    variable = EasyMCM.createTableVariable {id = "modActive", table = config},
    callback = function()
        if config.modActive == true then
            tes3.messageBox("Cursed Item Adjuster is turned ON")
        else
            tes3.messageBox("Cursed Item Adjuster is turned OFF")

        end
    end
}

local debug =
    general:createOnOffButton {
    label = "Toggle debug mode",
    description = "Debugging purposes only. Shows mod activity",
    variable = EasyMCM.createTableVariable {id = "debug", table = config},
    callback = function()
        if config.modActive == true then
            tes3.messageBox("Debug is turned ON")
        else
            tes3.messageBox("Debug is turned OFF")

        end
    end
}

general:createDropdown {
    label = "What type of summon?",
    variable = EasyMCM.createTableVariable {id = "summonType", table = config},
    description = "Adjust how a cursed item summoning should be\n\n"..table.concat(summoningTypeDetail, "\n\n"),
    defaultSetting = config.summonType,
    options = {
        {label = "Matching", value = "Matching"}, 
        {label = "Randomised", value = "Randomised"}, 
        {label = "Item Value", value = "Item Value"}, 
        {label = "Default", value = "Default"}, 
        {label = "Nothing", value = "Nothing"}
    },
    callback = function()
        tes3.messageBox(config.summonType)
    end
}

local debug =
    general:createYesNoButton {
    label = "Show summon VFX?",
    description = "Similar to a conjuring spell VFX",
    variable = EasyMCM.createTableVariable {id = "summonVFX", table = config},
    callback = function()
        if config.summonVFX == true then
            tes3.messageBox("Summon VFX is turned ON")
        else
            tes3.messageBox("Summon VFX is turned OFF")

        end
    end
}

EasyMCM.register(template)


