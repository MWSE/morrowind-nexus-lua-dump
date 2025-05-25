-- gamestate.lua
local gamestate = {}

-- Paths
gamestate.SNAKEGAMEJSONPATH = "custom/snakeGameCellData.json"

-- Global state
gamestate.SnakeGame = {
    activePlayers = {},
    gameObjects = {},
    timers = {}
}

function gamestate.initGameState(pid)
    local cfg = SnakeGame.cfg
    local helpers = SnakeGame.helpers
    local playerName = string.lower(Players[pid].accountName)
    local cellDescription = cfg.roomCell

    if not logicHandler.IsCellLoaded(cellDescription) then
        logicHandler.LoadCell(cellDescription)
    end

    -- table to store players original quickKeys
    Players[pid].data.customVariables.original_quickKeys = {}
    --add quick keys to players inventory  and set them up in the proper quickKey slots
    local quickKeys = { "left", "down", "up", "right" }
    tes3mp.ClearQuickKeyChanges(pid)
    tes3mp.ClearInventoryChanges(pid)
    for i = 1, #quickKeys do
        -- gamestate.original_quickKeys[i] = tableHelper.deepCopy(Players[pid].data.quickKeys[i])
        Players[pid].data.customVariables.original_quickKeys[i] = Players[pid].data.quickKeys[i]
        tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
        tes3mp.AddItemChange(pid, "sg_" .. quickKeys[i], 1, -1, -1, "")
        tes3mp.AddQuickKey(pid, i, 0, "sg_" .. quickKeys[i])
    end
    tes3mp.SendInventoryChanges(pid, false, false)
    tes3mp.SendQuickKeyChanges(pid)


    --save player inventory
    Players[pid]:SaveInventory(packetReader.GetPlayerPacketTables(pid, "PlayerInventory"))

    -- Teleport the player to game location
    tes3mp.SetCell(pid, cellDescription)
    tes3mp.SetPos(pid, cfg.platformPosition.x, cfg.platformPosition.y, cfg.platformPosition.z + 1)
    tes3mp.SetRot(pid, helpers.degToRad(60), 0)
    tes3mp.SendCell(pid)
    tes3mp.SendPos(pid)

    --set player to levitate
    logicHandler.RunConsoleCommandOnPlayer(pid, "addspell sg_levitate", true)
    logicHandler.RunConsoleCommandOnPlayer(pid, "addspell sg_light", true)

    if gamestate.SnakeGame.activePlayers[playerName] then
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] stopping previous game from initGameState....")
        SnakeGame.gameLogic.stopGame(pid)
    end

    -- Make sure objects are initialized
    if not gamestate.SnakeGame.preCreatedObjects then
        if jsonInterface.load(gamestate.SNAKEGAMEJSONPATH) ~= nil then
            gamestate.SnakeGame.preCreatedObjects = jsonInterface.load(gamestate.SNAKEGAMEJSONPATH)
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] Loaded pre-created objects from " .. gamestate.SNAKEGAMEJSONPATH)
        else
            -- First time initialization
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] Objects not found, delete snakeGameCellData.json and " ..
                cfg.roomCell .. ".json and restart the server.")
            return
        end
    end

    -- Initialize game state variables
    gamestate.SnakeGame.activePlayers[playerName] = {
        snake = {},
        food = { x = 0, y = 0 },
        direction = "right",
        score = 0,
        gameOver = false,
        headIndex = nil,
        segmentIndices = {},
        foodIndex = nil,
        foodRefId = nil,
        usedBodyIndices = {}
    }

    -- Set up initial snake position
    local gameStateData = gamestate.SnakeGame.activePlayers[playerName]
    local centerX = math.floor(cfg.roomSize / 2)
    local centerY = math.floor(cfg.roomSize / 2)

    for i = 1, cfg.initialSnakeLength do
        table.insert(gameStateData.snake, { x = centerX - (i - 1), y = centerY })
    end

    -- Initialize game objects array for this player (only to track dynamic objects)
    gamestate.SnakeGame.gameObjects[playerName] = {}

    -- track the pre created head
    if gamestate.SnakeGame.preCreatedObjects.head then
        gameStateData.headIndex = gamestate.SnakeGame.preCreatedObjects.head.uniqueIndex

        -- Track this dynamic object
        table.insert(gamestate.SnakeGame.gameObjects[playerName], {
            uniqueIndex = gameStateData.headIndex,
            cell = cellDescription,
            type = "head"
        })
    else
        tes3mp.LogMessage(enumerations.log.ERROR,
            "[SnakeGame] Pre-created head not available, cannot start game")
        return
    end

    -- Place initial food using a pre-created food object
    if cfg.initFood then
        SnakeGame.gameLogic.placeFood(pid)

        if gamestate.SnakeGame.preCreatedObjects.food then
            -- Randomly select one of the food items
            local randomFoodIndex = math.random(1, #cfg.objects.food)
            local selectedFood = cfg.objects.food[randomFoodIndex]

            -- Find the matching pre-created food object
            local preCreatedFoodObject = nil
            for _, foodObj in ipairs(gamestate.SnakeGame.preCreatedObjects.food) do
                if foodObj.refId == selectedFood then
                    preCreatedFoodObject = foodObj
                    break
                end
            end

            if preCreatedFoodObject then
                local foodLocation = {
                    posX = cfg.roomPosition.x + (gameStateData.food.x * 16),
                    posY = cfg.roomPosition.y + (gameStateData.food.y * 16),
                    posZ = cfg.roomPosition.z + 0.5,
                    rotX = 0,
                    rotY = 0,
                    rotZ = 9
                }

                -- Special height adjustment for rotating_skooma
                if selectedFood == cfg.objects.food[1] then
                    foodLocation.posZ = foodLocation.posZ + cfg.rotating_skooma_height_offset
                end

                local uniqueIndex = preCreatedFoodObject.uniqueIndex

                if LoadedCells[cellDescription].data.objectData[uniqueIndex] then
                    LoadedCells[cellDescription].data.objectData[uniqueIndex].location = {
                        posX = foodLocation.posX,
                        posY = foodLocation.posY,
                        posZ = foodLocation.posZ,
                        rotX = foodLocation.rotX,
                        rotY = foodLocation.rotY,
                        rotZ = foodLocation.rotZ
                    }

                    helpers.ResendPlace(pid, uniqueIndex, cellDescription, true)
                    gameStateData.foodIndex = uniqueIndex
                    gameStateData.foodRefId = selectedFood

                    -- Track this dynamic object
                    table.insert(gamestate.SnakeGame.gameObjects[playerName], {
                        uniqueIndex = uniqueIndex,
                        cell = cellDescription,
                        type = "food"
                    })

                    tes3mp.LogMessage(enumerations.log.INFO,
                        "[SnakeGame] Placed food (" ..
                        selectedFood .. ") at (" .. gameStateData.food.x .. "," .. gameStateData.food.y .. ")")
                else
                    tes3mp.LogMessage(enumerations.log.ERROR,
                        "[SnakeGame] Pre-created food object not found in cell")
                end
            else
                tes3mp.LogMessage(enumerations.log.ERROR,
                    "[SnakeGame] Selected food " .. selectedFood .. " not found in pre-created objects")
            end
        else
            tes3mp.LogMessage(enumerations.log.ERROR,
                "[SnakeGame] Pre-created food not available")
        end
    end

    -- Apply the player control settings
    logicHandler.RunConsoleCommandOnPlayer(pid, "DisableVanityMode", false)
    logicHandler.RunConsoleCommandOnPlayer(pid, "DisablePlayerViewSwitch", false)
    logicHandler.RunConsoleCommandOnPlayer(pid, "PCForce1stPerson", false)
    logicHandler.RunConsoleCommandOnPlayer(pid, "TM", false)

    -- Start the game timer
    SnakeGame.gameLogic.startGameTimer(pid)

    tes3mp.MessageBox(pid, -1, "Snake Game Started! Use keys 1-4 to move the snake.\nleft down up right")

end

return gamestate
