local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation
local shipObjectIds = {
    ["ab_ex_impgalleonfullunfurled"] = "ab_ex_impgalleonfullunfurled",
    ["ex_de_ship"] = "ex_de_ship",
    ["ab_ex_impgalleonfullfurled"] = "ab_ex_impgalleonfullfurled",
    ["aeth_dship_x"] = "aeth_dship_x",
    ["ex_longboat"] = "ex_longboat",
    ["ab_ex_deshipsmall"] = "ab_ex_deshipsmall",
    ["aeth_silvercascade_ship"] = "aeth_silvercascade_ship",
    ["aeth_airship3"] = "aeth_airship3"
}

local doorActivateMap = {
    aeth_door_impgalleon01_r = "aeth_sc_exitmarker_cabinl",
    aeth_door_impgalleon01_l = "aeth_sc_exitmarker_cabinr",

    aeth_door_impgalleon01_r_dock = "aeth_sc_exitmarker_dockr",
    aeth_door_impgalleon01_l_dock = "aeth_sc_exitmarker_dockl",

    aeth_door_impgalleon01_m = "aeth_sc_exitmarker_cabinm",
    aeth_door_impgalleon02_in = "aeth_sc_exitmarker_main",
    aeth_sw_exitdoor = "aeth_sw_exitmarker"

}

local markerToDoorMap = {
    aeth_sc_exitmarker_cabinl = "aeth_door_impgalleon01_r",
    aeth_sc_exitmarker_cabinr = "aeth_door_impgalleon01_l",

    aeth_sc_exitmarker_dockr = "aeth_door_impgalleon01_r_dock",
    aeth_sc_exitmarker_dockl = "aeth_door_impgalleon01_l_dock",

    aeth_sc_exitmarker_cabinm = "aeth_door_impgalleon01_m",
    aeth_sc_exitmarker_main = "aeth_door_impgalleon02_in",
    aeth_sw_exitmarker = "aeth_sw_exitdoor"
}
local function distanceBetweenPos(vector1, vector2)
    -- Quick way to find out the distance between two vectors.
    -- Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function objectWhiteListed(shipId, object)
    if object.type == types.Door or object.type == types.Container or
        object.type == types.Activator or object.type.baseType == types.Item then
        if (I.Aeth_ShipManage.getShipData() and I.Aeth_ShipManage.getShipData()[shipId] and I.Aeth_ShipManage.getShipData()[shipId].ladders) then
            for _, ladder in pairs(I.Aeth_ShipManage.getShipData()[shipId].ladders) do
                print("Does " .. object.recordId .. " match " .. ladder.recordId .. "? " .. tostring(object.recordId == ladder.recordId))
                if (object.recordId == ladder.recordId) then
                    return false
                end
            end
        end
        return true
    end
end
local function onObjectActive(object)
    if shipObjectIds[object.recordId] then
        local newGroup = {object}
        if not I.ObjectGroup_Management.getObjectGroup(object.recordId) then
            for _, act in ipairs(object.cell:getAll()) do
                if distanceBetweenPos(object.position, act.position) < 2000 and
                    objectWhiteListed(object.recordId, act) then
                    table.insert(newGroup, act)
                end
            end
            for _, x in ipairs(newGroup) do
                if markerToDoorMap[x.recordId] then
                    I.ObjectGroup_DoorTP.findDoorLink(x,newGroup)
                end
            end
            I.ObjectGroup_Management.createObjectGroup(newGroup,object.recordId)
            I.Aeth_ShipManage.addShipData(newGroup,object)
        end
    end
end
local function onInit()
    local cellItems = world.getCellById("Aetherveil Skies"):getAll()
    for _, x in ipairs(cellItems) do
        if shipObjectIds[x.recordId] then
            onObjectActive(x)
        end
    end
    local destCell = world.getCellById("Esm3ExteriorCell:-12:-13")
    I.ObjectGroup_Movementx.rotateAndMoveGroup("aeth_dship_x",0,util.vector3(-101879.016, 73187.422, 9388.679),nil,nil,destCell)
    local destCell2 = world.getCellById("Esm3ExteriorCell:-2:-13")
    I.ObjectGroup_Movementx.rotateAndMoveGroup("aeth_silvercascade_ship",0,util.vector3(-14894.735, -107003.719, 8806.694),nil,nil,destCell2)
    I.ObjectGroup_Movementx.rotateAndMoveGroup("aeth_airship3",0,util.vector3(-9381.982, -101998.398, 8972.859),nil,nil,destCell2)
    -- for _, ladder in pairs(I.Aeth_ShipManage.getShipData()["aeth_airship3"].ladders) do
    --     I.ObjectGroup_Movementx.rotateAndMoveGroup(ladder,0,util.vector3(-9381.982, -101998.398, 8972.859),nil,nil,destCell2)
    -- end
end
return {
    interfaceName = "ObjectGroup_DefaultGroups",
    interface = {
    },
    engineHandlers = {
        onObjectActive = onObjectActive,
        onInit = onInit,
    }
}


