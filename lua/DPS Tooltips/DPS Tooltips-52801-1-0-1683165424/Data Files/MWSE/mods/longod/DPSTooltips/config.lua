local this = {}

---@class Config
this.defaultConfig = {
    enable = true,
    minmaxRange = true,
    preDivider = false,
    postDivider = false,
    accurateDamage = true,
    maxDurability = true,
    -- maxFatigue = true,
    difficulty = false,
    breakdown = true,
    -- always or pressed key
    -- hitRate = false,
    -- armor = false,
    -- blocking = false,
    coloring = true,
    showIcon = true,
    logLevel = "INFO",
    unittest = false,
}
this.config = nil ---@type Config
this.configPath = "longod.DPSTooltips"

---@return Config
function this.Load()
    this.config = this.config or mwse.loadConfig(this.configPath, this.defaultConfig)
    return this.config
end

---@return Config
function this.Default()
    return table.deepcopy(this.defaultConfig)
end

return this
