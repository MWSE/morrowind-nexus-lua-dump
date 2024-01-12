---@class MidnightOil.Config
local this = {}
this.configPath = "midnightOil"
local inMemConfig
---@class MidnightOil.Config.mcm
this.defaultValues = {
    enabled = true,
    toggleHotkey = {
        keyCode = tes3.scanCode.lShift
    },
    useVariance = true,
    varianceInMinutes = 30,
    dawnHour = 6,
    duskHour = 20,
    merchants = {},
    settlementsOnly = true,
    staticLightsOnly = true,
    dungeonLightsOff = true,
    logLevel = "INFO",
    ---A list of cells to NOT turn lights off for.
    ---@type table<string, boolean>
    cellBlacklist = {
        ["Molag Mar, Waistworks"] = true
    }
}
---@return MidnightOil.Config.mcm
function this.getConfig()
    inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.defaultValues)
    return inMemConfig
end
function this.saveConfig(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(this.configPath, newConfig)
end
function this.saveConfigValue(key, val)
    local config = this.getConfig()
    if config then
        config[key] = val
        mwse.saveConfig(this.configPath, config)
    end
end


return this