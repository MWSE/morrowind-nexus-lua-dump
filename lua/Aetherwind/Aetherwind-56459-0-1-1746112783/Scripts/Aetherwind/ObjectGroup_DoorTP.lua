---
---This will detect the door markers, find a nearby teleport door, find the teleport door on the otherside, and link up with it.
---
---
---
---
---
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation

local doorLinks = {}
local markerToDoorMap = {
    aeth_sc_exitmarker_cabinl = "aeth_door_impgalleon01_r",
    aeth_sc_exitmarker_cabinr = "aeth_door_impgalleon01_l",

    aeth_sc_exitmarker_dockr = "aeth_door_impgalleon01_r_dock",
    aeth_sc_exitmarker_dockl = "aeth_door_impgalleon01_l_dock",

    aeth_sc_exitmarker_cabinm = "aeth_door_impgalleon01_m",
    aeth_sc_exitmarker_main = "aeth_door_impgalleon02_in",
    aeth_sw_exitmarker = "aeth_sw_exitdoor"
}


local markerToCellMap = {
    aeth_sc_exitmarker_cabinl = "Stormwrack, Cabin",
    aeth_sc_exitmarker_cabinr = "Stormwrack, Cabin",
    aeth_sc_exitmarker_cabinm = "Stormwrack, Cabin",

    aeth_sc_exitmarker_dockr = "Stormwrack",
    aeth_sc_exitmarker_dockl = "Stormwrack",

    aeth_sc_exitmarker_main = "Stormwrack",
    aeth_sw_exitmarker = "Skyforge"
}
local function getClosestDoor(pos, list)
    local closestDoor = nil
    local closestDistance = math.huge

    for _, ref in ipairs(list) do
        if ref.type == types.Door then
            local distance = (ref.position - pos):length()

            if distance < closestDistance then
                closestDistance = distance
                closestDoor = ref
            end
        end
    end

    if closestDoor then
      --  print("Closest door: " .. (closestDoor.recordId or "unknown"))
    else
        print("No door found in list.")
    end

    return closestDoor
end
local function getintDoor(marker,cellList)
    for i, x in ipairs(cellList) do
        if markerToDoorMap[marker.recordId] == x.recordId then
            return x
        end
    end
end
local function findDoorLink(extMarker,obList)
  --  local extDoor = getClosestDoor(extMarker.position,obList)
    local DestCell = world.getCellById( markerToCellMap[extMarker.recordId])

    local intDoor = getintDoor(extMarker,DestCell:getAll(types.Door))
    if not intDoor then
        print("No interior door! " ..extMarker.recordId, DestCell.id)
    else

    doorLinks[intDoor.recordId] = extMarker
    end
end
local function InsideDoorActivate(object, actor)
    print("doorClick")
    if doorLinks[object.recordId] then
        actor:sendEvent("PlaySound_AO",types.Door.records[object.recordId].openSound)
        for i,x in ipairs(actor.cell:getAll(types.NPC)) do
            x:sendEvent("GroupfollowerTeleport",{player = actor, destPos =doorLinks[object.recordId].position, destCell = doorLinks[object.recordId].cell.id })
        end
        for i,x in ipairs(actor.cell:getAll(types.Creature)) do
            x:sendEvent("GroupfollowerTeleport",{player = actor, destPos =doorLinks[object.recordId].position, destCell = doorLinks[object.recordId].cell.id })
        end
        world.players[1]:teleport(doorLinks[object.recordId].cell,doorLinks[object.recordId].position, { rotation = doorLinks[object.recordId].rotation, onGround = true })
    end
end
local function GroupFollowerTeleport(data)
    data.actor:teleport(world.getCellById(data.destCell),data.destPos)
end
acti.addHandlerForType(types.Door, InsideDoorActivate)
return {

    interfaceName = "ObjectGroup_DoorTP",
    interface = {
        findDoorLink = findDoorLink,
        getClosestDoor = getClosestDoor
    },
    eventHandlers = {GroupFollowerTeleport = GroupFollowerTeleport},
    engineHandlers = {
        onSave = function ()
            return {doorLinks = doorLinks,}
        end,
        onLoad = function (data)
            if data.doorLinks then
                doorLinks = data.doorLinks
            end
        end
    }
}
