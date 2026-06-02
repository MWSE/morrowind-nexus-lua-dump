local config = require("Music Tweaks.config")

return mwse.Logger.new({
	modName = "Music Tweaks",
	level = config.logLevel,
	outputFile = config.enableSeparateLogFile and "Music Tweaks" or false,
})
