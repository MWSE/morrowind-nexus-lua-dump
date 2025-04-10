local logger = require("logging.logger")
local config = require("DremoraModelRandomizer.config")

local log = logger.new({
    name = "Dremora Model Randomizer",
    logLevel = config.logLevel,
    logToConsole = false,
    includeTimestamp = false,
})

return log
