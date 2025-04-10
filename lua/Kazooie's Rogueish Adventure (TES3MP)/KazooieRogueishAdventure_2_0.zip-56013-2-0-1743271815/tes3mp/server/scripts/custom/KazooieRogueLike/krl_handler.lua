function KRL_IsGameWon()
    return KRL_GetSaveData("gameWon")
end

function KRL_OpenExitDoor(doorType)
	if KRL_IsGameWon() then
		for _, player in pairs(Players) do
			KRL_TeleportToCell(player.pid, KRL_ALDRUHN)
		end

		return
	end

	local livingPlayers = {}

	for _, player in pairs(Players) do
		KRL_RemovePlayerItem(player.pid, "kazooie_key")

    	if not KRL_IsPlayerWiped(player.pid) then
			table.insert(livingPlayers, player.accountName)
		end

		local currentCell = tes3mp.GetCell(player.pid)

		if currentCell == KRL_DEATH_CELL then
			Players[player.pid].data.customVariables.deathCellPos = {tes3mp.GetPosX(player.pid), tes3mp.GetPosY(player.pid), tes3mp.GetPosZ(player.pid)}
			Players[player.pid].data.customVariables.deathCellTeleportTime = os.time()
		end
	end

	KRL_SaveData("LivingPlayers", livingPlayers)

	KRL_UpdateDifficulty()

	local levelRoomCount = KRL_GetSaveData("levelRoomCount") or 0

	local roomsUntilShop = KRL_GetSaveData("roomsUntilShop")
	if not roomsUntilShop then error("KRL data has no roomsUntilShop?") end

	if doorType == "Inn" then
		levelRoomCount = 0
	elseif doorType == "Exit" then
		levelRoomCount = levelRoomCount + 1
		roomsUntilShop = roomsUntilShop - 1

		KRL_SaveData("roomsUntilShop", roomsUntilShop)
	end

	KRL_SaveData("levelRoomCount", levelRoomCount)

	local nextCell, roomType = KRL_GetNextRandomCell(doorType)

	if nextCell == KRL_FIFTH_BOSS_CELL and KRL_HasJournalIndex("kazooie_uliz", 120) then
		nextCell = KRL_VENGEANCE_CELL
		roomType = KRL_ROOM_TYPE_SPECIAL
	end

	if not nextCell then
		error("failed to get the next cell for ["..tostring(doorType).."] door")
	end

	KRL_SaveData("activeCell", nextCell)

	if roomType == KRL_ROOM_TYPE_NORMAL then
		local visitedRooms = KRL_GetSaveData("visitedRooms") or {}
		visitedRooms[nextCell] = true
	    KRL_SaveData("visitedRooms", visitedRooms)
	end

	for _, accountName in pairs(livingPlayers) do
		local player = KRL_GetPlayerByName(accountName)

		if player then
			if nextCell == KRL_BUFFS_CELL then
				player.data.customVariables.pulledBuffCrank = false
			end

			KRL_TeleportToCell(player.pid, nextCell)

			local currentMagicka = tes3mp.GetMagickaCurrent(player.pid)
			local maxMagicka = tes3mp.GetMagickaBase(player.pid)
			local newMagicka = math.min(maxMagicka, currentMagicka + math.ceil(maxMagicka / 2))

			tes3mp.SetMagickaCurrent(player.pid, newMagicka)
		    tes3mp.SetFatigueCurrent(player.pid, tes3mp.GetFatigueBase(player.pid))
    		tes3mp.SendStatsDynamic(player.pid)
		end
	end

	KRL_SaveData("playerGrabbedExitKey", false)

	KRL_OnRoomEntered(nextCell)
end

function KRL_ResetRoomsUntilShop()
	local roomsUntilShop = math.random(KRL_CONFIG.minimumRoomsUntilShop, KRL_CONFIG.maximumRoomsUntilShop)
	KRL_SaveData("roomsUntilShop", roomsUntilShop)
end

function KRL_LevelUpHighestSkill(pid)
	local player = KRL_GetPlayer(pid)

	if player then
		local skills = LevelingFramework.getClass(pid)
		local majorSkills = krl_array(skills.majorSkills).shallow_copy()
		local minorSkills = krl_array(skills.minorSkills).shallow_copy()
		local levelingSkills = krl_array(majorSkills).merge(minorSkills)

		local highestSkillName = nil
		local highestSkillLevel = -1

		for _, skillName in pairs(levelingSkills) do
			local skillLevel = player.data.skills[skillName].base

			if skillLevel > highestSkillLevel then
				highestSkillLevel = skillLevel
				highestSkillName = skillName
			end
		end

		LevelingFramework.increaseSkill(pid, highestSkillName, 1, false)

		player:LoadLevel()
		player:LoadSkills()
        player:LoadAttributes()
        player:LoadSkills()
        player:LoadStatsDynamic()
	end
end

function KRL_LevelupPlayer(pid)
	local skills = LevelingFramework.getClass(pid)
	local player = KRL_GetPlayer(pid)
	local skill_increases_remaining = 10 - player.data.stats.levelProgress

	if skill_increases_remaining > 0 then
		local majorSkills = krl_array(skills.majorSkills).shallow_copy()
		local minorSkills = krl_array(skills.minorSkills).shallow_copy()
		local levelingSkills = krl_array(majorSkills).merge(minorSkills)
		local shuffledSkills = krl_array(levelingSkills).shuffle()

		for i = 1, skill_increases_remaining do
			LevelingFramework.increaseSkill(pid, shuffledSkills[i], 1, false)
		end

		player:LoadLevel()
		player:LoadSkills()
	    player:LoadAttributes()
	    player:LoadSkills()
	    player:LoadStatsDynamic()

	    return true
	end

	return false
end

function KRL_LevelupLowestPlayers()
	local expectedLevel = KRL_GetSaveData("expectedLevel") or 1
	local livingPlayers = KRL_GetSaveData("LivingPlayers") or {}

	for _, accountName in pairs(livingPlayers) do
		local player = KRL_GetPlayerByName(accountName)

		if player then
			local player_level = player.data.stats.level

			if player_level < (expectedLevel + 1) then
				KRL_LevelupPlayer(player.pid)
			end
		end
	end
end

function KRL_ResetWorld()
    WorldInstance.data.kills = {}
    WorldInstance.data.topics = {}
    WorldInstance.data.journal = {}
    WorldInstance.data.customVariables = {}
    WorldInstance.data.fame = {
   		reputation = 0,
    	bounty = 0
    }
    WorldInstance.data.destinationOverrides = {}
	WorldInstance.data.factionRanks = {}
	WorldInstance.data.factionReputation = {}
	WorldInstance.data.mapExplored = {}
	WorldInstance.data.factionExpulsion = {}
end

function KRL_Reset()
	KRL_SaveData("LivingPlayers", {})
	KRL_SaveData("activeCell", KRL_START_CELL)
	KRL_SaveData("visitedRooms", {})
	KRL_SaveData("resetting", false)
	KRL_SaveData("gameWon", false)
	KRL_SaveData("expectedLevel", 1)
	KRL_SaveData("levelRoomCount", 0)

	local runNumber = KRL_GetSaveData("runNumber") or 1
	KRL_SaveData("runNumber", runNumber + 1)

    KRL_ResetWorld()
	KRL_ResetAllCustomCells()
end

function KRL_OnNewRunStarted()
	KRL_SaveData("expectedLevel", 1)

	local runNumber = KRL_GetSaveData("runNumber") or 1

	for _, player in pairs(Players) do
		if not Players[player.pid].data.customVariables.runNumber then
			Players[player.pid].data.customVariables.runNumber = runNumber
		end
	end
end

function KRL_OnAllPlayersDied()
	for _, player in pairs(Players) do
		KRL_TeleportToCell(player.pid, KRL_DEATH_CELL)
		Players[player.pid].data.customVariables.krlDied = true
		KRL_DisplayWipedCharacterGUI(player.pid)
	end

	KRL_SimpleTimer(1, function()
		KRL_Reset()
	end)
end

customEventHooks.registerValidator("OnPlayerDeath", function(_, pid)
	if KRL_IsGameWon() then return end

	KRL_AddStats(pid, "deaths")

	local activeCell = KRL_GetSaveData("activeCell")

	if activeCell and activeCell == KRL_START_CELL then return end

	local player = KRL_GetPlayer(pid)
	local livingPlayers = KRL_GetSaveData("LivingPlayers") or {}

	krl_array(livingPlayers).find_and_remove(function(accountName)
		return player.accountName == accountName
	end)

	KRL_SaveData("LivingPlayers", livingPlayers)

	if #livingPlayers <= 0 then
		KRL_OnAllPlayersDied()
	end
end)

customEventHooks.registerValidator("OnActorDeath", function(_, pid, cellName, actors)
	for _, actor in pairs(actors) do
		if actor and actor.killer and actor.killer.pid then
			KRL_AddStats(actor.killer.pid, "kills")
		end
	end
end)

function KRL_IsPlayerWiped(pid)
	if Players[pid].data.customVariables.krlDied then return true end

	local runNumber = KRL_GetSaveData("runNumber") or 1
	local playerRunNumber = Players[pid].data.customVariables.runNumber

	if playerRunNumber and (runNumber ~= playerRunNumber) then return true end

	return false
end

-- for some stupid reason, jsonInterface appends tes3mp.GetModDir() for you
-- so, if you use jsonInterface, you must not include tes3mp.GetModDir()
-- if you use tes3mp.DoesFileExist(), you must include tes3mp.GetModDir()
-- if you use jsonInterface.ioLibrary, you must include tes3mp.GetModDir()

local initialPlayerDataDirectory = "/custom/krl_init_players"

local function getInitialPlayerDataFilePath(accountName)
	return initialPlayerDataDirectory.."/"..accountName..".json"
end

local function saveInitialPlayerData(player)
	tes3mp.LogMessage(enumerations.log.INFO, "saving initial player data for: ["..tostring(player.accountName).."]")

	jsonInterface.createDirectoryIfNotExists(initialPlayerDataDirectory)

	local playerDataFilePath = "/player/"..player.accountName..".json"

    if tes3mp.DoesFileExist(tes3mp.GetModDir()..playerDataFilePath) then
    	local playerData = jsonInterface.load(playerDataFilePath)
		local initialPlayerDataFilePath = getInitialPlayerDataFilePath(player.accountName)

		jsonInterface.quicksave(initialPlayerDataFilePath, playerData)

		tes3mp.LogMessage(enumerations.log.INFO, "initial player data saved: ["..tostring(initialPlayerDataFilePath).."]")
	end
end

local function resetPlayerToInitialPlayerData(accountName)
	local playerDataFilePath = "/player/"..accountName..".json"
    local initialPlayerDataFilePath = getInitialPlayerDataFilePath(accountName)

    if not tes3mp.DoesFileExist(tes3mp.GetModDir()..playerDataFilePath) then
    	KRL_Log(0, "could not reset, failed to find player data", accountName)
    	return
    end

    if not tes3mp.DoesFileExist(tes3mp.GetModDir()..initialPlayerDataFilePath) then
    	KRL_Log(0, "could not reset, failed to find initial player data", accountName)
    	return
    end

    tes3mp.LogMessage(enumerations.log.INFO, "deleting player data: ["..tostring(playerDataFilePath).."]")
    jsonInterface.ioLibrary.fs.rm(tes3mp.GetModDir()..playerDataFilePath)

    local initialPlayerData = jsonInterface.load(initialPlayerDataFilePath)
    jsonInterface.quicksave(playerDataFilePath, initialPlayerData)

    tes3mp.LogMessage(enumerations.log.INFO, "reset to initial player data: ["..tostring(playerDataFilePath).."]")
end

customEventHooks.registerHandler("OnPlayerAuthentified", function(_, pid)
    if not KRL_IsPlayerValid(pid) then return end

    if not Players[pid].data.customVariables.playerInitialized then
    	Players[pid].data.customVariables.playerInitialized = true
    	KRL_GivePlayerItem(pid, "kazooie_key_chest")
		saveInitialPlayerData(Players[pid])
    end

    if KRL_IsPlayerWiped(pid) then
    	KRL_DisplayWipedCharacterGUI(pid)
    end
end)

local makeNewCharacterGuid = 19208
local jimmyKeyGuid = 192082

function KRL_DisplayWipedCharacterGUI(pid)
	tes3mp.CustomMessageBox(pid, makeNewCharacterGuid, "This character got party wiped. Click Leave to quit the game. Click Reset to quit the game, and reset this character to level 1, allowing it to be used again.", "Leave; Reset")
end

function KRL_DisplayJimmyKeyGuid(pid)
	tes3mp.CustomMessageBox(pid, jimmyKeyGuid, "Would you like to restart the game?", "Restart Game; Pickup the Key")
end

customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
    if not KRL_IsPlayerValid(pid) then return end
    if guiId ~= makeNewCharacterGuid then return end

    local accountName = KRL_GetPlayer(pid).accountName
    local selection = tonumber(data)

    tes3mp.Kick(pid)

    if selection == 1 then
	    KRL_SimpleTimer(0.5, function()
	    	resetPlayerToInitialPlayerData(accountName)
	    end)
	end
end)

customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
    if not KRL_IsPlayerValid(pid) then return end
    if guiId ~= jimmyKeyGuid then return end

    local selection = tonumber(data)

    if selection == 0 then
    	KRL_SaveData("gameWon", false)
    	KRL_OnAllPlayersDied()
    end
end)

customEventHooks.registerHandler("OnPlayerInventory", function(eventStatus, pid)
	if not KRL_GetSaveData("playerGrabbedExitKey") and KRL_GetPlayerItem(pid, "kazooie_key") then
		KRL_AddStats(pid, "keys")
		KRL_SaveData("playerGrabbedExitKey", true)
	end
end)
