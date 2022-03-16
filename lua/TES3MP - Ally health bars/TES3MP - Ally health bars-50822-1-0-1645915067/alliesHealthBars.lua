local jsonName = "alliesHealthBars.json"

local playerAllyHealths = {}
local playerNamesToRemove = {}

local updatePlayerAllyHealthsTimer = nil

local writeplayerAllyHealths = function()
	jsonInterface.quicksave(jsonName, playerAllyHealths)
end

local getPidByName = function(name)

	for pid, player in pairs(Players) do
		if string.lower(name) == string.lower(player.accountName) then
			return pid
		end
	end
	
	return nil
end

local processPlayerNamesToRemove = function()
	-- Remove player entry in every ally's health table
	-- Remove player's health table itself
	-- Remove player's name from playerNamesToRemove table
	for _, playerName in ipairs(playerNamesToRemove) do
		playerHealths = playerAllyHealths[playerName]
		for otherPlayerName, _ in pairs(playerHealths) do
			otherPlayerHealths = playerAllyHealths[otherPlayerName]
			otherPlayerHealths[playerName] = nil
		end
		
		playerAllyHealths[playerName] = nil
		table.remove(playerNamesToRemove, playerName)
	end
	
	-- Make sure there are no left over nil values
	tableHelper.cleanNils(playerAllyHealths)
end

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	writeplayerAllyHealths()
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	-- Do not start timer if there are less than 2 players
	if tableHelper.getCount(Players) < 2 then return end
	
	if updatePlayerAllyHealthsTimer == nil then 
		updatePlayerAllyHealthsTimer = tes3mp.CreateTimer("updatePlayerAllyHealths", 10)
		tes3mp.StartTimer(updatePlayerAllyHealthsTimer)
	end
end)

customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)

	local playerName = Players[pid].accountName
	table.insert(playerNamesToRemove, playerName)
end)

updatePlayerAllyHealths = function()
	-- Destroy timer if there are less than 2 players
	if tableHelper.getCount(Players) < 2 then
		-- Destroy timer
		tes3mp.StopTimer(updatePlayerAllyHealthsTimer)
		updatePlayerAllyHealthsTimer = nil
		-- Reset json file
		playerAllyHealths = {}
		playerNamesToRemove = {}
		writeplayerAllyHealths()
		return
	end
	
	processPlayerNamesToRemove()
	
	-- update allies health table for every logged player
	for pid, player in pairs(Players) do
		local playerName = player.accountName
		
		if playerAllyHealths[playerName] == nil then playerAllyHealths[playerName] = {} end
		
		local allyHealths = playerAllyHealths[playerName]
		local alliedPlayers = Players[pid].data.alliedPlayers
		
		for _, allyPlayerName in ipairs(alliedPlayers) do
			local alliedPid = getPidByName(allyPlayerName)
			
			if Players[alliedPid] ~= nil and Players[alliedPid]:IsLoggedIn() then
				if allyHealths[allyPlayerName] == nil then allyHealths[allyPlayerName] = {} end
				
				allyHealths[allyPlayerName] = {base = tes3mp.GetHealthBase(alliedPid), current = tes3mp.GetHealthCurrent(alliedPid)}
			end
		end
	end
	writeplayerAllyHealths()
	if updatePlayerAllyHealthsTimer == nil then return end
	tes3mp.RestartTimer(updatePlayerAllyHealthsTimer, 10)
end