local config = require("kindi.signpost fast travel.config")

local EasyMCM = require("easyMCM.EasyMCM")

local template = EasyMCM.createTemplate {}
template.name = "Signpost Fast Travel"
template:saveOnClose("signpost_travel", config)

local page =
    template:createSideBarPage {
    label = "Main",
    description = "Signpost Fast Travel. Enjoy!\n\nSet travel point priority:\nTravel = Silt Strider/Ship Arrival Point\nDivine = Divine Intervention Point\nAlmsivi = Almsivi Intervention Point\nPreset = Preset location\n\n",
    noScroll = false
}

local general = page:createCategory("General")

local onoff =
    general:createOnOffButton {
    label = "Toggles the mod on or off",
    description = "Toggles the mod on or off",
    variable = EasyMCM.createTableVariable {id = "modActive", table = config},
    callback = function()
        if config.modActive == true then
            --tes3.messageBox("Signpost Fast Travel is turned ON")
        else
            --tes3.messageBox("Signpost Fast Travel is turned OFF")
        end
    end
}

local debug = general:createOnOffButton{
    label = "Toggle debug mode",
    description = "Debugging purposes only.",
    variable = EasyMCM.createTableVariable {
        id = "debug",
        table = config
    },
    callback = function()
        if config.debug == true then
            --tes3.messageBox("Debug is turned ON")
        else
            --tes3.messageBox("Debug is turned OFF")
        end
    end
}

local stats = general:createYesNoButton{
    label = "Show journey statistics",
    description = "When you reached your destination a summary of the journey will be presented to you.",
    variable = EasyMCM.createTableVariable {
        id = "showStats",
        table = config
    },
    callback = function()
        if config.showStats == true then
            --tes3.messageBox("Show journey summary")
        else
            --tes3.messageBox("No journay summary")
        end
    end
}

local game = page:createCategory("Game")

for i = 1, 4 do
    local def = "travelTo" .. i
    game:createDropdown {
        label = string.format("Travel Point %s", i),
        variable = EasyMCM.createTableVariable {id = string.format("travelTo%s", i), table = config},
        description = string.format("Travel Point %s", i),
        defaultSetting = config[def],
        options = {
            {label = "Travel", value = "TravelMarker"},
            {label = "Almsivi", value = "TempleMarker"},
            {label = "Divine", value = "DivineMarker"},
            {label = "Preset", value = "Preset"}
        },
        callback = function()
        end
    }
end

local confirm =
    game:createYesNoButton {
    label = "Show confirmation before traveling?",
    description = "Opens a confirmation box before traveling",
    variable = EasyMCM.createTableVariable {id = "showConfirm", table = config},
    callback = function()
        if config.showConfirm == true then
            --tes3.messageBox("Confirm before traveling")
        else
            config.extraRealism = false
            --tes3.messageBox("No confirmation")
        end
        local MCMModList = tes3ui.findMenu("MWSE:ModConfigMenu").children

        for child in table.traverse(MCMModList) do
            if child.text == "Signpost Fast Travel" then
                child:triggerEvent("mouseClick")
            end
        end
    end
}

local combatDeny =
    game:createYesNoButton {
    label = "Travelling is forbidden during combat?",
    description = "Signpost Fast travel cannot be used while in combat\n\n",
    variable = EasyMCM.createTableVariable {id = "combatDeny", table = config},
    callback = function()
        if config.combatDeny == true then
            --tes3.messageBox("No fast travel during combat")
        else
            --tes3.messageBox("Fast travel anytime")
        end
    end
}

local timeAdvance =
    game:createYesNoButton {
    label = "Travelling advances time?",
    description = "Advance time upon arrival base on distance travelled\n\n*Takes into account player speed",
    variable = EasyMCM.createTableVariable {id = "timeAdvance", table = config},
    callback = function()
        if config.timeAdvance == true then
            --tes3.messageBox("Travel advances time")
        else
            config.extraRealism = false
            --tes3.messageBox("Do not advance time")
        end
        local MCMModList = tes3ui.findMenu("MWSE:ModConfigMenu").children

        for child in table.traverse(MCMModList) do
            if child.text == "Signpost Fast Travel" then
                child:triggerEvent("mouseClick")
            end
        end
    end
}

local penalty =
    game:createYesNoButton {
    label = "Travelling reduces fatigue and health?",
    description = "Deducts fatigue and health upon arrival base on distance travelled\n\n*Cannot cause death",
    variable = EasyMCM.createTableVariable {id = "penalty", table = config},
    callback = function()
        if config.penalty == true then
            --tes3.messageBox("Travel with penalty")
        else
            config.extraRealism = false
            --tes3.messageBox("Travel without penalty")
        end
        local MCMModList = tes3ui.findMenu("MWSE:ModConfigMenu").children

        for child in table.traverse(MCMModList) do
            if child.text == "Signpost Fast Travel" then
                child:triggerEvent("mouseClick")
            end
        end
    end
}

local bringfriends =
    game:createYesNoButton {
    label = "Followers travel together?",
    description = "Nearby followers will travel together",
    variable = EasyMCM.createTableVariable {id = "bringFriends", table = config},
    callback = function()
        if config.bringFriends == true then
            --tes3.messageBox("Followers travel together")
        else
            --tes3.messageBox("Followers do not travel together")
        end
    end
}

local extraRealism =
    game:createYesNoButton {
    label = "Reckless and Cautious travelling",
    description = "Add reckless and cautious travelling. Some of the above options must be active.\n\nReckless: \nTravel faster\nTrain athletics skill\nHealth and fatigue reduced\nAcquire a random disease\nLose a certain amount of gold\n\nCautious: \nTravel slower\nTrain sneak skill\nHealth and fatigue restored\nAcquire a random disease\nLose a certain amount of gold\n\nThe chance to catch a disease and lose gold depends on the distance travelled and the mode of travel\nLose 5% of gold carried",
    variable = EasyMCM.createTableVariable {id = "extraRealism", table = config},
    callback = function()
        if config.extraRealism == true then
            config.showConfirm = true
            config.penalty = true
            config.timeAdvance = true
            --tes3.messageBox("Extra realism mode")
        else
            --tes3.messageBox("Normal mode")
        end
        local MCMModList = tes3ui.findMenu("MWSE:ModConfigMenu").children

        for child in table.traverse(MCMModList) do
            if child.text == "Signpost Fast Travel" then
                child:triggerEvent("mouseClick")
            end
        end
    end
}

EasyMCM.register(template)
