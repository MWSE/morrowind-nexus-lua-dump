local inMemConfig

local this = {}
this.configPath = "ashfall"
this.defaultConfig = require ("mer.ashfall.MCM.defaultConfig")
this.save = function(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(this.configPath, inMemConfig)
end

this.config = setmetatable({}, {
    __index = function(_, key)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.defaultConfig)
        return inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.defaultConfig)
        inMemConfig[key] = value
        mwse.saveConfig(this.configPath, inMemConfig)
    end
})

return this