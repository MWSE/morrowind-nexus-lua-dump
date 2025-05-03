local logger = require("logging.logger")
local config = require("animationBlending.config")

local log = logger.new({
    name = "Animation Blending",
    logLevel = config.logLevel,
    logToConsole = false,
    includeTimestamp = false,
})

return log
