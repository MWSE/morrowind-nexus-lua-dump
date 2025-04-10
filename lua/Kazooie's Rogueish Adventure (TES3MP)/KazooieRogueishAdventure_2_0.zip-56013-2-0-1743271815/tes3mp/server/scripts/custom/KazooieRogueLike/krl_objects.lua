local scripted_objects = {}

local function setupScriptedObject(refId, on_activate_func)
    scripted_objects[refId] = on_activate_func
end

local function hasExitKey(pid)
    local exitKey = KRL_GetPlayerItem(pid, "kazooie_key")
    if exitKey then return true end

    local jimmyKey = KRL_GetPlayerItem(pid, "krl_jimmy_key")
    if jimmyKey then return true end

    return false
end

local function shouldLeaveRoom(pid)
    local player = KRL_GetPlayer(pid)

    if hasExitKey(pid) then return true end

    local otherPlayerWithKey = nil

    for _, player in pairs(Players) do
        if hasExitKey(player.pid) then
            otherPlayerWithKey = player
            break
        end
    end

    if otherPlayerWithKey and KRL_IsPlayerLiving(otherPlayerWithKey.pid) then
        KRL_MessageBoxAll(tostring(player.accountName).." wants to leave, but "..tostring(otherPlayerWithKey.accountName).." has the key.")
        return false 
    end

    if KRL_GetSaveData("playerGrabbedExitKey") then return true end

    return false
end

local function getNextExpectedLevel()
    local nextExpectedLevel = (KRL_GetSaveData("expectedLevel") or 1) + 1
    local averageLevel = KRL_CalculateAverageLevel()

    if averageLevel > nextExpectedLevel then
        if nextExpectedLevel <= 5 then return 5 end
        return math.min(averageLevel, KRL_CONFIG.maxRoomLevel)
    end

    return nextExpectedLevel
end

setupScriptedObject("kazooie_door_inn", function(pid, cellName, object)
    if not KRL_IsGameWon() then
        local activeCell = KRL_GetSaveData("activeCell")

        if activeCell == KRL_SHOP_CELL then
            KRL_TeleportToCell(pid, KRL_SHOP_CELL, KRL_Vector(2646, 3661, 20768), KRL_Angle(0, 0))
            return
        end

        local nextExpectedLevel = getNextExpectedLevel()

        if nextExpectedLevel >= KRL_CONFIG.maxRoomLevel then
            if not Players[pid].data.customVariables.notifiedAboutFinalLevel then
                Players[pid].data.customVariables.notifiedAboutFinalLevel = true

                for pid, _ in pairs(Players) do
                    tes3mp.CustomMessageBox(pid, 19081, "You've reached the final level! This is the last time you get to stay at this Inn. When you leave the Inn, you will go to the Azerjin shop island. After that is the final level. There's no coming back! If there's anything you want to do. Do it now!", "Ok")
                end

                return
            end

            KRL_SaveData("roomsUntilShop", 0)
        end

        KRL_SaveData("expectedLevel", nextExpectedLevel)
    end

    KRL_OpenExitDoor("Inn")
end)

setupScriptedObject("kazooie_door_shop", function(pid, cellName, object)
    KRL_OpenExitDoor("Shop")

    if KRL_IsGameWon() then return end

    KRL_SimpleTimer(1, function()
        for _, player in pairs(Players) do
            logicHandler.ResetCell(player.pid, KRL_SHOP_CELL)
            logicHandler.ResetCell(player.pid, KRL_SHOP_CELL_GUNS)
            logicHandler.ResetCell(player.pid, KRL_SHOP_CELL_EXCHANGE)
        end

        KRL_ResetCell(KRL_SHOP_CELL)
        KRL_ResetCell(KRL_SHOP_CELL_GUNS)
        KRL_ResetCell(KRL_SHOP_CELL_EXCHANGE)
    end)
end)

setupScriptedObject("kazooie_door_exit_buffs", function(pid, cellName, object)
    if shouldLeaveRoom(pid) then
        KRL_OpenExitDoor("BuffsOrDebuffs")

        KRL_SimpleTimer(1, function()
            for _, player in pairs(Players) do
                logicHandler.ResetCell(player.pid, cellName)
            end

            KRL_ResetCell(cellName)
        end)
    end
end)

setupScriptedObject("kazooie_door_exit_reset", function(pid, cellName, object)
    if shouldLeaveRoom(pid) then
        KRL_OpenExitDoor("Exit")

        KRL_SimpleTimer(1, function()
            for _, player in pairs(Players) do
                logicHandler.ResetCell(player.pid, cellName)
            end

            KRL_ResetCell(cellName)
        end)
    end
end)

setupScriptedObject("kazooie_door_start", function(pid, cellName, object)
    if shouldLeaveRoom(pid) then
        KRL_ResetRoomsUntilShop()
        KRL_OpenExitDoor("Start")
        KRL_OnNewRunStarted()
    end
end)

setupScriptedObject("kazooie_door_boss", function(pid, cellName, object)
    if shouldLeaveRoom(pid) then
        KRL_OpenExitDoor("Boss")

        if not KRL_IsGameWon() then
            KRL_LevelupLowestPlayers()

            if WorldInstance and WorldInstance.data and WorldInstance.data.fame then
                WorldInstance.data.fame.bounty = 0
            end

            for _, player in pairs(Players) do
                local curPid = player.pid
                tes3mp.SetBounty(curPid, 0)
                tes3mp.SendBounty(curPid)

                if Players[curPid] and Players[curPid].data.cooldowns then
                    for _, cooldown in pairs(Players[curPid].data.cooldowns) do
                        tes3mp.ClearCooldownChanges(curPid)
                            tes3mp.AddCooldownSpell(curPid, cooldown.spellId, 0, 0)
                        tes3mp.SendCooldownChanges(curPid)
                    end

                    Players[curPid].data.cooldowns = {}
                end
            end
        end
    end
end)

setupScriptedObject("kazooie_exit_door", function(pid, cellName, object)
    if shouldLeaveRoom(pid) then
        KRL_OpenExitDoor("Exit")
    end
end)

setupScriptedObject("kazooie_start_chest", function(pid, cellName, object)
    local startChestKey = KRL_GetPlayerItem(pid, "kazooie_key_chest")
    local alreadyUnlocked = LoadedCells[cellName].data.objectData[object.uniqueIndex].krlUnlocked

    if startChestKey and not alreadyUnlocked then
        LoadedCells[cellName].data.objectData[object.uniqueIndex].krlUnlocked = true

        KRL_SimpleTimer(0, function()
            if KRL_IsPlayerValid(pid) then
                KRL_RemovePlayerItem(pid, "kazooie_key_chest")
            end
        end)
    end
end)

setupScriptedObject("kazooie_crank_check", function(pid, cellName, object)
    local activeLivingPlayerCount = 0
    local totalPlayerCount = 0

    for _, player in pairs(Players) do
        local otherPid = player.pid

        if KRL_IsPlayerLiving(otherPid) then
            activeLivingPlayerCount = activeLivingPlayerCount + 1
        end

        totalPlayerCount = totalPlayerCount + 1
    end

    local livingPlayers = KRL_GetSaveData("LivingPlayers") or {}
    local aliveButNotOnServerCount = #livingPlayers - activeLivingPlayerCount
    local checkMessage = tostring(activeLivingPlayerCount).."/"..tostring(totalPlayerCount).." players are active. "
    checkMessage = checkMessage..tostring(aliveButNotOnServerCount).." players are alive, but not on the server. "

    if activeLivingPlayerCount <= 0 and aliveButNotOnServerCount > 0 then
        checkMessage = checkMessage.."You are allowed to pull the Reset Game crank."
    end

    tes3mp.MessageBox(pid, -1, checkMessage)
end)

setupScriptedObject("kazooie_crank_reset", function(pid, cellName, object)
    for _, player in pairs(Players) do
        local otherPid = player.pid

        if KRL_IsPlayerLiving(otherPid) then
            tes3mp.MessageBox(pid, -1, "Cannot reset game. Another player is still alive and active.")
            return
        end
    end

    if KRL_GetSaveData("resetting") then
        tes3mp.MessageBox(pid, -1, "Game is already resetting.")
        return
    end

    local playerName = Players[pid].accountName

    KRL_MessageBoxAll(tostring(playerName).." has pulled the Reset Game Crank!")
    KRL_SaveData("resetting", true)
    KRL_OnAllPlayersDied()
end)

setupScriptedObject("kazooie_crank_debug", function(pid, cellName, object)
    KRL_LevelupPlayer(pid)
end)

setupScriptedObject("kazooie_crank_debug_2", function(pid, cellName, object)
    local player = KRL_GetPlayer(pid)

    local skills = LevelingFramework.getClass(pid)
    local majorSkills = krl_array(skills.majorSkills).shallow_copy()
    local minorSkills = krl_array(skills.minorSkills).shallow_copy()
    local levelingSkills = krl_array(majorSkills).merge(minorSkills)

    for _, skill in pairs(levelingSkills) do
        LevelingFramework.increaseSkill(pid, skill, 10, false)
    end

    player:LoadLevel()
    player:LoadSkills()
    player:LoadAttributes()
    player:LoadSkills()
    player:LoadStatsDynamic()
end)

setupScriptedObject("kazooie_crank_enemy", function(pid, cellName, object)
    local location = {
        posX = 4634,
        posY = 4524,
        posZ = 11999,
        rotX = 0,
        rotY = 0,
        rotZ = 0
    }

    logicHandler.CreateObjectAtLocation(cellName, location, {refId = "kazooie_boss_debug"}, "spawn")
end)

setupScriptedObject("kazooie_debuff_1", function(pid, cellName, object)
    local gold = KRL_GetPlayerItem(pid, "Gold_001")

    if gold and gold.count >= 100 then
        KRL_RemovePlayerItem(pid, "Gold_001", 100)
        KRL_GivePlayerItem(pid, "kazooie_key")

        tes3mp.MessageBox(pid, -1, "You have lost 100 gold.")
        tes3mp.MessageBox(pid, -1, "You have been given an Exit Key.")
    else
        tes3mp.MessageBox(pid, -1, "You do not have enough gold.")
    end
end)

setupScriptedObject("kazooie_debuff_2", function(pid, cellName, object)
    KRL_CatchRandomDisease(pid)
    KRL_GivePlayerItem(pid, "kazooie_key")

    tes3mp.MessageBox(pid, -1, "You have been given an Exit Key.")
end)

setupScriptedObject("kazooie_debuff_3", function(pid, cellName, object)
    local debuffsCellAccountNames = KRL_GetSaveData("debuffsCellAccountNames") or {}

    for _, accountName in pairs(debuffsCellAccountNames) do
        local player = KRL_GetPlayerByName(accountName)

        if not player or not KRL_IsPlayerLiving(player.pid) then
            tes3mp.MessageBox(pid, -1, "You cannot use this if a player is missing or dead.")
            return
        end
    end

    for _, item in pairs(LoadedCells["Kazooie, Debuffs"].data.objectData or {}) do
        if item and item.refId and item.refId ~= "kazooie_door_exit_buffs" then
            tes3mp.MessageBox(pid, -1, "You cannot use this if there are items on the ground.")
            return
        end
    end

    local playerItems = {}

    for _, player in pairs(Players) do
        for _, item in pairs(player.data.inventory or {}) do
            if item and item.refId then
                table.insert(playerItems, {
                    pid = player.pid,
                    refId = item.refId
                })
            end
        end
    end

    if #playerItems >= 3 then
        local randomPlayerItem = playerItems[math.random(#playerItems)]
        local randomRefId = randomPlayerItem.refId
        local randomPlayer = KRL_GetPlayer(randomPlayerItem.pid)

        KRL_RemovePlayerItem(randomPlayerItem.pid, randomRefId, 1)
        KRL_MessageBoxAll("1 "..tostring(randomRefId).." has been removed from "..tostring(randomPlayer.accountName))
        KRL_GivePlayerItem(pid, "kazooie_key")
        tes3mp.MessageBox(pid, -1, "You have been given an Exit Key.")
    else
        tes3mp.MessageBox(pid, -1, "There are not enough player items to use this.")
    end
end)

setupScriptedObject("kazooie_buff_1", function(pid, cellName, object)
    if Players[pid].data.customVariables.pulledBuffCrank then
        tes3mp.MessageBox(pid, -1, "You already received a buff.")
        return
    end

    KRL_LevelUpHighestSkill(pid)

    Players[pid].data.customVariables.pulledBuffCrank = true
end)

setupScriptedObject("kazooie_buff_2", function(pid, cellName, object)
    if Players[pid].data.customVariables.pulledBuffCrank then
        tes3mp.MessageBox(pid, -1, "You already received a buff.")
        return
    end

    tes3mp.SetHealthCurrent(pid, tes3mp.GetHealthBase(pid))
    tes3mp.SetMagickaCurrent(pid, tes3mp.GetMagickaBase(pid))
    tes3mp.SetFatigueCurrent(pid, tes3mp.GetFatigueBase(pid))
    tes3mp.SendStatsDynamic(pid)

    tes3mp.MessageBox(pid, -1, "You feel rejuvenated.")

    Players[pid].data.customVariables.pulledBuffCrank = true
end)

setupScriptedObject("kazooie_buff_3", function(pid, cellName, object)
    if Players[pid].data.customVariables.pulledBuffCrank then
        tes3mp.MessageBox(pid, -1, "You already received a buff.")
        return
    end

    local lootResult = KRL_OpenMysteryBox()
    local rarity = lootResult.rarity
    local count = lootResult.count
    local item = lootResult.lootItem
    local refId = item.refId
    local itemName = item.name

    KRL_Log(pid, "Trying to give Mystery Box item "..tostring(refId)..".")
    KRL_GivePlayerItem(pid, refId, count)

    tes3mp.MessageBox(pid, -1, "["..rarity.."]".." You get "..tostring(count).." "..tostring(itemName).."!")

    Players[pid].data.customVariables.pulledBuffCrank = true
end)

setupScriptedObject("kazooie_crank_levelup", function(pid, cellName, object)
    local expectedLevel = KRL_GetSaveData("expectedLevel") or 1

    if tes3mp.GetLevel(pid) < expectedLevel then
        local leveledUp = KRL_LevelupPlayer(pid)

        if not leveledUp then
            tes3mp.MessageBox(pid, -1, "You must rest at a bed and level up before pulling the Crank again.")
        end
    else
        tes3mp.MessageBox(pid, -1, "You are already at or over the expected level.")
    end
end)

setupScriptedObject("krl_jimmy_key", function(pid, cellName, object)
    if cellName == "Kazooie, Jimmy_4" then return end
    KRL_DisplayJimmyKeyGuid(pid)
end)

local totalForksCount = 0

setupScriptedObject("kazooie_crank_forks", function(pid, cellName, object)
    local forksChest = nil

    for _, item in pairs(LoadedCells[cellName].data.objectData or {}) do
        if item and item.refId and item.refId == "krl_chest_forks" then
            forksChest = item
            break
        end
    end

    if forksChest then
        local forksCount = 0

        for _, item in pairs(forksChest.inventory) do
            if item and item.refId == "kazooie_fork" then
                forksCount = forksCount + item.count
            end
        end

        if forksCount > 0 then
            totalForksCount = totalForksCount + forksCount

            inventoryHelper.removeExactItem(forksChest.inventory, "kazooie_fork", 19208)

            for _, player in pairs(Players) do
                tes3mp.MessageBox(player.pid, -1, "You have redeemed "..tostring(totalForksCount).."/20 Silver Forks total!")
            end

            local goldToGive = forksCount * 2500
            KRL_GivePlayerItem(pid, "Gold_001", goldToGive)
            tes3mp.MessageBox(pid, -1, "You have been given "..tostring(goldToGive).." gold for the forks.")
        end
    end
end)

setupScriptedObject("krl_view_stats", function(pid, cellName, object)
    local statsIndex = KRL_GetStats(pid, "statsIndex")
    local player = KRL_GetPlayer(statsIndex)

    if player and KRL_IsPlayerValid(player.pid) then
        local kills = tostring(KRL_GetStats(player.pid, "kills"))
        local deaths = tostring(KRL_GetStats(player.pid, "deaths"))
        local keys = tostring(KRL_GetStats(player.pid, "keys"))

        tes3mp.MessageBox(pid, -1, tostring(player.accountName).." had "..kills.." kills, "..deaths.." deaths, and found "..keys.." Exit Keys.")
    end

    KRL_AddStats(pid, "statsIndex")

    if KRL_GetStats(pid, "statsIndex") > #Players then
        KRL_SetStats(pid, "statsIndex", 0)
    end
end)

setupScriptedObject("krl_door_end", function(pid, cellName, object)
    if KRL_GetPlayerItem(pid, "krl_jimmy_key") then
        KRL_SaveData("gameWon", true)

        for _, player in pairs(Players) do
            local curPid = player.pid

            if totalForksCount >= 20 then
                KRL_TeleportToCell(curPid, KRL_DEBUG_CELL)
                tes3mp.MessageBox(curPid, -1, "You collected TWENTY forks! Enjoy the developer room! (seriously, how the fuck?)")
            else
                KRL_TeleportToCell(curPid, KRL_ALDRUHN)
            end
        end
    end
end)

customEventHooks.registerValidator("OnObjectActivate", function(_, pid, cellName, objects, players)
    for _, object in pairs(objects) do
        local refId = object.refId

        if refId and scripted_objects[refId] then
            scripted_objects[refId](pid, cellName, object)
        end
    end
end)
