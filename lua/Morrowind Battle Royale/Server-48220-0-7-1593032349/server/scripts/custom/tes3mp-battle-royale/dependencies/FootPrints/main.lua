local FootPrints = {}

FootPrints.scriptName = "FootPrints"

FootPrints.defaultConfig = {
    interval = 4,
    refId = "footprints_key",
    baseId = "key_dwe_satchel00",
    name = "footprint",
    model = "",
    limit = 30,
    Z = 0
}

FootPrints.config = DataManager.loadConfiguration(FootPrints.scriptName, FootPrints.defaultConfig)


FootPrints.timers = {}

FootPrints.prints = {}

FootPrints.markToDelete = {}

function FootPrints.LogMessage(mes)
    tes3mp.LogMessage(enumerations.log.INFO, "[FootPrints] "..mes)
end


function FootPrints.OnServerPostInit()
    local recordStore = RecordStores["miscellaneous"]
    local refId = FootPrints.config.refId

    if recordStore.data.permanentRecords[refId] == nil then
        recordStore.data.permanentRecords[refId] = {
            baseId = FootPrints.config.baseId,
            model = FootPrints.config.model,
            name = FootPrints.config.name
        }
        recordStore:Save()
    end
end

customEventHooks.registerHandler("OnServerPostInit", FootPrints.OnServerPostInit)


function FootPrints.deletePrint(cellDescription, uniqueIndex)
    if LoadedCells[cellDescription] == nil then
        if FootPrints.markToDelete[cellDescription] == nil then
            FootPrints.markToDelete[cellDescription] = {}
        end

        table.insert(FootPrints.markToDelete[cellDescription], uniqueIndex)
        return
    end

    if next(Players) ~= nil then
        logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)
    end

    LoadedCells[cellDescription]:DeleteObjectData(uniqueIndex)
end

function FootPrints.addPrint(pid, print)
    local playerPrints = FootPrints.prints[pid]

    if playerPrints.count == FootPrints.config.limit then
        --remove the oldest print if we reached the limit
        local head = playerPrints.head
        local second = head.next
        local tail = head.prev

        tail.next = second
        second.prev = tail
        playerPrints.head = second

        FootPrints.deletePrint(head.value.cellDescription, head.value.uniqueIndex)
        playerPrints.count = playerPrints.count - 1
    end

    local t = {
        value = print
    }
    if playerPrints.count == 0 then
        t.next = t
        t.prev = t
        playerPrints.head = t
    else
        local head = playerPrints.head
        local tail = head.prev
        t.next = head
        t.prev = tail
        head.prev = t
        tail.next = t
    end
    playerPrints.count = playerPrints.count + 1
end

function FootPrintsPlayerTimer(pid)
    local location = {
        posX = tes3mp.GetPosX(pid),
        posY = tes3mp.GetPosY(pid),
        posZ = tes3mp.GetPosZ(pid) + FootPrints.config.Z,
        rotX = 0,
        rotY = 0,
        rotZ = 0
    }

    local cellDescription = tes3mp.GetCell(pid)
    local unload = false

    if LoadedCells[cellDescription] == nil then
       logicHandler.LoadCell(cellDescription)
       unload = true
    end

    local uniqueIndex = logicHandler.CreateObjectAtLocation(
        cellDescription,
        location,
        FootPrints.config.refId,
        "place"
    )

    FootPrints.addPrint(pid, {
        cellDescription = cellDescription,
        uniqueIndex = uniqueIndex
    })

    tes3mp.RestartTimer(FootPrints.timers[pid], time.seconds(FootPrints.config.interval))

    if unload then
       logicHandler.UnloadCell(cellDescription)
    end
end


function FootPrints.OnPlayerAuthentified(eventStatus, pid)
    local timerId = tes3mp.CreateTimerEx(
        "FootPrintsPlayerTimer",
        time.seconds(FootPrints.config.interval),
        "i",
        pid
    )
    FootPrints.timers[pid] = timerId
    FootPrints.prints[pid] = {
        head = nil,
        count = 0
    }
    tes3mp.StartTimer(timerId)
end

customEventHooks.registerHandler("OnPlayerAuthentified", FootPrints.OnPlayerAuthentified)


function FootPrints.clearPlayer(pid)
    FootPrints.LogMessage("Clearing player "..pid)
    if FootPrints.timers[pid] ~= nil then
        tes3mp.StopTimer(FootPrints.timers[pid])
        FootPrints.LogMessage("Stopped the timer")
        FootPrints.timers[pid] = nil
    end

    if FootPrints.prints[pid] ~= nil then
        FootPrints.LogMessage(string.format("Removing %d prints", FootPrints.prints[pid].count))
        if FootPrints.prints[pid].count ~= 0 then
            local t = FootPrints.prints[pid].head
            for i = 1, FootPrints.prints[pid].count do
                FootPrints.deletePrint(t.value.cellDescription, t.value.uniqueIndex)
                t = t.next
            end

            FootPrints.prints[pid] = nil
        end
    end
end

function FootPrints.OnPlayerDisconnect(eventStatus, pid)
    if eventStatus.validCustomHandlers then
        FootPrints.clearPlayer(pid)
    end
end

customEventHooks.registerHandler("OnPlayerDisconnect", FootPrints.OnPlayerDisconnect)


function FootPrints.clearCell(cellDescription)
    if FootPrints.markToDelete[cellDescription] ~= nil then
        FootPrints.LogMessage(string.format(
            "Removing %d prints from %s",
            #FootPrints.markToDelete[cellDescription],
            cellDescription
        ))
        for _, uniqueIndex in pairs(FootPrints.markToDelete[cellDescription]) do
            FootPrints.deletePrint(cellDescription, uniqueIndex)
        end
        FootPrints.markToDelete[cellDescription] = nil
    end
end

function FootPrints.OnCellLoad(eventStatus, pid, cellDescription)
    if eventStatus.validCustomHandlers then
        FootPrints.clearCell(cellDescription)
    end
end

customEventHooks.registerHandler("OnCellLoad", FootPrints.OnCellLoad)

function FootPrints.OnServerExit(eventStatus)
    for pid, player in pairs(Players) do
        FootPrints.clearPlayer(pid)
    end

    FootPrints.LogMessage("Clearing cells")
    for cellDescription, list in pairs(FootPrints.markToDelete) do
        local unload = false
        if LoadedCells[cellDescription] == nil then
            logicHandler.LoadCell(cellDescription)
            unload = true
        end

        FootPrints.clearCell(cellDescription)

        if unload then
            logicHandler.UnloadCell(cellDescription)
        end
    end
end

customEventHooks.registerHandler("OnServerExit", FootPrints.OnServerExit)


return FootPrints
