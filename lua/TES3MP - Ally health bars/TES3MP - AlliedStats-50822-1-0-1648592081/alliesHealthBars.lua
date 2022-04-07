local jsonName = "alliesHealthBars.json"

local playersData = {}
local disconnectedPlayers = {}

local updatePlayerAlliesDataTimer = nil

local writeplayersData = function()
	jsonInterface.quicksave(jsonName, playersData)
end

local getPidByName = function(name)

	for pid, player in pairs(Players) do
		if string.lower(name) == string.lower(player.accountName) then
			return pid
		end
	end
	
	return nil
end

-- Resolve entries for players who are no longer in alliance
local processUnAlliedPlayers = function(playerName, alliedPlayers)
	
	local alliesData = playersData[playerName].alliesData
	for alliedPlayerName, _ in pairs(alliesData) do
		if not tableHelper.containsValue(alliedPlayers, alliedPlayerName, false) then
			-- Remove previously allied player from this player
			alliesData[alliedPlayerName] = nil
			
			-- Also remove this player from previously allied player
			local previousAllyAlliesData = playersData[alliedPlayerName].alliesData
			previousAllyAlliesData[playerName] = nil
		end
	end
end

-- Resolve disconnected player's entries
local processDisconnectedPlayers = function()
	-- Remove player entry from allies data of all allied players
	-- Remove player's data
	-- Remove player's name from disconnectedPlayers table
	for _, playerName in ipairs(disconnectedPlayers) do
		local playerAlliesData = playersData[playerName].alliesData
		for otherPlayerName, _ in pairs(playerAlliesData) do
			local otherPlayerAlliesData = playersData[otherPlayerName].alliesData
			otherPlayerAlliesData[playerName] = nil
		end
		
		playersData[playerName] = nil
		tableHelper.removeValue(disconnectedPlayers, playerName)
	end
	
	-- Make sure there are no left over nil values
	tableHelper.cleanNils(playersData)
	tableHelper.cleanNils(disconnectedPlayers)
end

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	writeplayersData()
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	-- Do not start timer if there are less than 2 players
	if tableHelper.getCount(Players) < 2 then return end
	
	if updatePlayerAlliesDataTimer == nil then 
		updatePlayerAlliesDataTimer = tes3mp.CreateTimer("updatePlayerAlliesData", 10)
		tes3mp.StartTimer(updatePlayerAlliesDataTimer)
	end
end)

customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)
	local playerName = Players[pid].accountName
	table.insert(disconnectedPlayers, playerName)
end)

updatePlayerAlliesData = function()
	-- Destroy timer if there are less than 2 players
	if tableHelper.getCount(Players) < 2 then
		-- Destroy timer
		tes3mp.StopTimer(updatePlayerAlliesDataTimer)
		updatePlayerAlliesDataTimer = nil
		return
	end
	
	processDisconnectedPlayers()
	
	-- update allies health table for every logged player
	for pid, player in pairs(Players) do
		local playerName = player.accountName
		
		if playersData[playerName] == nil then playersData[playerName] = {ip = tes3mp.GetIP(pid), alliesData = {}} end
		
		local alliesData = playersData[playerName].alliesData
		local alliedPlayers = Players[pid].data.alliedPlayers
		
		processUnAlliedPlayers(playerName, alliedPlayers)
		
		for _, allyPlayerName in ipairs(alliedPlayers) do
			local alliedPid = getPidByName(allyPlayerName)
			
			if Players[alliedPid] ~= nil and Players[alliedPid]:IsLoggedIn() then				
				alliesData[allyPlayerName] = {
					level = tes3mp.GetLevel(alliedPid), 
					baseHealth = tes3mp.GetHealthBase(alliedPid), 
					currentHealth = tes3mp.GetHealthCurrent(alliedPid),
					baseMagicka = tes3mp.GetMagickaBase(alliedPid),
					currentMagicka = tes3mp.GetMagickaCurrent(alliedPid),
					baseFatigue = tes3mp.GetFatigueBase(alliedPid),
					currentFatigue = tes3mp.GetFatigueCurrent(alliedPid)
					}
			end
		end
	end
	writeplayersData()
	if updatePlayerAlliesDataTimer == nil then return end
	tes3mp.RestartTimer(updatePlayerAlliesDataTimer, 10)
end