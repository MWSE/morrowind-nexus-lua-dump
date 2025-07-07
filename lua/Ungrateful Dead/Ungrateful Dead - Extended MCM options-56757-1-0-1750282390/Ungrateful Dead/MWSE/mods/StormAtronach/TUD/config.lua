-- Set up the configuration
local default_config = {
    name                    = "Ungrateful Dead",
    logLevel               = "error",
    enabled                 = true,
    blessingsEnabled        = true,
    blessingsChance         = 100, -- 100% chance means always a blessing
    magnitudeVarEnabled     = true,
    magnitudeVar            = 0, -- 0% variation means no variation
    duration                = 600, -- 10 minutes
}
local config        = mwse.loadConfig("sa_TUD_config", default_config) ---@cast config table
config.fileName     = "sa_TUD_config"
config.default      = default_config

return config