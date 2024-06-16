local config  = require("gptts.config")
local GUI_ID_DialogMenu = tes3ui.registerID("MenuDialog")


local function increaseSpeech()
    local dialogMenu = tes3ui.findMenu(GUI_ID_DialogMenu)
    if (not dialogMenu) then return end
    tes3.mobilePlayer:exerciseSkill(25, (config.speechXP)/10)
end

local function init()
    event.register("infoResponse", increaseSpeech)
    print("Talking Trains Speechcraft: Initialized")
end

event.register("loaded", init)

event.register("modConfigReady", function()
    require("gptts.mcm")
    config = require("gptts.config")
end)
