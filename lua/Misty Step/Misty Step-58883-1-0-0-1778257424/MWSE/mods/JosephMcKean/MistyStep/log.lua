local constants = require("JosephMcKean.MistyStep.constants")
local config = require("JosephMcKean.MistyStep.config")
local log = mwse.Logger.new({
    modName = constants.MOD_NAME,
    logLevel = config.logLevel
})
return log
