local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local util = require("openmw.util")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local core = require("openmw.core")

-- Here, we will keep track of all the items that relate to containers.

-- When a container misc item is activated, the real container will be moved in, and activated.

---
-- Once it is closed(game is unpaused), we check if the weight is correct.

local obScr = "nolore"
local playerSneaking = false
local extractGold = true
local UseBaseWeight = true
---
if (core.API_REVISION < 51) then
    error("Corporeal Carryable Containers requires a newer version of OpenMW. Please update.")
end
-- Should be compatible with tabletop alchemy.
local function updateUBW(val) UseBaseWeight = val end
local function updateExtractGold(val) extractGold = val end
local ccc_conttypes = nil
local ccc_data = {}

local function addContainerCollection(actor)
    local inv = types.Actor.inventory(actor)
    for index, value in ipairs(ccc_conttypes) do
        I.CCC_cont.createContItemInstance(value.itemRecId, inv)
    end
end
local function getPlayer()
    for i, ref in ipairs(world.activeActors) do
        if (ref.type == types.Player) then return ref end
    end
end
local itemInstanceLast = 1000
local function moveGlobalSetter(zval, player)

end
local function onItemActive(item)
    -- When items are dropped, their ID is changed since the item is cloned when dropped via gui.
    -- So, we must check the items and update the item table.

    -- We can't set a unique ID, so the best thing may be to have a unique value int on each individual container item.
end

local function createContItemInstance(baseRecordId, targetInv)
    local newContId = nil
    for index, value in ipairs(ccc_conttypes) do
        if (value.itemRecId == baseRecordId) then
            newContId = value.contRecId
        end
    end
    if (newContId == nil) then
        error("Error, container ID not found")
        return
    end
    local baseRecord = types.Miscellaneous.record(baseRecordId)
    local miscitem = {
        name = baseRecord.name,
        weight = baseRecord.weight,
        value = itemInstanceLast,
        icon = baseRecord.icon,
        model = baseRecord.model,
        mwscript = obScr
    }
    local ret = types.Miscellaneous.createRecordDraft(miscitem)
    local record = world.createRecord(ret)

    async:newUnsavableSimulationTimer(0.1, function()
        local newItem = world.createObject(record.id)
        local newCont = world.createObject(newContId)
        async:newUnsavableSimulationTimer(0.1, function()
            newCont:teleport("ToddTest", util.vector3(0, 0, 0))
            newItem:moveInto(targetInv)
            async:newUnsavableSimulationTimer(0.1, function()
                I.CCC_cont.updateCCCData(newItem, newCont, targetInv)
            end)
        end)
    end)
    itemInstanceLast = itemInstanceLast + 1
end
local function createContItemInstanceEvent(data)
    createContItemInstance(data.baseRecordId, data.targetInv)
end
local function addContType(contModel, contIcon, contName, contBaseWeight,
                           contRecId)
    -- contRecId is the record ID of the actual contaner we'll use
    if (UseBaseWeight == false) then contBaseWeight = 0 end
    local newRecord
    local itemRecordId = nil
    for index, rec in ipairs(types.Miscellaneous.records) do
        if (rec.weight == contBaseWeight and rec.name == contName and
                rec.model:lower() == contModel:lower() and rec.icon:lower() ==
                contIcon:lower()) then
            newRecord = rec
            itemRecordId = rec.id
            break
        else
        end
    end
    if (newRecord == nil) then -- Didn't find a record that matches all the criteria, need to make a new one.
        local miscitem = {
            name = contName,
            weight = contBaseWeight,
            value = 1000,
            icon = contIcon,
            model = contModel,
            mwscript = obScr
        }
        local ret = types.Miscellaneous.createRecordDraft(miscitem)
        local record = world.createRecord(ret)
        itemRecordId = record.id
    end
    local tableItem = {
        model = contModel,
        icon = contIcon,
        baseName = contName,
        baseWeight = contBaseWeight,
        contRecId = contRecId,
        itemRecId = itemRecordId
    }
    table.insert(ccc_conttypes, tableItem)
end

local function addContTypes()
    -- if (ccc_conttypes == {} or ccc_conttypes == nil) then
    ccc_conttypes = {}
    addContType("meshes\\o\\Contain_chest_small_02.NIF", "icons\\ccc\\chest_small.tga",
        "Small Chest", 1, "chest_small_02")
    addContType("meshes\\o\\Contain_De_Chest_01.NIF", "icons\\ccc\\chest_big.tga",
        "Large Chest", 5, "de_r_chest_01")
    addContType("meshes\\o\\Contain_crate_02.NIF", "icons\\ccc\\crate.png", "Crate", 5,
        "crate_02")
    addContType("meshes\\o\\Contain_Com_Sack_02.NIF", "icons\\ccc\\sack02.tga", "Sack", 0,
        "com_sack_02")
    if core.contentFiles.has("oaab_data.esm") then
        addContType("meshes\\OAAB\\m\\misc_keyring.nif", "icons\\oaab\\m\\misc_keyring.tga", "Keyring", 0,
            "chest_small_02")
    end
    --  end
end

local weightMultiplier = 1

local function calculateWeight(containerOb)
    -- Will include an object's base weight here in the future.
    local baseWeight = 0
    if (UseBaseWeight) then
        for index, value in ipairs(ccc_conttypes) do
            if (value.contRecId == containerOb.recordId) then
                baseWeight = value.baseWeight
            end
        end
    end
    return math.ceil((types.Container.encumbrance(containerOb) + baseWeight) *
        weightMultiplier)
end
local function updateCCCData(itemOb, containerOb, parentInv, newName)
    -- This function replaces a record with one with the correct weight, and saves that data to the CCCData table.
    -- ContainerOb is the container that is actually accessed. ParentOb is the container that itemOb is contained in, if it's in a container.
    -- If we are renaming, then update name as well with newName
    local parentCont = itemOb.parentContainer
    if parentCont then
        parentInv = types.Actor.inventory(parentCont)
    end
    local name = types.Miscellaneous.record(itemOb).name
    if (newName ~= nil) then name = newName end
    local oldRecord = types.Miscellaneous.record(itemOb)
    local newData = {
        containerId = containerOb.id,
        itemId = itemOb.id,
        value = oldRecord.value,
        icon = oldRecord.icon
    }
    local weight = calculateWeight(containerOb)
    local newRecord = nil
    if (oldRecord.weight == weight and oldRecord.name == name) then
        newRecord = oldRecord
    else -- Need to replace with a new record
        for index, rec in ipairs(types.Miscellaneous.records) do
            if (rec.weight == weight and rec.name == name and
                    rec.model == oldRecord.model and
                    rec.icon == oldRecord.icon and rec.value == oldRecord.value) then
                newRecord = rec
                break
            end
        end
        if (newRecord == nil) then -- Didn't find a record that matches all the criteria, need to make a new one.
            local miscitem = {
                name = name,
                weight = weight,
                value = oldRecord.value,
                icon = oldRecord.icon,
                model = oldRecord.model,
                mwscript = obScr
            }
            local ret = types.Miscellaneous.createRecordDraft(miscitem)
            newRecord = world.createRecord(ret)
        end
    end
    if (newRecord ~= oldRecord and parentInv == nil) then
        local newItem = world.createObject(newRecord.id)
        newItem:teleport(itemOb.cell, itemOb.position, itemOb.rotation)
        if itemOb.count > 0 then
            itemOb:remove()
        end
    elseif (newRecord ~= oldRecord and parentInv ~= nil) then
        local newItem = world.createObject(newRecord.id)
        newItem:moveInto(parentInv)
        --   if itemOb.count > 0 then
        itemOb:remove()

        --end
    end
    for index, data in ipairs(ccc_data) do
        if (data.containerId == newData.containerId) then
            table.remove(ccc_data, index)
            break
        end
    end
    table.insert(ccc_data, newData)
end

local function getContainersNearbyPlayer()
    local player = getPlayer()
    local carriedIds = {}
    for index, item in ipairs(player.cell:getAll(types.Miscellaneous)) do
        for i, dataItem in ipairs(ccc_data) do
            if item.type.record(item).icon == dataItem.icon and
                item.type.record(item).value == dataItem.value then
                table.insert(carriedIds, dataItem.containerId)
            end
        end
    end

    if (#carriedIds == 0) then return {} end
    local ret = {}
    local ttItems = world.getCellByName("ToddTest"):getAll(types.Container)
    for index, cont in ipairs(ttItems) do
        for indx, contId in ipairs(carriedIds) do
            if (contId == cont.id) then table.insert(ret, cont) end
        end
    end
    return ret
end
local function getContainersCarriedByPlayer()
    local carriedIds = {}
    for i, dataItem in ipairs(ccc_data) do
        local playInv = types.Actor.inventory(getPlayer()):getAll(
            types.Miscellaneous)
        for index, item in ipairs(playInv) do
            if item.type.record(item).icon == dataItem.icon and
                item.type.record(item).value == dataItem.value then
                table.insert(carriedIds, dataItem.containerId)
            end
        end
    end
    if (#carriedIds == 0) then return {} end
    local ret = {}
    local ttItems = world.getCellByName("ToddTest"):getAll(types.Container)
    for index, cont in ipairs(ttItems) do
        for indx, contId in ipairs(carriedIds) do
            if (contId == cont.id) then table.insert(ret, cont) end
        end
    end
    return ret
end
local goldMovementData = {}
local function MoveGoldToPlayer()
    goldMovementData = {}
    for index, value in ipairs(getContainersCarriedByPlayer()) do
        local goldItem = types.Container.content(value):find("gold_001")
        if goldItem then
            table.insert(goldMovementData,
                { count = goldItem.count, id = value.id })
            goldItem:moveInto(types.Actor.inventory(getPlayer()))
        end
    end
end
local function MoveGoldBack()
    for index, data in ipairs(goldMovementData) do
        local ttItems = world.getCellByName("ToddTest"):getAll(types.Container)
        for index, cont in ipairs(ttItems) do
            if (cont.id == data.id) then
                local playerGold = types.Actor.inventory(getPlayer()):find(
                    "gold_001")
                if (playerGold and data.count) then
                    if (playerGold.count > data.count) then
                        playerGold:split(data.count):moveInto(types.Container
                            .content(cont))
                    else
                        playerGold:moveInto(types.Container.content(cont))
                    end
                end
            end
        end
    end
end
local function itemCarriedByPlayer(itemId, ignoreOwnInv)
    if (types.Actor.inventory(getPlayer()):find(itemId)) then return true end
    for index, value in ipairs(getContainersCarriedByPlayer()) do
        if (types.Container.content(value):find(itemId)) then return true end
    end
    return false
end
local function onSave()
    return {
        ccc_data = ccc_data,
        itemInstanceLast = itemInstanceLast,
        UseBaseWeight = UseBaseWeight,
        extractGold = extractGold
    }
end
local function onLoad(data)
    if not data then return end
    ccc_data = data.ccc_data
    UseBaseWeight = data.UseBaseWeight
    itemInstanceLast = data.itemInstanceLast
    extractGold = data.extractGold
    if world.players[1] and not ccc_conttypes then
        addContTypes()
    end
end
local function onPlayerAdded(plr)
    addContTypes()
end

local activatedContainer = nil
local activatedItem = nil
local needToActivate = false
local player = nil
local openingCont = nil
local function openContinInv(data)
    local contVal = data.value
    player = getPlayer()
    local bridgeItem = data.bridgeItem
    local realItem = nil
    bridgeItem:remove()

    for index, dataItem in ipairs(ccc_data) do
        if (dataItem.value == contVal) then
            for k, item in ipairs(types.Actor.inventory(player):getAll(
                types.Miscellaneous)) do
                if item.type.record(item).icon == dataItem.icon and
                    item.type.record(item).value == contVal then
                    realItem = item
                end
            end
            if (realItem == nil) then
                print("Item not found")
                return false
            end
            -- Then this is a CCC container object, activate it and do the thing
            local ttItems = world.getCellByName("ToddTest"):getAll(
                types.Container)

            for index, value in ipairs(ttItems) do
                if (value.id == dataItem.containerId) then
                    activatedContainer = value
                    activatedItem = realItem
                    openingCont = types.Actor.inventory(player)
                    break
                end
            end

            return false
        end
    end
end
local function activateMisc(object, actor)
    for index, dataItem in ipairs(ccc_data) do
        if (dataItem.value == object.type.record(object).value and dataItem.icon ==
                object.type.record(object).icon) then
            -- Then this is a CCC container object, activate it and do the thing
            if (playerSneaking) then
                actor:sendEvent("CCCstartRename", {
                    object = object,
                    data = dataItem,
                    currentName = types.Miscellaneous.record(object).name
                })
                return false
            end
            local ttItems = world.getCellByName("ToddTest"):getAll(
                types.Container)

            for index, value in ipairs(ttItems) do
                if (value.id == dataItem.containerId) then
                    player = actor
                    world.players[1]:sendEvent("openContainerInv", value)
                    -- value:teleport(actor.cell, util.vector3(actor.position.x, actor.position.y, -9000))
                    activatedContainer = value
                    activatedItem = object
                    return false
                end
            end

            return false
        end
    end
end
local function updateClosedCont()
    if not activatedItem then return end

    if activatedItem.parentContainer and activatedItem.parentContainer ~= getPlayer() then
        activatedItem:moveInto(getPlayer())
    end
    updateCCCData(activatedItem, activatedContainer)
end
local delay = 0
local activatingActor = nil
local function onUpdate(dt)
    if activatingActor ~= nil and delay > 10 then
        MoveGoldBack()
        activatingActor = nil
    elseif delay > 0 then
        delay = delay + 1
    end
end
local function activateLockable(door, player)
    if types.Lockable.isLocked(door) or types.Lockable.getTrapSpell(door) then
        local key = types.Lockable.getKeyRecord(door)
        if key and itemCarriedByPlayer(key.id) then
            if types.Lockable.getTrapSpell(door) then
                player:sendEvent("CCC_PlaySound", "Disarm Trap")
            end
            types.Lockable.setTrapSpell(door)
            types.Lockable.unlock(door)
            player:sendEvent("CCC_Message", key.name .. " " .. core.getGMST("sKeyUsed"))
        end
    end
end
local function activateActor(npc, player)
    if (types.Actor.stats.dynamic.health(npc).current > 0 and extractGold) then
        activatingActor = npc
        MoveGoldToPlayer()
        delay = 1
    end
end
acti.addHandlerForType(types.Miscellaneous, activateMisc)
acti.addHandlerForType(types.NPC, activateActor)
acti.addHandlerForType(types.Creature, activateActor)
acti.addHandlerForType(types.Door, activateLockable)
acti.addHandlerForType(types.Container, activateLockable)
I.ItemUsage.addHandlerForType(types.Miscellaneous, activateMisc)

local function onInit()
    -- crate
    -- com chest
    -- rich chest
    -- basket
end
local function getTypes() return ccc_conttypes end
local function renameContainer(data)
    local newName = data.newName
    local newCont = nil
    local val = 0
    local object = data.object
    for index, data in ipairs(ccc_data) do
        if (data.value == types.Miscellaneous.record(object).value and
                types.Miscellaneous.record(object).icon == data.icon) then
            for x, cont in ipairs(world.getCellByName("ToddTest"):getAll(
                types.Container)) do
                if (cont.id == data.containerId) then
                    newCont = cont
                    val = data.value
                    break
                end
            end
            break
        end
    end
    if (newCont ~= nil) then
        updateCCCData(object, newCont, types.Actor.inventory(getPlayer()),
            newName)
    end
end
local function emergencyItemExtraction()
    local ttItems = world.getCellByName("ToddTest"):getAll(types.Container)
    local player = getPlayer()
    local count = 0
    for index, cont in ipairs(ttItems) do
        if not cont.contentFile then
            for k, item in ipairs(types.Container.inventory(cont):getAll()) do
                count = count + item.count
                item:moveInto(player)
            end
        end
    end

    player:sendEvent("CCC_Message", tostring(count) .. " item extracted from containers")
end
local function CCCSneakUpdate(val) playerSneaking = val end
return {
    interfaceName = "CCC_cont",
    interface = {
        version = 1,
        updateCCCData = updateCCCData,
        calculateWeight = calculateWeight,
        createContItemInstance = createContItemInstance,
        getTypes = getTypes,
        moveGlobalSetter = moveGlobalSetter,
        itemCarriedByPlayer = itemCarriedByPlayer,
        getContainersCarriedByPlayer = getContainersCarriedByPlayer,
        getContainersNearbyPlayer = getContainersNearbyPlayer,
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
        onItemActive = onItemActive,
        onUpdate = onUpdate,
        onPlayerAdded = onPlayerAdded
    },
    eventHandlers = {
        renameContainer = renameContainer,
        openContinInv = openContinInv,
        CCCSneakUpdate = CCCSneakUpdate,
        addContainerCollection = addContainerCollection,
        updateUBW = updateUBW,
        updateExtractGold = updateExtractGold,
        emergencyItemExtraction = emergencyItemExtraction,
        updateClosedCont = updateClosedCont
    }
}
