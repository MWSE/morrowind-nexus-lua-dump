
-- Battle Royale game mode by testman
-- v0.7
-- for TES3MP 0.7.0-alpha

-- TODO: find a decent name
testBR = {}

testBR.scriptName = "TES3MP-Battle-Royale"

-- used for match IDs and for RNG seed
time = require("time")

-- used for generation of random numbers
math.randomseed(os.time())

-- import essay - https://www.barnorama.com/wp-content/uploads/2012/09/0113.jpg
-- load order of these is important
DataManager = require("custom/tes3mp-battle-royale/dependencies/DataManager/main")
PlayerLobby = require("custom/tes3mp-battle-royale/dependencies/PlayerLobby/main")
ContainerFramework = require("custom/tes3mp-battle-royale/dependencies/ContainerFramework/main")
DropFramework = require("custom/tes3mp-battle-royale/dependencies/DropFramework/main")
FullLoot = require("custom/tes3mp-battle-royale/dependencies/FullLoot/main")
brConfig = require("custom/tes3mp-battle-royale/BRConfig")
brDebug = require("custom/tes3mp-battle-royale/BRDebug")
matchLogic = require("custom/tes3mp-battle-royale/game_logic/matchLogic")
playerLogic = require("custom/tes3mp-battle-royale/game_logic/playerLogic")
mapLogic = require("custom/tes3mp-battle-royale/game_logic/mapLogic")
lobbyLogic = require("custom/tes3mp-battle-royale/game_logic/lobbyLogic")
brCustomHandlers = require("custom/tes3mp-battle-royale/BRCustomHandlers")
brCustomValidators = require("custom/tes3mp-battle-royale/BRCustomValidators")
brCustomCommands = require("custom/tes3mp-battle-royale/BRCustomCommands")

-- ========================= MAIN =========================

-- check the config for what type of matchmaking process is used and starts the process if needed
testBR.OnServerPostInit = function()
    -- if debug is above level 1 then write it in log
    brDebug.Log(1, "Running server in debug mode. DebugLevel: " .. tostring(brConfig.debugLevel))
    
    debug.DeleteExteriorCellData()
    
    -- make DataManager file names more readable
    DataManager.configPrefix = "custom/config_"
    DataManager.dataPrefix = "custom/data_"

    -- set config files from dependencies to reflect values from main config file
    PlayerLobby.config.cell = brConfig.lobbyCell
    PlayerLobby.config.pos = brConfig.lobbyCoordinates
    DataManager.saveData(PlayerLobby.scriptName,PlayerLobby.config)
    
    if brConfig.automaticMatchmaking then
        lobbyLogic.StartMatchProposal()
    end
    
end


return testBR

