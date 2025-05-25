--[[
Snake Game for TES3MP
Main module

installation instructions

place the snake folder into your tes3mp/server/scripts/custom folder

add this line to your tes3mp/server/scripts/customscripts.lua file:

require("custom.snake.main")

]]

-- Load all the components
SnakeGame = {}
SnakeGame.cfg = require("custom.snake.config")
SnakeGame.helpers = require("custom.snake.helpers")
SnakeGame.gamestate = require("custom.snake.gamestate")
SnakeGame.gameLogic = require("custom.snake.gamelogic")
SnakeGame.handlersAndValidators = require("custom.snake.handlersAndValidators")
SnakeGame.serverPostInit = require("custom.snake.serverPostInit")
SnakeGame.leaderboard = require("custom.snake.leaderboard")

SnakeGame.logging_enabled = false

-- Update game logic
function UpdateGame(pid)
    local playerName = string.lower(Players[pid].accountName)
    local gameState = SnakeGame.gamestate.SnakeGame.activePlayers[playerName]
    local cellDescription = SnakeGame.cfg.roomCell

    if not gameState or gameState.gameOver then
        tes3mp.LogMessage(enumerations.log.ERROR, "[SnakeGame] No game state or game over for " .. playerName)
        return
    end

    -- Initialize segment indices if needed
    gameState.segmentIndices = gameState.segmentIndices or {}

    -- Track previous direction for rotation optimization
    gameState.previousDirection = gameState.previousDirection or gameState.direction
    local directionChanged = gameState.previousDirection ~= gameState.direction

    -- Initialize snake array if needed
    gameState.snake = gameState.snake or {}

    if #gameState.snake == 0 then
        tes3mp.LogMessage(enumerations.log.ERROR, "[SnakeGame] No snake data, cannot update game")
        return
    end

    -- Check if segment indices are missing but should exist
    -- This handles first moves or if somehow indices become desynchronized
    if #gameState.snake > 1 and next(gameState.segmentIndices) == nil then
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Segment indices missing, initializing for initial snake length " .. #gameState.snake)

        -- For the initial state, we need to set up indices for all the body segments
        -- but at this point they probably don't exist in gameObjects yet
        -- So we'll add body segments one by one
        for i = 2, #gameState.snake do
            -- Find an unused body segment from pre-created ones
            local bodySegmentIndex = nil
            for _, bodyObj in ipairs(SnakeGame.gamestate.SnakeGame.preCreatedObjects.body) do
                local uniqueIndex = bodyObj.uniqueIndex

                -- Check if this segment is not already in use
                local isUsed = false
                for pos, index in pairs(gameState.segmentIndices) do
                    if index == uniqueIndex then
                        isUsed = true
                        break
                    end
                end

                if not isUsed then
                    bodySegmentIndex = uniqueIndex
                    gameState.segmentIndices[i] = bodySegmentIndex

                    -- Place the body segment at its corresponding snake position
                    local bodyPos = gameState.snake[i]
                    local bodyLocation = {
                        posX = SnakeGame.cfg.roomPosition.x + (bodyPos.x * 16),
                        posY = SnakeGame.cfg.roomPosition.y + (bodyPos.y * 16),
                        posZ = SnakeGame.cfg.roomPosition.z + 9.3,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    }

                    if LoadedCells[cellDescription].data.objectData[bodySegmentIndex] then
                        LoadedCells[cellDescription].data.objectData[bodySegmentIndex].location = {
                            posX = bodyLocation.posX,
                            posY = bodyLocation.posY,
                            posZ = bodyLocation.posZ,
                            rotX = bodyLocation.rotX,
                            rotY = bodyLocation.rotY,
                            rotZ = bodyLocation.rotZ
                        }

                        -- Always skip rotation for body segments
                        SnakeGame.helpers.ResendPlace(pid, bodySegmentIndex, cellDescription, true, true)

                        -- Add to tracked objects
                        table.insert(SnakeGame.gamestate.SnakeGame.gameObjects[playerName], {
                            uniqueIndex = bodySegmentIndex,
                            cell = cellDescription,
                            type = "body"
                        })

                        if SnakeGame.logging_enabled then
                            tes3mp.LogMessage(enumerations.log.INFO,
                                "[SnakeGame] Initialized segment index " .. i .. " to " .. bodySegmentIndex ..
                                " at position (" .. bodyPos.x .. "," .. bodyPos.y .. ")")
                        end

                        break
                    else
                        tes3mp.LogMessage(enumerations.log.ERROR,
                            "[SnakeGame] Body segment " .. bodySegmentIndex .. " not found in cell during initialization")
                    end
                end
            end

            if not gameState.segmentIndices[i] then
                tes3mp.LogMessage(enumerations.log.ERROR,
                    "[SnakeGame] Failed to initialize segment index " .. i)
            end
        end

        -- Debug output of initialized segment indices
        if SnakeGame.logging_enabled then
            local segmentString = "Initialized segment indices: "
            for i, idx in pairs(gameState.segmentIndices) do
                segmentString = segmentString .. i .. "=" .. idx .. ", "
            end
            tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] " .. segmentString)
        end
    end

    local head = gameState.snake[1]
    if SnakeGame.logging_enabled then
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Updating game for " .. playerName ..
            " - Direction: " .. gameState.direction ..
            ", Snake length: " .. #gameState.snake ..
            ", Head position: (" .. head.x .. "," .. head.y .. ")")
    end

    -- Calculate new head position
    local newHead = { x = head.x, y = head.y }
    if gameState.direction == "up" or gameState.direction == "raise" then
        newHead.y = newHead.y + 1
    elseif gameState.direction == "down" or gameState.direction == "lower" then
        newHead.y = newHead.y - 1
    elseif gameState.direction == "left" then
        newHead.x = newHead.x - 1
    elseif gameState.direction == "right" then
        newHead.x = newHead.x + 1
    end

    if SnakeGame.logging_enabled then
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] New head position: (" .. newHead.x .. "," .. newHead.y .. ")")
    end

    -- Check wall collisions
    if newHead.x < 0 or newHead.x >= SnakeGame.cfg.roomSize or
        newHead.y < 0 or newHead.y >= SnakeGame.cfg.roomSize then
        tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Wall collision detected")
        SnakeGame.gameLogic.gameOver(pid, "You hit a wall!")
        return
    end

    -- Check self collisions
    for i = 2, #gameState.snake do
        if newHead.x == gameState.snake[i].x and newHead.y == gameState.snake[i].y then
            tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Self collision detected")
            SnakeGame.gameLogic.gameOver(pid, "You hit yourself!")
            return
        end
    end

    -- Check if we're eating food
    local ateFood = (SnakeGame.cfg.foodCollision and newHead.x == gameState.food.x and newHead.y == gameState.food.y) or
        (SnakeGame.cfg.initFood and not gameState.foodIndex)

    -- Move snake head to new position
    local headRotation = SnakeGame.cfg.headRotations[gameState.direction]
    local headLocation = {
        posX = SnakeGame.cfg.roomPosition.x + (newHead.x * 16),
        posY = SnakeGame.cfg.roomPosition.y + (newHead.y * 16),
        posZ = SnakeGame.cfg.roomPosition.z + 9.5,
        rotX = math.rad(headRotation.rotX),
        rotY = math.rad(headRotation.rotY),
        rotZ = math.rad(headRotation.rotZ)
    }

    if LoadedCells[cellDescription].data.objectData[gameState.headIndex] then
        LoadedCells[cellDescription].data.objectData[gameState.headIndex].location = {
            posX = headLocation.posX,
            posY = headLocation.posY,
            posZ = headLocation.posZ,
            rotX = headLocation.rotX,
            rotY = headLocation.rotY,
            rotZ = headLocation.rotZ
        }

        -- Only send rotation update if direction changed
        local skipRotate = not directionChanged
        SnakeGame.helpers.ResendPlace(pid, gameState.headIndex, cellDescription, true, skipRotate)

        if SnakeGame.logging_enabled then
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] Moved head to (" .. newHead.x .. "," .. newHead.y .. ")")
        end
    else
        tes3mp.LogMessage(enumerations.log.ERROR,
            "[SnakeGame] Head object not found, cannot update game")
        return
    end

    -- Get a body segment for the position behind the head (the old head position)
    local bodySegmentIndex

    -- If not growing and snake is longer than 1, use the tail segment
    if not ateFood and #gameState.snake > 1 then
        local tailPos = #gameState.snake
        if gameState.segmentIndices[tailPos] then
            bodySegmentIndex = gameState.segmentIndices[tailPos]

            if SnakeGame.logging_enabled then
                tes3mp.LogMessage(enumerations.log.INFO,
                    "[SnakeGame] Reusing tail segment " .. bodySegmentIndex .. " at position " .. tailPos)
            end

            -- Remove tail from snake since we're moving it
            table.remove(gameState.snake)

            -- Remove the index from the segment indices map
            gameState.segmentIndices[tailPos] = nil
        else
            tes3mp.LogMessage(enumerations.log.WARN,
                "[SnakeGame] No tail segment index found at position " .. tailPos .. ", using new segment")
        end
    end

    -- If we need a new segment (either growing or couldn't find tail segment)
    if not bodySegmentIndex then
        -- Find an unused body segment from pre-created ones
        for i, bodyObj in ipairs(SnakeGame.gamestate.SnakeGame.preCreatedObjects.body) do
            local uniqueIndex = bodyObj.uniqueIndex

            -- Check if this segment is not already used in the snake
            local isUsed = false
            for _, index in pairs(gameState.segmentIndices) do
                if index == uniqueIndex then
                    isUsed = true
                    break
                end
            end

            if not isUsed then
                bodySegmentIndex = uniqueIndex

                if SnakeGame.logging_enabled then
                    tes3mp.LogMessage(enumerations.log.INFO,
                        "[SnakeGame] Using new body segment " .. bodySegmentIndex)
                end

                -- Track in game objects if not already there
                local isTracked = false
                for _, obj in ipairs(SnakeGame.gamestate.SnakeGame.gameObjects[playerName]) do
                    if obj.uniqueIndex == uniqueIndex then
                        isTracked = true
                        break
                    end
                end

                if not isTracked then
                    table.insert(SnakeGame.gamestate.SnakeGame.gameObjects[playerName], {
                        uniqueIndex = bodySegmentIndex,
                        cell = cellDescription,
                        type = "body"
                    })

                    if SnakeGame.logging_enabled then
                        tes3mp.LogMessage(enumerations.log.INFO,
                            "[SnakeGame] Added new body segment " .. bodySegmentIndex .. " to tracked objects")
                    end
                end

                break
            end
        end

        if not bodySegmentIndex then
            tes3mp.LogMessage(enumerations.log.ERROR,
                "[SnakeGame] No available body segments found, cannot update game")
            return
        end
    end

    -- Place body segment at old head position
    local bodyLocation = {
        posX = SnakeGame.cfg.roomPosition.x + (head.x * 16),
        posY = SnakeGame.cfg.roomPosition.y + (head.y * 16),
        posZ = SnakeGame.cfg.roomPosition.z + 9.3,
        rotX = 0,
        rotY = 0,
        rotZ = 0
    }

    if LoadedCells[cellDescription].data.objectData[bodySegmentIndex] then
        LoadedCells[cellDescription].data.objectData[bodySegmentIndex].location = {
            posX = bodyLocation.posX,
            posY = bodyLocation.posY,
            posZ = bodyLocation.posZ,
            rotX = bodyLocation.rotX,
            rotY = bodyLocation.rotY,
            rotZ = bodyLocation.rotZ
        }

        SnakeGame.helpers.ResendPlace(pid, bodySegmentIndex, cellDescription, true, true)

        if SnakeGame.logging_enabled then
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] Placed body segment at old head position (" .. head.x .. "," .. head.y .. ")")
        end
    else
        tes3mp.LogMessage(enumerations.log.ERROR,
            "[SnakeGame] Body segment " .. bodySegmentIndex .. " not found in cell")
        return
    end

    -- Add the new head to the front of the snake
    table.insert(gameState.snake, 1, newHead)

    -- Update segment indices - shift all indices and add the new body segment behind the head
    for i = #gameState.snake, 3, -1 do
        gameState.segmentIndices[i] = gameState.segmentIndices[i - 1]
    end
    gameState.segmentIndices[2] = bodySegmentIndex

    -- Debug output of segment indices
    if SnakeGame.logging_enabled then
        local segmentString = "Segment indices: "
        for i, idx in pairs(gameState.segmentIndices) do
            segmentString = segmentString .. i .. "=" .. idx .. ", "
        end
        tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] " .. segmentString)

        -- Also log the current snake array
        local snakeString = "Snake array: "
        for i, pos in ipairs(gameState.snake) do
            snakeString = snakeString .. i .. "=(" .. pos.x .. "," .. pos.y .. "), "
        end
        tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] " .. snakeString)
    end

    -- Handle food
    if ateFood then
        -- We're growing
        if SnakeGame.logging_enabled then
            tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Ate food - growing snake")
        end
        gameState.score = gameState.score + 1

        -- Play the basic food eating sound
        logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySound " .. SnakeGame.cfg.eatFoodSound, false)

        -- Play voiceline
        if gameState.foodRefId and SnakeGame.cfg.foodVoiceLines[gameState.foodRefId] then
            local voiceLines = SnakeGame.cfg.foodVoiceLines[gameState.foodRefId]
            local randomLine = voiceLines[math.random(1, #voiceLines)]
            if SnakeGame.logging_enabled then
                tes3mp.LogMessage(enumerations.log.INFO,
                    "[SnakeGame] Playing voice line: " .. randomLine .. " for food: " .. gameState.foodRefId)
            end
            tes3mp.PlaySpeech(pid, randomLine)
        end

        -- Move the eaten food back to staging area
        if gameState.foodIndex then
            local foodObj = nil
            for _, obj in ipairs(SnakeGame.gamestate.SnakeGame.gameObjects[playerName]) do
                if obj.uniqueIndex == gameState.foodIndex then
                    foodObj = obj
                    break
                end
            end

            if foodObj then
                -- Move food to staging area
                local stagingLocation = SnakeGame.cfg.stagingLocation

                if LoadedCells[foodObj.cell].data.objectData[foodObj.uniqueIndex] then
                    LoadedCells[foodObj.cell].data.objectData[foodObj.uniqueIndex].location = {
                        posX = stagingLocation.x,
                        posY = stagingLocation.y,
                        posZ = stagingLocation.z,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    }

                    SnakeGame.helpers.ResendPlace(pid, foodObj.uniqueIndex, foodObj.cell, true, true)

                    -- Remove it from tracked objects
                    for i, obj in ipairs(SnakeGame.gamestate.SnakeGame.gameObjects[playerName]) do
                        if obj.uniqueIndex == foodObj.uniqueIndex then
                            table.remove(SnakeGame.gamestate.SnakeGame.gameObjects[playerName], i)
                            break
                        end
                    end

                    if SnakeGame.logging_enabled then
                        tes3mp.LogMessage(enumerations.log.INFO,
                            "[SnakeGame] Moved food back to staging area")
                    end
                end
            end
        end

        -- Place new food
        SnakeGame.gameLogic.placeFood(pid)

        -- Randomly select one of the food items
        local randomFoodIndex = math.random(1, #SnakeGame.cfg.objects.food)
        local selectedFood = SnakeGame.cfg.objects.food[randomFoodIndex]

        -- Find the matching pre-created food object
        local preCreatedFoodObject = nil
        for _, foodObj in ipairs(SnakeGame.gamestate.SnakeGame.preCreatedObjects.food) do
            if foodObj.refId == selectedFood then
                preCreatedFoodObject = foodObj
                break
            end
        end

        if preCreatedFoodObject then
            local foodLocation = {
                posX = SnakeGame.cfg.roomPosition.x + (gameState.food.x * 16),
                posY = SnakeGame.cfg.roomPosition.y + (gameState.food.y * 16),
                posZ = SnakeGame.cfg.roomPosition.z + 0.5,
                rotX = 0,
                rotY = 0,
                rotZ = 9
            }

            -- Special height adjustment for rotating_skooma
            if selectedFood == SnakeGame.cfg.objects.food[1] then
                foodLocation.posZ = foodLocation.posZ + SnakeGame.cfg.rotating_skooma_height_offset
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

                SnakeGame.helpers.ResendPlace(pid, uniqueIndex, cellDescription, true, true)
                gameState.foodIndex = uniqueIndex
                gameState.foodRefId = selectedFood

                -- Track this dynamic object
                table.insert(SnakeGame.gamestate.SnakeGame.gameObjects[playerName], {
                    uniqueIndex = uniqueIndex,
                    cell = cellDescription,
                    type = "food"
                })

                if SnakeGame.logging_enabled then
                    tes3mp.LogMessage(enumerations.log.INFO,
                        "[SnakeGame] Placed new food (" ..
                        selectedFood .. ") at (" .. gameState.food.x .. "," .. gameState.food.y .. ")")
                end
            else
                tes3mp.LogMessage(enumerations.log.ERROR,
                    "[SnakeGame] Pre-created food object not found in cell")
            end
        end
    end

    if SnakeGame.logging_enabled then
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Final snake state: length=" .. #gameState.snake ..
            ", head=(" .. newHead.x .. "," .. newHead.y .. ")")
    end

    -- Update previous direction for next time
    gameState.previousDirection = gameState.direction

    SnakeGame.gameLogic.startGameTimer(pid)
end

-- Register event handlers
customEventHooks.registerHandler("OnPlayerDisconnect", SnakeGame.handlersAndValidators.OnPlayerDisconnectHandler)
customEventHooks.registerHandler("OnGUIAction", SnakeGame.handlersAndValidators.onGUIAction)
customEventHooks.registerHandler("OnServerPostInit", SnakeGame.serverPostInit.OnServerPostInitHandler)
customEventHooks.registerHandler("OnObjectActivate", SnakeGame.handlersAndValidators.OnObjectActivateHandler)
customEventHooks.registerHandler("OnPlayerCellChange", SnakeGame.handlersAndValidators.OnPlayerCellChangeHandler)
customEventHooks.registerHandler("OnObjectDelete", SnakeGame.handlersAndValidators.OnObjectDeleteHandler)
customEventHooks.registerHandler("OnPlayerAuthentified", SnakeGame.handlersAndValidators.OnPlayerAuthentifiedHandler)

--validators
-- customEventHooks.registerValidator("OnPlayerDeath", SnakeGame.handlersAndValidators.OnPlayerDeathValidator)
customEventHooks.registerValidator("OnDeathTimeExpiration",
    SnakeGame.handlersAndValidators.OnDeathTimeExpirationValidator)
customEventHooks.registerValidator("OnPlayerItemUse", SnakeGame.handlersAndValidators.OnPlayerItemUseValidator)
customEventHooks.registerValidator("OnPlayerInventory", SnakeGame.handlersAndValidators.OnPlayerInventoryValidator)

-- Register commands
customCommandHooks.registerCommand(SnakeGame.cfg.commands.start, SnakeGame.handlersAndValidators.commandHandler)
customCommandHooks.registerCommand(SnakeGame.cfg.commands.stop, SnakeGame.handlersAndValidators.commandHandler)
customCommandHooks.registerCommand(SnakeGame.cfg.commands.up, SnakeGame.handlersAndValidators.commandHandler)
customCommandHooks.registerCommand(SnakeGame.cfg.commands.down, SnakeGame.handlersAndValidators.commandHandler)
customCommandHooks.registerCommand(SnakeGame.cfg.commands.left, SnakeGame.handlersAndValidators.commandHandler)
customCommandHooks.registerCommand(SnakeGame.cfg.commands.right, SnakeGame.handlersAndValidators.commandHandler)

tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Module initialized")
