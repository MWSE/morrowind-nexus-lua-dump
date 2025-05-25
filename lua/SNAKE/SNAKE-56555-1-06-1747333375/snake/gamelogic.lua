local gamelogic = {}

-- Place food at a random position
function gamelogic.placeFood(pid)
    local playerName = string.lower(Players[pid].accountName)
    local gameState = SnakeGame.gamestate.SnakeGame.activePlayers[playerName]

    local foodPos = { x = math.random(0, SnakeGame.cfg.roomSize - 1), y = math.random(0, SnakeGame.cfg.roomSize - 1) }

    for _, segment in ipairs(gameState.snake) do
        if foodPos.x == segment.x and foodPos.y == segment.y then
            gamelogic.placeFood(pid) -- Recursive call if food spawns on snake
            return
        end
    end

    gameState.food = foodPos
end

-- Start game timer
function gamelogic.startGameTimer(pid)
    local playerName = string.lower(Players[pid].accountName)

    if SnakeGame.gamestate.SnakeGame.timers[playerName] then
        tes3mp.StopTimer(SnakeGame.gamestate.SnakeGame.timers[playerName])
    end

    SnakeGame.gamestate.SnakeGame.timers[playerName] = tes3mp.CreateTimerEx("UpdateGame",
        math.floor(SnakeGame.cfg.updateInterval * 1000),
        "i",
        pid)

    tes3mp.StartTimer(SnakeGame.gamestate.SnakeGame.timers[playerName])
end

-- Handle game over
function gamelogic.gameOver(pid, reason)
    local playerName = string.lower(Players[pid].accountName)
    local gameState = SnakeGame.gamestate.SnakeGame.activePlayers[playerName]
    local cellDescription = tes3mp.GetCell(pid)
    local yagrumIndex = SnakeGame.gamestate.SnakeGame.preCreatedObjects.yagrum.uniqueIndex
    local headIndex = SnakeGame.gamestate.SnakeGame.preCreatedObjects.head.uniqueIndex

    --flip client variable for move sound
    tes3mp.ClearClientGlobals()
    tes3mp.AddClientGlobalInteger("snakegameactive", 0, enumerations.variableType.SHORT)
    tes3mp.SendClientScriptGlobal(pid, true, false)

    -- Show game over message
    local message = reason .. "\nFinal Score: " .. gameState.score

    if gameState then
        gameState.gameOver = true
        -- Record the score in the leaderboard
        local position = SnakeGame.leaderboard.addScore(playerName, gameState.score)

        -- If the player made it to the leaderboard, mention it in the game over message
        if position then
            if position == 1 then
                message = message .. "\n\n" .. color.Gold .. "NEW HIGH SCORE! Rank 1" .. color.Default
            else
                message = message ..
                    "\n\n" .. color.Yellow .. "You made the leaderboard! Rank " .. position .. color.Default
            end
        end

        -- tes3mp.CustomMessageBox(pid, SnakeGame.cfg.gameOverId, "Game Over\n" .. color.Red .. message,
        --     color.Green .. "Play Again;" ..
        --     color.Yellow .. "Quit")

        tes3mp.SendMessage(pid,
            color.Coral ..
            "[SnakeGame] " ..
            color.Crimson ..
            "Game Over \n" ..
            color.Coral ..
            "[SnakeGame] " ..
            reason .. "\n" .. color.Coral .. "[SnakeGame] " .. "Final Score: " .. gameState.score .. "\n",
            false)

        tes3mp.MessageBox(pid, -1, color.Crimson .. "Game Over \n" .. color.Coral .. "[SnakeGame] " .. message)

        tes3mp.LogMessage(enumerations.log.INFO, "yagrumIndex: " .. yagrumIndex)

        logicHandler.RunConsoleCommandOnObject(pid,
            'say, "' .. SnakeGame.cfg.npcVoiceLines.yagrum[2] .. '", "nooooooooooo"', cellDescription, yagrumIndex, true)
        logicHandler.RunConsoleCommandOnObject(pid, 'say, "' .. SnakeGame.cfg.npcVoiceLines.caius[2] .. '", "WHA!"',
            cellDescription, headIndex, true)

        SnakeGame.gameLogic.stopGame(pid)
    end
end

-- Stop game and clean up
function gamelogic.stopGame(pid)
    local playerName = string.lower(Players[pid].accountName)

    if not SnakeGame.gamestate.SnakeGame.activePlayers[playerName] then return end

    if SnakeGame.gamestate.SnakeGame.timers[playerName] then
        tes3mp.StopTimer(SnakeGame.gamestate.SnakeGame.timers[playerName])
        SnakeGame.gamestate.SnakeGame.timers[playerName] = nil
        tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Stopped timer for " .. playerName)
    end

    if SnakeGame.gamestate.SnakeGame.gameObjects[playerName] then
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Moving " ..
            #SnakeGame.gamestate.SnakeGame.gameObjects[playerName] .. " objects back to staging area for " .. playerName)

        -- Set up a single common staging location below the game area
        local stagingLocation = SnakeGame.cfg.stagingLocation

        for i = #SnakeGame.gamestate.SnakeGame.gameObjects[playerName], 1, -1 do
            local object = SnakeGame.gamestate.SnakeGame.gameObjects[playerName][i]
            if object and object.uniqueIndex and logicHandler.IsCellLoaded(object.cell) then
                -- Move the object back to staging area
                if LoadedCells[object.cell].data.objectData[object.uniqueIndex] then
                    LoadedCells[object.cell].data.objectData[object.uniqueIndex].location = {
                        posX = stagingLocation.x,
                        posY = stagingLocation.y,
                        posZ = stagingLocation.z,
                        rotX = 0,
                        rotY = 0,
                        rotZ = 0
                    }
                    if LoadedCells[object.cell].data.objectData[object.uniqueIndex].refId == SnakeGame.cfg.objects.snakeHead then
                        -- move head back to starting position
                        LoadedCells[object.cell].data.objectData[object.uniqueIndex].location = {
                            posX = stagingLocation.x,
                            posY = stagingLocation.y,
                            posZ = SnakeGame.cfg.roomPosition.z + 9.5,
                            rotX = math.rad(SnakeGame.cfg.headRotations.right.rotX),
                            rotY = math.rad(SnakeGame.cfg.headRotations.right.rotY),
                            rotZ = math.rad(SnakeGame.cfg.headRotations.right.rotZ)
                        }
                    end

                    SnakeGame.helpers.ResendPlace(pid, object.uniqueIndex, object.cell, true)

                    tes3mp.LogMessage(enumerations.log.INFO,
                        "[SnakeGame] Moved " .. object.type .. " back to staging area")
                else
                    tes3mp.LogMessage(enumerations.log.WARN,
                        "[SnakeGame] Could not find object " .. object.uniqueIndex .. " in cell " .. object.cell)
                end
            end
        end

        SnakeGame.gamestate.SnakeGame.gameObjects[playerName] = nil
        tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Cleared all tracked objects for " .. playerName)
    end

    SnakeGame.gamestate.SnakeGame.activePlayers[playerName] = nil

    --restore players original quickKeys
    if Players[pid].data.customVariables.original_quickKeys and Players[pid].data.customVariables.original_quickKeys[1] then
        local quickKeys = { "left", "down", "up", "right" }
        tes3mp.ClearQuickKeyChanges(pid)
        tes3mp.ClearInventoryChanges(pid)
        for i = 1, #quickKeys do
            tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.REMOVE)
            tes3mp.AddItemChange(pid, "sg_" .. quickKeys[i], 1, -1, -1, "")
            tes3mp.AddQuickKey(pid, i, 0, Players[pid].data.customVariables.original_quickKeys[i].itemId)
            inventoryHelper.removeExactItem(Players[pid].data.inventory, "sg_" .. quickKeys[i], 1, -1, -1, "")
        end
        tes3mp.SendInventoryChanges(pid, false, false)
        tes3mp.SendQuickKeyChanges(pid)

        logicHandler.RunConsoleCommandOnPlayer(pid, "EnablePlayerControls", false)
        logicHandler.RunConsoleCommandOnPlayer(pid, "EnableVanityMode", false)
        logicHandler.RunConsoleCommandOnPlayer(pid, "EnablePlayerViewSwitch", false)
        logicHandler.RunConsoleCommandOnPlayer(pid, "TM", false)
        logicHandler.RunConsoleCommandOnPlayer(pid, "removespell sg_levitate", true)
        logicHandler.RunConsoleCommandOnPlayer(pid, "removespell sg_light", true)

        tes3mp.MessageBox(pid, -1, "Snake Game ended.")
        tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Game stopped for " .. playerName)
    end
end

return gamelogic
