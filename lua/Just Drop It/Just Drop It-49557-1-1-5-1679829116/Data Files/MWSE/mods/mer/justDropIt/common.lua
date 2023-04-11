local common = {}
local config = require("mer.justDropIt.config")

common.logger = require("logging.logger").new{
    name = "Just Drop It",
    logLevel = config.mcmConfig.logLevel
}

return common