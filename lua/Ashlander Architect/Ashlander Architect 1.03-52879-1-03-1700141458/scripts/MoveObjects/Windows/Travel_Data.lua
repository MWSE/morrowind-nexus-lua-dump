local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local async = require("openmw.async")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local acti = require("openmw.interfaces").Activation
local playerSelected
local iconsize = 4
local Actor = require("openmw.types").Actor

local mainWindowSizeX = 480
local mainWindowSizeY = 120

local travelUi = nil
local boldOne = false
local boldTwo = false

local travelData ={}

--Need to recreate the above data. This time, provide the source cell and position. Calculate this by the other NPCs.
--Have to have this data in order to create the reverse connection to the settlement.

local custTravelData = {}
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
        custTravelData = data
    end
end
local function onSave()
    return custTravelData
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
local function addCustDestTwoWay(sourceNpc, targetCellName, targetPos, targetRot,startingPos,startingCell)
   
end
local function getCustomDataID(sourceID)
    for _, item in ipairs(custTravelData) do
        if(item.ID == sourceID) then
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
    return travelData
end
local function getTravelPrice(data,npc)
    local price = core.getGMST("fMagesGuildTravel")
    local disposition = types.NPC.getDisposition(npc,self)
    local player = self
    if self.cell.isExterior then
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
    price = I.ZackUtils.getBarterOffer(npc, price, disposition, true)

    -- Add price for the travelling followers
    local followers = {}
    for i, record in ipairs(nearby.actors) do
        ---  records[string.lower(record.id)] = true
    end
    --need to fix this later
    -- Apply followers cost, unlike vanilla the first follower doesn't travel for free
    price = price * (1 + #followers)

    return ("" .. data.cellName .. "   -   " .. tostring(price) .. core.getGMST("sGp")), price
end
local function getTravelDataForActor(actor)

    if not travelData then
        scrapeNPCs()
    end
    local data = {}
    for index, fdata in ipairs(travelData) do
        if fdata.recordId == actor.recordId then
            for index, dest in ipairs(fdata.destinations) do
                dest.line, dest.price = getTravelPrice(dest,actor)
                table.insert(data, dest)
            end
        end
    end
    return data
end

local function getRequestForActorData(actor)
local data = getTravelDataForActor(actor)

world.players[1]:sendEvent("returnTravelData",data)
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
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
}
