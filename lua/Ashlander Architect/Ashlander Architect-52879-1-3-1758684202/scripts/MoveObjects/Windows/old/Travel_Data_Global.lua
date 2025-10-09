local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local world = require("openmw.world")


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
            data.class = npc.class
            data.destinations = {}
            for index, value in ipairs(travelDa) do
                table.insert(data.destinations, value)
            end
            table.insert(travelData, data)
            print(npc.recordId)
        end
    end
    --end
    return travelData
end
local function getTravelData()
    if not travelData then
        scrapeNPCs()
    end
    return travelData
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
    return data
end
--Need to recreate the above data. This time, provide the source cell and position. Calculate this by the other NPCs.
--Have to have this data in order to create the reverse connection to the settlement.

local function addCustDest(sourceNpc, targetCellName, targetPos, targetRot)
    --need  to add customdest for the NPC, and for the target NPC to return.
    --Here, we will set the
end
return {
    interfaceName = "TravelWindow_Data",
    interface = {
        travelData = travelData,
        getClosest4Dests = getClosest4Dests,
        addCustDest = addCustDest,
        scrapeNPCs = scrapeNPCs,
        getTravelData = getTravelData,
        getTravelDataForActor = getTravelDataForActor,

    }
}
