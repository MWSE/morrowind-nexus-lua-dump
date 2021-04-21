local VisualHarvesting = {}

VisualHarvesting.scriptName = "VisualHarvesting"

VisualHarvesting.defaultConfig = require("custom.VisualHarvesting.defaultConfig")

VisualHarvesting.config = DataManager.loadConfiguration(VisualHarvesting.scriptName, VisualHarvesting.defaultConfig)
tableHelper.fixNumericalKeys(VisualHarvesting.config)

VisualHarvesting.defaultData = {}
VisualHarvesting.data = DataManager.loadData(VisualHarvesting.scriptName, VisualHarvesting.defaultData)


function VisualHarvesting.sendObjectState(pid, cellDescription, uniqueIndex, state)
    local splitIndex = uniqueIndex:split("-")

    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectState(state)

    tes3mp.AddObject()
end

function VisualHarvesting.getRandom()
    return math.random()
end

function VisualHarvesting.getGameTime()
  return WorldInstance.data.time.daysPassed*24 + WorldInstance.data.time.hour
end

function VisualHarvesting.saveData()
    DataManager.saveData(VisualHarvesting.scriptName, VisualHarvesting.data)
end


function VisualHarvesting.isHarvestable(refId)
    return VisualHarvesting.config.plants[refId] ~= nil
end

function VisualHarvesting.isReady(uniqueIndex)
    local data = VisualHarvesting.data[uniqueIndex]
    if data == nil then
        return true
    end
    return data.state
end

function VisualHarvesting.addIngredientToPlayer(pid, refId)
    local player = Players[pid]
    local plantConfig = VisualHarvesting.config.plants[refId]

    local roll = VisualHarvesting.getRandom()
    local skillRoll = 0
    
    if VisualHarvesting.config.alchemyDeterminesChance then
        skillRoll = (player.data.skills.Alchemy.base + player.data.skills.Alchemy.damage) * 0.5 + roll * 50
    else
        skillRoll = roll * 100
    end
    
    local ingredient_count = 0
    for count, skillBracket in pairs(plantConfig.amount) do
        ingredient_count = count
        if skillBracket > skillRoll then
            break
        end
    end
    
    if ingredient_count == 0 then
        tes3mp.MessageBox(pid, VisualHarvesting.config.menuId, VisualHarvesting.config.fail.message)
        tes3mp.PlaySpeech(pid, VisualHarvesting.config.fail.sound)
    else
        local ingred
        if plantConfig.ingredient == nil then
            ingred = plantConfig.ingredients[math.random(#plantConfig.ingredients)]
        else
            ingred = plantConfig.ingredient
        end

        inventoryHelper.addItem(player.data.inventory, ingred, ingredient_count, -1, -1, "")
        local message = string.format(VisualHarvesting.config.success.message, ingredient_count)
        tes3mp.MessageBox(pid, VisualHarvesting.config.menuId, message)
        tes3mp.PlaySpeech(pid, VisualHarvesting.config.success.sound)
        
        tes3mp.ClearInventoryChanges(pid)
        tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
        tes3mp.AddItemChange(pid, ingred, ingredient_count, -1, -1, "")
        tes3mp.SendInventoryChanges(pid)
    end
end

function VisualHarvesting.enablePlant(pid, cellDescription, uniqueIndex)
    VisualHarvesting.data[uniqueIndex] = nil
    LoadedCells[cellDescription].data.objectData[uniqueIndex].state = true
    
    VisualHarvesting.sendObjectState(pid, cellDescription, uniqueIndex, true)
end

function VisualHarvesting.disablePlant(pid, cellDescription, uniqueIndex)
    VisualHarvesting.data[uniqueIndex] = {
        state = false,
        harvestTime = VisualHarvesting.getGameTime()
    }
    local objectData = LoadedCells[cellDescription].data.objectData[uniqueIndex]
    if objectData ~= nil then
        objectData.state = false
    end

    VisualHarvesting.sendObjectState(pid, cellDescription, uniqueIndex, false)
end

function VisualHarvesting.attemptHarvest(pid, cellDescription, plant)
    if VisualHarvesting.isReady(plant.uniqueIndex) then
        VisualHarvesting.addIngredientToPlayer(pid, plant.refId)

        tes3mp.ClearObjectList()
        tes3mp.SetObjectListPid(pid)
        tes3mp.SetObjectListCell(cellDescription)

        VisualHarvesting.disablePlant(pid, cellDescription, plant.uniqueIndex)

        tes3mp.SendObjectState(true, false)
    end
end

function VisualHarvesting.updateCell(pid, cellDescription)
    local cell = LoadedCells[cellDescription]
    
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
    
    for uniqueIndex, object in pairs(cell.data.objectData) do
        if VisualHarvesting.data[uniqueIndex] ~= nil then
            local data = VisualHarvesting.data[uniqueIndex]
            if not data.state then
                if VisualHarvesting.getGameTime() - data.harvestTime > VisualHarvesting.config.respawnTime then
                    VisualHarvesting.enablePlant(pid, cellDescription, uniqueIndex)
                else
                    VisualHarvesting.disablePlant(pid, cellDescription, uniqueIndex)
                end
            end
        end
    end
    
    tes3mp.SendObjectState(true, false)
end


function VisualHarvesting.OnObjectActivateValidator(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        if VisualHarvesting.isHarvestable(object.refId) then
            VisualHarvesting.attemptHarvest(pid, cellDescription, object)
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

function VisualHarvesting.OnCellLoadHandler(eventStatus, pid, cellDescription)
    if eventStatus.validCustomHandlers then
        VisualHarvesting.updateCell(pid, cellDescription)
        VisualHarvesting.saveData()
    end
end

function VisualHarvesting.OnServerExit()
    VisualHarvesting.saveData()
end


customEventHooks.registerHandler("OnCellLoad", VisualHarvesting.OnCellLoadHandler)
customEventHooks.registerValidator("OnObjectActivate", VisualHarvesting.OnObjectActivateValidator)
customEventHooks.registerHandler("OnServerExit", VisualHarvesting.OnServerExit)
