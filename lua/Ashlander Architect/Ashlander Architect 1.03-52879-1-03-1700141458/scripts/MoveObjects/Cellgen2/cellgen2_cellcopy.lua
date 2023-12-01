local structureData = require("scripts.MoveObjects.StructureData")
local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")

local cellcache = require("scripts.MoveObjects.Cellgen2.cellcache")
local settlementModData = storage.globalSection("AASettlements")
local posIndex = 1

local currentDestName
local function getCellToUse(template)
    return string.format("Ashlander Architect - " .. string.format("%04d", posIndex))
end
local function startsWith(str, prefix) --Checks if a string starts with another string
    return string.sub(str, 1, string.len(prefix)) == prefix
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        local rotatex = util.transform.rotateX(x)
        local rotatey = util.transform.rotateY(y)
        rotate = rotate:__mul(rotatey)
        rotate = rotate:__mul(rotatex)
        return rotate
    end
end
local function canCopyObject(obj)
    if obj.type == types.NPC then return false end
    if obj.type == types.Creature then return false end
    if obj.type == types.Container then return false end
    if obj.type.baseType == types.Item then return false end
    if obj.type == types.Activator then return false end
    if obj.enabled == false then return false end
    local recId = obj.recordId
    if string.find(recId, "furn_redoran_hearth") then
        return true
    elseif string.find(recId, "furn_de_firepit") then
        return true
    end
    if startsWith(recId, "furn") then
        return false
    elseif startsWith(recId, "flora") then
        return false
    elseif startsWith(recId, "t_imp_furn") then
        return false
    elseif startsWith(recId, "t_de_furn") then
        return false
    elseif startsWith(recId, "ab_furn") then
        return false
    elseif startsWith(recId, "t_com_furn") then
        return false
    elseif string.find(recId, "spiderweb") then
        return false
    elseif string.find(recId, "var_blood") then
        return false
    elseif startsWith(recId, "t_com_var") then
        return false
    elseif startsWith(recId, "active_com_bed") then
        return false
    elseif startsWith(recId, "active_de_be") then
        return false
    elseif startsWith(recId, "active_de_p_be") then
        return false
    elseif startsWith(recId, "terrain") then
        return false
    end
    return true
end
local function testCopyFilter(cell)
    for index, value in ipairs(cell:getAll()) do
        if not canCopyObject(value) then
            value.enabled = false
        end
    end
end
local function getPositionBehind(pos, rot, distance, direction)
    local currentRotation = -rot
    local angleOffset = 0

    if direction == "north" then
        angleOffset = math.rad(90)
    elseif direction == "south" then
        angleOffset = math.rad(-90)
    elseif direction == "east" then
        angleOffset = 0
    elseif direction == "west" then
        angleOffset = math.rad(180)
    else
        error("Invalid direction. Please specify 'north', 'south', 'east', or 'west'.")
    end

    currentRotation = currentRotation - angleOffset
    local obj_x_offset = distance * math.cos(currentRotation)
    local obj_y_offset = distance * math.sin(currentRotation)
    local obj_x_position = pos.x + obj_x_offset
    local obj_y_position = pos.y + obj_y_offset
    return util.vector3(obj_x_position, obj_y_position, pos.z)
end
local function copyCell(templateCellDataID, exteriorObjects)
    local data = structureData[templateCellDataID]
    if #data.interiors < 1 then
        error("No interior")
    end
    for index, interior in ipairs(data.interiors) do
        posIndex = posIndex + 1
        local posOffset = util.vector3(0, (posIndex * 0), 0)
        if not interior then error("No interior") end
        local sourceCell = cellcache[interior]
        local targetCell = world.getCellByName(getCellToUse(templateCellDataID))
        print(targetCell.name)
        if not sourceCell then
            print(interior)
        error("No sourceCell")

        end
        if not targetCell then

            error("No targetCell")
    
            end
        if not sourceCell or not targetCell then return end
        if currentDestName then
            I.AA_CellGen_2_Labels.setCellName(getCellToUse(templateCellDataID), currentDestName)
        else
            error("No currentDestName")
        end
        local intData = { cellName = targetCell.name, myIndex = posIndex }
        local cellPos
        for index, obj in ipairs(sourceCell) do
            local copiedObject
            local recordId = obj.recordId
            if obj.teleport then
                recordId = I.AA_Records.getDoorActivatorRecord(recordId).id
            end
            local sourcePos = util.vector3(obj.position.x, obj.position.y, obj.position.z)
            local sourceRot = createRotation(obj.rotation.x, obj.rotation.y, obj.rotation.z)
            copiedObject = world.createObject(recordId)
            copiedObject:setScale(obj.scale)
            local toPos = sourcePos + posOffset
            copiedObject:teleport(targetCell, toPos, sourceRot)
            if obj.teleport and obj.teleport.cell.name ~= interior then
                local exteriorDoor = obj.teleport.destDoor.id
                if not exteriorDoor then
                    error("Unable to find door pair")
                end
                local exteriorNewDoor
                for index, value in ipairs(exteriorObjects) do
                    local ogId = I.AA_Build_Group.getOriginalObjectID(value)
                    if ogId and ogId == exteriorDoor then
                        if not intData.settlementId then
                            intData.settlementId = I.AA_Settlements.getCurrentSettlementId(value)
                        end
                        exteriorNewDoor = value
                    else
                        print("OG"..ogId)
                        print("CheckedID",exteriorDoor)
                    end
                end
                if exteriorNewDoor then
                    local interiorPos = util.vector3(obj.teleport.destDoor.position.x, obj.teleport.destDoor.position.y,
                        obj.teleport.destDoor.position.z) + posOffset
                    local interiorRot = obj.teleport.destDoor.rotation.z
                    intData.interiorPos = interiorPos
                    local exteriorPos =util.vector3(obj.teleport.position.x, obj.teleport.position.y,
                    obj.teleport.position.z) + exteriorObjects[1].position
                    local override = I.AA_CellGen_2_CellCopy_DoorTP.getDirectionOverride()
                        [exteriorNewDoor.type.record(exteriorNewDoor).model:lower()]
                    local direction = "north"
                    local dist = 150
                    local rotOffset = 0
                    if override and override.dir then
                        direction = override.dir
                        print(direction)
                    end
                    if override and override.distance then
                        dist = override.distance
                    end
                    if override and override.rotOffset then
                        rotOffset = override.rotOffset
                    end
                    exteriorPos = getPositionBehind(exteriorNewDoor.position, exteriorNewDoor.rotation:getAnglesZYX() , dist, direction)
                    local exteriorCellLabel
                    local extCell = exteriorObjects[1].cell
                    if extCell.name == "" then
                        exteriorCellLabel = extCell.region
                    end
                    for x, structure in ipairs(settlementModData:get("settlementList")) do
                        print("Found one")
                        local dist = math.sqrt((exteriorObjects[1].position.x - structure.settlementCenterx) ^ 2 +
                            (exteriorObjects[1].position.y - structure.settlementCentery) ^ 2 +
                            (exteriorObjects[1].position.z - structure.settlementCenterz) ^ 2)
                        if (dist < structure.settlementDiameter / 2) then
                            exteriorCellLabel = structure.settlementName
                        end
                    end
                    I.AA_CellGen_2_CellCopy_DoorTP.registerDoorPair(
                        {
                            sourceObj = copiedObject.id,
                            targObj = exteriorNewDoor.id,
                            targetPosition = exteriorPos,
                            targetRotation =
                                exteriorNewDoor.rotation:getAnglesZYX() + math.rad(180) + math.rad(rotOffset),
                            targetCell = world.players[1].cell.name,
                            targetLabel = exteriorCellLabel,
                            intIndex = posIndex

                        },
                        {
                            sourceObj = exteriorNewDoor.id,
                            targObj = copiedObject.id,
                            targetPosition = interiorPos,
                            targetRotation = interiorRot,
                            targetCell = targetCell.name,
                            intIndex = posIndex
                        })
                else
                    print(#exteriorObjects)
                    error("unable to find exteriorNewDoor")
                end
            elseif obj.teleport and obj.teleport.cell.name == interior then
                local targPos = util.vector3(obj.teleport.position.x, obj.teleport.position.y, obj.teleport.position.z)
                I.AA_CellGen_2_CellCopy_DoorTP.registerDoor(
                    {
                        sourceObj = copiedObject.id,
                        targObj = obj.teleport.destDoor.id,
                        targetPosition = targPos + posOffset,
                        targetRotation =
                            obj.teleport.rotation.z,
                        targetCell = targetCell.name,
                        targetLabel = "",
                        intIndex = posIndex

                    })
            end
        end
        I.AA_CellGen_2.saveCellGenData(intData)
        --
    end
end
return {
    interfaceName = "AA_CellGen_2_CellCopy",
    interface = {
        version = 1,
        copyCell = copyCell,
        testCopyFilter = testCopyFilter,
        canCopyObject = canCopyObject,
    },
    eventHandlers = {
        setCurrentDestName = function(data) currentDestName = data end
    },
    engineHandlers = {
        onSave = function() return { posIndex = posIndex } end,
        onLoad = function(data)
            if not data then return end
            posIndex = data.posIndex
        end
    }
}
