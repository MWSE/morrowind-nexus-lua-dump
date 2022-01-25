local this = {}
this.configPath = "midnightOil"
local inMemConfig
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
}
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

--Returns if an object is blocked by the MCM
function this.getIsBlocked(obj)
    local config = this.getConfig()
    local mod = obj.sourceMod and obj.sourceMod:lower()
    return (
        config.blocked[obj.id] or
        config.blocked[mod]
    )
end

return this