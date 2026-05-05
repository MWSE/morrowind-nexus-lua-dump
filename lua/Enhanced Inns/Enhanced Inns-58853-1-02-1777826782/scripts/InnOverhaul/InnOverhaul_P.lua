local cam = require('openmw.interfaces').Camera
local camera = require('openmw.camera')
local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require("openmw.storage")
local async = require("openmw.async")
local input = require("openmw.input")


local function getRoomNavPos1(obj)
    local navPos = nearby.findNearestNavMeshPosition(obj.position)
    if not navPos then
        core.sendGlobalEvent("getRoomNavPos2")
        return
    end
    local status, path = nearby.findPath(self.position, navPos,
        { includeFlags = nearby.NAVIGATOR_FLAGS.Walk, areaCosts = { door = 100.5, },
        })
    if status ~= nearby.FIND_PATH_STATUS.Success or not path or #path == 0 then
        core.sendGlobalEvent("getRoomNavPos2")
        return
    end
    local endPos = path[#path]
    core.sendGlobalEvent("getRoomNavPos2", endPos)
end
local function ZS_ShowMessage(msg)
    ui.showMessage(msg)
end

local function InRoomCheck(data)
    local bed = data.bed
    local door = data.door
    local status, path = nearby.findPath(self.position, bed.position,
        { includeFlags = nearby.NAVIGATOR_FLAGS.Walk, areaCosts = { door = 100.5, }, })
    if status == nearby.FIND_PATH_STATUS.Success then
        core.sendGlobalEvent("OpenDoorInRoom", data)
    else
        print("Can't find the bed")
    end
end
return {
    interfaceName = "ZS_InnOverhaul",
    interface = {
    },
    engineHandlers = {
    },
    eventHandlers = {
        getRoomNavPos1 = getRoomNavPos1,
        ZS_ShowMessage = ZS_ShowMessage,
        InRoomCheck = InRoomCheck,
    }
}
