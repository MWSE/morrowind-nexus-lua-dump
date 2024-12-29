local defaultConfig = {
    maxHeight = 480,
    positionVertical = 0.0,
}
local configPath = "More Reasonable Inventory Portrait"
local config = mwse.loadConfig(configPath, defaultConfig)

--- @param e uiActivatedEventData
local function updatePortrait(e)
    local portrait = e.element:findChild("MenuInventory_character_layout")
    portrait.maxHeight = config.maxHeight
    portrait.parent.childAlignY = config.positionVertical
end
event.register(tes3.event.uiActivated, updatePortrait, { filter = "MenuInventory" })


local function registerModConfig()
    local template = mwse.mcm.createTemplate{
        name = configPath,
        config = config,
    }

    template:register()
    template:saveOnClose(configPath, config)
    local page = template:createPage{ label = "Settings" }

    page:createInfo{
        label = configPath,
        text = "Version 1.1.0\nCreated by Pete Goodfellow\non 27 Dec 2024"
    }

    page:createSlider{
        label = "Max Height",
        configKey = "maxHeight",
        min = 120,
        max = 800,
        step = 10,
        jump = 10,
    }

    page:createPercentageSlider{
        label = "Vertical Position",
        configKey = "positionVertical",
    }

    page:createInfo{
        text = "Restart the game or load a save to see the effect.",
    }
end
event.register(tes3.event.modConfigReady, registerModConfig)