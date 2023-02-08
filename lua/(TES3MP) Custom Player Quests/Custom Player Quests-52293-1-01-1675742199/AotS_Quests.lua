-- Created by Vidi_Aquam
-- Feel free to use and edit with credit
-- I can be contacted on Discord as Vidi_Aquam#8368

AotS_Quests = {}

local tempSelectedData = {}

local itemRecordTypes = {"Armor", "Weapon", 'MiscItem', 'Ingredient', 'Alchemy', 'Clothing', 'Book', 'Light', 'Apparatus', "Lockpick", "Probe", "RepairTool"}

local itemBlacklist = { -- list of item ids that should automatically be excluded from the item search; use for unobtainable items
    "Gold_005", "Gold_010", "Gold_025", "Gold_100", "Gold_Dae_cursed_001", "Gold_Dae_cursed_005", "misc_vivec_ashmask_01", "misc_vivec_ashmask_01_fake",
    "common_ring_01_arena", "common_ring_01_fg_corp01", "common_ring_01_fg_nchur01","common_ring_01_fg_nchur02","common_ring_01_fg_nchur03","common_ring_01_fg_nchur04","common_ring_01_haunt_Ken","common_ring_01_mgbwg","common_ring_01_mge","common_ring_01_tt_mountkand", 
    "Daedric_special01", "glenmoril_ring_BM", "hroldar_ring", "ritual_ring", "ulfgar_ring", "WerewolfRobe",
    "T_Com_Bucket_01_Hang", "T_Com_Bucket_02_Hang", "T_Com_GoldCoinDae_05", "T_Com_GoldCoinDae_25", "T_De_GoldCoinGhost_05", "T_De_GoldCoinGhost_25", "T_De_HlaaluCompanyScrip_02", "T_TestSkull",
    "T_IngCrea_Ambergris_float", "T_IngMine_DiamondDeTomb_01", "T_IngMine_EmeraldDeTomb_01", "T_IngMine_PearlDeTomb_01", "T_IngMine_RubyDeTomb_01",
    "T_ScBank_RingBriricca", "T_ScBank_RingHlaalu", "T_WereboarRobe",
    "AB_Misc_CeramicTeapot01Hang", "AB_Misc_ComBucket01Hang", "AB_Misc_ComPaintCanvas01","AB_Misc_ComPaintCanvas02","AB_Misc_ComPaintCanvas03", "AB_Misc_PurseCoin", "AB_Rep_GrinderWheel",
}

local itemIdPrefixBlacklist = {"T_De_CardHort", "writ_", "AB_Info", "T_News"}
local itemNamePrefixBlacklist = {"<"} -- Deprecated T_D items
local itemIdSuffixBlacklist = {"_x"} -- Museum of Artifacts duplicates

AotS_Quests.loadData = function()
    AotS_Quests.data = jsonInterface.load("custom/AotS_Quests_Data.json")
    if AotS_Quests.data == nil then AotS_Quests.data = {quests = {}} end
end

AotS_Quests.saveData = function()
    jsonInterface.save("custom/AotS_Quests_Data.json", AotS_Quests.data)
end

local AddItemToPid = function(pid, itemData) -- From Nkfree

    local player = Players[pid]

    if player == nil or not player:IsLoggedIn() then
        tes3mp.LogMessage(enumerations.log.ERROR, "Attempt at adding an item for non-existent pid " .. pid)
        return
    end

    local inventory = player.data.inventory
    local refId = itemData.refId
    local count = itemData.count
    local charge = itemData.charge
    local enchantmentCharge = itemData.enchantmentCharge
    local soul = itemData.soul

    -- Add the item server-side
    inventoryHelper.addItem(inventory, refId, count, charge, enchantmentCharge, soul)

    -- Send server packet to related player
    player:LoadItemChanges({itemData}, enumerations.inventory.ADD)
end

local RemoveItemFromPid = function(pid, itemData) -- From Nkfree

    local player = Players[pid]

    if player == nil or not player:IsLoggedIn() then
        tes3mp.LogMessage(enumerations.log.ERROR, "Attempt at removing an item for non-existent pid " .. pid)
        return
    end

    local inventory = player.data.inventory
    local refId = itemData.refId
    local count = itemData.count
    local charge = itemData.charge
    local enchantmentCharge = itemData.enchantmentCharge
    local soul = itemData.soul

    -- Remove the item server-side
    inventoryHelper.removeClosestItem(inventory, refId, count, charge, enchantmentCharge, soul)

    -- Send server packet to related player
    player:LoadItemChanges({itemData}, enumerations.inventory.REMOVE)
end

local generateListBoxStringFromList = function(list, funct) -- funct should take in an item from the list and return a string to be appended to the list
    local listString = "* BACK *\n"
    for i=1, #list do
        listString = listString  .. funct(list[i])
        if not (i == #list) then
            listString = listString .. "\n"
        end
    end
    return listString
end

local stringStartMatch = function(str, prefix) -- returns true if the string str begins with the string prefix (not case sensitive)
    local sub = string.sub(str, 1, string.len(prefix))
    if string.lower(sub) == string.lower(prefix) then
        return true
    end
end

local stringEndMatch = function(str, suffix) -- returns true if the string str ends with the string suffix (not case sensitive)
    local sub = string.sub(str, string.len(str) - string.len(suffix) + 1)
    if string.lower(sub) == string.lower(suffix) then
        return true
    end
end

local generateQuestId = function()
    if AotS_Quests.data.currentId == nil then AotS_Quests.data.currentId = 1 end
    AotS_Quests.data.currentId = AotS_Quests.data.currentId + 1
    return AotS_Quests.data.currentId
end

AotS_Quests.getFilteredQuestList = function(pid, filter) -- filter is a function with pid and questId as parameters returning true or false; this function returns a list of quest ids
    local list = {}
    for questId, _ in pairs(AotS_Quests.data.quests) do
        if filter(questId) then table.insert(list, questId) end
    end
    table.sort(list)
    return list
end

local sortItemList = function(list)
    table.sort(list, function(a, b) 
        local aData = dataFilesLoader.getItemRecord(a)
        local bData = dataFilesLoader.getItemRecord(b)
        if aData.name ~= bData.name then
            return aData.name < bData.name
        else
            return a < b
        end
    end)
    return list
end

AotS_Quests.getFilteredItemList = function(filterString) -- filterString is a string that should be included in the item ID or name of an item; returns a list of DFL-compatible ids 
    local list = {}
    for _, recordType in ipairs(itemRecordTypes) do
        if dataFilesLoader.data[recordType] ~= nil then
            for itemId, itemData in pairs(dataFilesLoader.data[recordType]) do
                if itemData ~= nil and itemId ~= nil then
                    if itemData.name == "" or itemData.name == nil then goto continue end -- ignore things with no name, like lights
                    if itemData.script == "noPickUp" then goto continue end -- ignore items with the generic noPickUp script
                    for _, prefix in ipairs(itemIdPrefixBlacklist) do
                        if stringStartMatch(itemId, prefix) then goto continue end
                    end
                    for _, prefix in ipairs(itemNamePrefixBlacklist) do
                        if stringStartMatch(itemData.name, prefix) then goto continue end
                    end
                    for _, suffix in ipairs(itemIdSuffixBlacklist) do
                        if stringEndMatch(itemId, suffix) then goto continue end
                    end
                    for _, id in ipairs(itemBlacklist) do
                        if string.lower(itemId) == string.lower(id) then goto continue end
                    end

                    local match = string.find(string.lower(itemId), string.lower(filterString))
                    match = match or string.find(string.lower(itemData.name), string.lower(filterString))
                    if match ~= nil then table.insert(list, itemId) end

                    ::continue::
                end
            end
        end
    end
    return sortItemList(list)
end

AotS_Quests.showFilteredItemList = function(pid, filter)
    tempSelectedData[pid].itemList = AotS_Quests.getFilteredItemList(filter)
    local listboxString = generateListBoxStringFromList(tempSelectedData[pid].itemList, function(itemId)
        local record = dataFilesLoader.getItemRecord(itemId)
        return record.name
    end)
    tes3mp.ListBox(pid, 101306, "Select an item.", listboxString)
end

AotS_Quests.showFilteredQuestList = function(pid, filter)
    tempSelectedData[pid].questList = AotS_Quests.getFilteredQuestList(pid, filter)
    local listboxString = generateListBoxStringFromList(tempSelectedData[pid].questList, function(questId)
        return AotS_Quests.data.quests[questId].title
    end)
    tes3mp.ListBox(pid, 101300, "Select a quest.", listboxString)
end

AotS_Quests.showItemData = function(pid, itemId)
    local itemData = dataFilesLoader.getItemRecord(itemId)
    local text = itemData.name .. "\n(" .. itemId .. ")\n\n" .. "Price: " .. itemData.data.value .. "\n" .. "Weight: " .. itemData.data.weight .. "\n"
    
    tes3mp.CustomMessageBox(pid, 101307, text, "Back;Accept")
end

local generateItemListString = function(itemList)
    local str = ""
    for index, entry in ipairs(itemList) do
        local itemInfo = dataFilesLoader.getItemRecord(entry.item)
        str = str .. itemInfo.name
        if entry.count > 1 then str = str .. " (" .. entry.count .. ")" end
        if index ~= #itemList then str = str .. ", " end
    end
    return str
end

AotS_Quests.generateQuestInfoString = function(pid, questId)
    local questTable
    if questId == nil then -- use this to generate info for the player's temp stored quest
        questTable = tempSelectedData[pid].questTable or {}
    else
        questTable = AotS_Quests.data.quests[questId]
    end
    local info = "Quest: " .. ( questTable.title or "Unnamed Quest" ) .. "\n\n"
    if questTable.description ~= nil then info = info .. questTable.description .. "\n\n" end

    if questTable.creator ~= nil then
        if string.lower(Players[pid].accountName) ~= string.lower(questTable.creator) then
            info = info .. "Questgiver: " .. questTable.creator .. "\n\n"
        else
            if questTable.doer ~= nil then
                info = info .. "Claimed by " .. questTable.doer .. "\n\n"
            else
                info = info .. "Currently Unclaimed\n\n"
            end
        end
    end

    if questTable.requestedItems ~= nil and questTable.requestedItems ~= {} then
        info = info .. "Requested Items: " .. generateItemListString(questTable.requestedItems) .. "\n"
    end
    if questTable.reward ~= nil and questTable.reward ~= {} then
        info = info .. "Reward: " .. generateItemListString(questTable.reward) .. "\n"
    end

    return info
end

local getQuestInfoButtons = function(pid, questId)
    local buttons = "Back"
    if AotS_Quests.data.quests[questId].doer == nil and string.lower(Players[pid].accountName) ~= string.lower(AotS_Quests.data.quests[questId].creator) then -- unclaimed quest not created by player pid
        buttons = buttons .. ";Accept Quest"
    elseif string.lower(Players[pid].accountName) == string.lower(AotS_Quests.data.quests[questId].creator) then
        buttons = buttons .. ";Cancel Quest"
    elseif AotS_Quests.data.quests[questId].doer ~= nil and string.lower(Players[pid].accountName) == string.lower(AotS_Quests.data.quests[questId].doer) then
        buttons = buttons .. ";Drop Quest;Submit Quest"
    end

    return buttons
end

local getButtonFunction = function(pid, questId, data)
    if tonumber(data) == 0 then return "back" end
    if AotS_Quests.data.quests[questId].doer == nil and string.lower(Players[pid].accountName) ~= string.lower(AotS_Quests.data.quests[questId].creator) then -- unclaimed quest not created by player pid
        return "accept"
    elseif string.lower(Players[pid].accountName) == string.lower(AotS_Quests.data.quests[questId].creator) then
        return "cancel"
    elseif AotS_Quests.data.quests[questId].doer ~= nil and string.lower(Players[pid].accountName) == string.lower(AotS_Quests.data.quests[questId].doer) then
        if tonumber(data) == 1 then
            return "drop"
        else
            return "submit"
        end
    end
end

local playerHasItemInCount = function(pid, itemId, count)
    if count == nil then count = 1 end
    local inventory = Players[pid].data.inventory

    local loc = inventoryHelper.getItemIndex(inventory, string.lower(itemId))
    if loc and inventory[loc].count >= count then
        return true
    end
    return false
end

local getFulfilledQuestReqs = function(pid, questId)
    for _, requestedItem in ipairs(AotS_Quests.data.quests[questId].requestedItems) do
        if not playerHasItemInCount(pid, requestedItem.item, requestedItem.count) then return false end
    end
    return true
end

AotS_Quests.onGui = function(pid, guiId, data)
    if guiId == 101300 then -- selecting a quest from the list (also used for showGui 101301 and 101302 because they act the same)
        if tonumber(data) ~= 0 and tonumber(data) < ( #tempSelectedData[pid].questList + 1 ) then
            tempSelectedData[pid].selectedQuestId = tempSelectedData[pid].questList[tonumber(data)]
            AotS_Quests.showGui(pid, 101304)
        else
            tempSelectedData[pid] = {} -- clear temp data upon leaving menu
            AotS_Quests.showGui(pid, 101312)
        end
    elseif guiId == 101303 then -- new quest menu
        if tonumber(data) == 0 then -- cancel
            tempSelectedData[pid] = {}
            AotS_Quests.showGui(pid, 101312)
        elseif tonumber(data) == 1 then -- edit
            AotS_Quests.showGui(pid, 101310)
        elseif tonumber(data) == 2 then -- submit
            if tempSelectedData[pid].questTable.title == nil then
                tes3mp.MessageBox(pid, 999999, "This quest requires a title.")
                AotS_Quests.showGui(pid, 101303)
                return
            end

            if tempSelectedData[pid].questTable.requestedItems == nil or #tempSelectedData[pid].questTable.requestedItems == 0 then
                tes3mp.MessageBox(pid, 999999, "This quest requires at least one request.")
                AotS_Quests.showGui(pid, 101303)
                return
            end

            if tempSelectedData[pid].questTable.reward == nil or #tempSelectedData[pid].questTable.reward == 0 then
                tes3mp.MessageBox(pid, 999999, "This quest requires a reward.")
                AotS_Quests.showGui(pid, 101303)
                return
            end

            local id = generateQuestId()
            tempSelectedData[pid].questTable.creator = Players[pid].accountName

            AotS_Quests.data.quests[id] = tempSelectedData[pid].questTable
            AotS_Quests.saveData()

            for _, item in ipairs(tempSelectedData[pid].questTable.reward) do
                RemoveItemFromPid(pid, {refId = string.lower(item.item), count = item.count})
            end

            tempSelectedData[pid] = {}
            tes3mp.MessageBox(pid, 999999, "This quest has been created.")
            
        end
    elseif guiId == 101304 then -- quest info menu
        if AotS_Quests.data.quests[tempSelectedData[pid].selectedQuestId] == nil then
            tes3mp.MessageBox(pid, 999999, "This quest has been completed or cancelled by its creator.")
            AotS_Quests.showGui(pid, tempSelectedData[pid].questListType)
            return
        end
        local button = getButtonFunction(pid, tempSelectedData[pid].selectedQuestId, data)
        if button == "back" then
            AotS_Quests.showGui(pid, tempSelectedData[pid].questListType)
        elseif button == "accept" then
            AotS_Quests.data.quests[tempSelectedData[pid].selectedQuestId].doer = Players[pid].accountName
            AotS_Quests.showGui(pid, 101304)
            AotS_Quests.saveData()
        elseif button == "cancel" then
            local id = tempSelectedData[pid].selectedQuestId
            for _, item in ipairs(AotS_Quests.data.quests[id].reward) do
                AddItemToPid(pid, {refId = string.lower(item.item), count = item.count})
            end
            AotS_Quests.data.quests[tempSelectedData[pid].selectedQuestId] = nil
            tes3mp.MessageBox(pid, 999999, "You have cancelled this quest.")
            AotS_Quests.showGui(pid, tempSelectedData[pid].questListType)
            AotS_Quests.saveData()
        elseif button == "drop" then
            AotS_Quests.data.quests[tempSelectedData[pid].selectedQuestId].doer = nil
            AotS_Quests.showGui(pid, 101304)
            AotS_Quests.saveData()
        elseif button == "submit" then
            if getFulfilledQuestReqs(pid, tempSelectedData[pid].selectedQuestId) then
                local questId = tempSelectedData[pid].selectedQuestId
                
                local targetPlayer = logicHandler.GetPlayerByName(AotS_Quests.data.quests[questId].creator)
                local questgiverOnline = false
                for _, player in pairs(Players) do
                    if string.lower(player.accountName) == string.lower(AotS_Quests.data.quests[questId].creator) then
                        questgiverOnline = true
                        break
                    end
                end

                local questGiverInventory = targetPlayer.data.inventory

                for _, item in ipairs(AotS_Quests.data.quests[questId].requestedItems) do 
                    RemoveItemFromPid(pid, {refId = string.lower(item.item), count = item.count})
                    -- Add the item server-side
                    inventoryHelper.addItem(questGiverInventory, string.lower(item.item), item.count)

                    -- Send server packet to related player
                    if questgiverOnline then
                        targetPlayer:LoadItemChanges({{refId = string.lower(item.item), count = item.count}}, enumerations.inventory.ADD)
                    end
                end

                targetPlayer:Save() -- all this to handle giving items to a possibly offline player

                for _, item in ipairs(AotS_Quests.data.quests[questId].reward) do -- give quest doer a reward
                    AddItemToPid(pid, {refId = string.lower(item.item), count = item.count})
                end

                AotS_Quests.data.quests[tempSelectedData[pid].selectedQuestId] = nil

                AotS_Quests.saveData()
                tes3mp.MessageBox(pid, 999999, "You have completed this quest!")
            else
                tes3mp.MessageBox(pid, 999999, "You have not completed the quest requirements.")
                AotS_Quests.showGui(pid, 101304)
            end
        end
    elseif guiId == 101305 then -- item filter inputbox
        if string.len(data) >= 2 then
            tempSelectedData[pid].filterString = data
            AotS_Quests.showGui(pid, 101306)
        elseif data == " " then
            AotS_Quests.showGui(pid, 101303)
        else
            tes3mp.MessageBox(pid, 999999, "Please enter more than two characters to search.")
            AotS_Quests.showGui(pid, 101305)
        end
    elseif guiId == 101306 then -- item select list
        if tonumber(data) ~= 0 and tonumber(data) < ( #tempSelectedData[pid].itemList + 1 ) then
            tempSelectedData[pid].selectedItem = tempSelectedData[pid].itemList[tonumber(data)]
            AotS_Quests.showGui(pid, 101307)
        else
            AotS_Quests.showGui(pid, 101305)
        end
    elseif guiId == 101307 then -- item data menu
        if tonumber(data) == 0 then -- back
            AotS_Quests.showGui(pid, 101306)
        else -- accept
            AotS_Quests.showGui(pid, 101308)
        end
    elseif guiId == 101308 then -- item count input box  
        local count = tonumber(data) or 1
        if tempSelectedData[pid].itemSelectType == "request" then
            if tempSelectedData[pid].questTable.requestedItems == nil then tempSelectedData[pid].questTable.requestedItems = {} end
            table.insert(tempSelectedData[pid].questTable.requestedItems, {item = tempSelectedData[pid].selectedItem, count = count})
            AotS_Quests.showGui(pid, 101303)
        elseif tempSelectedData[pid].itemSelectType == "reward" then 
            if playerHasItemInCount(pid, tempSelectedData[pid].selectedItem, count) then
                if tempSelectedData[pid].questTable.reward == nil then tempSelectedData[pid].questTable.reward = {} end
                table.insert(tempSelectedData[pid].questTable.reward, {item = tempSelectedData[pid].selectedItem, count = count})
                AotS_Quests.showGui(pid, 101303)
            else
                if string.lower(tempSelectedData[pid].selectedItem) == "gold_001" then
                    tes3mp.MessageBox(pid, 999999, "You do not have enough gold in your inventory to give as a reward.")
                    AotS_Quests.showGui(pid, 101303)
                else
                    local str = count > 1 and "these items" or "this item"
                    tes3mp.MessageBox(pid, 999999, "You do not have " .. str .. " in your inventory to give as a reward.")
                    AotS_Quests.showGui(pid, 101306)
                end 
                
            end
        end
    elseif guiId == 101309 then -- quest description input box  
        if data ~= "" then
            tempSelectedData[pid].questTable.description = data
        else
            tempSelectedData[pid].questTable.description = nil
        end
        AotS_Quests.showGui(pid, 101303)
    elseif guiId == 101310 then -- quest edit buttons 
        if tonumber(data) == 0 then -- back
            AotS_Quests.showGui(pid, 101303)
        elseif tonumber(data) == 1 then -- title
            AotS_Quests.showGui(pid, 101311)
        elseif tonumber(data) == 2 then -- description
            AotS_Quests.showGui(pid, 101309)
        elseif tonumber(data) == 3 then -- add item request
            tempSelectedData[pid].itemSelectType = "request"
            AotS_Quests.showGui(pid, 101305)
        elseif tonumber(data) == 4 then -- remove item request
            if tempSelectedData[pid].questTable.requestedItems ~= nil and #tempSelectedData[pid].questTable.requestedItems > 0 then
                tempSelectedData[pid].questTable.requestedItems[#tempSelectedData[pid].questTable.requestedItems] = nil
                tes3mp.MessageBox(pid, 999999, "Latest requested item entry removed.")
            end
            AotS_Quests.showGui(pid, 101303)
        elseif tonumber(data) == 5 then -- add reward item
            tempSelectedData[pid].itemSelectType = "reward"
            AotS_Quests.showGui(pid, 101305)
        elseif tonumber(data) == 6 then -- add reward gold
            tempSelectedData[pid].selectedItem = "gold_001"
            tempSelectedData[pid].itemSelectType = "reward"
            AotS_Quests.showGui(pid, 101308)
        elseif tonumber(data) == 7 then -- remove reward
            if tempSelectedData[pid].questTable.reward ~= nil and #tempSelectedData[pid].questTable.reward > 0 then
                tempSelectedData[pid].questTable.reward[#tempSelectedData[pid].questTable.reward] = nil
                tes3mp.MessageBox(pid, 999999, "Latest reward entry removed.")
            end
            AotS_Quests.showGui(pid, 101303)
        end
    elseif guiId == 101311 then -- quest title inputbox 
        if data ~= "" then
            tempSelectedData[pid].questTable.title = data
        else
            tempSelectedData[pid].questTable.title = nil
        end
        AotS_Quests.showGui(pid, 101303)
    elseif guiId == 101312 then -- quest main menu
        if tonumber(data) == 0 then -- exit
            tempSelectedData[pid] = {}
        elseif tonumber(data) == 1 then -- view all
            AotS_Quests.showGui(pid, 101300)
        elseif tonumber(data) == 2 then -- view my accepted
            AotS_Quests.showGui(pid, 101302)
        elseif tonumber(data) == 3 then -- view my created
            AotS_Quests.showGui(pid, 101301)
        elseif tonumber(data) == 4 then -- create new
            AotS_Quests.showGui(pid, 101303)
        end
    end
end

AotS_Quests.showGui = function(pid, guiId)
    if guiId == 101300 then -- available quests
        AotS_Quests.showFilteredQuestList(pid, function(questId) if AotS_Quests.data.quests[questId].doer == nil and string.lower(Players[pid].accountName) ~= string.lower(AotS_Quests.data.quests[questId].creator) then return true end end)
        tempSelectedData[pid].questListType = 101300
    elseif guiId == 101301 then -- created quests
        AotS_Quests.showFilteredQuestList(pid, function(questId) if string.lower(Players[pid].accountName) == string.lower(AotS_Quests.data.quests[questId].creator) then return true end end)
        tempSelectedData[pid].questListType = 101301
    elseif guiId == 101302 then -- accepted quests
        AotS_Quests.showFilteredQuestList(pid, function(questId) 
            if AotS_Quests.data.quests[questId].doer == nil then 
                return false
            elseif string.lower(Players[pid].accountName) == string.lower(AotS_Quests.data.quests[questId].doer) then 
                return true
            end
        end)
        tempSelectedData[pid].questListType = 101302
    elseif guiId == 101303 then -- new quest menu
        if tempSelectedData[pid] == nil then tempSelectedData[pid] = {} end
        if tempSelectedData[pid].questTable == nil then tempSelectedData[pid].questTable = {} end
        local infoString = AotS_Quests.generateQuestInfoString(pid)
        local buttons = "Cancel;Edit;Submit"
        tes3mp.CustomMessageBox(pid, 101303, infoString, buttons)
    elseif guiId == 101304 then -- quest info menu
        if AotS_Quests.data.quests[tempSelectedData[pid].selectedQuestId] == nil then
            tes3mp.MessageBox(pid, 999999, "This quest has been canceled by its creator.")
            AotS_Quests.showGui(pid, tempSelectedData[pid].questListType)
        end
        local infoString = AotS_Quests.generateQuestInfoString(pid, tempSelectedData[pid].selectedQuestId)
        local buttons = getQuestInfoButtons(pid, tempSelectedData[pid].selectedQuestId)
        tes3mp.CustomMessageBox(pid, 101304, infoString, buttons)
    elseif guiId == 101305 then -- item filter inputbox
        tes3mp.InputDialog(pid, 101305, "Search for an item by name or ID.", "Enter a single space to go back.")
    elseif guiId == 101306 then -- item select list
        AotS_Quests.showFilteredItemList(pid, tempSelectedData[pid].filterString)
    elseif guiId == 101307 then -- item data menu
        AotS_Quests.showItemData(pid, tempSelectedData[pid].selectedItem)
    elseif guiId == 101308 then -- item count input box
        tes3mp.InputDialog(pid, 101308, "How many of this item?", "")
    elseif guiId == 101309 then -- quest description input box
        tes3mp.InputDialog(pid, 101309, "Provide a description for your quest.", "")
    elseif guiId == 101310 then -- quest edit buttons 
        tes3mp.CustomMessageBox(pid, 101310, "", "Back;Set Title;Set Description;Add Item Request;Remove Item Request;Add Reward Item;Add Reward Gold;Remove Reward")
    elseif guiId == 101311 then -- quest title inputbox
        tes3mp.InputDialog(pid, 101311, "Provide a name for your quest.", "")
    elseif guiId == 101312 then -- quest main menu
        if tempSelectedData[pid] == nil then tempSelectedData[pid] = {} end
        tes3mp.CustomMessageBox(pid, 101312, "Custom Quests", "Exit;View Available Quests;View My Accepted Quests;View My Created Quests;Create New Quest")
    end
end

customCommandHooks.registerCommand("quests", function(pid, cmd) AotS_Quests.showGui(pid, 101312) end)

customEventHooks.registerHandler("OnGUIAction", function(eventStatus,pid,idGui,data) AotS_Quests.onGui(pid,idGui,data) end)
customEventHooks.registerHandler("OnServerPostInit", AotS_Quests.loadData)