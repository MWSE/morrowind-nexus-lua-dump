local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local util = require("openmw.util")
local npcScriptData = {
    ["chargen class"] = { path = "scripts/immersiveChargen/npcScripts/ChargenClass.lua" },
    ["tr_m1_jeande_beluel"] = { path = "scripts/immersiveChargen/npcScripts/ChargenClass.lua", initData = { distance = 200 } },

    ["chargen dock guard"] = { path = "scripts/immersiveChargen/npcScripts/ChargenRace.lua" },
    ["chargen boat guard 2"] = { path = "scripts/immersiveChargen/npcScripts/ChargenWalk.lua" },
    ["chargen door guard"] = { path = "scripts/immersiveChargen/npcScripts/ChargenDoorGuard.lua" },
    ["chargen name"] = { path = "scripts/immersiveChargen/npcScripts/jiubScript.lua" }
}

local tempObjects = {}
local objectsToRestore = {}
local objectsToUnlock = {}

local shipExitId = "chargen_shipdoor"
local alternateData = {}
alternateData.firewatch = require("scripts.ImmersiveChargen.ChargenStates.Firewatch")

local activeStart = "default"
local activeStart = "firewatch"
local sheetWasDisabled = false
local chargenCells = {
    { cellName = "Seyda Neen, Census and Excise Office" },
    { x = -2,                                           y = -9 },
    { x = -1,                                           y = -9 },
    { x = -2,                                           y = -10 },
    { x = -2,                                           y = -9 },
}
local unlockObjects = {
    "0x101d2d9",
    "chargen door hall"
}
local chargenCleanDone = false
local function onActorActive(actor)
    local data = npcScriptData[actor.recordId]
    if data and not actor:hasScript(data.path) then
        actor:addScript(data.path, data.initData)
    end
end

local chargenObjects = {
    ["chargen boat"] = true,
    ["chargen boat guard 1"] = true,
    ["chargen boat guard 2"] = true,
    ["chargen dock guard"] = true,
    ["chargen_cabindoor"] = true,
    ["chargen_chest_02_empty"] = true,
    ["chargen_crate_01"] = true,
    ["chargen_crate_01_empty"] = true,
    ["chargen_crate_01_misc01"] = true,
    ["chargen_crate_02"] = true,
    ["chargen_lantern_03_sway"] = true,
    ["chargen_ship_trapdoor"] = true,
    ["chargen_barrel_01"] = true,
    ["chargen_barrel_02"] = true,
    ["chargenbarrel_01_drinks"] = true,
    ["chargen_plank"] = true,
}

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
local function onNewGame()
    if alternateData[activeStart] then
        for index, value in ipairs(alternateData[activeStart].extCells) do
            
            local cell = world.getExteriorCell(value.x, value.y)
            cell:getAll()
        end
        for index, value in ipairs(chargenCells) do
            if value.cellName then
            else
                local cell = world.getExteriorCell(value.x, value.y)
                for index, obj in ipairs(cell:getAll()) do
                    if  alternateData[activeStart].repositions[obj.recordId] then
                        local data =  alternateData[activeStart].repositions[obj.recordId]
                        obj:teleport("", data.position,
                            createRotation(0, 0, data.rotation))
                        table.insert(tempObjects, obj)
                    end
                    if alternateData[activeStart].extNPCPositions[obj.recordId] then
                        obj:teleport("", alternateData[activeStart].extNPCPositions[obj.recordId].position,
                            createRotation(0, 0, alternateData[activeStart].extNPCPositions[obj.recordId].rotation))
                        table.insert(tempObjects, obj)
                    end
                end
            end
        end
        shipExitId = alternateData[activeStart].shipExitId
        local orginalExit
        for index, value in ipairs(world.getCellByName("Imperial Prison Ship"):getAll()) do
            if value.recordId == "chargen_shipdoor" then
                orginalExit = value
            end
        end
        for index, value in ipairs(world.getCellByName("Imperial Prison Ship"):getAll()) do
            if value.recordId == shipExitId and value.id ~= orginalExit.id then
                value:teleport(orginalExit.cell, orginalExit.position)
                orginalExit.enabled = false
                orginalExit:remove()
            end
        end
        for index, value in ipairs(alternateData[activeStart].placeObjects) do
            local newObject = world.createObject(value.id)
            if value.position ~= nil then
                newObject:teleport(value.cell, value.position, createRotation(0, 0, value.rotation))
                table.insert(tempObjects, newObject)

                if value.script and not newObject:hasScript(value.script) then
                    newObject:addScript(value.script)
                end
            else
                newObject.ownerRecordId = value.owner
                newObject:teleport(value.cell,util.vector3(value.translation[1],value.translation[2],value.translation[3]), createRotation(value.rotation[1], value.rotation[2],value.rotation[3]))
                table.insert(tempObjects, newObject)

            end
        end
        
        for index, value in ipairs(alternateData[activeStart].placeObjectsExt) do
            local newObject = world.createObject(value.id)
            if value.position ~= nil then
                newObject:teleport("", value.position, createRotation(0, 0, value.rotation))
                table.insert(tempObjects, newObject)

            else
                newObject:teleport("",util.vector3(value.translation[1],value.translation[2],value.translation[3]), createRotation(value.rotation[1], value.rotation[2],value.rotation[3]))
                table.insert(tempObjects, newObject)

            end
        end
        local intCells = alternateData[activeStart].intCells
        --
        for index, value in ipairs(intCells) do
            local cell = world.getCellByName(value)
            for index, obj in ipairs(cell:getAll()) do
            end
        end
    end
    for index, objData in ipairs(alternateData[activeStart].intObjectsToDisable) do
        local obj = world.getObjectByFormId(core.getFormId(objData[2], tonumber(objData[1])))
        obj.enabled = false

        table.insert(objectsToRestore, obj)
    end
    for index, objData in ipairs(alternateData[activeStart].intObjectsToLock) do
        local obj = world.getObjectByFormId(core.getFormId(objData[2], tonumber(objData[1])))
        types.Lockable.lock(obj, 100)
        table.insert(objectsToUnlock, obj)
    end
end

local function unlockHallwayDoors()
    for index, objData in ipairs(alternateData[activeStart].hallwayDoorUnlock) do
        local obj = world.getObjectByFormId(core.getFormId(objData[2], tonumber(objData[1])))
        types.Lockable.unlock(obj)
    end
    world.players[1]:sendEvent("IC_playSound", "Open Lock")
end

local function exitDoorUnlock()
    for index, objData in ipairs(alternateData[activeStart].exitDoorUnlock) do
        local obj = world.getObjectByFormId(core.getFormId(objData[2], tonumber(objData[1])))
        types.Lockable.unlock(obj)
    end
    --world.players[1]:sendEvent("IC_playSound", "Open Lock")
end
local function performCharGenClean()
    for index, value in ipairs(chargenCells) do
        if value.cellName then
            local cell = world.getCellByName(value.cellName)
            for index, obj in ipairs(cell:getAll()) do
                for index, unOb in ipairs(unlockObjects) do
                    if obj.id == unOb or obj.recordId == unOb then
                        types.Lockable.unlock(obj)
                    end
                end
                if chargenObjects[obj.recordId] then
                    obj.enabled = false
                end
            end
        else
            local cell = world.getExteriorCell(value.x, value.y)
            for index, obj in ipairs(cell:getAll()) do
                if chargenObjects[obj.recordId] then
                    obj.enabled = false
                end
            end
        end
    end
end

local function finishChargen()
    performCharGenClean()
    for index, value in ipairs(objectsToRestore) do
        value.enabled = true
    end
    for index, value in ipairs(tempObjects) do
        if value.count > 0 then
            value:remove()
        end
    end
    for index, value in ipairs(objectsToUnlock) do
        types.Lockable.unlock(value)
    end
    local playerObj = world.createObject("zhac_finishchargen")
    playerObj:teleport(world.players[1].cell, world.players[1].position)
    chargenCleanDone = true
end
local function setObjectState_ICG(data)
    local id = data.id:lower()
    local state = data.state
    if state == true then
        for index, value in ipairs(world.players[1].cell:getAll()) do
            if value:hasScript("scripts/immersiveChargen/npcScripts/chargendoorguard.lua") then
                value:sendEvent("setreadyForPapers")
            end
        end
    end
    for index, obj in ipairs(world.players[1].cell:getAll()) do
        if obj.recordId == id then
            obj.enabled = state
            return
        end
        --
    end
end



local function onChargenExit()

end
local function onSave()
    if not chargenCleanDone then
        performCharGenClean()
    end
    return { chargenCleanDone = chargenCleanDone }
end
local function onLoad(data)
    if data then
        chargenCleanDone = data.chargenCleanDone
    end
end
local function onItemActive(item)
    if item.recordId == "chargen statssheet" and not sheetWasDisabled then
        item.enabled = false
        sheetWasDisabled = true
    end
end

local function onActivate(object, actor)
    if object.type.baseType == types.Item then
        for index, value in ipairs(tempObjects) do
            if value == object then
                table.remove(tempObjects, index)
                return
            end
        end
    end
end
return {
    engineHandlers = {
        onActorActive = onActorActive,
        onSave = onSave,
        onLoad = onLoad,
        onNewGame = onNewGame,
        onItemActive = onItemActive,
        onActivate = onActivate,
    },
    eventHandlers = {
        setObjectState_ICG = setObjectState_ICG,
        performCharGenClean = performCharGenClean,
        finishChargen = finishChargen,
        unlockHallwayDoors = unlockHallwayDoors,
        exitDoorUnlock = exitDoorUnlock,
    }
}
