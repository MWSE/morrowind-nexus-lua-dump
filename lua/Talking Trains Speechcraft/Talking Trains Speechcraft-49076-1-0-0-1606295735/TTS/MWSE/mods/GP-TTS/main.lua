local ttsConfigPath = "GP-TTS"
local ttsConfig = mwse.loadConfig(ttsConfigPath)
if not config then
    config = { }
end


local function increaseSpeech()
    if tes3.mobilePlayer then
        if ttsConfig.speechXP then
            tes3.mobilePlayer:exerciseSkill(25, (ttsConfig.speechXP)/10)
        end
    end
end

local function init()
    event.register("infoResponse", increaseSpeech)
    print("Talking Trains Speechcraft: Initialized")
end

event.register("initialized", init)

local function registerTTSModConfig()
    local EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Talking Trains Speechcraft")
    local page = template:createPage()
    local category = page:createCategory("Settings")
    template:saveOnClose(ttsConfigPath, ttsConfig)
    category:createSlider{
        label = "Speechcraft XP: ",
        description = "Changes the XP gain from each dialogue option clicked.",
        min = 0,
        max = 10,
        variable = EasyMCM.createTableVariable{id = "speechXP", table = ttsConfig,
            defaultSetting = ttsConfig.speechXP},
    }
    EasyMCM.register(template)
end
event.register("modConfigReady", registerTTSModConfig)
