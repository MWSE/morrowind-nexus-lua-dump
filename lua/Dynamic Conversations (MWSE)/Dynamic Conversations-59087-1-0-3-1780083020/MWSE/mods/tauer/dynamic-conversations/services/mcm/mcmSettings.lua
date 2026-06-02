---@type string
local configPath = "Dynamic Conversations"

--- Provides abstractions to retrieve and save mod settings
---@class mcmSettings
local this = {}

--- The current settings loaded from the MCM file
---@public
---@type settings
this.mcm = mwse.loadConfig(configPath, {
    enabled = true,
    conversationTimer = 45,
    conversationChance = 0.5,
    exteriorsOnly = false,
    enableAnimations = true,
    blacklistedNpcs = {},
    blacklistedCells = {},
    conversationDistance = 700,
    logLevel = "INFO",
}) --[[@as settings]]

--- Saves the current settings to the MCM file
---@public
function this.save()
    mwse.saveConfig(configPath, this.mcm)
end

return this
