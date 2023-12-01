local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")

local tempGroups = {}

local savedObjGroups = {} --Saves the IDs of the perm object groups.
local parentObjectMap = {}

local originalObjectMap = {}
local cachedGroups = {} --Holds the tables of the actual objects. Cleared on reload.
local function createObjectGroup(objectList, mainObjectId)
    savedObjGroups[mainObjectId] = {}
    for index, value in ipairs(objectList) do
        if value.id ~= mainObjectId then
            parentObjectMap[value.id] = mainObjectId
        end
        table.insert(savedObjGroups[mainObjectId], value.id)
    end
end

local function getOriginalObjectID(obj)
    return originalObjectMap[obj.id]
end


local function saveObjectGroup(group)
    local mainObjectId = group[1].id
    savedObjGroups[mainObjectId] = {}
    for index, value in ipairs(group) do
        if value.id ~= mainObjectId then
            parentObjectMap[value.id] = mainObjectId
        end
        table.insert(savedObjGroups[mainObjectId], value.id)
    end
end
local function saveOriginalObjectID(newObj, origId)
    originalObjectMap[newObj.id] = origId
end
local structureData = require("scripts.MoveObjects.StructureData")
local function getObjectInCell(cellList, id)
    for index, cellData in ipairs(cellList) do
        local cell = world.getExteriorCell(cellData.x, cellData.y)

        for index, obj in ipairs(cell:getAll()) do
            if obj.id == id then
                return obj
            end
        end
    end
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        return rotate
    end
end
local function placeObjectsForGroup(data, pos, cell)
    local mainObjectId = data.ids[1].id
    local mainObject = data.ids[1]
    local mainObjectPos =  util.vector3(mainObject.position.x,mainObject.position.y,mainObject.position.z)
    local createdObjects = {}
    local createdMarkers = {}
    local newMainObject
    local cell = world.players[1].cell
    for index, obj in ipairs(data.ids) do
        local sourcePos = util.vector3(obj.position.x,obj.position.y,obj.position.z)
        local sourceRot =createRotation(obj.rotation.x,obj.rotation.y,obj.rotation.z)
        local isMainObject = false
        if obj.id == mainObjectId then
            isMainObject = true
        end
        local realPos = sourcePos - mainObjectPos
        
        local recordId = obj.recordId
        if obj.teleport then
            recordId = interfaces.AA_Records.getDoorActivatorRecord(recordId).id
         
        end
        local newObj = world.createObject(recordId)
        if obj.teleport then
            local sourcePosMarker = util.vector3(obj.teleport.destDoor.position.x,obj.teleport.destDoor.position.y,obj.teleport.destDoor.position.z)
            local realPosMarker = sourcePosMarker - mainObjectPos
            table.insert(createdMarkers,{doorId = newObj.id,position = realPosMarker+ realPos,  rotation = obj.teleport.destDoor.rotation.z})
        end
        newObj:setScale(obj.scale)
        --originalObjectMap[newObj.id] = obj.id
        saveOriginalObjectID(newObj, obj.id)
        table.insert(createdObjects, newObj)
        if isMainObject then
            newMainObject = newObj
        end
        newObj:teleport(cell, realPos + pos, sourceRot)
    end
    createObjectGroup(createdObjects, newMainObject.id)
    return newMainObject, createdObjects, createdMarkers
end

local function tableIncludes(tbl, id)
    for index, value in ipairs(tbl) do
        if value == id then
            return true
        end
    end
    return false
end

local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        local rotatex = util.transform.rotateX(x)
        local rotatey = util.transform.rotateY(y)
        rotate = rotate:__mul(rotatex)
        rotate = rotate:__mul(rotatey)
        return rotate
    end
end
local TPedObjects = {}
local function teleportObject(cell, rot, pos, ob)
    if TPedObjects[ob.id] then print("Already TPed") return end
    if not ob:isValid() or ob.count == 0 then return end
    local rotAngle = 0
    if rot then
        rotAngle = rot:getAnglesZYX()
    else
        rotAngle = ob.rotation:getAnglesZYX()
    end
    TPedObjects[ob.id] = true
    interfaces.AA_CellGen_2_CellCopy_DoorTP.updateDoorPos(ob, pos, rotAngle)
    if not rot then
        ob:teleport(cell, pos)
        return
    end
    ob:teleport(cell, pos, rot)
    --shipObjects[i]:setRotation(rotation)
    --shipObjects[i]:setPosition(position)
end
local function getObjectGroupforObject(obj)
    if not obj then return end
    if cachedGroups[obj.id] and #cachedGroups[obj.id] > 0 then
        return cachedGroups[obj.id]
    end
    if savedObjGroups[obj.id] then
        local retTable = {}
        for index, objId in ipairs(savedObjGroups[obj.id]) do
          --  if obj.cell then
                for index, value in ipairs(
                    interfaces.AA_CellGen_2.getSurroundCellObjects(obj.cell)) do
                    if value.id == objId then
                        table.insert(retTable, value)
                    end
                end
           -- end
        end
        cachedGroups[obj.id] = retTable
        return retTable
    end
    if tempGroups[obj.id] then
        return tempGroups[obj.id].objects
    end
end
local function destroyGroupForObject(mainObject)
    local group = getObjectGroupforObject(mainObject)
    if not group then return end
    for index, value in ipairs(group) do
        value:remove()
    end
    return true
end
local lastCheck = 0
local function rotateAndMoveObjects(mainObject, zRot, newPosition)

    local cell = mainObject.cell
    if not cell then cell = world.players[1].cell end
   -- if core.getRealTime() - lastCheck < 0.01 then
       --print("Timeout")
        --return
   -- else
       -- lastCheck = core.getRealTime()
   -- end
    local objectList = getObjectGroupforObject(mainObject)
    if not objectList then print("No valid olist") return false end
    if #objectList == 0  then print("Empty Olist") return end
    local newPos = {}
    TPedObjects = {}
    for index, value in ipairs(objectList) do
        newPos[value.id] = (value.position - mainObject.position + newPosition)
    end
    if math.deg(zRot) == 0 then
        for index, value in ipairs(objectList) do
            teleportObject(cell, nil, newPos[value.id], value)
        end
    else
        local angle = (zRot)
        local recordId = mainObject.recordId
        -- Find the object with the specified recordId and calculate its position
        local center = newPos[mainObject.id]


        -- Calculate the total offset of all objects from the center
        local totalOffset = util.vector3(0, 0, 0)
        for i = 1, #objectList do
            totalOffset = totalOffset + (newPos[objectList[i].id] - center)
        end

        -- Calculate the average position of all objects
        local averagePosition = center

        -- Rotate each object around the average position
        for i = 1, #objectList do
            -- Calculate the relative position of the object to the average position
            local relativePosition = newPos[objectList[i].id] - averagePosition
            local x = relativePosition.x * math.cos(angle) - relativePosition.y * math.sin(angle)
            local y = relativePosition.x * math.sin(angle) + relativePosition.y * math.cos(angle)
            local position = util.vector3(x + averagePosition.x, y + averagePosition.y, newPos[objectList[i].id].z)

            -- Calculate the new rotation
            local rz, ry, rx = objectList[i].rotation:getAnglesZYX()
            local rotation = createRotation(rx, ry, rz - angle)


            if objectList[i]:isValid() then
                -- Move the object
            end
            teleportObject(cell, rotation, position, objectList[i])
        end
    end
end
local function setGroupState(parentObj, state)
    local group = getObjectGroupforObject(parentObj)
    if group then
        for index, value in ipairs(group) do
            value.enabled = state
        end
    end
end
local function addToTempGroup(object, name)
    for index, value in ipairs(tempGroups) do
        if value.name == name then
            table.insert(value.objects, object)
            object.enabled = false
        end
    end
end
local function disableTempGroup(name, state)
    for index, value in ipairs(tempGroups) do
        if value.name == name then
            for index, obj in ipairs(value.objects) do
                obj.enabled = state or false
            end
        end
    end
end
local function createTempGroup(object, name)
    table.insert(tempGroups, { objects = { object }, mainObject = object, name = name })
end

local function onSave()
    return { savedObjGroups = savedObjGroups, parentObjectMap = parentObjectMap, }
end
local function getParentObject(obj)
    local check = parentObjectMap[obj.id]
    if check then
        for index, value in ipairs(
            interfaces.AA_CellGen_2.getSurroundCellObjects(obj.cell)) do
            if value.id == check and value.id ~= obj.id then
                return obj
            end
        end
    end
end
local function onLoad(data)
    if not data then return end
    savedObjGroups = data.savedObjGroups
    if data.parentObjectMap then
        parentObjectMap = data.parentObjectMap
    end
end
return {
    interfaceName = "AA_Build_Group",
    interface = {
        version                 = 1,
        createTempGroup         = createTempGroup,
        addToTempGroup          = addToTempGroup,
        disableTempGroup        = disableTempGroup,
        createObjectGroup       = createObjectGroup,
        getObjectGroupforObject = getObjectGroupforObject,
        setGroupState           = setGroupState,
        rotateObjects           = rotateObjects,
        rotateAndMoveObjects    = rotateAndMoveObjects,
        destroyGroupForObject   = destroyGroupForObject,
        placeObjectsForGroup    = placeObjectsForGroup,
        saveObjectGroup         = saveObjectGroup,
        getOriginalObjectID     = getOriginalObjectID,
        saveOriginalObjectID    = saveOriginalObjectID,
        getParentObject         = getParentObject,
    },
    eventHandlers = {
        deleteTempObjects = deleteTempObjects,
        setBuildModeState = setBuildModeState,
        updateSelectedObject = updateSelectedObject,
        updateTargetPos = updateTargetPos,
        createPermObject = createPermObject,
        setGrabbedObject = setGrabbedObject,
    },
    engineHandlers = { onSave = onSave, onLoad = onLoad }
}
