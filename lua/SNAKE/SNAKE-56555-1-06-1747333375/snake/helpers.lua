-- helpers.lua
local helpers = {}

-- Helper function to convert degrees to radians
function helpers.degToRad(degrees)
    return degrees * math.pi / 180
end

function helpers.setScale(pid, cellDescription, uniqueIndex, refId, scale)
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
    local splitIndex = uniqueIndex:split("-")
    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectRefId(refId)
    tes3mp.SetObjectScale(scale)
    tes3mp.AddObject()
    tes3mp.SendObjectScale(true, false)
end

function helpers.DeleteObject(pid, cellDescription, uniqueIndex, forEveryone)
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
    local splitIndex = uniqueIndex:split("-")
    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.AddObject()
    tes3mp.SendObjectDelete(forEveryone, false)
end

function helpers.ResendPlace(pid, uniqueIndex, cellDescription, forEveryone, skipRotate)
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)

    local object = LoadedCells[cellDescription].data.objectData[uniqueIndex]
    if not object then
        tes3mp.LogMessage(enumerations.log.ERROR,
            "[SnakeGame] ResendPlace: Object " .. uniqueIndex .. " not found in cell " .. cellDescription)
        return
    end

    if object and object.location and object.refId then
        local splitIndex = uniqueIndex:split("-")
        tes3mp.SetObjectRefNum(splitIndex[1])
        tes3mp.SetObjectMpNum(splitIndex[2])
        tes3mp.SetObjectRefId(object.refId)

        -- Set the position and rotation
        tes3mp.SetObjectPosition(object.location.posX, object.location.posY, object.location.posZ)
        tes3mp.SetObjectRotation(object.location.rotX, object.location.rotY, object.location.rotZ)

        -- Set scale if present
        if object.scale then
            tes3mp.SetObjectScale(object.scale)
        else
            tes3mp.SetObjectScale(1.0)
        end

        tes3mp.AddObject()

        -- Send ObjectMove instead of ObjectPlace to avoid recreating the object
        tes3mp.SendObjectMove(forEveryone, false)

        -- Only send rotation if needed - log for debugging
        if skipRotate then
            if SnakeGame.logging_enabled then
                tes3mp.LogMessage(enumerations.log.INFO,
                    "[SnakeGame] ResendPlace: Skipping rotation for " .. uniqueIndex)
            end
        else
            tes3mp.SendObjectRotate(forEveryone, false)
            -- if SnakeGame.logging_enabled then
                tes3mp.LogMessage(enumerations.log.INFO,
                    "[SnakeGame] ResendPlace: Sending rotation for " .. uniqueIndex)
            -- end
        end

        if object.scale and object.scale ~= 1 then
            tes3mp.SendObjectScale(forEveryone, false)
        end

        if SnakeGame.logging_enabled then
            tes3mp.LogMessage(enumerations.log.INFO,
                "[SnakeGame] ResendPlace: Moved object " .. uniqueIndex .. " (" .. object.refId .. ") to position " ..
                object.location.posX .. ", " .. object.location.posY .. ", " .. object.location.posZ ..
                (skipRotate and " (skipped rotation)" or " (with rotation)"))
        end
    else
        tes3mp.LogMessage(enumerations.log.ERROR, "[SnakeGame] ResendPlace: Invalid object data for " .. uniqueIndex)
    end
end

function helpers.createObjects(cellDescription, objectsToCreate, packetType, temp_object_uniqueIndex)
    -- local uniqueIndexes = {}
    local generatedRecordIdsPerType = {}
    local unloadCellAtEnd = false
    local shouldSendPacket = false
    local uniqueIndex
    local isValid

    -- If the desired cell is not loaded, load it temporarily
    if LoadedCells[cellDescription] == nil then
        logicHandler.LoadCell(cellDescription)
        unloadCellAtEnd = true
    end

    local cell = LoadedCells[cellDescription]

    -- Only send a packet if there are players on the server to send it to
    shouldSendPacket = true
    tes3mp.ClearObjectList()

    for _, object in pairs(objectsToCreate) do
        local refId = object.refId
        local count = object.count
        local charge = object.charge
        local enchantmentCharge = object.enchantmentCharge
        local soul = object.soul
        local location = object.location
        if object.scale == nil then object.scale = 1 end
        local scale = object.scale

        local mpNum

        if SnakeGame.cfg.initializing then
            mpNum = WorldInstance:GetCurrentMpNum() + 1
            uniqueIndex = 0 .. "-" .. mpNum
            isValid = true
        else
            local splitIndex = temp_object_uniqueIndex:split("-")
            mpNum = splitIndex[2]
            uniqueIndex = 0 .. "-" .. mpNum
            isValid = true
        end

        -- Is this object based on a a generated record? If so, it needs special
        -- handling here and further below
        if logicHandler.IsGeneratedRecord(refId) then
            local recordType = logicHandler.GetRecordTypeByRecordId(refId)

            if RecordStores[recordType] ~= nil then
                -- Add a link to this generated record in the cell it is being placed in
                cell:AddLinkToRecord(recordType, refId, uniqueIndex)

                if generatedRecordIdsPerType[recordType] == nil then
                    generatedRecordIdsPerType[recordType] = {}
                end

                if shouldSendPacket and not tableHelper.containsValue(generatedRecordIdsPerType[recordType], refId) then
                    table.insert(generatedRecordIdsPerType[recordType], refId)
                end
            else
                isValid = false
                tes3mp.LogMessage(enumerations.log.ERROR, "Attempt at creating object " .. refId ..
                    " based on non-existent generated record")
            end
        end

        if isValid then
            WorldInstance:SetCurrentMpNum(mpNum)
            tes3mp.SetCurrentMpNum(mpNum)

            cell:InitializeObjectData(uniqueIndex, refId)
            cell.data.objectData[uniqueIndex].location = location
            cell.data.objectData[uniqueIndex].scale = scale

            if packetType == "place" then
                table.insert(cell.data.packets.place, uniqueIndex)
            elseif packetType == "spawn" then
                table.insert(cell.data.packets.spawn, uniqueIndex)
                table.insert(cell.data.packets.actorList, uniqueIndex)
            end

            -- Are there any players on the server? If so, initialize the object
            -- list for the first one we find and just send the corresponding packet
            -- to everyone
            if shouldSendPacket then
                tes3mp.SetObjectListCell(cellDescription)
                tes3mp.SetObjectRefId(refId)
                tes3mp.SetObjectRefNum(0)
                tes3mp.SetObjectMpNum(mpNum)

                if packetType == "place" then
                    tes3mp.SetObjectCount(count)
                    tes3mp.SetObjectCharge(charge)
                    tes3mp.SetObjectEnchantmentCharge(enchantmentCharge)
                    tes3mp.SetObjectSoul(soul)
                end

                tes3mp.SetObjectPosition(location.posX, location.posY, location.posZ)
                tes3mp.SetObjectRotation(location.rotX, location.rotY, location.rotZ)
                tes3mp.SetObjectScale(scale)
                tes3mp.AddObject()

                if scale ~= 1 then
                    tableHelper.insertValueIfMissing(LoadedCells[cellDescription].data.packets.scale, uniqueIndex)
                end
            end
        end
    end

    if shouldSendPacket then
        -- Ensure the visitors to this cell have the records they need for the
        -- objects we've created
        for priorityLevel, recordStoreTypes in ipairs(config.recordStoreLoadOrder) do
            for _, recordType in ipairs(recordStoreTypes) do
                if generatedRecordIdsPerType[recordType] ~= nil then
                    local recordStore = RecordStores[recordType]
                    if recordStore ~= nil then
                        local idArray = generatedRecordIdsPerType[recordType]
                        for _, visitorPid in pairs(cell.visitors) do
                            recordStore:LoadGeneratedRecords(visitorPid, recordStore.data.generatedRecords, idArray)
                        end
                    end
                end
            end
        end

        if packetType == "place" then
            tes3mp.SendObjectPlace(true, false)
            tes3mp.SendObjectRotate(true, false)
            tes3mp.SendObjectScale(true, false)
        elseif packetType == "spawn" then
            tes3mp.SendObjectSpawn(true, false)
        end
    end

    cell:Save()

    if unloadCellAtEnd then
        logicHandler.UnloadCell(cellDescription)
    end

    return uniqueIndex
end

-- Custom function to load objects including scale
function helpers.LoadObjectsPlacedWithScale(pid, cellDescription, forEveryone)
    if not logicHandler.IsCellLoaded(cellDescription) then
        return false
    end

    local cell = LoadedCells[cellDescription]
    local objectCount = 0
    local objectData = cell.data.objectData
    local uniqueIndexArray = cell.data.packets.place

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Loading " .. #uniqueIndexArray .. " objects for cell " .. cellDescription)

    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)

    -- Keep track of objects that need scale
    local objectsWithScale = {}

    for _, uniqueIndex in pairs(uniqueIndexArray) do
        if objectData[uniqueIndex] ~= nil then
            local location = objectData[uniqueIndex].location

            -- Ensure data integrity before proceeding
            if type(location) == "table" and tableHelper.getCount(location) == 6 and
                tableHelper.usesNumericalValues(location) and
                cell:ContainsPosition(location.posX, location.posY) then
                -- Add the object to the packet
                local splitIndex = uniqueIndex:split("-")
                tes3mp.SetObjectRefNum(splitIndex[1])
                tes3mp.SetObjectMpNum(splitIndex[2])
                tes3mp.SetObjectRefId(objectData[uniqueIndex].refId)

                if objectData[uniqueIndex].count then
                    tes3mp.SetObjectCount(objectData[uniqueIndex].count)
                end

                if objectData[uniqueIndex].charge then
                    tes3mp.SetObjectCharge(objectData[uniqueIndex].charge)
                end

                if objectData[uniqueIndex].enchantmentCharge then
                    tes3mp.SetObjectEnchantmentCharge(objectData[uniqueIndex].enchantmentCharge)
                end

                if objectData[uniqueIndex].soul then
                    tes3mp.SetObjectSoul(objectData[uniqueIndex].soul)
                end

                tes3mp.SetObjectPosition(location.posX, location.posY, location.posZ)
                tes3mp.SetObjectRotation(location.rotX, location.rotY, location.rotZ)

                -- Check if object has scale
                if objectData[uniqueIndex].scale and objectData[uniqueIndex].scale ~= 1 then
                    tes3mp.SetObjectScale(objectData[uniqueIndex].scale)
                    table.insert(objectsWithScale, uniqueIndex)
                end

                tes3mp.AddObject()
                objectCount = objectCount + 1
            end

            -- If we're about to exceed the maximum number of objects in a single packet,
            -- start a new packet
            if objectCount >= 3000 then
                tes3mp.SendObjectPlace(forEveryone, false)
                tes3mp.SendObjectRotate(forEveryone, false)

                -- Send scale packets for this batch if needed
                if #objectsWithScale > 0 then
                    tes3mp.ClearObjectList()
                    tes3mp.SetObjectListPid(pid)
                    tes3mp.SetObjectListCell(cellDescription)

                    for _, scaleIndex in ipairs(objectsWithScale) do
                        local splitIndex = scaleIndex:split("-")
                        tes3mp.SetObjectRefNum(splitIndex[1])
                        tes3mp.SetObjectMpNum(splitIndex[2])
                        tes3mp.SetObjectScale(objectData[scaleIndex].scale)
                        tes3mp.AddObject()
                    end

                    tes3mp.SendObjectScale(forEveryone, false)
                    objectsWithScale = {}
                end

                tes3mp.ClearObjectList()
                tes3mp.SetObjectListPid(pid)
                tes3mp.SetObjectListCell(cellDescription)
                objectCount = 0
            end
        end
    end

    if objectCount > 0 then
        tes3mp.SendObjectPlace(forEveryone, false)
        tes3mp.SendObjectRotate(forEveryone, false)

        -- Send scale packets if needed
        if #objectsWithScale > 0 then
            tes3mp.ClearObjectList()
            tes3mp.SetObjectListPid(pid)
            tes3mp.SetObjectListCell(cellDescription)

            for _, scaleIndex in ipairs(objectsWithScale) do
                local splitIndex = scaleIndex:split("-")
                tes3mp.SetObjectRefNum(splitIndex[1])
                tes3mp.SetObjectMpNum(splitIndex[2])
                tes3mp.SetObjectScale(objectData[scaleIndex].scale)
                tes3mp.AddObject()
            end

            tes3mp.SendObjectScale(forEveryone, false)
        end
    end

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Loaded " .. objectCount .. " objects with " ..
        #objectsWithScale .. " scaled objects for cell " .. cellDescription)

    return true
end

-- Verify that key objects are present in the cell
function helpers.VerifyCellObjects(pid, cellDescription)
    -- Determine which key object to check based on the cell
    local objectRefId = nil

    tes3mp.LogMessage(enumerations.log.INFO,
        "[SnakeGame] Verifying objects in cell: " .. cellDescription ..
        ", comparing with room cell: " .. SnakeGame.cfg.roomCell)

    -- Use string.lower() to ensure case-insensitive comparison
    local lowerCurrentCell = string.lower(cellDescription)
    local lowerRoomCell = string.lower(SnakeGame.cfg.roomCell)

    if lowerCurrentCell == lowerRoomCell then
        objectRefId = "sg_dwemer_game_hall_door"
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Checking for object: sg_dwemer_game_hall in main game room")
    elseif cellDescription == "-3, -2" then
        objectRefId = "sg_cryptic_building_door"
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Checking for object: sg_cryptic_building in Balmora cell")
    else
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Not a monitored cell, skipping verification")
        return true -- Not a cell we're monitoring
    end

    -- Additional safety check
    if objectRefId == nil then
        tes3mp.LogMessage(enumerations.log.ERROR,
            "[SnakeGame] Failed to determine object refId for cell: " .. cellDescription)
        return false
    end

    -- Check if the cell is loaded
    if not logicHandler.IsCellLoaded(cellDescription) then
        return false -- Cell not loaded, assume objects are missing
    end

    -- Look for the key object in the cell
    tes3mp.LogMessage(enumerations.log.INFO, "[SnakeGame] Verifying cellDescription..." .. tostring(cellDescription))
    local objectFound = false
    local uniqueIndex = SnakeGame.preCreatedObjects[objectRefId].uniqueIndex -- this is nil
    if tableHelper.containsValue(LoadedCells[cellDescription].data.packets.place, uniqueIndex) then
        objectFound = true
    end

    return objectFound
end

-- Restore cell from the most recent backup
function helpers.RestoreCellFromBackup(pid, cellDescription)
    local backupFilename = "custom/snake_backup_" .. cellDescription .. ".json"

    -- Try to load the backup
    local backupData = jsonInterface.load(backupFilename)

    if backupData ~= nil then
        -- Backup found, restore the cell
        tes3mp.LogMessage(enumerations.log.INFO,
            "[SnakeGame] Restoring cell " .. cellDescription ..
            " from backup " .. backupFilename)

        -- Make sure the cell is loaded
        if not logicHandler.IsCellLoaded(cellDescription) then
            logicHandler.LoadCell(cellDescription)
        end

        -- Replace the cell data with the backup data
        LoadedCells[cellDescription].data = tableHelper.deepCopy(backupData)

        -- Save the cell to ensure it's written to disk
        LoadedCells[cellDescription]:Save()

        -- Send a fresh load of objects to all players in the cell
        local objectData = LoadedCells[cellDescription].data.objectData
        local packets = LoadedCells[cellDescription].data.packets
        SnakeGame.helpers.LoadObjectsPlacedWithScale(pid, cellDescription, true)
        if cellDescription == SnakeGame.cfg.roomCell then
            LoadedCells[cellDescription]:LoadObjectsSpawned(pid, objectData, packets.spawn, true)
        end
        return true
    else
        tes3mp.LogMessage(enumerations.log.ERROR,
            "[SnakeGame] Failed to restore cell " .. cellDescription ..
            ". No backup file found.")

        return false
    end
end

function helpers.playSoundInCell(sound, index, cellDescription)
    for i = 0, #Players do
        if Players[i] ~= nil and Players[i]:IsLoggedIn() then
            if Players[i].data.location.cell == cellDescription then
                table.insert(Players[i].consoleCommandsQueued, sound)
                -- logicHandler.RunConsoleCommandOnObject(i, sound, cellDescription, index, false)
                tes3mp.ClearObjectList()
                tes3mp.SetObjectListPid(i)
                tes3mp.SetObjectListCell(cellDescription)
                tes3mp.SetObjectListConsoleCommand(sound)
                local splitIndex = index:split("-")
                tes3mp.SetObjectRefNum(splitIndex[1])
                tes3mp.SetObjectMpNum(splitIndex[2])
                tes3mp.AddObject()
                tes3mp.SendConsoleCommand(false, false)
            end
        end
    end
end

return helpers
