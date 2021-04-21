local common = require("More Choppin Axes.common")

local currentConfig = nil

local this = {}

this.default = {
    enabled = true,
    fixType = common.fixTypes.swap,
    logLevel = common.logLevels.small
}

function this.getConfig()
    currentConfig = currentConfig or mwse.loadConfig(common.configString, this.default)
    return currentConfig
end

function this.saveConfig(config)
    currentConfig = config
    mwse.saveConfig(common.configString, config)
end

return this
