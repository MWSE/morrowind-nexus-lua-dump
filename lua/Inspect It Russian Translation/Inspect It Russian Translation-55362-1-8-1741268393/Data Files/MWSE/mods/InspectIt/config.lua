local settings = require("InspectIt.settings")
local config = nil ---@type Config

---@return Config
local function Load()
    config = config or mwse.loadConfig(settings.configPath, settings.defaultConfig)
    return config
end

return Load()
