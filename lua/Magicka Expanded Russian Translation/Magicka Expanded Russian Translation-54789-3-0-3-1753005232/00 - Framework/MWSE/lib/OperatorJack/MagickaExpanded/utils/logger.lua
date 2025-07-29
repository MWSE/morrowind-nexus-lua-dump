local logger = require("logging.logger")
local config = require("OperatorJack.MagickaExpanded.config")
return logger.getLogger("Magicka Expanded") or
           logger.new {name = "Magicka Expanded", logLevel = config.logLevel}
