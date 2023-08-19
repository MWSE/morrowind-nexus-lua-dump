local util = require("openmw.util")
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")
local LocIndex = 0
local NextIndex = 46
local myModData = storage.globalSection('MundisData')
local function onLoad(data)
    if (data) then
        LocIndex = data.LocIndex
        myModData:set("LocIndex", LocIndex)
        NextIndex = data.NextIndex
    end
end
local function onSave()
    return { LocIndex = LocIndex, NextIndex = NextIndex }
end
local function setNextDest(data)
    NextIndex = data
end

local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ((z))
        return rotate
    end
end

local function teleportMundis()
    local oldindex = LocIndex
    local newIndex = NextIndex
    if (newIndex == nil) then
        print("No new index")
        return
    end
    if (newIndex == 0) then
        print("No new index")
        return
    else
        print("Trying index: " .. newIndex)
    end
    --where things are at at the start here. Don't assign to this.
    local locData = interfaces.MundisDataHandler.getData()
    local currData = locData[newIndex]
    if (currData == nil) then
        print("currData at " .. newIndex .. " is nil")
        return
    end
    local enterdoor = nil
    --first we find our door, and box to move and disable

    if (oldindex == 0) then --no box to disable, door is in the same cell
        for i, door in ipairs(world.getCellByName("MUNDIS Control Room"):getAll(types.Door)) do
            if door.recordId == "mundis_3_enterdoor" then
                enterdoor = door
                break -- exit the loop once the door is found
            end
        end
        if (enterdoor == nil) then
            print("door couldn't be found at 0")
            return
        end
    else
        local oldData = locData[oldindex]
        if (oldData.cellX == -999) then --interior
            for i, door in ipairs(world.getCellByName(oldData.cell):getAll(types.Door)) do
                if door.recordId == "mundis_3_enterdoor" then
                    enterdoor = door
                    break -- exit the loop once the door is found
                end
            end
            for i, acti in ipairs(world.getCellByName(oldData.cell):getAll(types.Activator)) do
                if acti.id == oldData.boxId then
                    acti.enabled = false
                    break -- exit the loop once the door is found
                end
            end
            if (enterdoor == nil) then
                print("interior door couldn't be found at " .. oldData.cell)
                return
            end
        else
            for i, door in ipairs(world.getExteriorCell(oldData.cellX, oldData.cellY):getAll(types.Door)) do
                if door.recordId == "mundis_3_enterdoor" then
                    enterdoor = door
                    break -- exit the loop once the door is found
                end
            end
            for i, acti in ipairs(world.getExteriorCell(oldData.cellX, oldData.cellY):getAll(types.Activator)) do
                if acti.id == oldData.boxId then
                    acti.enabled = false
                    break -- exit the loop once the door is found
                end
            end
            if (enterdoor == nil) then
                print("door couldn't be found at " .. oldData.cell)
                return
            end
        end
    end
    local targetbox = nil
    print(enterdoor.cell.name)
    --old box is disabled, now to find our new box
    if (currData.boxId == "") then --new place, better save the data
        local targetbox = world.createObject("mundis_3_extBox")
        targetbox:teleport(
            currData.cell,
            util.vector3(currData.px, currData.py, currData.pz),
           createRotation(0,0,currData.rz) 
        )
        print(targetbox.id)
        currData.boxId = targetbox.id
        print(currData.boxId)
        locData[newIndex] = currData
        interfaces.MundisDataHandler.setData(locData)
    else                                 --been there, time to kick it
        if (currData.cellX == -999) then --interior
            for i, acti in ipairs(world.getCellByName(currData.cell):getAll(types.Activator)) do
                if acti.id == currData.boxId then
                    acti.enabled = true
                    break -- exit the loop once the door is found
                end
            end
        else
            for i, acti in ipairs(world.getExteriorCell(currData.cellX, currData.cellY):getAll(types.Activator)) do
                if acti.id == currData.boxId then
                    acti.enabled = true
                    break -- exit the loop once the door is found
                end
            end
        end
    end
    enterdoor:teleport(
        currData.cell,
        util.vector3(currData.px, currData.py, currData.pz),
        createRotation(0,0,currData.rz) 
    )

    LocIndex = newIndex
    myModData:set("LocIndex", LocIndex)
    NextIndex = 0
end

local function exitMundisFunc(data) --called when exiting the mundis
    local locData = interfaces.MundisDataHandler.getData()
    local currData = locData[LocIndex]
    data[2]:teleport(
        currData.cell,
        util.vector3(currData.dx, currData.dy, currData.dz),
        createRotation(0,0,currData.drz) 
    )
end
function getLocIndex()
    return LocIndex
end

function onInit()

end

local function checkButtonText(text) --will teleport the mundis if the button matches a destination
    local locData = interfaces.MundisDataHandler.getData()
    local i = 1
    for _, currLocData in ipairs(locData) do
        if currLocData.cell == text then
            NextIndex = i
            teleportMundis()
            return
        end
        i = i + 1
    end
end
local function MUNDISInit()
    NextIndex = 46


    teleportMundis()
end

return {
    interfaceName = "MundisGlobalData",
    interface = {
        version = 1,
        getLocIndex = getLocIndex,
    },
    eventHandlers = {
        teleportMundis = teleportMundis,
        setNextDest = setNextDest,
        exitMundisFunc = exitMundisFunc,
        checkButtonText = checkButtonText,
        MUNDISInit = MUNDISInit,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = onInit
    }
}
