local constants = require("Wisp.ImprovedMainMenu.common.constants")
local logger    = require("logging.logger")

local this = {}

this.log = logger.new{
	name     = "Improved Main Menu",
	logLevel = constants.logLevels.trace
}

return this