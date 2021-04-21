matchLogic = {}

matchID = nil

-- indicates if there is currently an active match going on
matchInProgress = false

-- keep track of which players are in a match
-- used in actual match logic
playerList = {}

-- used to track the fog progress
-- 1 = no damage or warning zones
-- 2 = outside of zone 1 is warning
-- 3 = outside of zone 1 is damage level 1, zone 1 is warning
-- 4 = zone 2 is warning, zone 1 is damage level 1, outside is damage level 2
currentFogStage = 1

-- for warnings about time remaining until fog shrinks
fogShrinkRemainingTime = 0

-- used for handling the stages of player movement at the start of the match
airmode = 0

-- timer used for zone shrink countdown
-- global variable because we have to have access to it in matchLogic.End
fogtimer = nil

-- pools of item IDs used for distribution of unique items when placing loot
-- each tier being it's own pool
uniqueItemIDs = {}

-- Used to initiate next step of the air-drop process
function HandleAirTimerTimeout()
    brDebug.Log(2, "AirTimer Timeout")
    matchLogic.HandleAirMode()
end

matchLogic.Start = function()
    matchID = os.time()
    matchInProgress = true
    tes3mp.LogMessage(2, "Starting a battle royale match with ID " .. tostring(matchID))
    tes3mp.SendMessage(0, "Match has started.\n", true)
    
    -- copy readylist into playerlist
    for key, value in pairs(lobbyLogic.GetReadyList()) do
        table.insert(playerList, value)
    end
    
    --debug.DeleteExteriorCellData()
    
    matchLogic.SetInitialStage()
    
    mapLogic.GenerateZones()

    matchLogic.StartZoneShrinkProcess()

    mapLogic.ResetMapTiles()
    
    mapLogic.UpdateMap()

    mapLogic.SpawnLoot()

    brDebug.Log(2, "playerList has " .. tostring(#playerList) .. " PIDs in it")
    
    matchLogic.RemoveOfflinePlayersFromPlayerList()
    
    playerLogic.InitPlayers(playerList)

    -- has to be after for loop, otherwise PlayerInit resets the initial speed given by first stage of Airdrop
    matchLogic.StartAirdrop()
end

-- check if player is last one
-- this can be modified in case teams get implemented
matchLogic.CheckVictoryConditions = function()
    tes3mp.LogMessage(2, "Checking if victory conditions are met")
    brDebug.Log(1, "#playerList: " .. tostring(#playerList))
    
    -- TODO: find less barbaric way of getting table length
    remainingPlayers = 0
    for key, value in pairs(playerList) do
        if value then
            remainingPlayers = remainingPlayers + 1
        end
    end
    
	if remainingPlayers == 1 then
        matchLogic.End()
	end
end

matchLogic.End = function()
    tes3mp.LogMessage(2, "Ending match with ID " .. tostring(matchID))
    matchInProgress = false
    tes3mp.SendMessage(playerList[1], color.Yellow .. Players[playerList[1]].data.login.name .. " has won the match\n", true)
    tes3mp.MessageBox(playerList[1], -1, "Winner winner CHIM for dinner")
    playerLogic.IncreaseWinCount(playerList[1])
    -- respawn player in lobby
    playerLogic.PlayerInit(playerList[1], true)
    Players[playerList[1]]:Save()
    FullLoot.destroyAllDeathContainers()
    
    mapLogic.ResetWorld()
    
    -- clear playerList only *after* all the player-relates stuff above is handled
    playerList = {}
    
    -- stop zone shrink timer
    tes3mp.StopTimer(fogTimer)
    
    if brConfig.automaticMatchmaking then
        lobbyLogic.StartMatchProposal()
    end
end


matchLogic.SetInitialStage = function()
    
    currentFogStage = brConfig.defaultMatchStage
    
    -- determine the initial match stage
    for index=1,#brConfig.playerCountStageMapping do
        if #playerList >= brConfig.playerCountStageMapping[index] then
            currentFogStage = currentFogStage + 1
        end
    end
end

matchLogic.RemovePlayerFromPlayerList = function(pid)
    --tablehelper does not work in this case, so we do it the barbaric way
    --tableHelper.removeValue(playerList, pid)
    for index, pidInList in ipairs(playerList) do
        if pidInList == pid then
            table.remove(playerList, index)
        end
    end
end

matchLogic.RemoveOfflinePlayersFromPlayerList = function()
    for index, pid in pairs(playerList) do
        if not Players[pid]:IsLoggedIn() then
            matchLogic.RemovePlayerFromPlayerList(pid)
        end
    end
end

matchLogic.StartAirdrop = function()
    brDebug.Log(3, "Starting airdrop")
    airmode = 1
	matchLogic.HandleAirMode()
    tes3mp.SendMessage(playerList[1], "You have " .. tostring(brConfig.airDropStages[1][1]) .. " seconds of speed boost.\n", true)
end

matchLogic.HandleAirMode = function()
    if brConfig.airDropStages[airmode] and brConfig.airDropStages[airmode][1] then
        for _, pid in pairs(playerList) do
            if Players[pid]:IsLoggedIn() then
                playerLogic.SetAirMode(pid, airmode)
            end
        end
        if brConfig.airDropStages[airmode][1] ~= -1 then
            airTimer = tes3mp.CreateTimerEx("HandleAirTimerTimeout", time.seconds(brConfig.airDropStages[airmode][1]), "i", 1)
            tes3mp.StartTimer(airTimer)
        end
    else
        -- if there are no more stages, return players to default
        for _, pid in pairs(playerList) do
            if Players[pid]:IsLoggedIn() then
                playerLogic.SetSpeed(pid, -1)
                playerLogic.SetSlowFall(pid, false)
            end
        end
    end
    airmode = airmode + 1
end

matchLogic.StartZoneShrinkProcess = function()
    matchLogic.StartZoneShrinkTimerForStage(currentFogStage)
end

matchLogic.StartZoneShrinkTimerForStage = function(stage)
    delay = brConfig.stageDurations[stage]
    if delay then
	    tes3mp.SendMessage(0, brConfig.fogName .. " will be shrinking in " .. tostring(delay) .. " seconds.\n", true)
	    fogTimer = tes3mp.CreateTimerEx("AdvanceZoneShrink", time.seconds(delay), "i", 1)
	    tes3mp.StartTimer(fogTimer)
    end
end

-- returns the value that zone deals at the current stage
matchLogic.GetDamageLevelForZone = function(zone)
    damageLevel = brConfig.stageDamageLevels[currentFogStage-zone-1]
    if currentFogStage-zone-1 > #brConfig.stageDamageLevels then
        return 3
    end
    if damageLevel then
        return damageLevel
    end
end

matchLogic.GetDamageLevelForCell = function(x, y)
    zone = mapLogic.GetZoneForCell(x,y)
    return matchLogic.GetDamageLevelForZone(zone)
end

matchLogic.IsPlayerInMatch = function(pid)
  return tableHelper.containsValue(playerList, pid)
end

matchLogic.GetCurrentStage = function()
    return currentFogStage
end

matchLogic.GetPlayerList = function()
  return playerList
end

matchLogic.IsMatchInProgress = function()
  return matchInProgress
end

-- for debug purposes, not used outside of brDebug
matchLogic.ForceAdvanceZoneShrink = function()
    AdvanceZoneShrink()
end


matchLogic.InformPlayersAboutStageProgress = function(pid, damageLevel)
    message = "Zone shrink stage " .. color.Yellow .. tostring(currentFogStage) .. 
        color.White .. "/" .. tostring(#brConfig.stageDurations) .. ". " .. color.Yellow .. 
        tostring(#playerList) .. color.White .. " players still alive.\n"
    tes3mp.SendMessage(playerList[1], message, true)
end

-- removes the existing ghostfence meshes and places new ones in appropriate positions
matchLogic.UpdateZoneBorder = function()
    
    if currentFogStage > 2 then
    
        mapLogic.RemoveCurrentBorder()
        
        mapLogic.PlaceBorderAroundZone(currentFogStage-2)
    
    end
    
end

-- currently just creates a list of unique items and shuffles it
matchLogic.PrepareLootTables = function()

    uniqueItemIDs = {{}, {}, {}, {}}

    if brConfig.allowUniqueItems then
        for tier=1,4 do
            if #brConfig.lootTables.unique[tier] > 0 then
                for key, value in pairs(brConfig.lootTables.unique[tier]) do
                    table.insert(uniqueItemIDs[tier], value)
                end
                
                -- shuffle the positions in each tier table so that they get chosen in random order
                if #brConfig.lootTables.unique[tier] >= 2  then
                    for i = #uniqueItemIDs[tier], 2, -1 do
                        local j = math.random(i)
                        uniqueItemIDs[tier][i], uniqueItemIDs[tier][j] = uniqueItemIDs[tier][j], uniqueItemIDs[tier][i]
                    end
                end
            end
        end
    end
end

-- returns a table of item IDs
matchLogic.GetRandomLoot = function(itemCount, uniqueItemCount, lootType, lootTier)
    
    local randomLoot = {}
    
    -- add generic items
    for i = 1,itemCount do
        table.insert(randomLoot, matchLogic.GetRandomGenericItem(lootType, lootTier))
    end
    
    -- add unique items
    for i = 1,uniqueItemCount do
        --local randomUniqueItem = matchLogic.GetRandomUniqueItem(lootType, lootTier)
        local randomUniqueItem = matchLogic.GetRandomUniqueItem(lootTier)
        -- check if function even returned anything, since it is possible to run out of unique items
        if randomUniqueItem then
            table.insert(randomLoot, randomUniqueItem)
        end
    end
    
    return randomLoot
    
end

-- returns random item from requested category in loot tables
matchLogic.GetRandomGenericItem = function(lootType, lootTier)
    
    local itemCount = 1
    
    if not lootType then
        lootTypes = {"armor", "potions", "weapons", "scrolls", "projectiles"}
        -- this math wizardry makes it so that projectiles have a very small chance of spawning
        lootType = lootTypes[math.ceil((math.random(105)/30)+0.5)+math.floor(math.random(11)/10)]
    end

    if not lootTier then
        brDebug.Log(3, "loot_type: " .. tostring(lootType))
        lootTier = math.random(1,#brConfig.lootTables[lootType])
    end
    
    if lootType == "projectiles" then
        itemCount = math.random(1,3)*10
    end
    
    return {brConfig.lootTables[lootType][lootTier][math.random(#brConfig.lootTables[lootType][lootTier])], itemCount}
end


-- change logic here once unique items are split by type in config
--matchLogic.GetRandomUniqueItem = function(lootType, lootTier)
matchLogic.GetRandomUniqueItem = function(lootTier)

    if not lootTier then
        brDebug.Log(3, "setting random loot tier")
        lootTier = math.random(1,4)
    end

    if #uniqueItemIDs[lootTier] > 0 then
        -- take last element of uniqueItemIDs[lootTier] and add it to randomLoot
        local uniqueItemID = uniqueItemIDs[lootTier][#uniqueItemIDs[lootTier]]
        -- then remove it from the pool
        table.remove(uniqueItemIDs[lootTier], #uniqueItemIDs[lootTier])
        return uniqueItemID
    end

end

-- logic for next shrink stage
function AdvanceZoneShrink()
    
    currentFogStage = currentFogStage + 1
    
    matchLogic.InformPlayersAboutStageProgress()
    
    brDebug.Log(3, "Updating map")
    mapLogic.UpdateMap()
    
    brDebug.Log(3, "Updating zone border")
    matchLogic.UpdateZoneBorder()
    
    brDebug.Log(3, "Handling player stuff")
    for _, pid in pairs(playerList) do
		if Players[pid]:IsLoggedIn() then
			-- send new map state to player
			playerLogic.SendMapToPlayer(pid)
			-- apply fog effects to players in cells that are now in fog
			playerLogic.UpdateDamageLevel(pid)
		end
	end
    brDebug.Log(3, "Starting timer for next shrink")
    matchLogic.StartZoneShrinkTimerForStage(currentFogStage)
end

return matchLogic
