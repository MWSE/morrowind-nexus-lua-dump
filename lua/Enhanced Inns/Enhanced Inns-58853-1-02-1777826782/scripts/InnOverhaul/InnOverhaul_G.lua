local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local util = require("openmw.util")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local core = require("openmw.core")
local calendar = require('openmw_aux.calendar')
local bovr = require("scripts.InnOverhaul.bed_override")
local bedOverride, doorOverride = bovr.beds, bovr.doors

local checkInDatas = {}
local function isInnDoor(door)
    if door.globalVariable then
        return true
    else
        local rec = types.Door.record(door)
        if rec.name == "Room Door" then
            return true
        end
    end
    for index, value in ipairs(doorOverride) do
        if value.recordId and value.recordId == door.recordId then
            return true
        elseif value.xpos ~= nil and value.xpos == math.floor(door.position.x) then
            return true
        end
    end
    return false
end

local function sanitizeString(str)
    -- Convert to lowercase
    local lowerStr = string.lower(str)

    -- Remove non-alphanumeric characters
    local sanitizedStr = lowerStr:gsub("%W", "")

    return sanitizedStr
end
local function isInnBed(bed)
    if bed.globalVariable then
        return true
    else
        if bedOverride[bed.cell.name] then
            if bedOverride[bed.cell.name].recordId and bedOverride[bed.cell.name].recordId == bed.recordId then
                return true
            elseif bedOverride[bed.cell.name].xpos ~= nil and bedOverride[bed.cell.name].xpos == math.floor(bed.position.x) then
                return true
            end
        end
    end
    return false
end
local function doorIsClosed(door)
    local closed = door.startingRotation:getAnglesZYX() == door.rotation:getAnglesZYX()
    return closed
end
local function addOrRemoveWithMessage(itemId, count, remove)
    if not count then
        count = 1
    end
    if not remove then
        remove = false
    end
    if not remove then
        local newKey = world.createObject(itemId, count)
        newKey:moveInto(world.players[1])
        if count == 1 then
            local message = core.getGMST("sNotifyMessage60")

            local formattedString = string.format(message, newKey.type.record(newKey).name)
            world.players[1]:sendEvent("ZS_ShowMessage", formattedString)
        else
            local message = core.getGMST("sNotifyMessage61")

            local formattedString = string.format(message, count, newKey.type.record(newKey).name)
            world.players[1]:sendEvent("ZS_ShowMessage", formattedString)
        end
    else
        local itemToRemove = types.Actor.inventory(world.players[1]):find(itemId)
        if not itemToRemove then
            for index, value in ipairs(types.Actor.inventory(world.players[1]):getAll()) do
                if value.recordId == itemId then
                    itemToRemove = value
                end
            end
        end
        if not itemToRemove then
            return false
        end
        if count > 1 then
            local message = core.getGMST("sNotifyMessage63")

            local formattedString = string.format(message, count, itemToRemove.type.record(itemToRemove).name)
            world.players[1]:sendEvent("ZS_ShowMessage", formattedString)
        else
            local message = core.getGMST("sNotifyMessage62")

            local formattedString = string.format(message, itemToRemove.type.record(itemToRemove).name)
            world.players[1]:sendEvent("ZS_ShowMessage", formattedString)
        end
        itemToRemove:remove(count)
    end
end
local function playerHasItemCount(itemId, count)
    local invItemCount = 0

    for index, value in ipairs(types.Actor.inventory(world.players[1]):getAll()) do
        if value.recordId == itemId then
            invItemCount = invItemCount + value.count
        end
    end


    if invItemCount >= count then return 1 end


    return 0
end
local function getGameTimeData()
    local secondsPerGameDay = 86400
    local gameTimeInSeconds = core.getGameTime()
    -- Calculate the total number of days passed
    local daysPassed = math.floor(gameTimeInSeconds / secondsPerGameDay)

    -- Calculate the current hour of the day
    local currentHour = math.floor((gameTimeInSeconds % secondsPerGameDay) / (secondsPerGameDay / 24))

    return daysPassed, currentHour
end

local function convertContainers(bed, owner, rented)
    if not bed then return end
    if rented then
        local storedOwners = {}
        if not bed.globalVariable then
            storedOwners[bed.id] = bed.owner.recordId
            bed.owner.recordId = nil
        end
        for index, obj in ipairs(bed.cell:getAll(types.Container)) do
            local dist = (obj.position - bed.position):length()
            local zDist = math.abs(bed.position.z - obj.position.z)
            if dist < 500 and zDist < 100 then
                storedOwners[obj.id] = obj.owner.recordId
                obj.owner.recordId = nil
                types.Container.content(obj):resolve()
                types.Lockable.unlock(obj)
            end
        end
        for index, obj in ipairs(bed.cell:getAll()) do
            if obj.owner.recordId and obj.type.baseType == types.Item and obj.type.records[obj.recordId].value < 100 then
                local dist = (obj.position - bed.position):length()
                local zDist = math.abs(bed.position.z - obj.position.z)
                if dist < 500 and zDist < 100 then
                    storedOwners[obj.id] = obj.owner.recordId
                    obj.owner.recordId = nil
                end
            end
        end

        I.ZS_DataManager.setData("OwnedObjects_" .. sanitizeString(bed.cell.name), storedOwners)
    else
        local storedOwners = I.ZS_DataManager.getData("OwnedObjects_" .. sanitizeString(bed.cell.name))
        if not storedOwners then return end

        for index, obj in ipairs(bed.cell:getAll()) do
            if storedOwners[obj.id] then
                obj.owner.recordId = storedOwners[obj.id]
            end
        end
        I.ZS_DataManager.setData("OwnedObjects_" .. sanitizeString(bed.cell.name), nil)
    end
end
local function getEstablishmentName(cell)
    local start = cell.name

    -- Process the exterior cell name as before
    for index, value in ipairs(cell:getAll(types.Door)) do
        local cellCheck = types.Door.destCell(value)
        if cellCheck and cellCheck.isExterior and cellCheck.name and #cellCheck.name > 2 then
            if start:find(cellCheck.name) then
                -- Remove the exterior cell name and any following ", " from the start string
                start = start:gsub(cellCheck.name .. ",? ?", "")
                break
            end
        end
    end

    -- Check for a comma in the string and cut off anything before it
    local commaPosition = start:find(",")
    if commaPosition then
        start = start:sub(commaPosition + 1)
    end

    -- Trim only leading and trailing spaces
    start = start:match("^%s*(.-)%s*$")

    return start
end
local function findInns()
    local publicanCount = 0
    local innCount = 0
    for index, cell in ipairs(world.cells) do
        if not cell.isExterior then
            for index, npc in ipairs(cell:getAll(types.NPC)) do
                local npcRecord = types.NPC.records[npc.recordId]
                if npcRecord.class:lower() == "publican" then
                    local bedCount = 0
                    local doorCount = 0
                    for index, bed in ipairs(cell:getAll(types.Activator)) do
                        if isInnBed(bed) then
                            bedCount = bedCount + 1
                        end
                    end
                    local hasGlobal = false
                    for index, door in ipairs(cell:getAll(types.Door)) do
                        if isInnDoor(door) then
                            if door.globalVariable then
                               hasGlobal = true
                            end
                            doorCount = doorCount + 1
                        end
                    end
                    if bedCount > 0 then
                        if doorCount > 0 and not hasGlobal then
                            print("Missing global on door: " .. cell.name)
                        end
                        --  print("Found Inn: " ..
                        --       getEstablishmentName(cell))
                        --  print("With " .. tostring(bedCount) .. " and " .. tostring(doorCount) .. " doors")
                        --   print("Owned by " .. npcRecord.name)
                        --   print("")
                        innCount = innCount + 1
                    else
                  --      print("No inn objects for " .. npcRecord.name)
                 --       print(npc.cell.name)
                 --       print("")
                        publicanCount = publicanCount + 1
                    end
                end
            end
        end
    end
    print("Found " .. tostring(innCount) .. " inns")
    print("Found " .. tostring(publicanCount) .. " publicans with no rooms")
end
local function getRoomKeyName(cell)
    return cell.name
end
local function getRoomKeyID(cell)
    local fixedId = sanitizeString(cell.name)
    local idCheck = I.ZS_DataManager.getData("key_" .. fixedId)
    if not idCheck then
        local recordDraft = types.Miscellaneous.createRecordDraft { template = types.Miscellaneous.record("key_abebaalslaves_01"), value = 0, name = "Room Key - " .. getEstablishmentName(cell) }
        local newRecord = world.createRecord(recordDraft)
        I.ZS_DataManager.setData("key_" .. fixedId, newRecord.id)
        return newRecord.id
    end
    return idCheck
end
local function formatDateWithSuffix(time)
    if not time then
        time = core.getGameTime()
    end
    local day = calendar.formatGameTime("%d", time)

    -- Determine the suffix
    local suffix = "th"
    if day % 10 == 1 and day ~= 11 then
        suffix = "st"
    elseif day % 10 == 2 and day ~= 12 then
        suffix = "nd"
    elseif day % 10 == 3 and day ~= 13 then
        suffix = "rd"
    end

    return calendar.formatGameTime("%B, ", time) .. tonumber(day) .. suffix
end
local function getCheckinNoteRecord(cell, checkInGameTime, checkOutGameTime, nightCount, cost)
    local fixedId = sanitizeString(cell.name)
    local baseRecord = types.Book.record("zhac_room_info")
    local estName = getEstablishmentName(cell)
    local nights = tostring(nightCount) .. " nights"
    if nightCount == 1 then
        nights = "1 night"
    end
    local text = string.format(baseRecord.text, estName, types.NPC.record("player").name,
        formatDateWithSuffix(checkInGameTime), formatDateWithSuffix(checkOutGameTime), nights, cost, cost)
    local recordDraft = types.Book.createRecordDraft { template = baseRecord, value = 0, name = "Room Reservation - " .. estName, text = text }
    local newRecord = world.createRecord(recordDraft)
    return newRecord
end
local function setInnRoomRented(cell, state, player)
    local globalVar = nil
    local innBed
    local innPublican
    local innDoor
    local keyId = nil
    if state then
        for index, obj in ipairs(cell:getAll()) do
            if obj.type == types.Door and isInnDoor(obj) then
                if obj.globalVariable then
                    globalVar = obj.globalVariable
                end
                local keyRecord = getRoomKeyID(cell)
                types.Lockable.setKeyRecord(obj, keyRecord)
                keyId = keyRecord
                addOrRemoveWithMessage(keyRecord, 1, false)

                innDoor = obj
            elseif obj.type == types.Activator and isInnBed(obj) then
                if not globalVar and obj.globalVariable then
                    globalVar = obj.globalVariable
                end
                innBed = obj
            elseif obj.type == types.NPC then
                local record = types.NPC.records[obj.recordId]
                if record.class:lower() == "publican" then
                    innPublican = obj
                end
            end
        end
        if globalVar then
            world.mwscript.getGlobalVariables(player)[globalVar] = 1
            if innPublican and innBed and innDoor then
            elseif not innPublican then
                print("No publican")
            elseif not innBed then
                print("No bed")
            end
        end
        convertContainers(innBed, innPublican, state)
    else
        for index, obj in ipairs(cell:getAll()) do
            if obj.type == types.Door and isInnDoor(obj) then
                if not doorIsClosed(obj) then
                    types.Lockable.unlock(obj)
                    async:newUnsavableSimulationTimer(1, function()
                        world._runStandardActivationAction(obj, player)
                    end)
                end
                async:newUnsavableSimulationTimer(2, function()
                    if doorIsClosed(obj) then
                        types.Lockable.lock(obj, 50)
                    end
                    types.Lockable.setKeyRecord(obj, nil)
                end)
                if obj.globalVariable then
                    globalVar = obj.globalVariable
                end
            elseif obj.type == types.Activator and isInnBed(obj) then
                if not globalVar and obj.globalVariable then
                    globalVar = obj.globalVariable
                end
                innBed = obj
            end
        end
        if globalVar then
            world.mwscript.getGlobalVariables(player)[globalVar] = 0
            -- print("setting  " .. globalVar)
        else
            -- print("No global var")
        end
        convertContainers(innBed, innPublican, state)
    end
    return {
        keyId = keyId,
        door = innDoor,
        innBed = innBed,
    }
end

local function checkInPlayer(cell, daysToRent, player)
    if not player then
        player = world.players[1]
    end
    local daysPassed, currentHour = getGameTimeData()
    local checkinDay = daysPassed
    local checkInGameTime = core.getGameTime()
    if currentHour < 6 then
        checkinDay = checkinDay - 1
        daysToRent = daysToRent - 1 --If already at night, one night should include the current night.
        checkInGameTime = checkInGameTime - 86400
    end
    local goldPerNight = I.ZS_InnOverhaul_Settings.getSetting("goldPerNight")
    local goldPerWeek = I.ZS_InnOverhaul_Settings.getSetting("goldPerWeek")
    if daysToRent == 0 then
        daysToRent = daysToRent + 1
    end
    local checkOutGameTime = daysToRent * 86400 + checkInGameTime
    local totalCost = goldPerNight * daysToRent
    if daysToRent == 7 then
        totalCost = goldPerWeek
    end

    local noteRecord = getCheckinNoteRecord(cell, checkInGameTime, checkOutGameTime, daysToRent, totalCost)
    addOrRemoveWithMessage(noteRecord.id, 1)
  
    addOrRemoveWithMessage("gold_001", totalCost, true)

    local data = setInnRoomRented(cell, true, player)
    local checkOutData = {
        checkOutGameTime = checkOutGameTime ,
        noteId = noteRecord.id,
        keyId = data.keyId,
        door = data.innBed,
        cellName = cell.name,
    }
    table.insert(checkInDatas,checkOutData)
    local checkoutDay = daysPassed + daysToRent
    I.ZS_DataManager.setData("CheckInGameTime_" .. sanitizeString(cell.name), checkInGameTime)
    I.ZS_DataManager.setData("StayCost_" .. sanitizeString(cell.name), totalCost)
    I.ZS_DataManager.setData("CheckOutGameTime_" .. sanitizeString(cell.name), checkOutGameTime)
    I.ZS_DataManager.setData("CheckInNote" .. sanitizeString(cell.name), noteRecord.id)
    I.ZS_DataManager.setData("CheckOutDay_" .. sanitizeString(cell.name), checkoutDay)
end

local function checkInnStatus(cell, player)
    if not player then
        player = world.players[1]
    end
    local daysPassed, currentHour = getGameTimeData()
    local checkoutDay = I.ZS_DataManager.getData("CheckOutDay_" .. sanitizeString(cell.name))
    local playerGlobals = world.mwscript.getGlobalVariables(player)
    local shouldBeCheckedIn = playerGlobals["IHS_1"] == 1
    if checkoutDay ~= nil and (checkoutDay == daysPassed and currentHour >= 11) or checkoutDay ~= nil and checkoutDay < daysPassed then
        I.ZS_InnOverHaul.checkOutPlayer(cell, player)
        playerGlobals["IHS_1"] = 0
        print("Player is now checked out")
        return false
    elseif checkoutDay ~= nil then
        playerGlobals["IHS_1"] = 1
        print("Player is still checked in")
        return true
    elseif checkoutDay == nil then
        playerGlobals["IHS_1"] = 0
        if shouldBeCheckedIn then
            error("Player should be checked in, but no checkout data was found")
        end
        return false
    end
end

local function miscActivation(pillow, actor)
    --Prevent the player from stealing the pillow accidently
    local record = types.Miscellaneous.record(pillow)

    if record.name == "Pillow" then
        for index, bed in ipairs(pillow.cell:getAll(types.Activator)) do
            if isInnBed(bed) then
                if (bed.position - pillow.position):length() < 100 then
                    bed:activateBy(actor)
                    return false
                end
            end
        end
    end
end
I.Activation.addHandlerForType(types.Miscellaneous, miscActivation)

local function extendRent(cell, daysToRent, player)
    if not player then
        player = world.players[1]
    end
    local currentCheckOut = I.ZS_DataManager.getData("CheckOutDay_" .. sanitizeString(cell.name))
    local currentCheckOutGT = I.ZS_DataManager.getData("CheckOutGameTime_" .. sanitizeString(cell.name))
    local currentNote = I.ZS_DataManager.getData("CheckInNote" .. sanitizeString(cell.name))
    local checkInGameTime = I.ZS_DataManager.getData("CheckInGameTime_" .. sanitizeString(cell.name))
    local currentStayCost = I.ZS_DataManager.getData("StayCost_" .. sanitizeString(cell.name))

    local goldPerNight = I.ZS_InnOverhaul_Settings.getSetting("goldPerNight")
    local goldPerWeek = I.ZS_InnOverhaul_Settings.getSetting("goldPerWeek")
    if daysToRent == 0 then
        daysToRent = daysToRent + 1
    end
    if not currentCheckOut or not currentCheckOutGT or not currentNote or not checkInGameTime or not currentStayCost then
        return
    end
    local checkOutGameTime = (daysToRent * 86400) + currentCheckOutGT
    local totalCost = goldPerNight * daysToRent
    if daysToRent == 7 then
        totalCost = goldPerWeek
    end
    addOrRemoveWithMessage("gold_001", totalCost, true)
    totalCost = totalCost + currentStayCost

    local noteRecord = getCheckinNoteRecord(cell, checkInGameTime, checkOutGameTime, daysToRent, totalCost)
    addOrRemoveWithMessage(currentNote, 1, true)
    addOrRemoveWithMessage(noteRecord.id, 1)

    for index, value in ipairs(checkInDatas) do
        if value.cellName == cell.name then
            checkInDatas[index].checkOutGameTime = checkOutGameTime
            checkInDatas[index].noteId = noteRecord.id

            break
        end
    end
    local checkoutDay = currentCheckOut + daysToRent
    I.ZS_DataManager.setData("CheckOutGameTime_" .. sanitizeString(cell.name), checkOutGameTime)
    I.ZS_DataManager.setData("CheckOutDay_" .. sanitizeString(cell.name), checkoutDay)
    I.ZS_DataManager.setData("CheckInNote" .. sanitizeString(cell.name), noteRecord.id)
    I.ZS_DataManager.setData("StayCost_" .. sanitizeString(cell.name), totalCost)
end
local function checkOutPlayer(cell, player)
    if not player then
        player = world.players[1]
    end
    if not cell.name then
        cell = world.getCellByName(cell)
    end
    local noteId
    for index, value in ipairs(checkInDatas) do
        if value.cellName == cell.name then
            table.remove(checkInDatas,index)
            noteId = value.noteId
            break
        else
            if checkInnStatus(world.getCellByName(value.cellName), player) == false and checkInDatas.door then
                types.Lockable.lock(checkInDatas.door, 50)
            end
        end
    end
    local daysPassed, currentHour = getGameTimeData()
    setInnRoomRented(cell, false, player)

    if I.ZS_InnOverhaul_Settings.getSetting("returnReservationNote") and noteId and playerHasItemCount(noteId, 1) == 1 then
        addOrRemoveWithMessage(noteId, 1, true)
    end
    local keyId = getRoomKeyID(cell)
    if I.ZS_InnOverhaul_Settings.getSetting("returnRoomKey") and keyId and playerHasItemCount(keyId, 1) == 1 then
        addOrRemoveWithMessage(keyId, 1, true)
    end
    I.ZS_DataManager.setData("CheckOutDay_" .. sanitizeString(cell.name), nil)
    I.ZS_DataManager.setData("CheckInGameTime_" .. sanitizeString(cell.name), nil)
end




local function doorActivation(door, actor)
    --Lock the door automatically
    local checkoutDay = I.ZS_DataManager.getData("CheckOutDay_" .. sanitizeString(door.cell.name))
    local autoClose = I.ZS_InnOverhaul_Settings.getSetting("autoCloseDoor")
    if isInnDoor(door) and not I.ZS_DataManager.getData("CheckInGameTime_" .. sanitizeString(door.cell.name)) and doorIsClosed(door) then
        local doorVar = door.globalVariable
        local fbed
        for index, bed in ipairs(door.cell:getAll(types.Activator)) do
            if isInnBed(bed) then
                if not doorVar or doorVar == bed.globalVariable then
                    fbed = bed
                end
            end
        end
        if door and fbed then
            actor:sendEvent("InRoomCheck", { door = door, bed = fbed })
        end

        return
    end
    if not checkoutDay then return end
    if not doorIsClosed(door) and isInnDoor(door) then
        async:newUnsavableSimulationTimer(1, function()
            if doorIsClosed(door) then
                types.Lockable.lock(door, 50)
            end
        end)
    elseif doorIsClosed(door) and isInnDoor(door) and autoClose then
        --Close the door automatically
        async:newUnsavableSimulationTimer(5, function()
            if door.startingRotation:getAnglesZYX() ~= door.rotation:getAnglesZYX() then
                --if the door was closed already, don't do anything
                world._runStandardActivationAction(door, actor)
                async:newUnsavableSimulationTimer(1, function()
                    if doorIsClosed(door) then
                        types.Lockable.lock(door, 50)
                    end
                end)
            end
        end)
    end
    return true
end
I.Activation.addHandlerForType(types.Door, doorActivation)
local function teleportPlayer(pos)
    world.players[1]:teleport(world.players[1].cell, pos)
end
local function teleportPlayer(pos)
    world.players[1]:teleport(world.players[1].cell, pos)
end

local function npcActivation(npc, actor)
    local class = types.NPC.records[npc.recordId].class
    if class:lower() == "publican" then
        local actorGlobals = world.mwscript.getGlobalVariables(actor)
        local innBed
        for index, value in ipairs(npc.cell:getAll(types.Activator)) do
            if isInnBed(value) then
                innBed = value
            end
        end
        local innDoor
        for index, value in ipairs(npc.cell:getAll(types.Door)) do
            if isInnDoor(value) then
                innDoor = value
            end
        end
        if not innBed then
            actorGlobals["IH_ModEnabled"] = 0
        else
            actorGlobals["IH_ModEnabled"] = 1
            if not innDoor then
                actorGlobals["IH_HasRoomNotJustBed"] = 0
            else
                actorGlobals["IH_HasRoomNotJustBed"] = 1
            end
        end
        local goldPerNight = I.ZS_InnOverhaul_Settings.getSetting("goldPerNight")
        local goldPerWeek = I.ZS_InnOverhaul_Settings.getSetting("goldPerWeek")
        actorGlobals["IH_GoldCost_1"] = goldPerNight
        actorGlobals["IH_GoldCost_2"] = goldPerNight * 2
        actorGlobals["IH_GoldCost_7"] = goldPerWeek

        actorGlobals["IH_HasGold_1"] = playerHasItemCount("gold_001", goldPerNight)
        actorGlobals["IH_HasGold_2"] = playerHasItemCount("gold_001", goldPerNight * 2)
        actorGlobals["IH_HasGold_7"] = playerHasItemCount("gold_001", goldPerWeek)

        if actorGlobals["IHS_1"] == 1 then
            local daysPassed = getGameTimeData()
            local checkoutDay = I.ZS_DataManager.getData("CheckOutDay_" .. sanitizeString(npc.cell.name))
            if checkoutDay then
                actorGlobals["IH_NightsRemaining"] = checkoutDay - daysPassed
                local keyID = getRoomKeyID(npc.cell)
                if keyID then
                    print("Has key? " .. keyID)
                    actorGlobals["IH_HasKey"] = playerHasItemCount(keyID, 1)
                end
            end
        end
        checkInnStatus(npc.cell, actor)
    end
end
I.Activation.addHandlerForType(types.NPC, npcActivation)
local navCell
local navDoor

local function getRoomNavPos1(cell)
    for index, obj in ipairs(cell:getAll(types.Door)) do
        if obj.type == types.Door and isInnDoor(obj) then
            navCell = cell
            navDoor = obj
            world.players[1]:sendEvent("getRoomNavPos1", obj)
            return
        end
    end
    navCell = nil
    navDoor = nil
end
local function getRoomNavPos2(pos)
    if not navCell or not navDoor or not pos then
        navCell = nil
        navDoor = nil
        return
    end
    for index, npc in ipairs(navCell:getAll(types.NPC)) do
        local record = types.NPC.records[npc.recordId]
        if record.class:lower() == "publican" then
            print(pos)
            npc:sendEvent('StartGuiding', { doorObj = navDoor, destPosition = pos })
        end
    end
    navCell = nil
    navDoor = nil
end

local function openDoor(obj)
    if obj.startingRotation:getAnglesZYX() == obj.rotation:getAnglesZYX() then
        types.Lockable.unlock(obj)
        async:newUnsavableSimulationTimer(1, function()
            world._runStandardActivationAction(obj, world.players[1])
        end)
    end
end
local function OpenDoorInRoom(data)
    local door = data.door
    openDoor(door)
    --Close the door automatically
    async:newUnsavableSimulationTimer(5, function()
        if door.startingRotation:getAnglesZYX() ~= door.rotation:getAnglesZYX() then
            --if the door was closed already, don't do anything
            world._runStandardActivationAction(door, world.players[1])
            async:newUnsavableSimulationTimer(5, function()
                if doorIsClosed(door) then
                    types.Lockable.lock(door, 50)
                end
            end)
        end
    end)
end

local function bedActivation(bed, actor)
    if isInnBed(bed) then
        local checkInGameTime = I.ZS_DataManager.getData("CheckInGameTime_" .. sanitizeString(bed.cell.name))
        if not checkInGameTime then
            for index, door in ipairs(bed.cell:getAll(types.Door)) do
                if isInnDoor(door) and doorIsClosed(door) then
                    OpenDoorInRoom({ door = door })
                    world.players[1]:sendEvent("ZS_ShowMessage", "You can't sleep now, your reservation has expired.")
                    return false
                end
            end
        end
    end
end
I.Activation.addHandlerForType(types.Activator, bedActivation)
local function onItemActive(item)
    if item.recordId == "zhac_checkin_marker" then
        local player = world.players[1]
        local nights = world.mwscript.getGlobalVariables(player)["IH_NightsToRent"]
        checkInPlayer(player.cell, nights, player)
        world.mwscript.getGlobalVariables(player)["IHS_1"] = 1
        item:remove()
    elseif item.recordId == "zhac_marker_extendmarker" then
        local player = world.players[1]
        local nights = world.mwscript.getGlobalVariables(player)["IH_NightsToRent"]
        extendRent(player.cell, nights, player)
        item:remove()
    elseif item.recordId == "zhac_marker_guidetoroom" then
        getRoomNavPos1(item.cell)
        item:remove()
    elseif item.recordId == "zhac_marker_checkout" then
        local player = world.players[1]
        checkOutPlayer(player.cell, player)
        item:remove()
    elseif item.recordId == "zhac_marker_goldupdate" then
        local player = world.players[1]
        local goldPerNight = I.ZS_InnOverhaul_Settings.getSetting("goldPerNight")
        local goldPerWeek = I.ZS_InnOverhaul_Settings.getSetting("goldPerWeek")

        world.mwscript.getGlobalVariables(player)["IH_HasGold_1"] = playerHasItemCount("gold_001", goldPerNight)
        world.mwscript.getGlobalVariables(player)["IH_HasGold_2"] = playerHasItemCount("gold_001", goldPerNight * 2)
        world.mwscript.getGlobalVariables(player)["IH_HasGold_7"] = playerHasItemCount("gold_001", goldPerWeek)
        item:remove()
    end
end

local function CellChange(player)
    local newCell = player.cell
    local updated = false
    if newCell.isExterior == false then
        local dataCheck = I.ZS_DataManager.getData("CheckOutDay_" .. sanitizeString(newCell.name))
        if dataCheck then
            updated = true
            checkInnStatus(newCell, player)
        end
    end
    if not updated then
        world.mwscript.getGlobalVariables(player)["IHS_1"] = 0
    end
    local hour = core.getGameTime()
    for index, value in ipairs(checkInDatas) do
       if hour > value.checkOutGameTime then
        checkOutPlayer(value.cellName,player)
        return
       end 
    end
    
end
local function hourChange(player)
    local hour = core.getGameTime()
    for index, value in ipairs(checkInDatas) do
       if hour > value.checkOutGameTime then
        checkOutPlayer(value.cellName,player)
        return
       end 
    end
end
local returnstage = -1
local sleeperstage = -1
local function bedRented(bed)
    if bed.globalVariable and world.mwscript.getGlobalVariables(world.players[1])[bed.globalVariable] == 1 then return true end

    if not bed.owner.recordId then
        return true
    end
    return false
end
local function RestStart(data)
    local bed = data.bed
    local safeSleep = I.ZS_InnOverhaul_Settings.getSetting("safeSleep")
    if returnstage ~= -1 and sleeperstage ~= -1 then
        local quests = types.Player.quests(world.players[1])
        if quests["TR_dbAttack"] and quests["A2_2_6thHouse"] then
            quests["TR_dbAttack"].stage = returnstage
            quests["A2_2_6thHouse"].stage = sleeperstage
        end
    end
    local isWait = data.isWait
    if bed and not isWait and isInnBed(bed) and bedRented(bed) and safeSleep then
        local innDoor
        for index, door in ipairs(bed.cell:getAll(types.Door)) do
            if isInnDoor(door) and not doorIsClosed(door) then --door must be closed!
                return
            elseif isInnDoor(door) and doorIsClosed(door) then
                innDoor = door
            end
        end
        if not innDoor then
            return
        end
        local quests = types.Player.quests(world.players[1])
        if not quests["TR_dbAttack"] or not quests["A2_2_6thHouse"] then
            return
        end
        print("Making it safe")
        if quests["TR_dbAttack"].stage ~= 51 then
            returnstage = quests["TR_dbAttack"].stage
            sleeperstage = quests["A2_2_6thHouse"].stage
        end
        quests["TR_dbAttack"].stage = 51
        quests["A2_2_6thHouse"].stage = -10
        async:newUnsavableSimulationTimer(0.1, function()
            if returnstage ~= -1 then
                local quests = types.Player.quests(world.players[1])
                if quests["TR_dbAttack"] and quests["A2_2_6thHouse"] then
                    quests["TR_dbAttack"].stage = returnstage
                    quests["A2_2_6thHouse"].stage = sleeperstage
                end
            end
            returnstage = -1
            sleeperstage = -1
        end)
    end
end
local function RestEnd(data)
    local player = world.players[1]
    checkInnStatus(player.cell, player)
end

local function objectIsInInnRoom(obj)
    for index, bed in ipairs(obj.cell:getAll(types.Activator)) do
        if isInnBed(bed) and I.ZS_DataManager.getData("OwnedObjects_" .. sanitizeString(bed.cell.name)) ~= nil then
            return true
        end
    end
end
return {
    interfaceName = "ZS_InnOverhaul",
    interface = {
        version = 1.1,
        findInns             = findInns,
        sanitizeString       = sanitizeString,
        setInnRoomRented     = setInnRoomRented,
        checkInPlayer        = checkInPlayer,
        checkInnStatus       = checkInnStatus,
        getRoomNavPos1       = getRoomNavPos1,
        formatDateWithSuffix = formatDateWithSuffix,
        convertContainers    = convertContainers,
        objectIsInInnRoom    = objectIsInInnRoom,
        checkOutPlayer      = checkOutPlayer,
         extendRent          = extendRent,
    },
    engineHandlers = {
        onItemActive = onItemActive,
        onSave = function ()
            return {checkInDatas = checkInDatas}
        end,
        onLoad = function (data)
            if data then
                checkInDatas = data.checkInDatas
            end
        end
    },
    eventHandlers = {
        teleportPlayer = teleportPlayer,
        getRoomNavPos2 = getRoomNavPos2,
        openDoor = openDoor,
        CellChange = CellChange,
        RestStart = RestStart,
        RestEnd = RestEnd,
        OpenDoorInRoom = OpenDoorInRoom,
        hourChange = hourChange,
    }
}
