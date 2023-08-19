local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")

local tempObjects = {}
local grabbedObject = nil
local buildMode = false
local placePosition = nil
local placeRotation = 0
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        return rotate
    end
end
local function updatePlayerData()
    world.players[1]:sendEvent("createItemReturn_AA", tempObjects)
end
local function moveTempObjects()
    if grabbedObject then
        grabbedObject:teleport(grabbedObject.cell, placePosition, placeRotation)
        return
    end
    local player = world.players[1]
    for index, ob in ipairs(tempObjects) do
        ob:teleport(player.cell, placePosition, placeRotation)
    end
end
local waitTime = 0
local function onUpdate(dt)
    waitTime = waitTime + dt
    if buildMode and dt > 0 and #tempObjects > 0 then
        if (waitTime > 0.01) then
            waitTime = 0
            moveTempObjects()
        end
    else
        return
    end
end
local function updateTargetPos(data)
    placePosition = data.placePosition
    placeRotation = data.placeRotation
 
    moveTempObjects()
end
local function deleteTempObjects()
    for index, value in ipairs(tempObjects) do
        value:remove()
    end
    tempObjects = {}
end
local function updateSelectedObject(data)
    local player = world.players[1]
    local recordId = data.recordId
    local pos = data.position
    local rotation = data.rotation
    if pos then
        placePosition = pos
    end
    if rotation then
        placeRotation = createRotation(0, 0, rotation)
    end
    if not placePosition then
        placePosition = player.position
    end
    if not placeRotation or placeRotation == 0 then
        placeRotation = createRotation(0, 0, 0)
    end
    deleteTempObjects()
    if not recordId then
        tempObjects = {}

        updatePlayerData()
        return
    end
    local newObject = world.createObject(recordId)
    -- newObject:teleport(player.cell, placePosition, placeRotation)
    waitTime = 0
    table.insert(tempObjects, newObject)
    updatePlayerData()
    print("object select")
end
local function createPermObject()
    for index, value in ipairs(tempObjects) do
        local newOb = world.createObject(tempObjects[index].recordId)
        newOb:teleport(value.cell, value.position, value.rotation)
        world.players[1]:sendEvent("permaObjectStore", newOb)
        core.sendGlobalEvent("exitBuildMode", { placedItem = newOb, player = world.players[1] })
    end
end
local function setGrabbedObject(object)
grabbedObject = object

end
local function setBuildModeState(state)
    buildMode = state
    if not state then
        deleteTempObjects()
        grabbedObject = nil
    end
    updatePlayerData()
end
local function onSave()
    deleteTempObjects()
    updatePlayerData()
end
return {
    interfaceName = "AA_BuildMode",
    interface = {
        version = 1,
    },
    eventHandlers = {
        deleteTempObjects = deleteTempObjects,
        setBuildModeState = setBuildModeState,
        updateSelectedObject = updateSelectedObject,
        updateTargetPos = updateTargetPos,
        createPermObject = createPermObject,
        setGrabbedObject = setGrabbedObject,
    },
    engineHandlers = { onSave = onSave }
}
