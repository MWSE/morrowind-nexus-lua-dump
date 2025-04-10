function KRL_IsPlayerValid(pid)
    local player = Players[pid]

    if not player then return false end
    if not player:IsLoggedIn() then return false end

    return true
end

function KRL_Log(pidOrMessage, messageOrLabel, messageOptional)
    if messageOrLabel == nil then
        tes3mp.LogMessage(enumerations.log.WARN, tostring(pidOrMessage))
    elseif messageOptional == nil then
        tes3mp.LogMessage(enumerations.log.WARN, "pid ["..tostring(pidOrMessage).."] "..tostring(messageOrLabel))
    else
        tes3mp.LogMessage(enumerations.log.WARN, "pid ["..tostring(pidOrMessage).."] "..tostring(messageOrLabel).." "..tostring(messageOptional))
    end
end

function KRL_Vector(x, y, z)
    return {x = x, y = y, z = z}
end

function KRL_Angle(x, z)
    return {x = x, z = z}
end

function KRL_RollLuck(percentChance)
    return math.random() < (percentChance / 100)
end

function KRL_GetPlayer(pid)
    return Players[pid]
end

function KRL_GetPlayerByName(accountName)
    for _, player in pairs(Players) do
        if player.accountName == accountName then
            return player
        end
    end
end

function KRL_GetPlayerPos(pid)
    local player = KRL_GetPlayer(pid)
    local location = player.data.location

    return KRL_Vector(location.posX, location.posY, location.posZ)
end

function KRL_GetPlayerAngle(pid)
    local player = KRL_GetPlayer(pid)
    local location = player.data.location

    return KRL_Angle(location.rotX, location.rotZ)
end

function KRL_PrintPlayerPos(pid)
    local pos = KRL_GetPlayerPos(pid)
    KRL_Log(pid, "pos: ("..pos.x..", "..pos.y..", "..pos.z..")")
end

function KRL_PrintPlayerAngle(pid)
    local ang = KRL_GetPlayerAngle(pid)
    KRL_Log(pid, "ang: ("..ang.x..", "..ang.z..")")
end

function KRL_IsPlayerLiving(pid)
    local player = KRL_GetPlayer(pid)

    if not KRL_IsPlayerValid(pid) then return end

    local livingPlayers = KRL_GetSaveData("LivingPlayers") or {}

    return krl_array(livingPlayers).some(function(livingPlayer)
        return livingPlayer == player.accountName
    end)
end

function KRL_GetPlayerItem(pid, itemId)
    local player = KRL_GetPlayer(pid)
    local itemIndex = inventoryHelper.getItemIndex(player.data.inventory, string.lower(itemId))

    return itemIndex and player.data.inventory[itemIndex]
end

function KRL_GivePlayerItem(pid, itemId, count)
    count = count or 1

    local player = KRL_GetPlayer(pid)
    local item = {refId = string.lower(itemId), count = count}

    inventoryHelper.addItem(player.data.inventory, string.lower(itemId), count)
    player:LoadItemChanges({item}, enumerations.inventory.ADD)
end

function KRL_RemovePlayerItem(pid, itemId, count)
    local item = KRL_GetPlayerItem(pid, itemId)

    if not item then return end

    if not count then
        count = item.count
    end

    count = math.min(count, item.count)

    local player = KRL_GetPlayer(pid)
    local item = {refId = string.lower(itemId), count = count}

    inventoryHelper.removeExactItem(player.data.inventory, string.lower(itemId), count, -1, -1, "")
    player:LoadItemChanges({item}, enumerations.inventory.REMOVE)
end

local lastDifficulty = nil

local function getDifficultyNiceText(difficulty)
    if difficulty >= 100 then
        return "Extremely Hard"
    elseif difficulty >= 90 then
        return "Extremely Hard"
    elseif difficulty >= 75 then
        return "Very Hard"
    elseif difficulty >= 60 then
        return "Very Hard"
    elseif difficulty >= 45 then
        return "Hard"
    elseif difficulty >= 30 then
        return "Hard"
    elseif difficulty >= 15 then
        return "Normal"
    elseif difficulty >= 0 then
        return "Normal"
    end

    return "Easy"
end

function KRL_UpdateDifficulty()
    if not KRL_CONFIG.enableDifficultyPerPlayer then return end

    local maxPlayers = KRL_CONFIG.maxPlayersUntilDifficultyIncrease
    local difficultyPerPlayer = KRL_CONFIG.difficultyPerPlayer
    local difficulty = 0

    local livingPlayers = KRL_GetSaveData("LivingPlayers") or {}

    if difficultyPerPlayer > 0 and #livingPlayers > maxPlayers then
        local totalDifficultyPerPlayer = difficultyPerPlayer * (#livingPlayers - maxPlayers)
        difficulty = math.min(KRL_CONFIG.baseDifficulty + totalDifficultyPerPlayer, KRL_CONFIG.maxDifficulty)
    end

    config.difficulty = difficulty
    tes3mp.SetRuleValue("difficulty", difficulty)

    for _, accountName in pairs(livingPlayers) do
        local player = KRL_GetPlayerByName(accountName)

        if player then
            player:SetDifficulty(difficulty)
            tes3mp.SetDifficulty(player.pid, difficulty)
            tes3mp.SendSettings(player.pid)
        end
    end

    if difficulty ~= lastDifficulty then
        KRL_SimpleTimer(3, function()
            if difficulty then
                local difficultyNiceText = getDifficultyNiceText(difficulty)
                KRL_MessageBoxAll("Difficulty set to "..tostring(difficulty).."/100 ("..difficultyNiceText..") due to party size.")
            end
        end)
    end

    lastDifficulty = difficulty
end

function KRL_CalculateAverageLevel()
    local playerCount = 0
    local totalLevel = 0

    for _, player in pairs(Players) do
        local pid = player.pid

        if not KRL_IsPlayerWiped(pid) then
            playerCount = playerCount + 1
            totalLevel = totalLevel + tes3mp.GetLevel(pid)
        end
    end

    return math.floor(totalLevel / playerCount)
end

function KRL_HasJournalIndex(questRefId, journalIndex)
    for _, journalEntry in pairs(WorldInstance.data.journal or {}) do
        if journalEntry.quest == questRefId and journalEntry.index == journalIndex then
            return true
        end
    end

    return false
end

function KRL_GetObjectIndexesByRefId(refId, cellName)
    local objectsIndexes = {}

    for objectIndex, item in pairs(LoadedCells[cellName].data.objectData or {}) do
        if item and item.refId and item.refId == refId then
            table.insert(objectsIndexes, objectIndex)
        end
    end

    return objectsIndexes
end

function KRL_MessageBoxAll(message)
    for _, player in pairs(Players) do
        tes3mp.MessageBox(player.pid, -1, message)
    end
end

function KRL_GetStats(pid, statName)
    if not Players[pid] then return end
    if not Players[pid].data then return end
    if not Players[pid].data.customVariables then return end

    if not Players[pid].data.customVariables.krlStats then
        Players[pid].data.customVariables.krlStats = {}
    end

    return Players[pid].data.customVariables.krlStats[statName] or 0
end

function KRL_SetStats(pid, statName, value)
    if not Players[pid] then return end
    if not Players[pid].data then return end
    if not Players[pid].data.customVariables then return end

    if not Players[pid].data.customVariables.krlStats then
        Players[pid].data.customVariables.krlStats = {}
    end

    Players[pid].data.customVariables.krlStats[statName] = value
end

function KRL_AddStats(pid, statName, toAdd)
    KRL_SetStats(pid, statName, KRL_GetStats(pid, statName) + (toAdd or 1))
end

local timerId = 1

function KRL_SimpleTimer(duration, timerFunc)
    local globalFuncName = "KRL_Timer_"..tostring(timerId)
    timerId = timerId + 1

    _G[globalFuncName] = function()
        timerFunc()
        _G[globalFuncName] = nil
    end

    local simpleTimer = tes3mp.CreateTimer(globalFuncName, time.seconds(duration))
    tes3mp.StartTimer(simpleTimer)
end

function krl_clamp(value, min, max)
    if value > max then return max end
    if value < min then return min end

    return value
end

function krl_array(arr)
    return {
        map = function(map_func)
            local result = {}

            for _, element in pairs(arr) do
                table.insert(result, map_func(element))
            end

            return result
        end,
        filter = function(filter_func)
            local result = {}

            for _, element in pairs(arr) do
                if filter_func(element) then
                    table.insert(result, element)
                end
            end

            return result
        end,
        find = function(find_func)
            for _, element in pairs(arr) do
                if find_func(element) then
                    return element
                end
            end
        end,
        find_index = function(find_func)
            for index, element in pairs(arr) do
                if find_func(element) then
                    return index
                end
            end
        end,
        some = function(some_func)
            for _, element in pairs(arr) do
                if some_func(element) then
                    return true
                end
            end

            return false
        end,
        every = function(every_func)
            for _, element in pairs(arr) do
                if not every_func(element) then
                    return false
                end
            end

            return true
        end,
        has = function(target_item)
            for _, element in pairs(arr) do
                if element == target_item then
                    return true
                end
            end

            return false
        end,
        join = function(separator)
            local result = ""
            
            for i, v in ipairs(arr) do
                result = result..tostring(v)

                if i < #arr then
                    result = result..separator
                end
            end
            
            return result
        end,
        find_and_remove = function(find_func)
            local found_index = nil

            for index, element in pairs(arr) do
                if find_func(element) then
                    found_index = index
                    break
                end
            end

            if found_index then
                return table.remove(arr, found_index)
            end
        end,
        shuffle = function()
            local tbl = {}

            for i = 1, #arr do
                tbl[i] = arr[i]
            end

            for i = #tbl, 2, -1 do
                local j = math.random(i)
                tbl[i], tbl[j] = tbl[j], tbl[i]
            end

            return tbl
        end,
        shallow_copy = function()
            local tableCopy = {}

            for k, v in pairs(arr) do
                tableCopy[k] = v
            end

            return tableCopy
        end,
        merge = function(other_table)
            local result = {}

            for _, v in pairs(arr) do
                table.insert(result, v)
            end

            for _, v in pairs(other_table) do
                table.insert(result, v)
            end

            return result
        end
    }
end
