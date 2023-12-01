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
    print(newData.ID)
    table.insert(custTravelData, newData)
end
local function addCustDestTwoWay(sourceNpc, targetCellName, targetPos, targetRot,startingPos,startingCell)
    print("Setting up travel")
     addCustDest(sourceNpc.id, targetCellName, targetPos, targetRot)--add for the starting direction
    local didFix = false
     for _, item in ipairs(travelData) do
        if(item.myCell == targetCellName) then
            addCustDest(item.ID,startingCell,startingPos,0)
            didFix = true
        end

    end
    if(didFix == false) then
        print("Return direction not created!")
    end
end
local function getCustomDataID(sourceID)
    for _, item in ipairs(custTravelData) do
        if(item.ID == sourceID) then
            return item
        end

    end
return nil
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
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
}
