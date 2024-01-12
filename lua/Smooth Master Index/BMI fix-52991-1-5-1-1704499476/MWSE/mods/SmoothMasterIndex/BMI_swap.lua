ZackBridge = require("SmoothMasterIndex.scripts.SmoothMasterIndex.zackbridge")
local function teleport(ob, pos, rot)
    tes3.positionCell({
        reference  = ob,
        cell = ob.cell,
        position = pos,
        orientation = rot
    })
end
local function swapObjects(obx1, obx2)
    local ob1Pos =ZackBridge.vector3(  obx1.position.x,obx1.position.y,obx1.position.z)
    local ob1Rot =ZackBridge.vector3(  obx1.orientation.x,obx1.orientation.y,obx1.orientation.z)
    local ob2Pos =ZackBridge.vector3(  obx2.position.x,obx2.position.y,obx2.position.z)
    local ob2Rot =ZackBridge.vector3(  obx2.orientation.x,obx2.orientation.y,obx2.orientation.z)
    teleport(obx1, ob2Pos, ob2Rot)
    teleport(obx2, ob1Pos, ob1Rot)
end
local function findObjectInCell(cellName, obId, type)
    local cell = ZackBridge.getCell(cellName)

    for index, value in ipairs(ZackBridge.getObjectsInCell(cell, type)) do
        if (value.id:lower() == obId) then return value end
    end
end
local function getRecord(id) return tes3.getObject(id) end
local function placeIfNotFound(objectId, cellName, position)
    local record = (getRecord(objectId))
    if (record == nil) then return nil end
    local cell = ZackBridge.getCell(cellName)
    for index, value in ipairs(
                            ZackBridge.getObjectsInCell(cell, "Miscellaneous")) do
        if (value.id:lower() == objectId:lower()) then return nil end
    end
    print("Placing ".. objectId)
    local newOb = tes3.createReference({
        object = objectId,
        position = position,
        cell = cellName,
        orientation = ZackBridge.vector3(0, 0, 0)
    })

    return newOb
end
local function placeOrb()
    local ret = {}
    table.insert(ret,
                 placeIfNotFound("t_com_crystalball_01",
                                 "Caldera, Guild of Mages",
                                 ZackBridge.vector3(793.762, 570.143, 232.457)))
    table.insert(ret,
                 placeIfNotFound("t_com_crystalballstand_01",
                                 "Caldera, Guild of Mages",
                                 ZackBridge.vector3(793.762, 570.143, 232.457)))
    return ret
end
local swapDone = false
local function swapBroken(cellName)
    -- if (swapDone) then return end

    local cell1 = "Indoranyon, Propylon Chamber"

    local cell2 = "Andasreth, Propylon Chamber"
    local ob1, ob2
    if (cellName == cell1) then
        ob1 = findObjectInCell(cell1, "active_port_roth", "Activator")
        ob2 = findObjectInCell(cell1, "active_port_falen", "Activator")

        swapObjects(ob1, ob2)
    elseif (cellName == cell2) then
        ob1 = findObjectInCell(cell2, "active_port_hlor", "Activator")
        ob2 = findObjectInCell(cell2, "active_port_beran", "Activator")

        swapObjects(ob1, ob2)
    else
    end
    swapDone = true
end
return {
    interfaceName = "zhac_BMI_swap",
    interface = {
        version = 1,
        swapObjects = swapObjects,
        swapBroken = swapBroken,
        placeOrb = placeOrb
    }
}
