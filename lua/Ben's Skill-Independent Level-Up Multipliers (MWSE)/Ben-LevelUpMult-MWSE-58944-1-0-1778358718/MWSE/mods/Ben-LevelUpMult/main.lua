require("Ben-LevelUpMult.mcm")
local common = require("Ben-LevelUpMult.common")
local config = require("Ben-LevelUpMult.config")
local util = require("Ben-LevelUpMult.util")
local gameConfig = config.getGameConfig()

local function onPreLevelUp(e)
    
    -- levelupsPerAttribute is 1-based
    -- gameConfig.attributeMults is 0-based
    for key, _ in pairs(tes3.mobilePlayer.levelupsPerAttribute) do
        tes3.mobilePlayer.levelupsPerAttribute[key] = gameConfig.attributeMults[key - 1]
    end
    
end

local function onLoaded(e)
    
    common.setGmsts(gameConfig.gameSettings)
    
end

local function onInitialized(e)
    
    event.register(tes3.event.loaded, onLoaded, { priority = -10 })
    event.register(tes3.event.preLevelUp, onPreLevelUp, { priority = -10 })
    
end

event.register(tes3.event.initialized, onInitialized, { priority = -10 })
