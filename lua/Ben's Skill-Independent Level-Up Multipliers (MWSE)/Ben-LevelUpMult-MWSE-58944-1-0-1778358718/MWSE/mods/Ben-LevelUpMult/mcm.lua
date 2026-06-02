local common = require("Ben-LevelUpMult.common")
local config = require("Ben-LevelUpMult.config")
local util = require("Ben-LevelUpMult.util")
local mcmConfig = config.loadMcmConfig()

local function createHomePage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Home" })
    
    page.sidebar:createInfo({ text = 
        "Attributes chosen on level-up are increased by a fixed amount, regardless of skill increases."..
        " Set each attribute to its desired level-up multiplier on this page."
    })
    
    for i = 0, 7 do
    
        page:createSlider({
            label = util.capitalizeFirstLetter(tes3.attributeName[i]),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.attributeMults,
                id = i,
            }),
            min = 1,
            max = 10,
            step = 1,
            jump = 1,
            decimalPlaces = 0,
        })
    
    end
    
end

local function onModConfigReady()
    
    local defaultMcmConfig = config.getDefaultMcmConfig()
    
    local mainTemplate = mwse.mcm.createTemplate({ name = config.getModName() })
    mainTemplate.onClose = function() config.saveMcmConfig(mcmConfig) end
    mainTemplate:register()
    
    createHomePage(mainTemplate, defaultMcmConfig)
    
end

event.register(tes3.event.modConfigReady, onModConfigReady)