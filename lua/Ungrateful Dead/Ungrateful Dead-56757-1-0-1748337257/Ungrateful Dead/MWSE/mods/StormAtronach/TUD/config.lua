-- Set up the configuration
local default_config = {
    log_level               = "ERROR",
    enabled                 = true,
    duration              = 600, -- 10 minutes
}
local config      = mwse.loadConfig("sa_TUD_config", default_config) ---@cast config table
config.confPath    = "sa_TUD_config"

return { config = config, default_config = default_config }