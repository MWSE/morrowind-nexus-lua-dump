local settings = require("YourName.settings")
local config = nil ---@type Config

---@return Config
local function Load()
    config = config or mwse.loadConfig(settings.configPath, settings.DefaultConfig())
    return config
end

return Load()
