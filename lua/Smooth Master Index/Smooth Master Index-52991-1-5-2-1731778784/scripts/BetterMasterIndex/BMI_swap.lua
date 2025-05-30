local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local function teleport(ob, pos, rot,xcell)
    local cell = xcell or world.players[1].cell --hack
    ob:teleport(cell, pos, rot)
end
local function swapObjects(ob1, ob2)
    local ob1Pos = ob1.position
    local ob1Rot = ob1.rotation
    local ob2Pos = ob2.position
    local ob2Rot = ob2.rotation
    teleport(ob1, ob2Pos, ob2Rot,ob1.cell)
    teleport(ob2, ob1Pos, ob1Rot,ob1.cell)
end
local function findObjectInCell(cellName, obId)
    local cell = world.getCellByName(cellName)

    for index, value in ipairs(cell:getAll(types.Activator)) do
        if (value.recordId == obId) then return value end
    end
end
local function getRecord(id)
    for index, value in ipairs(types.Miscellaneous.records) do
        if (value.id == id) then return value end
    end
    print("No record for " .. id)
    return nil
end
local function placeIfNotFound(objectId, cellName, position)
    local record = (getRecord(objectId))
    if (record == nil) then return nil end
    local cell = world.getCellByName(cellName)
    for index, value in ipairs(cell:getAll(types.Miscellaneous)) do
        if (value.recordId == objectId:lower()) then return nil end
    end
    --print("Placing ", objectId)
    local newOb = world.createObject(objectId)
    teleport(newOb, position)
    return newOb
end
local function placeOrb()
    if not core.contentFiles.has("Tamriel_data.esm") then
        return
    end
    local ret = {}
    table.insert(ret,
        placeIfNotFound("t_com_crystalball_01",
            "Caldera, Guild of Mages",
            util.vector3(793.762, 570.143, 232.457)))
    table.insert(ret,
        placeIfNotFound("t_com_crystalballstand_01",
            "Caldera, Guild of Mages",
            util.vector3(793.762, 570.143, 232.457)))
    return ret
end
local swapDone = false
local function swapBroken(force)
    if (swapDone and not force) then return end
    local cell = "Indoranyon, Propylon Chamber"
    local ob1 = findObjectInCell(cell, "active_port_roth")
    local ob2 = findObjectInCell(cell, "active_port_falen")
    swapObjects(ob1, ob2)

    cell = "Andasreth, Propylon Chamber"
    ob1 = findObjectInCell(cell, "active_port_hlor")
    ob2 = findObjectInCell(cell, "active_port_beran")
    swapObjects(ob1, ob2)
    swapDone = true
    print("Did the swap.")
end
local function onSave()
    return { swapDone = swapDone }
end
local function onLoad(data)
    if not data then return end

    swapDone = data.swapDone
end
return {
    interfaceName = "zhac_BMI_swap",
    interface = {
        version = 1,
        swapObjects = swapObjects,
        swapBroken = swapBroken,
        placeOrb = placeOrb
    },
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = { swapBroken = swapBroken }
}
