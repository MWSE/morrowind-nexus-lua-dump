local name = "Cosmetic Overrides"
local config = mwse.loadConfig(name, {
    -- Initialize Settings
    name = name,
    logLevel = "ERROR",
    showMessages = true
}); ---@cast config table

return config
