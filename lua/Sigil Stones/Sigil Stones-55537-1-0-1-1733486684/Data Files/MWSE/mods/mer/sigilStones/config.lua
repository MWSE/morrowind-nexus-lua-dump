---@class SigilStones.Config
local config = {}

config.metadata = toml.loadFile("Data Files\\Sigil Stones-metadata.toml") --[[@as MWSE.Metadata]]

config.static = {}

---@class SigilStones.Config.MCM
local mcmDefault = {
    enabled = true,
    ---The log level for the mod. One of "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
    logLevel = "INFO",
}

---@type SigilStones.Config.MCM
config.mcm = mwse.loadConfig(config.metadata.package.name, mcmDefault)

config.save = function()
    mwse.saveConfig(config.metadata.package.name, config.mcm)
end

return config