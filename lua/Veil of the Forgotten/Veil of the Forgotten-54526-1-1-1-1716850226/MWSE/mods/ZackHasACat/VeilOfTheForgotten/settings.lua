local configPath = "zhac_votf"

local defaultConfig = {
    dropAtFeet = false,
    healthCaptureThreshold = 0.5,
}
local config = mwse.loadConfig(configPath, defaultConfig)
local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Veil of the Forgotten")
    local page = template:createSideBarPage({
        label = "Settings",
        -- This description will be displayed at the right panel if no component is moused over.
        description =
            "Veil of the Forgotten\n" ..
            "Version 1.0.0\n" ..
            "\n" ..
            "Veil of the Forgotten adds a quest, and a mechanic that allows you to capture creatures and people in 'temporal globes'.\n" ..
            "To begin, wait to have a dream with a vision, or visit the cave at the far southwest of the Grazelands.\n",
    })
    -- page:createCategory{
    --      label = string.format(infoText)
    --  }
    -- page.description = infoText
    local cSettings = page:createCategory("Settings")
    cSettings:createYesNoButton({
        label = "Drop at Feet",
        description =
        "If enabled, Temporal Globes will drop at the feet of the captured, if not, they will be added to your inventory.",
        variable = mwse.mcm.createTableVariable { id = "dropAtFeet", table = config }
    })
    cSettings:createPercentageSlider({
        label          = "Health Capture threshold",
        description    =
        "The percentage of health an actor must have expended to be captured. If it is at 10 percent, you'll have to have them under 10 percent to capture them initially.",
        variable       = mwse.mcm.createTableVariable { id = "healthCaptureThreshold", table = config },
        min            = 0,
        max            = 1,
        step           = 1,
        defaultSetting = 0.5
    })
    template:saveOnClose(configPath, config)
    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)

return config
