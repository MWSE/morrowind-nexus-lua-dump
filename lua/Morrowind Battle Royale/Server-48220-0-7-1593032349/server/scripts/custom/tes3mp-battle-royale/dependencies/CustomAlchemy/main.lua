CustomAlchemy = {}

local Formulas = require("custom.CustomAlchemy.formulas")

CustomAlchemy.scriptName = "CustomAlchemy"

CustomAlchemy.initialConfig = require("custom.CustomAlchemy.initialConfig")

CustomAlchemy.config = DataManager.loadConfiguration(
    CustomAlchemy.scriptName,
    CustomAlchemy.initialConfig.default,
    CustomAlchemy.initialConfig.keyOrder
)
tableHelper.fixNumericalKeys(CustomAlchemy.config)


CustomAlchemy.initialData = require("custom.CustomAlchemy.initialData")

CustomAlchemy.uniqueIndexCache = {}

CustomAlchemy.skillId = tes3mp.GetSkillId("Alchemy")


function CustomAlchemy.loadData()
    CustomAlchemy.data = DataManager.loadData(
        CustomAlchemy.scriptName,
        CustomAlchemy.initialData.default,
        CustomAlchemy.initialData.keyOrder
    )
end

function CustomAlchemy.saveData()
    DataManager.saveData(CustomAlchemy.scriptName, CustomAlchemy.data)
end

function CustomAlchemy.importESPs()
    if espParser == nil then
        return
    end

    -- Load esp files if necessary
    local loaded = espParser.isLoaded()
    if not loaded then
        espParser.loadFiles()
    end

    -- Parse ingredients
    for _, record in pairs(espParser.getAllRecords("INGR")) do
        local ingredient = {}
        local refId = ""
        for _, subRecord in pairs(record.subRecords) do
            local data = subRecord.data
            if data ~= nil then
                if subRecord.name == "NAME" then
                    refId = espParser.getValue(data, "s", 1):lower()
                elseif subRecord.name == "IRDT" then
                    local pos = 1
                    ingredient.weight = espParser.getValue(data, "f", pos)
                    pos = pos + 4
                    pos = pos + 4 --skip value
                    ingredient.effects = {}
                    for i = 1, 4 do
                        ingredient.effects[i] = espParser.getValue(data, "i", pos)
                        pos = pos + 4
                    end
                    ingredient.skills = {}
                    for i = 1, 4 do
                        ingredient.skills[i] = espParser.getValue(data, "i", pos)
                        pos = pos + 4
                    end
                    ingredient.attributes = {}
                    for i = 1, 4 do
                        ingredient.attributes[i] = espParser.getValue(data, "i", pos)
                        pos = pos + 4
                    end
                end
            end
        end
        CustomAlchemy.data.ingredients[refId] = ingredient
    end

    -- Parse apparatuses
    for _, record in pairs(espParser.getAllRecords("APPA")) do
        local apparatus = {}
        local refId = ""
        for _, subRecord in pairs(record.subRecords) do
            local data = subRecord.data
            if data ~= nil then
                if subRecord.name == "NAME" then
                    refId = espParser.getValue(data, "s", 1):lower()
                elseif subRecord.name == "AADT" then
                    local pos = 1
                    apparatus.type = espParser.getValue(data, "I", pos)
                    pos = pos + 4
                    apparatus.quality = espParser.getValue(data, "f", pos)
                end
            end
        end
        CustomAlchemy.data.apparatuses[refId] = apparatus
    end
    
    -- Clean after if expected
    if not loaded then
        espParser.unloadFiles()
    end

    -- Save freshly loaded classes
    DataManager.saveData(CustomAlchemy.scriptName, CustomAlchemy.data, CustomAlchemy.initialData.keyOrder)
end


function CustomAlchemy.updatePlayerSpellbook(pid)
    Players[pid]:LoadSpellbook()
end

function CustomAlchemy.sendSpell(pid, id, action)
    tes3mp.ClearSpellbookChanges(pid)
    tes3mp.SetSpellbookChangesAction(pid, action)
    tes3mp.AddSpell(pid, id)
    tes3mp.SendSpellbookChanges(pid)
end


function CustomAlchemy.createAlchemyContainerRecord()
    local recordStore = RecordStores[CustomAlchemy.config.container.type]
    if recordStore.data.permanentRecords[CustomAlchemy.config.container.refId] == nil then
        recordStore.data.permanentRecords[CustomAlchemy.config.container.refId] = {
            baseId = CustomAlchemy.config.container.baseId,
            name = CustomAlchemy.config.container.name
        }
        recordStore:Save()
    end

    if CustomAlchemy.data.recordId == nil or ContainerFramework.getRecordData(CustomAlchemy.data.recordId) == nil then
        CustomAlchemy.data.recordId = ContainerFramework.createRecord(
            CustomAlchemy.config.container.refId,
            CustomAlchemy.config.container.packetType
        )
    end

    CustomAlchemy.saveData()
end

function CustomAlchemy.createContainer(pid)
    local instanceId = ContainerFramework.createContainer(CustomAlchemy.data.recordId)
    CustomAlchemy.data.instances[pid] = instanceId
    CustomAlchemy.data.weight[pid] = 0
end

function CustomAlchemy.getContainerInstanceId(pid)
    return CustomAlchemy.data.instances[pid]
end

function CustomAlchemy.getContainerInventory(pid)
    local instanceId = CustomAlchemy.getContainerInstanceId(pid)
    return ContainerFramework.getInventory(instanceId)
end

function CustomAlchemy.setContainerInventory(pid, inventory)
    local instanceId = CustomAlchemy.getContainerInstanceId(pid)
    ContainerFramework.setInventory(instanceId, inventory)
end

function CustomAlchemy.refreshUI(pid)
    logicHandler.RunConsoleCommandOnPlayer(pid, "togglemenus", false)
    logicHandler.RunConsoleCommandOnPlayer(pid, "togglemenus", false)
end

function CustomAlchemy.updateContainer(pid)
    local instanceId = CustomAlchemy.getContainerInstanceId(pid)
    ContainerFramework.updateInventory(pid, instanceId)
    CustomAlchemy.refreshUI(pid)
    CustomAlchemy.activateContainer(pid)
end

function CustomAlchemy.getContainerWeight(pid)
    return CustomAlchemy.data.weight[pid]
end

function CustomAlchemy.updateContainerWeight(pid)
    local inventory = CustomAlchemy.getContainerInventory(pid)
    local weight = 0
    for _, item in pairs(inventory) do
        if CustomAlchemy.isIngredient(item.refId) then
            weight = weight + CustomAlchemy.data.ingredients[item.refId].weight * item.count
        end
    end

    CustomAlchemy.data.weight[pid] = weight

    return CustomAlchemy.data.weight[pid]
end

function CustomAlchemy.isContainerEmpty(pid)
    return next(CustomAlchemy.getContainerInventory(pid)) == nil
end

function CustomAlchemy.getContainerUniqueIndex(pid)
    if CustomAlchemy.uniqueIndexCache[pid] == nil then
        local instanceId = CustomAlchemy.getContainerInstanceId(pid)
        local instanceData = ContainerFramework.getInstanceData(instanceId)
        local uniqueIndex = instanceData.container.uniqueIndex
        CustomAlchemy.uniqueIndexCache[pid] = uniqueIndex
    end
    return CustomAlchemy.uniqueIndexCache[pid]
end

function CustomAlchemy.emptyContainer(pid)
    local inventory = CustomAlchemy.getContainerInventory(pid)
    local player = Players[pid]

    tes3mp.ClearInventoryChanges(pid)
    tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)

    for _, item in pairs(inventory) do
        inventoryHelper.addItem(player.data.inventory, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)
        tes3mp.AddItemChange(pid, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)
    end

    tes3mp.SendInventoryChanges(pid)

    CustomAlchemy.setContainerInventory(pid, {})

    local splitIndex = CustomAlchemy.getContainerUniqueIndex(pid):split("-")

    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(ContainerFramework.config.storage.cell)
    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectRefId(CustomAlchemy.config.container.refId)
    tes3mp.AddObject()
    tes3mp.SetObjectListAction(enumerations.container.SET)
    tes3mp.SendContainer()

    CustomAlchemy.updateContainerWeight(pid)
    CustomAlchemy.applyContainerBurden(pid)
end

function CustomAlchemy.destroyContainer(pid)
    CustomAlchemy.emptyContainer(pid)
    ContainerFramework.removeContainer(CustomAlchemy.data.instances[pid])
    CustomAlchemy.data.instances[pid] = nil
end

function CustomAlchemy.activateContainer(pid)
    ContainerFramework.activateContainer(pid, CustomAlchemy.getContainerInstanceId(pid))
end

function CustomAlchemy.filterContainerIngredients(pid, objectIndex)
    local nonIngredients = false

    tes3mp.ClearInventoryChanges(pid)
    tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)

    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(ContainerFramework.config.storage.cell)

    local splitIndex = CustomAlchemy.getContainerUniqueIndex(pid):split("-")
    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectRefId(CustomAlchemy.config.container.refId)

    for itemIndex = 0, tes3mp.GetContainerChangesSize(objectIndex) - 1 do
        local item = {
            refId = tes3mp.GetContainerItemRefId(objectIndex, itemIndex),
            count = tes3mp.GetContainerItemCount(objectIndex, itemIndex),
            charge = tes3mp.GetContainerItemCharge(objectIndex, itemIndex),
            enchantmentCharge = tes3mp.GetContainerItemEnchantmentCharge(objectIndex, itemIndex),
            soul = tes3mp.GetContainerItemSoul(objectIndex, itemIndex)
        }

        if not CustomAlchemy.isIngredient(item.refId) then
            nonIngredients = true

            inventoryHelper.addItem(Players[pid].data.inventory, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)
            tes3mp.AddItemChange(pid, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)

            tes3mp.SetContainerItemRefId(item.refId)
            tes3mp.SetContainerItemCount(item.count)
            tes3mp.SetContainerItemCharge(item.charge)
            tes3mp.SetContainerItemEnchantmentCharge(item.enchantmentCharge)
            tes3mp.SetContainerItemSoul(item.soul)

            tes3mp.AddContainerItem()
        end
    end

    tes3mp.AddObject()
    tes3mp.SetObjectListAction(enumerations.container.REMOVE)

    if nonIngredients then
        tes3mp.SendInventoryChanges(pid)

        tes3mp.SendContainer()

        return true
    end

    return false
end


function CustomAlchemy.applyContainerBurden(pid, readd)
    if readd == nil then
        readd = false
    end

    local id = CustomAlchemy.data.burdenId[pid]

    tableHelper.removeValue(Players[pid].data.spellbook, id)
    CustomAlchemy.sendSpell(pid, id, enumerations.spellbook.REMOVE)

    if readd then
        local recordStore = RecordStores["spell"]
        tableHelper.removeValue(Players[pid].generatedRecordsReceived, id)
        tableHelper.cleanNils(Players[pid].generatedRecordsReceived)
        recordStore:LoadGeneratedRecords(pid, recordStore.data.generatedRecords, {id})

        table.insert(Players[pid].data.spellbook, id)
        CustomAlchemy.sendSpell(pid, id, enumerations.spellbook.ADD)
    end

    tableHelper.cleanNils(Players[pid].data.spellbook)
end

function CustomAlchemy.createContainerBurden(pid)
    local recordStore = RecordStores["spell"]
    local id = recordStore:GenerateRecordId()
    CustomAlchemy.data.burdenId[pid] = id

    local recordTable = {
        name = "Weight of ingredients",
        subtype = 2,
        effects = {{
            id = 7,
            attribute = -1,
            skill = -1,
            rangeType = 0,
            area = 0,
            magnitudeMin = 0,
            magnitudeMax = 0
        }}
    }

    recordStore.data.generatedRecords[id] = recordTable

    recordStore:AddLinkToPlayer(id, Players[pid])
    Players[pid]:AddLinkToRecord("spell", id)
    recordStore:Save()
end

function CustomAlchemy.updateContainerBurden(pid)
    local weight = math.ceil(CustomAlchemy.getContainerWeight(pid))

    local recordStore = RecordStores["spell"]
    local id = CustomAlchemy.data.burdenId[pid]

    recordStore.data.generatedRecords[id].effects[1].magnitudeMin = weight
    recordStore.data.generatedRecords[id].effects[1].magnitudeMax = weight

    CustomAlchemy.applyContainerBurden(pid, weight > 0)
end

function CustomAlchemy.destroyContainerBurden(pid)
    CustomAlchemy.applyContainerBurden(pid, false)

    local id = CustomAlchemy.data.burdenId[pid]
    CustomAlchemy.data.burdenId[pid] = nil

    local recordStore = RecordStores["spell"]
    recordStore.data.generatedRecords[id] = nil

    recordStore:RemoveLinkToPlayer(id, Players[pid])
    Players[pid]:RemoveLinkToRecord("spell", id)
    recordStore:Save()
end


function CustomAlchemy.isApparatus(refId)
    return CustomAlchemy.data.apparatuses[refId] ~= nil
end

function CustomAlchemy.isMortar(refId)
    return CustomAlchemy.data.apparatuses[refId] ~= nil and CustomAlchemy.data.apparatuses[refId].type == 1
end

function CustomAlchemy.getApparatus(refId)
    return CustomAlchemy.data.apparatuses[refId]
end

function CustomAlchemy.isIngredient(refId)
    return CustomAlchemy.data.ingredients[refId] ~= nil
end

function CustomAlchemy.determineApparatuses(pid)
    local player_apparatuses = {0, 0, 0}
    player_apparatuses[0] = 0

    local inventory = Players[pid].data.inventory
    for _, item in pairs(inventory) do
        if CustomAlchemy.isApparatus(item.refId) then
            local apparatus = CustomAlchemy.getApparatus(item.refId)
            player_apparatuses[apparatus.type] = math.max(player_apparatuses[apparatus.type], apparatus.quality)
        end
    end
    return player_apparatuses
end

CustomAlchemy.skillEffects = {}
CustomAlchemy.skillEffects[21]=true
CustomAlchemy.skillEffects[26]=true
CustomAlchemy.skillEffects[78]=true
CustomAlchemy.skillEffects[83]=true
CustomAlchemy.skillEffects[89]=true

CustomAlchemy.attributeEffects = {}
CustomAlchemy.attributeEffects[17]=true
CustomAlchemy.attributeEffects[22]=true
CustomAlchemy.attributeEffects[74]=true
CustomAlchemy.attributeEffects[79]=true
CustomAlchemy.attributeEffects[85]=true

function CustomAlchemy.needsCombinedId(id)
    return CustomAlchemy.attributeEffects[id] ~= nil or CustomAlchemy.skillEffects[id] ~= nil
end

function CustomAlchemy.isSkillEffect(id)
    return CustomAlchemy.skillEffects[id]
end

function CustomAlchemy.isAttributeEffect(id)
    return CustomAlchemy.attributeEffects[id]
end

CustomAlchemy.maxEffectId = 256

function CustomAlchemy.makeCombinedId(id, parameter)
    return (parameter + 1) * CustomAlchemy.maxEffectId + id
end

function CustomAlchemy.isCombinedId(id)
    return id >= CustomAlchemy.maxEffectId
end

function CustomAlchemy.parseCombinedId(combinedId)
    local id = combinedId % CustomAlchemy.maxEffectId
    local parameter = math.floor(combinedId / CustomAlchemy.maxEffectId) - 1

    return {
        effectId = id,
        parameter = parameter
    }
end


function CustomAlchemy.failure(pid, label)
    GuiFramework.MessageBox({
        pid = pid,
        name = 'CustomAlchemy_failure',
        label = label
    })
    tes3mp.PlaySpeech(pid, CustomAlchemy.config.fail.sound)
end

function CustomAlchemy.success(pid,count)
    local message = nil
    if count == 1 then
        message = CustomAlchemy.config.success.message1
    else
        message = string.format(CustomAlchemy.config.success.message, count)
    end

    tes3mp.PlaySpeech(pid, CustomAlchemy.config.success.sound)
    GuiFramework.MessageBox({
        pid = pid,
        name = 'CustomAlchemy_success',
        message = message
    })
end

function CustomAlchemy.brewPotions(pid, name)
    local player_apparatuses = CustomAlchemy.determineApparatuses(pid)
    --check if the player has a mortar
    if player_apparatuses[0] == 0 then
        CustomAlchemy.failure(pid, CustomAlchemy.config.fail.messageMortarRequired)
        CustomAlchemy.cancel(pid)
        return
    end

    local containerInventory = CustomAlchemy.getContainerInventory(pid)

    --if there are too many different ingredients (>4 by default), we can't brew a potion
    if #containerInventory <= CustomAlchemy.config.maximumIngredientCount then
        local potion_effects = {} --keeping track of all effects of our ingredients
        local min_ingredient_count = nil --how many potions we can brew
        local potion_ingredients = {} --list of all ingredients we will use

        for _, item in pairs(containerInventory) do
            if min_ingredient_count == nil then
                min_ingredient_count = item.count
            else
                min_ingredient_count = math.min(min_ingredient_count, item.count)
            end

            local ingredient = CustomAlchemy.data.ingredients[item.refId]

            table.insert(potion_ingredients, ingredient)

            if ingredient~=nil then

                for index, id in pairs(ingredient.effects) do
                    if id~=-1 then
                        local effectId = id
                        if CustomAlchemy.isSkillEffect(id) then
                            effectId = CustomAlchemy.makeCombinedId(id, ingredient.skills[index])
                        elseif CustomAlchemy.isAttributeEffect(id) then
                            effectId = CustomAlchemy.makeCombinedId(id, ingredient.attributes[index])
                        end

                        if potion_effects[effectId] == nil then
                            potion_effects[effectId] = 1
                        else
                            potion_effects[effectId] = 1 + potion_effects[effectId]
                        end
                    end
                end

            end
        end

        --removing ingredients that we ended up using
        for _, item in pairs(containerInventory) do
            inventoryHelper.removeItem(
                containerInventory,
                item.refId,
                min_ingredient_count,
                item.charge,
                item.enchantmentCharge,
                item.soul
            )
        end

        --return whatever is left to the player
        CustomAlchemy.emptyContainer(pid)

        local status = Formulas.makeAlchemyStatus(pid, player_apparatuses, potion_ingredients)

        local potion_count = Formulas.getPotionCount(status, min_ingredient_count)

        local recordTable = {
            name = name,
            weight = status.weight,
            icon = status.icon,
            model = status.model,
            value = status.value
        }

        recordTable.effects = {}

        for combinedId, count in pairs(potion_effects) do
            --if there are fewer than necessary (2 by default) ingredients with the same effect, don't add it
            if count >= CustomAlchemy.config.potionEffectTreshold then
                local effectId = 0
                local skill = -1
                local attribute = -1

                if CustomAlchemy.isCombinedId(combinedId) then
                    local parsed = CustomAlchemy.parseCombinedId(combinedId)
                    effectId = parsed.effectId
                    if CustomAlchemy.isSkillEffect(effectId) then
                        skill = parsed.parameter
                    else
                        attribute = parsed.parameter
                    end
                else
                    effectId = combinedId
                end

                local effectData = CustomAlchemy.data.effects[effectId]

                if effectData == nil then
                    effectData = CustomAlchemy.data.effects[tostring(effectId)]
                end

                local magnitude = Formulas.getEffectMagnitude(status, effectData)
                local duration = Formulas.getEffectDuration(status, effectData)

                local effect = {
                    id = effectId,
                    attribute = attribute,
                    skill = skill,
                    rangeType = 0,
                    area = 0,
                    magnitudeMin = magnitude,
                    magnitudeMax = magnitude,
                    duration = duration
                }
                table.insert(recordTable.effects, effect)
            end
        end

        if recordTable.effects[1] ~= nil then

            if potion_count < 1 then
                CustomAlchemy.failure(pid, CustomAlchemy.config.fail.messageAttempt)
                CustomAlchemy.updateContainer(pid)
                return
            end

            local recordStore = RecordStores["potion"]
            local potionId = recordStore:GenerateRecordId()

            recordStore.data.generatedRecords[potionId] = recordTable
            recordStore:AddLinkToPlayer(potionId, Players[pid])
            Players[pid]:AddLinkToRecord("potion", potionId)
            recordStore:Save()

            recordStore:LoadGeneratedRecords(pid, recordStore.data.generatedRecords, {potionId})

            inventoryHelper.addItem(Players[pid].data.inventory, potionId, potion_count, -1, -1, "")

            tes3mp.ClearInventoryChanges(pid)
            tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
            tes3mp.AddItemChange(pid, potionId, potion_count, -1, -1, "")
            tes3mp.SendInventoryChanges(pid)

            CustomAlchemy.success(pid, potion_count)

            CustomAlchemy.updateContainer(pid)

            -- Improve alchemy skill
            if CustomAlchemy.config.progressSkill then
                LevelingFramework.progressSkill(pid, "Alchemy", 2, potion_count)
                Players[pid]:LoadSkills()
                Players[pid]:LoadLevel()
            end
        else

           CustomAlchemy.failure(pid, CustomAlchemy.config.fail.messageUseless)
           CustomAlchemy.setContainerInventory(pid,{})
           CustomAlchemy.updateContainer(pid)
        end
    else
        CustomAlchemy.failure(pid, CustomAlchemy.config.fail.messageTooMany)
        CustomAlchemy.cancel(pid)
        CustomAlchemy.updateContainer(pid)
    end
end

function CustomAlchemy.addIngredient(pid)
    CustomAlchemy.activateContainer(pid)
end

function CustomAlchemy.cancel(pid)
    CustomAlchemy.emptyContainer(pid)
    CustomAlchemy.refreshUI(pid)
end

--UI actions
function CustomAlchemy.showApparatusGUI(pid)
    GuiFramework.CustomMessageBox({
        pid = pid,
        name = "CustomAlchemy_apparatus",
        buttons = CustomAlchemy.config.menu.apparatusButtons,
        returnValues = { "brew", "add", "cancel" },
        callback = CustomAlchemy.processApparatusGUI
    })
end

function CustomAlchemy.processApparatusGUI(pid, name, input, data, parameters)
    if data == "brew" then
        CustomAlchemy.showPotionNameGUI(pid)
    elseif data == "add" then
        CustomAlchemy.addIngredient(pid)
    elseif data == "cancel" then
        CustomAlchemy.cancel(pid)
    end
end


function CustomAlchemy.showPotionNameGUI(pid)
    GuiFramework.InputDialog({
        pid = pid,
        name = "CustomAlchemy_potionName",
        label = CustomAlchemy.config.menu.nameLabel,
        callback = CustomAlchemy.processPotionNameGUI
    })
end

function CustomAlchemy.processPotionNameGUI(pid, name, data, parameters)
    if data~=nil then
        CustomAlchemy.brewPotions(pid, data)
    else
        CustomAlchemy.showPotionNameGUI(pid)
    end
end

--Event hooks
function CustomAlchemy.OnServerPostInit()
    CustomAlchemy.loadData()
    if CustomAlchemy.config.importESPs then
        CustomAlchemy.importESPs()
    end
    CustomAlchemy.createAlchemyContainerRecord()
    if CustomAlchemy.config.disableQuickKeys then
        for refId, _ in pairs(CustomAlchemy.data.apparatuses) do
            QuickKeyCleaner.banItem(refId)
        end
    end
end

function CustomAlchemy.OnServerExit(eventStatus)
    for pid, player in pairs(Players) do
        CustomAlchemy.destroyContainer(pid)
        CustomAlchemy.destroyContainerBurden(pid)
    end
    CustomAlchemy.saveData()
end

function CustomAlchemy.OnPlayerAuthentified(eventStatus, pid)
    if eventStatus.validCustomHandlers then
        CustomAlchemy.createContainer(pid)
        CustomAlchemy.createContainerBurden(pid)
    end
end

function CustomAlchemy.OnPlayerDisconnectValidator(eventStatus, pid)
   CustomAlchemy.destroyContainer(pid)
   CustomAlchemy.destroyContainerBurden(pid)
end

function CustomAlchemy.OnPlayerItemUseValidator(eventStatus, pid, refId)
    if CustomAlchemy.isApparatus(refId) then
        CustomAlchemy.activateContainer(pid)

        if not CustomAlchemy.isContainerEmpty(pid) then
            CustomAlchemy.showApparatusGUI(pid)
        end
        return customEventHooks.makeEventStatus(false, nil)
    end
end

function CustomAlchemy.OnContainerValidator(eventStatus, pid, instanceId, index)
    if not eventStatus.validCustomHandlers then
        return
    end

    if instanceId == CustomAlchemy.getContainerInstanceId(pid) then
        if CustomAlchemy.filterContainerIngredients(pid, index) then
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

function CustomAlchemy.OnContainer(eventStatus, pid, instanceId, index)
    if not eventStatus.validCustomHandlers then
        return
    end

    if instanceId == CustomAlchemy.getContainerInstanceId(pid) then
        CustomAlchemy.updateContainerWeight(pid)
        CustomAlchemy.updateContainerBurden(pid)
    end
end


customEventHooks.registerHandler("OnServerPostInit", CustomAlchemy.OnServerPostInit)
customEventHooks.registerHandler("OnServerExit", CustomAlchemy.OnCellUnloadValidator)
customEventHooks.registerHandler("OnPlayerAuthentified", CustomAlchemy.OnPlayerAuthentified)
customEventHooks.registerValidator("OnPlayerDisconnect", CustomAlchemy.OnPlayerDisconnectValidator)

customEventHooks.registerValidator("OnPlayerItemUse", CustomAlchemy.OnPlayerItemUseValidator)

customEventHooks.registerValidator("ContainerFramework_OnContainer", CustomAlchemy.OnContainerValidator)
customEventHooks.registerHandler("ContainerFramework_OnContainer", CustomAlchemy.OnContainer)

customCommandHooks.registerCommand("caimportesps", function(pid, cmd)
    CustomAlchemy.importESPs()
    tes3mp.SendMessage(pid, "Imported ESPs!")
end)
customCommandHooks.setRankRequirment("caimportesps", CustomAlchemy.config.cmdRank)

return CustomAlchemy