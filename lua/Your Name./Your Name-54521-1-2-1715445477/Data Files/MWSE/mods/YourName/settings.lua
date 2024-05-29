local this = {}
this.modName = "Your Name."
this.configPath = "YourName"

---@class Config
local defaultConfig = {
    ---@class Config.Filtering
    filtering = {
        essential = true,
        corpse = true,
        guard = true,
        nolore = true,
        creature = true,
    },
    ---@class Config.Masking
    masking = {
        gender = true,
        race = true,
        fillUnknowns = true,
    },
    ---@class Config.Gameplay
    game = {
        skill = true,
    },
    ---@class Config.Development
    development = {
        logLevel = "INFO",
        logToConsole = false,
        test = false,
    }
}

---@return Config
function this.DefaultConfig()
    return table.deepcopy(defaultConfig)
end

return this
