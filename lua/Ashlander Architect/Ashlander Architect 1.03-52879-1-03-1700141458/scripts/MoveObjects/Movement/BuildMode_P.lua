local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local async = require("openmw.async")
local activeObjectTypes = {}

local time = require('openmw_aux.time')
local zutils = require("scripts.moveobjects.utility.player").interface
local zutilsUI = require("scripts.moveobjects.utility.ui").interface

local settlementModData = storage.globalSection("AASettlements")
local genModData = storage.globalSection("MoveObjectsCellGen")
local PlaceInterface = {}
function PlaceInterface.updateSelectedObject(objectId, position, rotation)
    core.sendGlobalEvent("updateSelectedObject", { recordId = objectId, position = position, rotation = rotation })
end

function PlaceInterface.deleteTempObjects()
    core.sendGlobalEvent("deleteTempObjects")
end

function PlaceInterface.createPermObject()
    core.sendGlobalEvent("createPermObject")
end

function PlaceInterface.placePermObject(objectId)
    core.sendGlobalEvent("placePermObject", objectId)
end

function PlaceInterface.setGrabbedObject(object)
    core.sendGlobalEvent("setGrabbedObject", object)
end

function PlaceInterface.setBuildModeState(state)
    core.sendGlobalEvent("setBuildModeState", state)
end

function PlaceInterface.updateTargetPos(position, rotation)
    core.sendGlobalEvent("updateTargetPos", { placePosition = position, placeRotation = rotation })
end
local cellGenStorage = storage.globalSection("AACellGen2")
function PlaceInterface.getDoorDestinationStr(obj)
local check = cellGenStorage:get("doorData")[obj.id]
if check then
    local name = cellGenStorage:get("cellNames")[check.targetCell]
    if name then
        return name
    end
    return check.targetCell
end
return "Invalid Destination"
end
return PlaceInterface
