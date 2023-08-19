local util = require("openmw.util")
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")
local LocIndex = 0
local NextIndex = 46
local myModData = storage.globalSection('MundisData')
local tpEffect = require("scripts.mundis.teleport_effect")
local function getData(ID)
    local locData = interfaces.MundisDataHandler.getData()
    for index, value in ipairs(locData) do
        if value.ID == ID then
            return value
        end
    end
end
local function getPlayer()
    if core.API_REVISION > 29 then
        return world.players[1]
    else
        for index, value in ipairs(world.activeActors) do
            if value.type == types.Player then
                return value
            end
        end
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
    local currData = nil
    local oldData = nil
    for index, data in ipairs(locData) do
        if data.ID == NextIndex then
            currData = data
        elseif data.ID == oldindex then
            oldData = data
        end
    end
    if (currData == nil) then
        print("currData at " .. newIndex .. " is nil")
        return
    end
    local enterdoor = nil
    local enterBox = nil
    --first we find our door, and box to move

    if (oldindex == 0) then --no box to disable, door is in the same cell
        for i, door in ipairs(world.getCellByName("MUNDIS Control Room"):getAll(types.Door)) do
            if door.recordId == "mundis_3_enterdoor" then
                enterdoor = door
                break -- exit the loop once the door is found
            end
        end
        for i, acti in ipairs(world.getCellByName("MUNDIS Control Room"):getAll(types.Activator)) do
            if acti.recordId == "mundis_3_extbox" then
                --   acti.enabled = false
                enterBox = acti
                break -- exit the loop once the door is found
            end
        end
        if (enterdoor == nil or enterBox == nil) then
            print("door couldn't be found at 0")
            return
        end
    else                                         --not the first time we've TPed
        if (oldData.cellData.cellX == -999) then --interior
            for i, door in ipairs(world.getCellByName(oldData.cellData.cellName):getAll(types.Door)) do
                if door.recordId == "mundis_3_enterdoor" then
                    enterdoor = door
                    break -- exit the loop once the door is found
                end
            end
            for i, acti in ipairs(world.getCellByName(oldData.cellData.cellName):getAll(types.Activator)) do
                if acti.recordId == "mundis_3_extbox" then
                    --   acti.enabled = false
                    enterBox = acti
                    break -- exit the loop once the door is found
                end
            end
            if (enterdoor == nil or enterBox == nil) then
                print("interior door couldn't be found at " .. oldData.cellData.cellName)
                return
            end
        else --exterior
            for i, door in ipairs(world.getExteriorCell(oldData.cellData.cellX, oldData.cellData.cellY):getAll(types.Door)) do
                if door.recordId == "mundis_3_enterdoor" then
                    enterdoor = door
                    break -- exit the loop once the door is found
                end
            end
            for i, acti in ipairs(world.getExteriorCell(oldData.cellData.cellX, oldData.cellData.cellY):getAll(types.Activator)) do
                if acti.recordId == "mundis_3_extbox" then
                    --   acti.enabled = false
                    enterBox = acti
                    break -- exit the loop once the door is found
                end
            end
            if (enterdoor == nil or enterBox == nil) then
                print("door couldn't be found at " .. oldData.cellData.cellName)
                return
            end
        end
    end
    if not enterBox then
        error("Box not found")
    end
    print(enterdoor.cell.name)
    enterBox:teleport(
        currData.cellData.cellName,
        currData.position,
        createRotation(0, 0, currData.rotation)
    )
    enterdoor:teleport(
        currData.cellData.cellName,
        currData.position,
        createRotation(0, 0, currData.rotation)
    )

    LocIndex = newIndex
    myModData:set("LocIndex", LocIndex)
    NextIndex = 0
end

local function onLoad(data)
    if (data) then
        LocIndex = data.LocIndex
        myModData:set("LocIndex", LocIndex)
        NextIndex = data.NextIndex

        teleportMundis()
        print("Loaded mundis")
    else

    end
end
local function exitMundisFunc(data) --called when exiting the mundis
    local currData = getData(LocIndex)
    local position, rotation = interfaces.MundisDataHandler.getBoxExitPos(currData.position, currData.rotation)

    if core.API_REVISION > 29 then
        data[2]:teleport(
            currData.cellData.cellName,
            position,
            { rotation = rotation, onGround = true }
        )
    else
        data[2]:teleport(
            currData.cellData.cellName,
            position,
            rotation
        )
    end
    for index, value in ipairs(world.activeActors) do
        value:sendEvent("ExitMundisCheck",{cellName = currData.cellData.cellName,position = position, rotation = rotation})
    end
end
local function MUNDIS_TeleportToCell(data)
        --Simple function to teleport an object to any cell.
    
        if (data.cellname.name ~= nil) then
            data.cellname = data.cellname.name
        end
        data.item:teleport(data.cellname, data.position, data.rotation)
    
end
local function getLocIndex()
    return LocIndex
end

function onInit()

end

local function startTPTimer()
    world.activeActors[1]:sendEvent("setPlayerControlState", false)
    tpEffect.startTeleport()
end

local function checkButtonText(text) --will teleport the mundis if the button matches a destination
    local locData = interfaces.MundisDataHandler.getData()
    local i = 1
    for _, currLocData in ipairs(locData) do
        if currLocData.ID == text then
            local powerRemaining = interfaces.MundisPowerSystem.getChargeCount()
            if powerRemaining < 1 then
                getPlayer():sendEvent("showMessageMundis",
                    string.format("You don't have enough charges. You currently have %d, but you need %d", powerRemaining,
                        1))
                return
            else
                interfaces.MundisPowerSystem.incrementChargeCount(-1)
            end
            NextIndex = i
            startTPTimer()
            return
        end
        i = i + 1
    end
end
local function MUNDISInit()
    -- NextIndex = 46


    --teleportMundis()
end
local function getAngle(rotation)

    
if core.API_REVISION > 29 then 
    return  rotation:getAnglesZYX()
else
    return  rotation.z
    end

end
local function markAndRecallPos()
    local newPosition, newRotation = interfaces.MundisDataHandler.getBoxExitPos(getPlayer().position,
    getAngle( getPlayer().rotation), "south")
    local newData = interfaces.MundisDataHandler.addMundisLocation(newPosition, getAngle( newRotation),
        interfaces.MundisDataHandler.getCellData(getPlayer().cell))

    NextIndex = newData.ID
    startTPTimer()
end
local function onObjectActive(obj)
    if obj.recordId == "mundis_3_exitdoor" then
        obj:teleport("MUNDIS Control Room", util.vector3(6262.600, 2427.532, 10718.883))
    elseif obj.recordId == "zhac_mundis_summononb" then
        local powerRemaining = interfaces.MundisPowerSystem.getChargeCount()

        if powerRemaining < 4 then
            getPlayer():sendEvent("showMessageMundis",
                string.format("You don't have enough charges. You currently have %d, but you need %d", powerRemaining, 4))
            return
        else
            interfaces.MundisPowerSystem.incrementChargeCount(-4)
        end
        local pos = obj.position
        local rotation = obj.rotation
        local cell = obj.cell
        
    if core.API_REVISION > 29 then 
        obj:remove()
    else
        obj:teleport("toddtest",obj.position)
    end
        local i = 1
        if myModData:get("enableLegacySummon") == true then
            local locData = interfaces.MundisDataHandler.getData()
            for _, currLocData in ipairs(locData) do
                if currLocData.cellData.cellName:lower() == cell.name:lower() and currLocData.ID ~= LocIndex and cell.name:lower() ~= "" then
                    NextIndex = currLocData.ID
                    startTPTimer()
                    return
                end
                i = i + 1
            end
        end
        markAndRecallPos()
    end
end

local function setSettingMundis(data)
    local key = data.key
    local value = data.value
    local player = data.player
    myModData:set(key, value)
    if key == "enableCheats" then
        for index, obj in ipairs(world.getCellByName("Mundis Control Room"):getAll()) do
            interfaces.MundisGlobalCheat.setCheatState(obj)
        end
        for index, obj in ipairs(getPlayer().cell:getAll()) do
            interfaces.MundisGlobalCheat.setCheatState(obj)
        end
    end
end

local mundisCells = {}
local function MundisCreateObject(data)
    mundisCells[data.sourceObject.cell.name] = data.sourceObject.cell
    world.createObject(data.objectId):teleport(data.sourceObject.cell, data.sourceObject.position,
        data.sourceObject.rotation)
end
local function MundisSetObjState(data)
    mundisCells[data.obj.cell.name] = data.obj.cell
    data.obj.enabled = data.state
end
local function getMundisCells()
    return mundisCells
end

return {
    interfaceName = "MundisGlobalData",
    interface = {
        version = 1,
        getLocIndex = getLocIndex,
        getMundisCells = getMundisCells,
        onLoad = onLoad,
    },
    eventHandlers = {
        teleportMundis = teleportMundis,
        setNextDest = setNextDest,
        exitMundisFunc = exitMundisFunc,
        checkButtonText = checkButtonText,
        MUNDISInit = MUNDISInit,
        startTPTimer = startTPTimer,
        setSettingMundis = setSettingMundis,
        MundisCreateObject = MundisCreateObject,
        MundisSetObjState = MundisSetObjState,
        MUNDIS_TeleportToCell = MUNDIS_TeleportToCell,
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = onInit,
        onObjectActive = onObjectActive,
    }
}
