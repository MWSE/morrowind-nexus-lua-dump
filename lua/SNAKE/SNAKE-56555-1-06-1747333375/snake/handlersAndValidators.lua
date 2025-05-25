local handlersAndValidators = {}

-- Command handler for customCommandHooks.registerCommand
function handlersAndValidators.commandHandler(pid, command, args)
    local playerName = string.lower(Players[pid].accountName)
    command = string.lower(command[1])

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Command received: " .. command .. " from player: " .. playerName)

    if command == SnakeGame.cfg.commands.start then
        tes3mp.CustomMessageBox(pid, SnakeGame.cfg.mainMenuId, "Snake Game",
            color.Green .. "Start Game;" ..
            color.Red .. "Quit")
        return true
    elseif command == SnakeGame.cfg.commands.stop then
        if SnakeGame.gamestate.SnakeGame.activePlayers[playerName] then
            tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Stopping game for: " .. playerName)
            SnakeGame.gameLogic.stopGame(pid)
        else
            tes3mp.MessageBox(pid, -1, "No active game to stop.")
        end
    elseif command == SnakeGame.cfg.commands.up or
        command == SnakeGame.cfg.commands.down or
        command == SnakeGame.cfg.commands.left or
        command == SnakeGame.cfg.commands.right then
        if SnakeGame.gamestate.SnakeGame.activePlayers[playerName] and not SnakeGame.gamestate.SnakeGame.activePlayers[playerName].gameOver then
            local newDirection = command
            local currentDirection = SnakeGame.gamestate.SnakeGame.activePlayers[playerName].direction

            if (newDirection == SnakeGame.cfg.commands.up and currentDirection ~= SnakeGame.cfg.commands.down) or
                (newDirection == SnakeGame.cfg.commands.down and currentDirection ~= SnakeGame.cfg.commands.up) or
                (newDirection == SnakeGame.cfg.commands.left and currentDirection ~= SnakeGame.cfg.commands.right) or
                (newDirection == SnakeGame.cfg.commands.right and currentDirection ~= SnakeGame.cfg.commands.left) then
                SnakeGame.gamestate.SnakeGame.activePlayers[playerName].direction = newDirection
                tes3mp.LogMessage(enumerations.log.INFO,
                    "[SnakeGame] Direction changed to " .. newDirection .. " for " .. playerName)
            end
        end
    end

    return false -- Allow other scripts to process
end

-- Handle GUI actions
function handlersAndValidators.onGUIAction(eventStatus, pid, idGui, data)
    if idGui == SnakeGame.cfg.gameOverId then
        if tonumber(data) == 0 then     -- Play Again
            SnakeGame.gamestate.initGameState(pid)
        elseif tonumber(data) == 1 then -- Quit
            SnakeGame.gameLogic.stopGame(pid)
        end
    elseif idGui == SnakeGame.cfg.mainMenuId then
        if tonumber(data) == 0 then -- Start Game
            --flip client variable for move sound
            tes3mp.ClearClientGlobals()
            tes3mp.AddClientGlobalInteger("snakegameactive", 1, enumerations.variableType.SHORT)
            tes3mp.SendClientScriptGlobal(pid, true, false)
            SnakeGame.gamestate.initGameState(pid)
        elseif tonumber(data) == 1 then -- What's going on here?
            tes3mp.CustomMessageBox(pid, SnakeGame.cfg.ask_yagrum_id, SnakeGame.cfg.yagrums_explanation, "close;")
            local sound = 'say, "' .. SnakeGame.cfg.npcVoiceLines.yagrum[3] .. '", "yagrums engineer talk..."'
            SnakeGame.helpers.playSoundInCell(sound, SnakeGame.preCreatedObjects.yagrum.uniqueIndex, tes3mp.GetCell(pid))
        elseif tonumber(data) == 1 then -- Quit
            -- Nothing to do here
        end
    elseif idGui == SnakeGame.cfg.leaderboardId_1 then -- Caius dialog
        if tonumber(data) == 0 then                    -- Leaderboard button
            SnakeGame.leaderboard.updateAndDisplayLeaderboardBook(pid)
        end
    end
end

function handlersAndValidators.OnPlayerDisconnectHandler(eventStatus, pid)
    SnakeGame.gameLogic.stopGame(pid)
end

function handlersAndValidators.OnObjectActivateHandler(eventStatus, pid, cellDescription, objects, players)
    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Object activation detected")

    for index, object in pairs(objects) do
        if object.refId == "sg_snake_yagrum" then
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] Player " .. Players[pid].name .. " activated sg_snake_yagrum")

            if tableHelper.isEmpty(SnakeGame.gamestate.SnakeGame.activePlayers) then
                tes3mp.CustomMessageBox(pid, SnakeGame.cfg.mainMenuId,
                    "It all started when I asked Caius if he was interested in restoring some vintage Dwemer technology.\n\n Once he saw how it worked, he retired from the blades and hasn't left since.\n\n\n" ..
                    color.Coral ..
                    "To control the snake use keys 1-4.\nStartng at one the controls are:\nleft, down, up, right.\n It' recommended to change your 1-4 quickKey binds to your arrow keys.\n Unless you have a gamePad then binidng the controls to the Dpad is ideal.",
                    "Start Game;" ..
                    "What's going on here?;" ..
                    "Close;")

                local sound =
                'say, "vo\\Misc\\Yagrum_1.mp3", "A visitor? What brings you to visit Yagrum Bagarn, master crafter and last living dwarf?"'
                SnakeGame.helpers.playSoundInCell(sound, index, cellDescription)
            else
                tes3mp.MessageBox(pid, -1, "Patience fetcher.")
                return customEventHooks.makeEventStatus(false, false)
            end
        elseif object.refId == "sg_snake_caius" then
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] Player " .. Players[pid].name .. " activated sg_snake_caius")

            tes3mp.CustomMessageBox(pid, SnakeGame.cfg.leaderboardId_1,
                "Don't tell the other blades members I spend all my time here.", "Leaderboard;close;")
            local sound = 'say, "vo\\i\\m\\bIdl_IM022.mp3", "Without me, it all falls to pieces."'
            SnakeGame.helpers.playSoundInCell(sound, index, cellDescription)
            return customEventHooks.makeEventStatus(false, false)
        elseif object.refId == "sg_leaderboard_book" then
            return customEventHooks.makeEventStatus(false, false)
        elseif object.refId == "sg_snake_head" then
            logicHandler.RunConsoleCommandOnObject(pid, 'say, "' .. SnakeGame.cfg.npcVoiceLines.caius[2] .. '", "WHA!"',
                cellDescription, object.uniqueIndex, true)
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

-- restore from backup in case user has cell reset script or resets the cell manually
function handlersAndValidators.OnPlayerCellChangeHandler(eventStatus, pid, playerPacket, previousCellDescription)
    local currentCellDescription = tes3mp.GetCell(pid)
    -- Check if the player entered one of our game cells

    -- attempt to fix some bug where -3, -2 isn't loaded when i exit to balmora....
    if currentCellDescription == "-3, -2" and not logicHandler.IsCellLoaded(currentCellDescription) then
        logicHandler.LoadCell(currentCellDescription)
    end

    if currentCellDescription == SnakeGame.cfg.roomCell or currentCellDescription == "-3, -2" then
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Player " .. Players[pid].name ..
            " entered cell " .. currentCellDescription .. ". Verifying game objects...")

        -- Verify objects for the specific cell
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Verifying currentCellDescription..." .. tostring(currentCellDescription))
        local objectsIntact = SnakeGame.helpers.VerifyCellObjects(pid, currentCellDescription)

        if not objectsIntact then
            tes3mp.LogMessage(enumerations.log.WARN,
                "[SnakeGame] Missing objects detected in cell " .. currentCellDescription ..
                ". Attempting to restore from backup...")

            SnakeGame.helpers.RestoreCellFromBackup(pid, currentCellDescription)
        end
    end

    return eventStatus
end

function handlersAndValidators.OnPlayerItemUseValidator(eventStatus, pid, itemRefId)
    if itemRefId == "sg_up" then
        OnPlayerSendMessage(pid, "/raise")
    elseif itemRefId == "sg_down" then
        OnPlayerSendMessage(pid, "/lower")
    elseif itemRefId == "sg_left" then
        OnPlayerSendMessage(pid, "/left")
    elseif itemRefId == "sg_right" then
        OnPlayerSendMessage(pid, "/right")
    end

    if itemRefId == "sg_up" or itemRefId == "sg_down" or itemRefId == "sg_left" or itemRefId == "sg_right" then
        logicHandler.RunConsoleCommandOnPlayer(pid, "PlaySound \"Menu Click\"", false)
        return customEventHooks.makeEventStatus(false, false)
    end
end

function handlersAndValidators.OnPlayerInventoryValidator(eventStatus, pid, playerPacket)
    tableHelper.print(playerPacket)
    -- tes3mp.LogMessage(enumerations.log.INFO, "OnPlayerInventoryHandler called")
    tes3mp.LogMessage(enumerations.log.INFO, "playerPacket.inventory[1]: " .. tostring(playerPacket.inventory[1]))
    if playerPacket.inventory[1].refId == "sg_leaderboard_book" then
        tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] preventing shit from pants....")
        tes3mp.ClearInventoryChanges(pid)
        tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.REMOVE)
        tes3mp.AddItemChange(pid, "sg_leaderboard_book", 1, -1, -1, "")
        tes3mp.SendInventoryChanges(pid, false, false)
        return customEventHooks.makeEventStatus(false, false)
    end
end

function handlersAndValidators.OnObjectDeleteHandler(eventStatus, pid, cellDescription, objects)
    local index = SnakeGame.preCreatedObjects.leaderboard.uniqueIndex
    for _, object in pairs(objects) do
        if object.refId == "sg_leaderboard_book" then
            tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Found sg_leaderboard_book object, preventing deletion.")

            --leaderboard book
            local leaderboard_location = {
                posX = SnakeGame.cfg.stagingLocation.x,
                posY = SnakeGame.cfg.stagingLocation.y,
                posZ = SnakeGame.cfg.stagingLocation.z,
                rotX = 0,
                rotY = 0,
                rotZ = 0
            }

            local leaderboard_object = {
                refId = "sg_leaderboard_book",
                count = 1,
                charge = -1,
                enchantmentCharge = -1,
                soul = "",
                location = leaderboard_location,
            }
            SnakeGame.helpers.createObjects(cellDescription, { leaderboard_object }, "place", index)

            --remove delete packet so it doesn't get removed when player logs off....
            if tableHelper.containsValue(LoadedCells[cellDescription].data.packets, index) then
                tableHelper.removeValue(LoadedCells[cellDescription].data.packets, index)
            end
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

-- respawn in balmora temple instead of in the lava you died in...
function handlersAndValidators.OnDeathTimeExpirationValidator(eventStatus, pid)
    local cell = tes3mp.GetCell(pid)
    local playerName = string.lower(Players[pid].accountName)

    if SnakeGame.gamestate.SnakeGame.activePlayers[playerName] then SnakeGame.gameLogic.stopGame(pid) end

    if cell == SnakeGame.cfg.roomCell then
        tes3mp.LogAppend(enumerations.log.INFO, "[SnakeGame] OnDeathTimeExpirationValidator called")
        local Respawn = {
            cellDescription = "Balmora, Temple",
            position = { 4700.5673828125, 3874.7416992188, 14758.990234375 },
            rotation = { 0.25314688682556, 1.570611000061 }
        }
        tes3mp.SetCell(pid, Respawn.cellDescription)
        tes3mp.SendCell(pid)
        tes3mp.SetPos(pid, Respawn.position[1], Respawn.position[2], Respawn.position[3])
        tes3mp.SetRot(pid, Respawn.rotation[1], Respawn.rotation[2])
        tes3mp.SendPos(pid)

        -- Ensure that dying as a werewolf turns you back into your normal form
        if Players[pid].data.shapeshift.isWerewolf == true then
            Players[pid]:SetWerewolfState(false)
        end

        -- Ensure that we unequip deadly items when applicable, to prevent an
        -- infinite death loop
        contentFixer.UnequipDeadlyItems(pid)

        tes3mp.Resurrect(pid, 0)
        return customEventHooks.makeEventStatus(false, false)
    end
end

function handlersAndValidators.OnPlayerAuthentifiedHandler(eventStatus, pid)
    if Players[pid].data.clientVariables == nil then
        Players[pid].data.clientVariables = {}
    end

    if Players[pid].data.clientVariables.globals == nil then
        Players[pid].data.clientVariables.globals = {}
    end

    -- grid snap globals
    if Players[pid].data.clientVariables.globals.snakegameactive == nil then
        Players[pid].data.clientVariables.globals.snakegameactive = { ["variableType"] = 0, ["intValue"] = 0 }
    end

    --flip client variable for move sound
    tes3mp.ClearClientGlobals()
    tes3mp.AddClientGlobalInteger("snakegameactive", 0, enumerations.variableType.SHORT)
    tes3mp.SendClientScriptGlobal(pid)
end

return handlersAndValidators
