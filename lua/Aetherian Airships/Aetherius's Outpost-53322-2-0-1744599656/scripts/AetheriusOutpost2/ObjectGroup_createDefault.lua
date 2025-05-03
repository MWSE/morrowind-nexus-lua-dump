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
    ["zhac_dsub_full"] = "zhac_dsub_full",
    ["ex_de_ship"] = "ex_de_ship",
    ["ab_ex_impgalleonfullfurled"] = "ab_ex_impgalleonfullfurled",
    ["zhac_dship_x"] = "zhac_dship_x",
    ["ex_longboat"] = "ex_longboat",
    ["ab_ex_deshipsmall"] = "ab_ex_deshipsmall",
    ["zhac_silvercascade_ship"] = "zhac_silvercascade_ship"
}

local doorActivateMap = {
    zhac_door_impgalleon01_r = "zhac_sc_exitmarker_cabinl",
    zhac_door_impgalleon01_l = "zhac_sc_exitmarker_cabinr",

    zhac_door_impgalleon01_r_dock = "zhac_sc_exitmarker_dockr",
    zhac_door_impgalleon01_l_dock = "zhac_sc_exitmarker_dockl",

    zhac_door_impgalleon01_m = "zhac_sc_exitmarker_cabinm",
    zhac_door_impgalleon02_in = "zhac_sc_exitmarker_main",
    zhac_sw_exitdoor = "zhac_sw_exitmarker"

}

local markerToDoorMap = {
    zhac_sc_exitmarker_cabinl = "zhac_door_impgalleon01_r",
    zhac_sc_exitmarker_cabinr = "zhac_door_impgalleon01_l",

    zhac_sc_exitmarker_dockr = "zhac_door_impgalleon01_r_dock",
    zhac_sc_exitmarker_dockl = "zhac_door_impgalleon01_l_dock",

    zhac_sc_exitmarker_cabinm = "zhac_door_impgalleon01_m",
    zhac_sc_exitmarker_main = "zhac_door_impgalleon02_in",
    zhac_sw_exitmarker = "zhac_sw_exitdoor"
}
local function distanceBetweenPos(vector1, vector2)
    -- Quick way to find out the distance between two vectors.
    -- Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function objectWhiteListed(object)
    if object.type == types.Door or object.type == types.Container or
        object.type == types.Activator or object.type.baseType == types.Item then
        return true
    end
end
local function onObjectActive(object)
    if shipObjectIds[object.recordId] then
        local newGroup = {object}
        if not I.ObjectGroup_Management.getObjectGroup(object.recordId) then

            for index, act in ipairs(object.cell:getAll()) do
                if distanceBetweenPos(object.position, act.position) < 2000 and
                    objectWhiteListed(act) then
                    table.insert(newGroup, act)
                  
                end
            end
            for i, x in ipairs(newGroup) do
                if markerToDoorMap[x.recordId] then
                    I.ObjectGroup_DoorTP.findDoorLink(x,newGroup)
                end
            end
            I.ObjectGroup_Management.createObjectGroup(newGroup,object.recordId)
            I.AOutpost_ShipManage.addShipData(newGroup,object)

        end
    end
end

return {

    interfaceName = "ObjectGroup_DefaultGroups",
    interface = {
    },
    engineHandlers = {
        onObjectActive = onObjectActive,
    }
}


