---@class RCME.Config
local config = {}

---Table of registered buttons
---@type table<string, {closeButton: string}>
config.registeredButtons = {}

config.metadata = toml.loadMetadata("Right Click Menu Exit")

---@class RCME.Config.MCM
local mcmDefault = {
    ---Enable right click to exit menus
    enableRightClickExit = true,
    ---The log level for the mod. One of "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
    logLevel = "INFO",
    ---Enable "Menu Click" sound when exiting a menu
    enableClickSound = true,
    ---Re-open the inventory menu if it was open when closing another menu
    reopenInventory = true,
}

---@type RCME.Config.MCM
config.mcm = mwse.loadConfig(config.metadata.package.name, mcmDefault)

config.save = function()
    mwse.saveConfig(config.metadata.package.name, config.mcm)
end

return config