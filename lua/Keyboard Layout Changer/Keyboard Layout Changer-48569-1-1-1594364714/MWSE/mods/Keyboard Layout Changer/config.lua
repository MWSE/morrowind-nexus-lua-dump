local common = require("Keyboard Layout Changer.common")

local this = {}

local currentConfig

this.default = {
    keyboardLayout = "qwerty"
}

function this.getConfig()
    currentConfig = currentConfig or mwse.loadConfig(common.configString, this.default)
    return currentConfig
end

return this
