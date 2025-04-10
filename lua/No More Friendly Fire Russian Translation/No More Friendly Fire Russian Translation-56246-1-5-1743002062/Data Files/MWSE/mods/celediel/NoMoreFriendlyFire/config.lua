local common = require("celediel.NoMoreFriendlyFire.common")

local currentConfig
local defaultConfig = {stopDamage = true, stopCombat = true, debugLevel = common.logLevels.no, ignored = {}}
local this = {}

this.getConfig = function()
    currentConfig = currentConfig or mwse.loadConfig(common.modConfig, defaultConfig)
    return currentConfig
end

return this
