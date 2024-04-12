local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local gameConfig = config.getGameConfig()
local gameConfigUpdated = config.getGameConfigUpdated()

this = {}

this.onLoaded = function(e)
    
    if not gameConfig.unarmored.rebalanceEnabled then return end
    if not gameConfigUpdated.unarmored then return end
    gameConfigUpdated.unarmored = false
    
    common.log("--------------------------------------------------")
    common.log("Unarmored GMSTs")
    common.log("--------------------------------------------------")
    
    common.setGmsts(gameConfig.unarmored.gameSettings)
    
end

return this
