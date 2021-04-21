local FullLoot = {}

FullLoot.scriptName = "FullLoot"


FullLoot.defaultConfig = {
    container = {
        refId = "fullloot_loot",
        name = "Player loot",
        baseId = "dead rat",
        packetType = "spawn",
        type = "creature"
    },
    guise = {
        name = "%s's grave",
        models = {
            "f/furn_shrine_aralor_01.nif",
            "f/furn_shrine_delyn_01.nif",
            "f/furn_shrine_felms_01.nif",
            "f/furn_shrine_llothis_01.nif",
            "f/furn_shrine_meris_01.nif",
            "f/furn_shrine_nerevar_01.nif",
            "f/furn_shrine_olms_01.nif",
            "f/furn_shrine_rilms_01.nif",
            "f/furn_shrine_roris_01.nif",
            "f/furn_shrine_seryn_01.nif",
            "f/furn_shrine_tribunal_01.nif",
            "f/furn_shrine_veloth_01.nif",
            "f/furn_shrine_vivec_01.nif"
        },
        packetType = "place",
        type = "miscellaneous",
        script = "noPickUp"
    },
    offset = {
        posX = 0,
        posY = 0,
        posZ = -25,
        rotX = 0,
        rotY = 0,
        rotZ = math.pi
    },
    collision = true,
    despawn = false,
    despawnTime = 120
}

FullLoot.config = DataManager.loadConfiguration(FullLoot.scriptName, FullLoot.defaultConfig)


FullLoot.defaultData = {
    instances = {},
    records = {}
}

function FullLoot.getRandom(ceiling)
    return math.random(1, ceiling)
end


function FullLoot.loadData()
    FullLoot.data = DataManager.loadData(FullLoot.scriptName, FullLoot.defaultData)
end

function FullLoot.saveData()
    DataManager.saveData(FullLoot.scriptName, FullLoot.data)
end


function FullLoot.checkContainerRecord()
    local recordStore = RecordStores[FullLoot.config.container.type]

    if recordStore.data.permanentRecords[FullLoot.config.container.refId]  == nil then
        recordStore.data.permanentRecords[FullLoot.config.container.refId] = {
            baseId = FullLoot.config.container.baseId,
            name = FullLoot.config.container.name
        }

        recordStore:Save()
    end
end

function FullLoot.makeRecords(pid)
    local cell = LoadedCells[tes3mp.GetCell(pid)]

    local name = string.format(FullLoot.config.guise.name, Players[pid].accountName)

    --pick a random model
    local models = FullLoot.config.guise.models
    local model = models[ FullLoot.getRandom(#models) ]

    --make guise custom record
    local recordStore = RecordStores[FullLoot.config.guise.type]
    local guiseId = recordStore:GenerateRecordId()
    recordStore.data.generatedRecords[guiseId] = {
        name = name,
        model = model,
        script = FullLoot.config.guise.script
    }

    recordStore:Save()

    --send custom records to all necessary players
    recordStore:LoadGeneratedRecords(pid, recordStore.data.generatedRecords, {guiseId}, true)
    
    --make framework record
    return ContainerFramework.createRecord(
        FullLoot.config.container.refId,
        FullLoot.config.container.packetType,
        guiseId,
        FullLoot.config.guise.packetType,
        FullLoot.config.collision
    )
end


function FullLoot.isPlayerLoot(instanceId)
    return FullLoot.data.instances[instanceId] ~= nil
end

function FullLoot.isContainerEmpty(instanceId)
    return next(ContainerFramework.getInventory(instanceId)) == nil
end


function FullLootDestroyContainer(instanceId)
    FullLoot.destroyDeathContainer(instanceId)
end

function FullLoot.makeDespawnTimer(instanceId, delay)
    tes3mp.StartTimer(tes3mp.CreateTimerEx(
        "FullLootDestroyContainer",
        1000 * delay,
        "i",
        instanceId
    ))
end

function FullLoot.createDeathContainer(pid)
    local recordId = FullLoot.makeRecords(pid)
    local location = {
        posX = tes3mp.GetPosX(pid),
        posY = tes3mp.GetPosY(pid),
        posZ = tes3mp.GetPosZ(pid),
        rotX = 0,
        rotY = 0,
        rotZ = tes3mp.GetRotZ(pid),
    }
    for index, value in pairs(location) do
        location[index] = value + FullLoot.config.offset[index]
    end

    local cellDescription = tes3mp.GetCell(pid)

    local tempLoad = false
    if LoadedCells[cellDescription] == nil then
        tempLoad = true
        logicHandler.LoadCell(cellDescription)
    end

    local instanceId = ContainerFramework.createContainerAtLocation(recordId, cellDescription, location)

    if tempLoad then
        logicHandler.UnloadCell(cellDescription)
    end

    FullLoot.data.instances[instanceId] = os.time()

    if FullLoot.config.despawn then
        FullLoot.makeDespawnTimer(instanceId, FullLoot.config.despawnTime)
    end

    return instanceId
end

function FullLoot.destroyDeathContainer(instanceId)
    if FullLoot.data.instances[instanceId] ~= nil then
        ContainerFramework.removeContainer(instanceId)
        FullLoot.data.instances[instanceId] = nil
    end
end

function FullLoot.destroyAllDeathContainers()
    for instanceId in pairs(FullLoot.data.instances) do
        FullLoot.destroyDeathContainer(instanceId)
    end
end

function FullLoot.fillDeathContainer(pid, instanceId, inventory)
    ContainerFramework.setInventory(instanceId, inventory)
end

function FullLoot.emptyPlayerInventory(pid)
    local player = Players[pid]
    player.data.inventory = {}
    player.data.equipment = {}
    player:LoadInventory()
    player:LoadEquipment()
end


function FullLoot.OnPlayerDeathValidator(eventStatus, pid)
    if next(Players[pid].data.inventory) ~= nil or next(Players[pid].data.equipment) ~= nil then
        local instanceId = FullLoot.createDeathContainer(pid)
        
        FullLoot.fillDeathContainer(pid, instanceId, Players[pid].data.inventory)
        FullLoot.emptyPlayerInventory(pid)
    end
end

function FullLoot.OnServerPostInit(eventStatus)
    FullLoot.loadData()
    FullLoot.checkContainerRecord()
    if FullLoot.config.despawn then
        for instanceId, instanceTime in pairs(FullLoot.data.instances) do
            local dtime = os.time() - instanceTime
            if dtime > FullLoot.config.despawnTime then
                FullLoot.destroyDeathContainer(instanceId)
            else
                FullLoot.makeDespawnTimer(instanceId, dtime)
            end
        end
    end
end

function FullLoot.OnServerExit(eventStatus)
    FullLoot.saveData()
end

function FullLoot.CFOnContainer(eventStatus, pid, instanceId)
    if eventStatus.validCustomHandlers then
        if
            FullLoot.isPlayerLoot(instanceId) and
            FullLoot.isContainerEmpty(instanceId)
        then
            FullLoot.destroyDeathContainer(instanceId)
        end
    end
end


customEventHooks.registerHandler("OnServerPostInit", FullLoot.OnServerPostInit)
customEventHooks.registerHandler("OnServerExit", FullLoot.OnServerExit)
customEventHooks.registerValidator("OnPlayerDeath", FullLoot.OnPlayerDeathValidator)

customEventHooks.registerHandler("ContainerFramework_OnContainer", FullLoot.CFOnContainer)


return FullLoot