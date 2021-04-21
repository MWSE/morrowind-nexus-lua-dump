playerLogic = {}

playerLogic.InitPlayers = function(playerList)
    for _, pid in pairs(playerList) do
        playerLogic.PlayerInit(pid)
    end
end

playerLogic.InitAllPlayers = function()
    for pid, player in pairs(Players) do
        playerLogic.PlayerInit(pid)
    end
end

-- handle character properties and move them to designated position
playerLogic.PlayerInit = function(pid, lobby)
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        playerLogic.ResetCharacter(pid)
        playerLogic.PlayerSpells(pid)
        playerLogic.PlayerItems(pid)
        
        if lobby then
            playerLogic.SpawnPlayerInLobby(pid)
            playerLogic.SetSlowFall(pid, false)
        else
            playerLogic.SendMapToPlayer(pid)
            playerLogic.SpawnPlayerInMatch(pid)
        end
    end
end

-- move player to designated position
playerLogic.SpawnPlayerInMatch = function(pid)
    tes3mp.LogMessage(2, "Spawning player " .. tostring(pid) .. " in exterior")

    -- TODO: figure out how to make this less of a mess
    randomSpawnPosition = mapLogic.GerRandomPositionInsideZone(matchLogic.GetCurrentStage()-2)
    -- we can't do pairs() because it doesn't iterate through array in same order as it was generated
    tes3mp.LogMessage(2, "Spawning player " .. tostring(pid) .. " at " .. tostring(random_x) .. ", " .. tostring(random_y))
    local chosenSpawnPoint = {"1, 1", randomSpawnPosition[1], randomSpawnPosition[2], 40000, 0}

    tes3mp.SetCell(pid, chosenSpawnPoint[1])
    tes3mp.SendCell(pid)
    tes3mp.SetPos(pid, chosenSpawnPoint[2], chosenSpawnPoint[3], chosenSpawnPoint[4])
    tes3mp.SetRot(pid, 0, chosenSpawnPoint[5])
    tes3mp.SendPos(pid)

end

-- move player to lobby cell
playerLogic.SpawnPlayerInLobby = function(pid)
    tes3mp.LogMessage(2, "Spawning player " .. tostring(pid) .. " in lobby")
    PlayerLobby.teleportToLobby(pid)
end

-- check what changes to apply now that player crossed cell border
playerLogic.ProcessCellChange = function(pid)
	tes3mp.LogMessage(2, "Processing cell change for PID " .. tostring(pid))
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() and matchLogic.IsPlayerInMatch(pid) then
		-- TODO: lol I have no idea how to properly re-paint a tile after player "discovered it"
        playerLogic.UpdateDamageLevel(pid)
		Players[pid]:SaveStatsDynamic()
	end
end

-- reset player to default
playerLogic.ResetCharacter = function(pid)
    playerLogic.ResetCharacterStats(pid)
    playerLogic.ResetCharacterItems(pid)
    playerLogic.SetFogDamageLevel(pid, 0)
end

playerLogic.PlayerSpells = function(pid)

end

-- give player relevant items
playerLogic.PlayerItems = function(pid)
	tes3mp.LogMessage(2, "Loading items for " .. tostring(pid))
    playerLogic.LoadPlayerOutfit(pid)
	Players[pid]:Save()
	Players[pid]:LoadInventory()
	Players[pid]:LoadEquipment()
end

-- Add battle-royale specific data to player file if it is not already present
playerLogic.AddBRStats = function(pid)
	tes3mp.LogMessage(2, "Verifying player data for " .. tostring(Players[pid]))
	
	if Players[pid].data.BRinfo == nil then
		BRinfo = {}
		BRinfo.lastMatchId = ""
		BRinfo.chosenSpawnPoint = nil
		BRinfo.team = 0
		BRinfo.totalKills = 0
		BRinfo.totalDeaths = 0		
		BRinfo.wins = 0
		BRinfo.BROutfit = {} -- used to hold data about player's chosen outfit
		BRinfo.secretNumber = math.random(100000,999999) -- used for verification
		Players[pid].data.BRinfo = BRinfo
		Players[pid]:Save()
	end
end

-- when player wins a round
playerLogic.IncreaseWinCount = function(pid)
    Players[pid].data.BRinfo.wins = Players[pid].data.BRinfo.wins + 1
end

-- Handle generation of new character
playerLogic.EndCharGen = function(pid)
	tes3mp.LogMessage(2, "Ending character generation for " .. tostring(pid))
	Players[pid]:SaveLogin()
	Players[pid]:SaveCharacter()
	Players[pid]:SaveClass()
	Players[pid]:SaveStatsDynamic()
	Players[pid]:SaveEquipment()
	Players[pid]:SaveIpAddress()
	Players[pid]:CreateAccount()
	playerLogic.AddBRStats(pid)
    playerLogic.ResetCharacterStats(pid)
end

-- return player stats to default
playerLogic.ResetCharacterStats = function(pid)
    tes3mp.LogMessage(2, "Resetting stats for " .. Players[pid].data.login.name .. ".")

	-- Reset battle royale
	--Players[pid].data.BRinfo.team = 0
	
	-- Reset player level
	Players[pid].data.stats.level = brConfig.defaultStats.playerLevel
	Players[pid].data.stats.levelProgress = 0
	
	-- Reset player attributes
	for name in pairs(Players[pid].data.attributes) do
		Players[pid].data.attributes[name].base = brConfig.defaultStats.playerAttributes
		Players[pid].data.attributes[name].skillIncrease = 0
	end

	Players[pid].data.attributes.Speed.base = brConfig.defaultStats.playerSpeed
	Players[pid].data.attributes.Luck.base = brConfig.defaultStats.playerLuck
	
	-- Reset player skills
	for name in pairs(Players[pid].data.skills) do
		Players[pid].data.skills[name].base = brConfig.defaultStats.playerSkills
		Players[pid].data.skills[name].progress = 0
	end

	Players[pid].data.skills.Acrobatics.base = brConfig.defaultStats.playerAcrobatics
	Players[pid].data.skills.Marksman.base = brConfig.defaultStats.playerMarksman

	-- Reset player stats
	Players[pid].data.stats.healthBase = brConfig.defaultStats.playerHealth
	Players[pid].data.stats.healthCurrent = brConfig.defaultStats.playerHealth
	Players[pid].data.stats.magickaBase = brConfig.defaultStats.playerMagicka
	Players[pid].data.stats.magickaCurrent = brConfig.defaultStats.playerMagicka
	Players[pid].data.stats.fatigueBase = brConfig.defaultStats.playerFatigue
	Players[pid].data.stats.fatigueCurrent = brConfig.defaultStats.playerFatigue
	
	-- Reload player with reset information
	Players[pid]:Save()
	Players[pid]:LoadLevel()
	Players[pid]:LoadAttributes()
	Players[pid]:LoadSkills()
	Players[pid]:LoadStatsDynamic()
end

-- return player's inventory to default
playerLogic.ResetCharacterItems = function(pid)
    if Players[pid]:IsLoggedIn() then
        Players[pid].data.inventory = {}
        Players[pid].data.equipment = {}
	    Players[pid]:Save()
	    Players[pid]:LoadInventory()
	    Players[pid]:LoadEquipment()
    end
end

-- mapping of clothes:
-- clothes: https://github.com/OpenMW/openmw/blob/ff44b2c66fb49b72995624da850a39150b49781d/apps/openmw/mwworld/inventorystore.hpp#L44-L62
playerLogic.LoadPlayerOutfit = function(pid)
    tes3mp.LogMessage(2, "Loading outfit for " .. tostring(pid))
    -- TODO: consider making a check for the existance of required data
    -- for now just assume that testBR.VerifyPlayerData did it's thing fine
    --Players[pid].data.BRinfo.BROutfit

    playerRace = string.lower(Players[pid].data.character.race)
    -- give shoes
    if (playerRace ~= "argonian") and (playerRace ~= "khajiit") then
	    Players[pid].data.equipment[7] = { refId = "common_shoes_01", count = 1, charge = -1 }
    end
    -- give shirt
	Players[pid].data.equipment[8] = { refId = "common_shirt_01", count = 1, charge = -1 }
    -- give pants
	Players[pid].data.equipment[9] = { refId = "common_pants_01", count = 1, charge = -1 }
end

-- apply damage level of the cell that player is in
playerLogic.UpdateDamageLevel = function(pid)
    brDebug.Log(1, "Updating damage level for PID " .. tostring(pid))
    playerCell = tes3mp.GetCell(pid)
    
    -- sanity check
    if not mapLogic.IsCellExternal(playerCell) then
        tes3mp.LogMessage(2, tostring(playerCell) .. " is not external cell and therefore can't have damage level.")
        return false
    end
    
    _, _, x, y = string.find(playerCell, patterns.exteriorCell)
    newDamageLevel = matchLogic.GetDamageLevelForCell(x, y)
    
    if not newDamageLevel or newDamageLevel == "warn" then
        brDebug.Log(1, "New damage level is 0")
		playerLogic.SetFogDamageLevel(pid, 0)
    else
        -- there are only 3 damage levels
        if newDamageLevel > 3 then
            newDamageLevel = 3
        end
        brDebug.Log(1, "New damage level is " .. tostring(newDamageLevel))
        playerLogic.SetFogDamageLevel(pid, newDamageLevel)
	end
end

-- Apply given damage effect to player
playerLogic.SetFogDamageLevel = function(pid, damageLevel)
    tes3mp.LogMessage(2, "Damage level for PID " .. tostring(pid) .. " is now " .. tostring(damageLevel))
	if damageLevel == 0 then
		command = "player->removespell fogdamage1"
		logicHandler.RunConsoleCommandOnPlayer(pid, command)
		command = "player->removespell fogdamage2"
		logicHandler.RunConsoleCommandOnPlayer(pid, command)
		command = "player->removespell fogdamage3"
		logicHandler.RunConsoleCommandOnPlayer(pid, command)
	elseif damageLevel == 1 then
		command = "player->addspell fogdamage1"
		logicHandler.RunConsoleCommandOnPlayer(pid, command)
	elseif damageLevel == 2 then
		command = "player->addspell fogdamage2"
		logicHandler.RunConsoleCommandOnPlayer(pid, command)
	elseif damageLevel == 3 then
		command = "player->addspell fogdamage3"
		logicHandler.RunConsoleCommandOnPlayer(pid, command)
	end
end

playerLogic.DropAllItems = function(pid, damageLevel)
    
end

-- display a message to player about blocked interior cells
playerLogic.WarnPlayerAboutInterior = function(pid)
    tes3mp.SendMessage(pid, "You can not enter interiors during this match.\n", false)
end

-- set player stats and slowfall to the ones determined by stage of air-drop
playerLogic.SetAirMode = function(pid, mode)
    brDebug.Log(1, "Setting airmode for PID " .. tostring(pid) .. " to " .. tostring(mode))
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        
        -- set player speed
        if brConfig.airDropStages[mode][2] then
            -- check if speed has to be changed or is it the same as in the previous stage
            playerLogic.SetSpeed(pid, brConfig.airDropStages[mode][2])
        end

        -- check if slowfall has to be enabled
        if brConfig.airDropStages[mode][3] then
            -- check that slowfall wasn't already enabled in previous stage
            -- so that we don't re-enable it unncecessarily
            -- (IF this is first stage OR this is not first stage but slowfall is already enabled)
            if not brConfig.airDropStages[mode-1] or (brConfig.airDropStages[mode-1] and not brConfig.airDropStages[mode-1][3]) then
                brDebug.Log(1, "Enabling slowfall for PID " .. tostring(pid))
                playerLogic.SetSlowFall(pid, true)
            end
        else
            brDebug.Log(1, "Disabling slowfall for PID " .. tostring(pid))
            playerLogic.SetSlowFall(pid, false)
        end
    end
    
    Players[pid]:Save()
end

-- either enables or disables slowfall for player
-- this part assumes that there is a proper entry for slowfall_power in recordstore
playerLogic.SetSlowFall = function(pid, boolean)
	--tes3mp.LogMessage(2, "Setting slowfall mode for PID " .. tostring(pid))
	if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
		if boolean then
			command = "player->addspell slowfall_power"
		else
			command = "player->removespell slowfall_power"
		end
		logicHandler.RunConsoleCommandOnPlayer(pid, command)
	end
end

-- set player speed
-- interpret -1 as "reset to default"
playerLogic.SetSpeed = function(pid, speed)
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        if speed == -1 then
            brDebug.Log(1, "Setting speed for PID " .. tostring(pid) .. " to default")
            Players[pid].data.attributes["Speed"].base = brConfig.defaultStats.playerSpeed
        else
            brDebug.Log(1, "Setting speed for PID " .. tostring(pid) .. " to " .. tostring(speed))
            Players[pid].data.attributes["Speed"].base = speed
        end
        Players[pid]:Save()
        Players[pid]:LoadAttributes()
    end

end

-- handle player death
playerLogic.ProcessDeath = function(pid)
    brDebug.Log(1, "Processing death for PID " .. tostring(pid))
	if matchLogic.IsPlayerInMatch(pid) then
        brDebug.Log(3, tostring(pid) .. " was a match participant")
		playerLogic.DropAllItems(pid)
        matchLogic.RemovePlayerFromPlayerList(pid)
		matchLogic.CheckVictoryConditions()
	end
    -- respawn player in lobby
	playerLogic.PlayerInit(pid, true)
	Players[pid]:Save()
end

-- Send all the new changes to world-view map to player
playerLogic.SendMapToPlayer = function(pid)
	tes3mp.LogMessage(2, "Sending map to PID " .. tostring(pid))
	tes3mp.SendWorldMap(pid)
end

-- returns list of online players, splits it into players in match and players in lobby if match is going on
-- TODO: would it be better to call non-modified function if there is no match going on?
local GetConnectedPlayerList = function()

    local lastPid = tes3mp.GetLastPlayerId()
    local matchTitle = "Players in match:\n"
    local lobbyTitle = "Players in lobby:\n"
    local matchList = ""
    local lobbyList = ""
    local separator = ""
    local divider = "\n"

    for playerIndex = 0,lastPid do
        if playerIndex == lastPid then
            divider = ""
        else
            divider = "\n"
        end
        if Players[playerIndex] ~= nil and Players[playerIndex]:IsLoggedIn() then
            if matchLogic.IsPlayerInMatch(playerIndex) then
                matchList = matchList .. color.SteelBlue .. tostring(Players[playerIndex].name) .. " (pid: " .. tostring(Players[playerIndex].pid) ..
                ", ping: " .. tostring(tes3mp.GetAvgPing(Players[playerIndex].pid)) .. ")" .. divider
            else
                lobbyList = lobbyList .. tostring(Players[playerIndex].name) .. " (pid: " .. tostring(Players[playerIndex].pid) ..
                ", ping: " .. tostring(tes3mp.GetAvgPing(Players[playerIndex].pid)) .. ")" .. divider
            end
        end
    end

    if matchList ~= "" and lobbyList ~= "" then
        separator = "---------------\n"
    else
        matchTitle = ""
        lobbyTitle = ""
    end
    
    result = matchTitle .. matchList .. "#caa560" .. separator .. lobbyTitle .. lobbyList
    return  result
end

-- displays player list
playerLogic.ListPlayers = function(pid)
    
    local playerCount = logicHandler.GetConnectedPlayerCount()
    local label = playerCount .. " connected player"

    if playerCount ~= 1 then
        label = label .. "s"
    end

    tes3mp.ListBox(pid, guiHelper.ID.PLAYERSLIST, label, GetConnectedPlayerList())

end

return playerLogic
