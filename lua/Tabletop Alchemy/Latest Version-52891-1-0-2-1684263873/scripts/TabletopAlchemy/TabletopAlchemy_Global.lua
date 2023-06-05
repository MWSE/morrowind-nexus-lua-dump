local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local AlembicId = nil
local CalcinatorId = nil
local MortarPestleId = nil
local RetortId = nil

local tempAlembic = nil
local tempCalcinator = nil
local tempMortar = nil
local tempRetort = nil
local player = nil
local function ownerCheck(object)
    if (object.ownerRecordId ~= nil) then
        return false
    elseif (object.ownerFactionId ~= nil) then
        return false
    end
    return true
end

local itemsTable = nil
local function sortIntoPlayer()
    local itemsTable = {} -- Table to store the item information

    local allConts = player.cell:getAll(types.Container)
    for x, cont in ipairs(allConts) do
        if (ownerCheck(cont)) then
            local ingreds = types.Container.content(cont):getAll(types.Ingredient)

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

    return itemsTable -- Return the table containing the item information
end
local function returnFromPlayer()
    local allConts = player.cell:getAll(types.Container)

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
                            ingred:split(tcount):moveInto(types.Container.content(cont))
                            break
                        else
                            ingred:moveInto(types.Container.content(cont)) --Move the remainder

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
    for x, appar in ipairs(objectList) do
        if (ownerCheck(appar) == true) then--can't use someone else's set
            local quality = types.Apparatus.record(appar).quality
            local type = types.Apparatus.record(appar).type
            if (quality == originQuality and type == types.Apparatus.TYPE.Alembic) then
                AlembicId = appar.recordId
            end
            if (quality == originQuality and type == types.Apparatus.TYPE.Calcinator) then
                CalcinatorId = appar.recordId
            end
            if (quality == originQuality and type == types.Apparatus.TYPE.MortarPestle) then
                MortarPestleId = appar.recordId
            end
            if (quality == originQuality and type == types.Apparatus.TYPE.Retort) then
                RetortId = appar.recordId
            end
        end
    end

    if (AlembicId == nil or CalcinatorId == nil or MortarPestleId == nil or RetortId == nil) then
        return false
    end
    return true
end
local waitCount = -1
local function onUpdate(dt)
    if (waitCount > -1) then
        waitCount = waitCount + 1
        if (waitCount > 10) then
            returnFromPlayer()
            types.Actor.inventory(player):find(AlembicId):remove(1)
            types.Actor.inventory(player):find(CalcinatorId):remove(1)
            types.Actor.inventory(player):find(MortarPestleId):remove(1)
            types.Actor.inventory(player):find(RetortId):remove(1)
            waitCount = -1
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
local function getInventory(object)
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        print("actor")
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
    print("no?")
end

local function AddItem(itemId,count,actor)
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
    if (ownerCheck(object) == false) then
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
        local holdingCell = world.getCellByName("_AHA_HoldingCell"):getAll()
        waitCount = 0
        -- print(#holdingCell)
        for x, appar in ipairs(holdingCell) do
            local decimalPlaces = 1 -- You can adjust the decimal places as per your requirement

            if (isCloseEnough(types.Apparatus.record(tempAlembic).quality, 1.5) and appar.recordId == "zhac_aha_gm") then
                appar:teleport(player.cell, player.position)
                --  print("tp")
            end
            if (isCloseEnough(types.Apparatus.record(tempAlembic).quality, 1.2) and appar.recordId == "zhac_aha_m") then
                appar:teleport(player.cell, player.position)
            end
            if (isCloseEnough(types.Apparatus.record(tempAlembic).quality, 1.0) and appar.recordId == "zhac_aha_j") then
                appar:teleport(player.cell, player.position)
            end
            if (isCloseEnough(types.Apparatus.record(tempAlembic).quality, 0.5) and appar.recordId == "zhac_aha_a") then
                appar:teleport(player.cell, player.position)
            end
        end
    end
    return false
end
acti.addHandlerForType(types.Apparatus, apparatusActivate)
return {
    interfaceName  = "AtHomeAlchemy",
    interface      = {
        version = 1,
        returnFromPlayer = returnFromPlayer,
    },
    engineHandlers = {
        onUpdate = onUpdate
    },
}
