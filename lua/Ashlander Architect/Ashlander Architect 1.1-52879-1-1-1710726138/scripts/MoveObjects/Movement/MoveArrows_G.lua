local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")



local arrowIds = { "zhac_selectionmarker_x1", "zhac_selectionmarker_x2", "zhac_selectionmarker_y1",
    "zhac_selectionmarker_y2", "zhac_selectionmarker_z1", "zhac_selectionmarker_z2" }

    local moveModes = {
        pointAndClick = 1,
        moveWithArrows = 2,
    }
local targetObj
local availableMarkers = {}

local function createMarkers()
    if true == true then return end
    if #availableMarkers > 0 then return end

    for index, value in ipairs(arrowIds) do
    
        local obj = world.createObject(value)
        table.insert(availableMarkers,obj)
    end
end
local function disableMarkers()
    for index, value in ipairs(availableMarkers) do
        value.enabled = false
    end
end
local function setMarkerPosition(data)
    if true == true then return end

    createMarkers()
    local cellName = data.cellName
    local pos = data.pos
    pos = util.vector3(pos.x,pos.y,pos.z + 300)
    local rot = data.rot
    for index, value in ipairs(availableMarkers) do
        if not value.enabled then
            value.enabled = true
        end
        value:teleport(cellName, pos, rot)
    end
end
local function destroyMarkers()
    if true == true then return end
    for index, value in ipairs(availableMarkers) do
        value:remove()
    end
    availableMarkers = {}
end
local function onSave()
    destroyMarkers()
end
local function onFrame_AA()
    if true == true then return end
    if not targetObj then return end
    if not targetObj.cell then return end
    setMarkerPosition({ cellName = targetObj.cell.name, pos = targetObj.position, rot = targetObj.rotation })
end
local function updateTargetObj(data)
    if true == true then return end
    local obj = data.obj
    local moveMode = data.moveMode
    if moveMode == moveModes.pointAndClick then
        disableMarkers()
        targetObj = nil
        return
    end
    targetObj = obj
    if not obj then
        disableMarkers()
    end
end
return {
    interfaceName = "AA_ArrowMover",
    interface = {
        version = 1,
    },
    eventHandlers = {
        setMarkerPosition = setMarkerPosition,
        disableMarkers = disableMarkers,
        destroyMarkers = destroyMarkers,
        updateTargetObj = updateTargetObj,
        onFrame_AA = onFrame_AA,
    },
    engineHandlers = { onSave = onSave, onUpdate = onUpdate }
}
