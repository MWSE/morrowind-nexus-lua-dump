local core = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local AlembicId = nil
local CalcinatorId = nil
local MortarPestleId = nil
local RetortId = nil

local tempAlembic = nil
local tempCalcinator = nil
local tempMortar = nil
local tempRetort = nil
local player = nil
local SettingsTTA = storage.globalSection("SettingsTTAlchemy")
local function ownerCheck(object, skipSetting)
    if SettingsTTA:get("UseOwnedContainers") == true and not skipSetting then
        return true
    end
    if (object.ownerRecordId ~= nil) then
        return false
    elseif (object.ownerFactionId ~= nil) then
        return false
    end
    return true
end

local function getInventory(object)
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
end
local itemsTable = nil
local function sortIntoPlayer()
    local itemsTable = {} -- Table to store the item information

    local allConts = { player.cell:getAll(types.Container) }
    if SettingsTTA:get("UseDeadBodies") == true then
        table.insert(allConts, player.cell:getAll(types.NPC))
        table.insert(allConts, player.cell:getAll(types.Creature))
    end
    if I.CCC_cont and I.CCC_cont.getContainersCarriedByPlayer then
        table.insert(allConts, I.CCC_cont.getContainersCarriedByPlayer())
        if I.CCC_cont.getContainersNearbyPlayer then
            table.insert(allConts, I.CCC_cont.getContainersNearbyPlayer())
        end
    end
    for index, contList in ipairs(allConts) do
        for x, cont in ipairs(contList) do
            local contValid = false
            if cont.type == types.Container and not ownerCheck(cont) then
                contValid = false
            elseif cont.type == types.Container and ownerCheck(cont) then
                contValid = true
            elseif (cont.type == types.Creature or cont.type == types.NPC) and types.Actor.stats.dynamic.health(cont).current == 0 then
                contValid = true
            else
                contValid = false
            end
            if not getInventory(cont):isResolved() then
                contValid = false
            end
            if (contValid) then
                local ingreds = getInventory(cont):getAll(types.Ingredient)

                for i, ingred in ipairs(ingreds) do
                    local recordId = ingred.recordId -- Record ID of the object
                    local count = ingred.count       -- Number of objects
                    local contId = cont.id           -- ID of the container

                    -- Save the item information to the table
                    local item = {
                        recordId = recordId,
                        count = count,
                        containerId = contId
                    }
                    ingred:moveInto(types.Actor.inventory(player))
                    table.insert(itemsTable, item)
                end
            end
        end
    end

    return itemsTable -- Return the table containing the item information
end
local function returnFromPlayer()
    local allConts ={}


    if I.CCC_cont and I.CCC_cont.getContainersCarriedByPlayer then
        for index, value in ipairs(I.CCC_cont.getContainersCarriedByPlayer()) do
            table.insert(allConts, value)
        end

        if I.CCC_cont.getContainersNearbyPlayer then
            for index, value in ipairs(I.CCC_cont.getContainersNearbyPlayer()) do
                table.insert(allConts, value)
            end
        end
    end
    for index, value in ipairs( player.cell:getAll()) do
        table.insert(allConts, value)
    end

    local ingreds = types.Actor.inventory(player):getAll(types.Ingredient)

    for c, ingred in ipairs(ingreds) do
        local recordId = ingred.recordId -- Record ID of the object
        local count = ingred.count       -- Number of objects
        local contId = ""                -- ID of the container


        local returnToContainer = false --this will determine if we need to return this ingredient to a container

        for i, tableItem in ipairs(itemsTable) do
            local trecordId = tableItem.recordId -- Record ID of the object
            local tcount = tableItem.count       -- Number of objects
            local tcontId = tableItem.containerId
            --  print("Trying to move", tcount, trecordId, tcontId)
            if (trecordId == recordId) then
                for x, cont in ipairs(allConts) do
                    if (cont.id == tcontId and ingred.count > 0) then
                        if (tcount < ingred.count) then --if we are moving less than the ingredients in this container
                            ingred:split(tcount):moveInto(cont)
                            break
                        else
                            ingred:moveInto(getInventory(cont)) --Move the remainder

                            break
                        end
                        table.remove(itemsTable, i) -- Remove the table item
                    end
                end
            end
        end
    end
    itemsTable = nil
end

local function checkForApparus(objectList, originObject)
    local originQuality = types.Apparatus.record(originObject).quality
    AlembicId = nil
    CalcinatorId = nil
    MortarPestleId = nil
    RetortId = nil
    local alemQuality = 0
    local calcQuality = 0
    local mortarQuality = 0
    local retoQuality = 0
    for x, appar in ipairs(objectList) do
        if (ownerCheck(appar, true) == true) then --can't use someone else's set
            local quality = types.Apparatus.record(appar).quality
            local type = types.Apparatus.record(appar).type
            if (type == types.Apparatus.TYPE.Alembic and quality > alemQuality) then
                AlembicId = appar.recordId
                alemQuality = quality
            end
            if (type == types.Apparatus.TYPE.Calcinator and quality > calcQuality) then
                CalcinatorId = appar.recordId
                calcQuality = quality
            end
            if (type == types.Apparatus.TYPE.MortarPestle and quality > mortarQuality) then
                MortarPestleId = appar.recordId
                mortarQuality = quality
            end
            if (type == types.Apparatus.TYPE.Retort and quality > retoQuality) then
                RetortId = appar.recordId
                retoQuality = quality
            end
        end
    end

    if (MortarPestleId == nil) then
        return false
    end
    return true
end
local function removeItem(itemId)
    if itemId then
        types.Actor.inventory(player):find(itemId):remove(1)
    end
end
local waitCount = -1
local function onUpdate(dt)
    if (waitCount > -1) then
        waitCount = waitCount + 1
        if (waitCount > 10) then
            returnFromPlayer()
            removeItem(AlembicId)
            removeItem(CalcinatorId)
            removeItem(MortarPestleId)
            removeItem(RetortId)
            waitCount = -1
            world.players[1]:sendEvent("TTA_setControlState", true)
        end
    end
end
local function isCloseEnough(value1, value2, decimalPlaces)
    decimalPlaces = 3
    local factor = 10 ^ decimalPlaces
    local roundedValue1 = math.floor(value1 * factor + 0.5) / factor
    local roundedValue2 = math.floor(value2 * factor + 0.5) / factor
    return roundedValue1 == roundedValue2
end

local function AddItem(itemId, count, actor)
    if not itemId then return nil end
    local item = world.createObject(itemId, count)

    local inv = getInventory(actor)
    item:moveInto(types.Actor.inventory(actor))
    return item
end
local function apparatusActivate(object, actor)
    player = actor
    if (core.isWorldPaused() == true) then
        --let the user pick up the apparatus if in their inventory. This is pointless right now since it's not called in that case, but this future proofs things.
        return true
    end
    if (ownerCheck(object, true) == false) then
        --can't cook with someone else's apparatus.
        return true
    end
    local allApparatus = object.cell:getAll(types.Apparatus)
    local valid = checkForApparus(allApparatus, object)
    --print(valid)
    if (valid) then
        tempAlembic = AddItem(AlembicId, 1, player)
        tempCalcinator = AddItem(CalcinatorId, 1, player)
        tempMortar = AddItem(MortarPestleId, 1, player)
        tempRetort = AddItem(RetortId, 1, player)
        itemsTable = sortIntoPlayer()
        waitCount = 0
        world.players[1]:sendEvent("TTA_setControlState", false)
    else
        world.players[1]:sendEvent("TTA_ShowMessage", "You are missing an apparatus")
    end
    return false
end
local function TabletopAlchemyUpdateSetting(data) SettingsTTA:set(data.key, data.value) end
acti.addHandlerForType(types.Apparatus, apparatusActivate)
return {
    interfaceName  = "AtHomeAlchemy",
    interface      = {
        version = 1.2,
        returnFromPlayer = returnFromPlayer,
    },
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers  = {
        TabletopAlchemyUpdateSetting = TabletopAlchemyUpdateSetting
    }
}
