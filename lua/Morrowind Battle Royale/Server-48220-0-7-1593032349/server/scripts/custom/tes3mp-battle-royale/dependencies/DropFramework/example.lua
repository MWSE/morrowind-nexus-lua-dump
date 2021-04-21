local example = {}

example.scriptName = "DropExample"

example.data = DataManager.loadData(example.scriptName, {})

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
    if example.data.containerId == nil then
        example.data.containerId = ContainerFramework.createRecord(
            "dead rat",
            "spawn",
            "misc_vivec_ashmask_01_fake",
            "place",
            "false"
        )
        tes3mp.LogMessage(enumerations.log.INFO, string.format("Created and example custom container with id %d", example.data.containerId))
        DataManager.saveData(example.scriptName, example.data)
    end
end)

function example.command(pid, cmd)
    tes3mp.SendMessage(pid,"Spawning a custom container!\n")
    DropFramework.addStock("test")
    DropFramework.addDrop(
        "test",
        DropFramework.createDrop({ refId = "iron claymore" }, 1, 10)
    )

    DropFramework.addRoll(
        "test",
        {
            DropFramework.createDrop({ refId = "iron longsword" }, 1, 10),
            DropFramework.createDrop({ refId = "iron broadsword" }, 1, 10),
            DropFramework.createDrop({ refId = "iron saber" }, 1, 10)
        },
        {
            0.33,
            0.33,
            0.35
        }
    )
    
    local inventory = DropFramework.resolveStock("test")

    local instanceId = ContainerFramework.createContainerAtLocation(example.data.containerId, tes3mp.GetCell(pid), 
    {
        posX = tes3mp.GetPosX(pid),
        posY = tes3mp.GetPosY(pid),
        posZ = tes3mp.GetPosZ(pid),
        rotX = math.pi * 0.5,
        rotY = 0,
        rotZ = 0
    })

    ContainerFramework.setInventory(instanceId, inventory)
end

customCommandHooks.registerCommand("drop", example.command)