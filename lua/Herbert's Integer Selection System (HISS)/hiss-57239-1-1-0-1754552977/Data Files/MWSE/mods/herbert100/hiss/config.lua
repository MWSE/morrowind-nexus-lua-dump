local log = mwse.Logger.new()

local config = mwse.loadConfig(
	log.modName,
	require("herbert100.hiss.config.default")
) --[[@as herbert.HISS.Config]]

log:setLevel(config.log_level)
log("updated logging level to %q", log:getLevelString())
return config
