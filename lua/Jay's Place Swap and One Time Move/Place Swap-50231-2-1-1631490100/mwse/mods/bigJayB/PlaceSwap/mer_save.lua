local inMemConfig

local this = {}
this.configPath = "placeswap"
this.defaultConfig = require("bigJayB.PlaceSwap.defaultConf")
this.config = setmetatable({
    save = function()
        mwse.log("[Jay's Place Swap & Move Away] saving config to json")
        mwse.saveConfig(this.configPath, inMemConfig)
    end
}, {
    __index = function(_, key)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.defaultConfig)
        return inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.defaultConfig)
        inMemConfig[key] = value
    end,
})

return this