local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local gameConfig = config.getGameConfig()
local gameConfigUpdated = config.getGameConfigUpdated()

local function onLoaded()
    
    if not gameConfigUpdated.unarmored then return end
    gameConfigUpdated.unarmored = false
    
    common.log("--------------------------------------------------")
    common.log("Unarmored GMSTs")
    common.log("--------------------------------------------------")
    
    common.setGmsts(gameConfig.unarmored.gameSettings)
    
end

local function onInitialized()
    
    if not gameConfig.shared.modEnabled then return end
    if not gameConfig.unarmored.rebalanceEnabled then return end
    
    event.register(tes3.event.loaded, onLoaded, { priority = config.eventPriority.loaded.unarmored })
    
end

event.register(tes3.event.initialized, onInitialized, { priority = config.eventPriority.initialized.unarmored })
