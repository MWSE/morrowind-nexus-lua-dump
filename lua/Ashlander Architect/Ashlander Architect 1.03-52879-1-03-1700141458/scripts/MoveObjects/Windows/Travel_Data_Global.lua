local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local world = require("openmw.world")

local travelData = {}

--Need to recreate the above data. This time, provide the source cell and position. Calculate this by the other NPCs.
--Have to have this data in order to create the reverse connection to the settlement.

local custTravelData = {}
local custDestinations = {}
local function findDestNPCIds()
    --this function finds every cell listed as a destination in the above data, and matches an NPC to that destination, by checking every NPC in that cell and checking the class and ID on them.
end
local function getAvailableDestinations(sourceNPC)
    --Need to find all the available destintions. If the NPC is a boat, find the boat travel destinations.
    --If Inside, it is a mage travel marker, so no range is specified. Otherwise, there is a maximum range.

    local class = types.NPC.record(sourceNPC).class
    local isExterior = sourceNPC.cell.isExterior

    if (isExterior) then

    else --is interior, so need to only look for Guild Guides.

    end
end
local function onLoad(data)
    if (data ~= nil) then
        custTravelData = data.custTravelData
        custDestinations = data.custDestinations
    end
end
local function onSave()
    return { custTravelData = custTravelData, custDestinations = custDestinations }
end
local function resetCustData()
    custTravelData = {}
end
local function addCustDest(sourceNpc, targetCellName, targetPos, targetRot)
    --need  to add customdest for the NPC, and for the target NPC to return.
    --Here, we will set the
    local newData = { ID = sourceNpc, targetCellName = targetCellName, targetPos = targetPos, targetRot = targetRot }
    table.insert(custTravelData, newData)
end
local function addCustDestTwoWay(sourceNpc, targetCellName, targetPos, targetRot, startingPos, startingCell)

end
local function getCustomDataID(sourceID)
    for _, item in ipairs(custTravelData) do
        if (item.ID == sourceID) then
            return item
        end
    end
    return nil
end


local travelData
local function scrapeNPCs()
    travelData = {}
    --for index, cell in ipairs(world.cells) do
    for index, npc in ipairs(types.NPC.records) do
        local travelDa = npc.servicesOffered["Travel"]
        if travelDa then
            local data = {}
            -- data.sourcePos = npc.position
            ---data.sourceCell = npc.cell.name
            --data.sourceRot = npc.rotation.z
            data.recordId = npc.id
            data.destinations = {}
            data.class = npc.class
            for index, value in ipairs(travelDa) do
                table.insert(data.destinations, value)
            end
            table.insert(travelData, data)
        end
    end
    --end
    return travelData
end
local function getTravelData()
    if not travelData or #travelData == 0 then
        scrapeNPCs()
    end
    return travelData
end
local function getTravelPrice(data, npc)
    local price = core.getGMST("fMagesGuildTravel")
    local disposition = types.NPC.getDisposition(npc, world.players[1])
    local player = world.players[1]
    if world.players[1].cell.isExterior then
        local cell = I.ZackUtilsAA.getCellByPos(data.position)
        data.cellName = cell.name
        local Tarpos = data.position
        local playerPos = player.position
        local d = math.sqrt(math.pow(Tarpos.x - playerPos.x, 2) + math.pow(Tarpos.y - playerPos.y, 2)
            + math.pow(Tarpos.z - playerPos.z, 2))
        local fTravelMult = core.getGMST("fTravelMult")
        if fTravelMult ~= 0 then
            price = math.floor(d / fTravelMult)
        else
            price = math.floor(d)
        end
    end

    price = math.max(1, price)
    price = I.ZackUtilsAA.getBarterOffer(npc, price, disposition, true)

    -- Add price for the travelling followers
    local followers = {}
    for i, record in ipairs(world.activeActors) do
        ---  records[string.lower(record.id)] = true
    end
    --need to fix this later
    -- Apply followers cost, unlike vanilla the first follower doesn't travel for free
    price = price * (1 + #followers)
    local label = data.cell.name
    if data.label ~= nil then
        label = data.label
    end
    return ("" .. label .. "   -   " .. tostring(price) .. core.getGMST("sGp")), price
end
local function getClosest4Dests(actor)
    print("gc4")
    local data = getTravelData()
    local myPos = actor.position -- assuming actor.position is a vector3
    local actorRecord = actor.type.record(actor)
    local validDests = {}

    -- Filter valid destinations based on class and cellName
    for _, npcData in ipairs(data) do
        if npcData.class == actorRecord.class then
            for _, dest in ipairs(npcData.destinations) do
                local cellCheck = world.getCellByName(dest.cellName)
                if cellCheck then

                end
                if dest.cellName == "" then
                    cellCheck = I.ZackUtilsAA.getCellByPos(dest.position)
                end
                if dest.cellName and not validDests[cellCheck.name] and cellCheck.name ~= actor.cell.name and cellCheck.isExterior == actor.cell.isExterior then
                    validDests[cellCheck.name] = dest
                    print(dest.cellName)
                    dest.cellName = cellCheck.name
                end
            end
        end
    end

    -- Calculate distances and sort destinations
    local sortedDests = {}
    for _, dest in pairs(validDests) do
        local destPos = util.vector3(dest.position.x, dest.position.y, dest.position.z)
        local distance = (destPos - myPos):length() -- assuming vector3 supports length() function

        table.insert(sortedDests, { dest = dest, distance = distance })
    end

    table.sort(sortedDests, function(a, b) return a.distance < b.distance end)

    -- Get the 4 closest destinations
    local closest4Dests = {}
    for i = 1, math.min(#sortedDests, 4) do
        table.insert(closest4Dests, sortedDests[i].dest)
        print(sortedDests[i].dest.cellName)
    end

    return closest4Dests
end
local function getTravelDataForActor(actor)
    if not travelData then
        scrapeNPCs()
    end
    local data = {}
    for index, fdata in ipairs(travelData) do
        if fdata.recordId == actor.recordId then
            for index, dest in ipairs(fdata.destinations) do
                table.insert(data, dest)
            end
        end
    end
    if types.NPC.getFactions(actor) and types.NPC.getFactions(actor)[1] and not custTravelData[actor.id] then
        local faction = types.NPC.getFactions(actor)[1]
        if faction == "zhac_settlement" then
            data = getClosest4Dests(actor)
            custTravelData[actor.id] = data
            for index, value in ipairs(data) do
                custDestinations[value.cellName] = {
                    cellName = world.players[1].cell.name,
                    position = util.vector3(world.players[1]
                        .position.x, world.players[1]
                        .position.y, world.players[1]
                        .position.z + 100),
                    rotation = world.players[1].rotation,
                    label = I.AA_Settlements.getCurrentSettlementName(actor)
                }
            end
        end
    end
    if custTravelData[actor.id] then
        data = custTravelData[actor.id]
    end
    if custDestinations[actor.cell.name] then
        table.insert(data, custDestinations[actor.cell.name])
    end
    for index, dest in ipairs(data) do
        data[index].line, data[index].price = getTravelPrice(dest, actor)
    end
    return data
end
local function getRequestForActorData(actor)
    local data = getTravelDataForActor(actor)

    world.players[1]:sendEvent("returnTravelData", data)
end
return {
    interfaceName = "TravelWindow_Data",
    interface = {
        travelData = travelData,
        addCustDest = addCustDest,
        custTravelData = custTravelData,
        resetCustData = resetCustData,
        getCustomDataID = getCustomDataID,
        addCustDestTwoWay = addCustDestTwoWay,
        getTravelDataForActor = getTravelDataForActor,
        getClosest4Dests = getClosest4Dests,
        getTravelData = getTravelData,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        getRequestForActorData = getRequestForActorData
    }
}
