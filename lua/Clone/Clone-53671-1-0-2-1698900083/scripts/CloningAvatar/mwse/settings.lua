local configPath = "clone"

local defaultConfig = {
    keybindClone = {
        keyCode = tes3.scanCode.k,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    }, 
}
local fconfig = require("Clone.scripts.CloningAvatar.config")
local infoText = fconfig.infoText
local config = mwse.loadConfig(configPath, defaultConfig)
local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Clone")
    local page = template:createPage()
    page:createCategory{
        label = string.format(infoText)
    }
    page.description = infoText
    local cSettings = page:createCategory("Settings")
    cSettings:createKeyBinder({
        label = "Clone Switch Keybind",
        description = "This key will open the menu to switch between clones, when you are in Avatar mode.",
        variable = mwse.mcm.createTableVariable{ id = "keybindClone", table = config },
        allowCombinations = true,
    })
	template:saveOnClose(configPath,config)
    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)
