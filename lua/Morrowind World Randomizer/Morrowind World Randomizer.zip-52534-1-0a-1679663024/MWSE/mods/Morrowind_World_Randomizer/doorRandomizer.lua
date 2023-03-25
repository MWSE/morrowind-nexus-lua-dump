local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
local log = require("Morrowind_World_Randomizer.log")

local this = {}

this.forbiddenDoorIds = {
    ["chargen customs door"] = true,
    ["chargen door captain"] = true,
    ["chargen door exit"] = true,
    ["chargen door hall"] = true,
    ["chargen exit door"] = true,
    ["chargen_cabindoor"] = true,
    ["chargen_ship_trapdoor"] = true,
    ["chargen_shipdoor"] = true,
    ["chargendoorjournal"] = true,
}

this.config = nil

this.doorsData = {All = {}, InToIn = {}, InToEx = {}, ExToIn = {}, ExToEx = {}}

function this.initConfig(config)
    this.config = config
end

local function isValidDestination(destination)
    if destination == nil or destination.marker == nil then return false end
    local pos = destination.marker.position
    local rot = destination.marker.orientation
    return not (pos == nil or rot == nil or (pos.x == 0 and pos.y == 0 and pos.z == 0 and rot.x == 0 and rot.y == 0 and rot.z == 0))
end

function this.findDoors()
    log("Door list generation...", tostring(os.time()))
    this.doorsData = {All = {}, InToIn = {}, InToEx = {}, ExToIn = {}, ExToEx = {}}

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for door in cell:iterateReferences(tes3.objectType.door) do
            if not door.deleted and not door.disabled and not door.script and not this.forbiddenDoorIds[door.id:lower()] and isValidDestination(door.destination) then
                local destIsEx = door.destination.cell.isOrBehavesAsExterior
                local isEx = door.cell.isOrBehavesAsExterior
                if isEx and destIsEx then
                    table.insert(this.doorsData.ExToEx, door)
                elseif not isEx and destIsEx then
                    table.insert(this.doorsData.InToEx, door)
                elseif not isEx and not destIsEx then
                    table.insert(this.doorsData.InToIn, door)
                elseif isEx and not destIsEx then
                    table.insert(this.doorsData.ExToIn, door)
                end
                table.insert(this.doorsData.All, door)
            end
        end
    end

    log("Door list: InToIn = %i, InToEx = %i, ExToIn = %i, ExToEx = %i", #this.doorsData.InToIn, #this.doorsData.InToEx, #this.doorsData.ExToIn, #this.doorsData.ExToEx)
end


local function findingCells_asEx(cells, cell, depth)
    depth = depth - 1
    if depth >= 0 then
        if cell.behavesAsExterior then
            cells[cell.id] = cell
            for door in cell:iterateReferences(tes3.objectType.door) do
                if door.destination and not cells[door.destination.cell.id] then
                    findingCells_asEx(cells, door.destination.cell, depth)
                end
            end
        end
    end
end

local function findingCells_Ex(cells, cell, depth)
    depth = depth - 1
    if depth >= 0 and cell then
        if cell.isOrBehavesAsExterior then
            cells[cell.id] = cell
            for i = cell.gridX - 1, cell.gridX + 1 do
                for j = cell.gridY - 1, cell.gridY + 1 do
                    findingCells_asEx(cells, tes3.getCell{x = i, y = j}, depth)
                end
            end
        end
    end
end

local function findingCells_In(cells, cell, depth)
    depth = depth - 1
    if depth >= 0 and cell then
        if not cell.isOrBehavesAsExterior then
            cells[cell.id] = cell
            for door in cell:iterateReferences(tes3.objectType.door) do
                if door.destination and not cells[door.destination.cell.id] then
                    findingCells_In(cells, door.destination.cell, depth)
                end
            end
        end
    end
end

local function saveDoorOrigDestination(reference)
    local data = dataSaver.getObjectData(reference)
    if data.origDestination == nil then
        local cellData = {id = reference.destination.cell.isInterior and reference.destination.cell.id or nil,
            x = reference.destination.cell.gridX, y = reference.destination.cell.gridY}
        data.origDestination = {x = reference.destination.marker.position.x, y = reference.destination.marker.position.y,
            z = reference.destination.marker.position.z, rotZ = reference.destination.marker.orientation.z, cell = cellData}
    end
end

local function getDoorOriginalDestinationData(reference)
    local data = dataSaver.getObjectData(reference)
    if data.origDestination ~= nil then
        local dest = data.origDestination
        local cell
        if dest.cell.id == nil then
            cell = tes3.getCell{ x = dest.cell.x, y = dest.cell.y }
        else
            cell = tes3.getCell{ id = dest.cell.id }
        end
        return {cell = cell, marker = {position = tes3vector3.new(dest.x, dest.y, dest.z), orientation = tes3vector3.new(0, 0, dest.rotZ)}}
    else
        local marker = reference.destination.marker
        return {cell = reference.destination.cell, marker = {
            position = tes3vector3.new(marker.position.x, marker.position.y, marker.position.z),
            orientation = tes3vector3.new(0, 0, marker.orientation.z)}}
    end
    return nil
end

local function getBackDoorFromReference(reference)
    if reference and reference.destination then
        local origDestinationData = getDoorOriginalDestinationData(reference)
        if origDestinationData ~= nil then
            local nearestDoor
            local minDistance = math.huge
            for door in origDestinationData.cell:iterateReferences(tes3.objectType.door) do
                local distance = door.position:distance(origDestinationData.marker.position)
                if minDistance > distance then
                    nearestDoor = door
                    minDistance = distance
                end
            end
            return nearestDoor
        end
    end
    return nil
end

local function replaceDoorDestinations(door1, door2)
    if door1 and door2 then
        saveDoorOrigDestination(door1)
        saveDoorOrigDestination(door2)
        local door1OrigDestData = getDoorOriginalDestinationData(door1)
        local door2OrigDestData = getDoorOriginalDestinationData(door2)
        if door1OrigDestData and door2OrigDestData then
            local oldDoorCell = door1OrigDestData.cell
            local oldDoorOrient = door1OrigDestData.marker.orientation
            local oldDoorPos = door1OrigDestData.marker.position
            local newDoorCell = door2OrigDestData.cell
            local newDoorOrient = door2OrigDestData.marker.orientation
            local newDoorPos = door2OrigDestData.marker.position

            dataSaver.getObjectData(door1).doorCDTimestamp = tes3.getSimulationTimestamp() + this.config.data.doors.cooldown
            dataSaver.getObjectData(door2).doorCDTimestamp = tes3.getSimulationTimestamp() + this.config.data.doors.cooldown

            log("Door destination %s (%s (%s, %s, %s)) %s (%s (%s, %s, %s))", tostring(door1), tostring(oldDoorCell),
                tostring(oldDoorPos.x), tostring(oldDoorPos.y), tostring(oldDoorPos.z), tostring(door2),
                tostring(newDoorCell), tostring(newDoorPos.x), tostring(newDoorPos.y), tostring(newDoorPos.z))

            tes3.setDestination{ reference = door1, position = newDoorPos, orientation = newDoorOrient, cell = newDoorCell }
            tes3.setDestination{ reference = door2, position = oldDoorPos, orientation = oldDoorOrient, cell = oldDoorCell }
        end
    end
end

function this.randomizeDoor(reference)
    local data = dataSaver.getObjectData(reference)
    if not this.forbiddenDoorIds[reference.baseObject.id:lower()] and this.config.data.doors.randomize and this.config.data.doors.chance >= math.random() and
            data ~= nil and (data.doorCDTimestamp == nil or data.doorCDTimestamp < tes3.getSimulationTimestamp()) and
            reference.object.objectType == tes3.objectType.door and reference.destination ~= nil then

        saveDoorOrigDestination(reference)

        local shouldChangeReverseDoor = (reference.cell.isOrBehavesAsExterior == reference.destination.cell.isOrBehavesAsExterior) and false or true

        local doors = {}
        if this.config.data.doors.onlyNearest then
            
            if reference.destination.cell.isOrBehavesAsExterior then
                local cellsToCheck = {}
                if reference.destination.cell.behavesAsExterior then
                    findingCells_asEx(cellsToCheck, reference.destination.cell, this.config.data.doors.nearestCellDepth)
                else
                    findingCells_Ex(cellsToCheck, reference.destination.cell, this.config.data.doors.nearestCellDepth)
                end

                for cellId, cell in pairs(cellsToCheck) do
                    for door in cell:iterateReferences(tes3.objectType.door) do
                        if door.destination then
                            for ndoor in door.destination.cell:iterateReferences(tes3.objectType.door) do
                                if isValidDestination(ndoor.destination) and ndoor.destination.cell.id == cell.id then
                                    local newDoorData = dataSaver.getObjectData(ndoor)
                                    if (newDoorData and not this.forbiddenDoorIds[ndoor.baseObject.id:lower()] and
                                            (newDoorData.doorCDTimestamp == nil or newDoorData.doorCDTimestamp < tes3.getSimulationTimestamp())) then
                                        table.insert(doors, ndoor)
                                    end
                                end
                            end
                        end
                    end
                end
            elseif reference.cell.isOrBehavesAsExterior and not reference.destination.cell.isOrBehavesAsExterior then
                local cellsToCheck = {}
                if reference.cell.behavesAsExterior then
                    findingCells_asEx(cellsToCheck, reference.cell, this.config.data.doors.nearestCellDepth)
                else
                    findingCells_Ex(cellsToCheck, reference.cell, this.config.data.doors.nearestCellDepth)
                end

                for cellId, cell in pairs(cellsToCheck) do
                    for door in cell:iterateReferences(tes3.objectType.door) do
                        if isValidDestination(door.destination) then
                            local newDoorData = dataSaver.getObjectData(door)
                            if (newDoorData and not this.forbiddenDoorIds[door.baseObject.id:lower()] and
                                    (newDoorData.doorCDTimestamp == nil or newDoorData.doorCDTimestamp < tes3.getSimulationTimestamp())) then
                                table.insert(doors, door)
                            end
                        end
                    end
                end

            elseif not reference.cell.isOrBehavesAsExterior and not reference.destination.cell.isOrBehavesAsExterior then
                local cellsToCheck = {}

                findingCells_In(cellsToCheck, reference.destination.cell, this.config.data.doors.nearestCellDepth)

                for cellId, cell in pairs(cellsToCheck) do
                    for door in cell:iterateReferences(tes3.objectType.door) do
                        if door.destination then
                            local newDoorData = dataSaver.getObjectData(door)
                            if (newDoorData and not this.forbiddenDoorIds[door.baseObject.id:lower()] and
                                    (newDoorData.doorCDTimestamp == nil or newDoorData.doorCDTimestamp < tes3.getSimulationTimestamp())) then
                                table.insert(doors, door)
                            end
                        end
                    end
                end
            end
        else
            local newDoor
            if reference.destination.cell.isOrBehavesAsExterior and reference.cell.isOrBehavesAsExterior then
                if #this.doorsData.ExToEx > 0 then newDoor = this.doorsData.ExToEx[math.random(1, #this.doorsData.ExToEx)] end
            elseif reference.destination.cell.isOrBehavesAsExterior and not reference.cell.isOrBehavesAsExterior then
                if #this.doorsData.InToEx > 0 then newDoor = this.doorsData.InToEx[math.random(1, #this.doorsData.InToEx)] end
            elseif not reference.destination.cell.isOrBehavesAsExterior and reference.cell.isOrBehavesAsExterior then
                if #this.doorsData.ExToIn > 0 then newDoor = this.doorsData.ExToIn[math.random(1, #this.doorsData.ExToIn)] end
            elseif not reference.destination.cell.isOrBehavesAsExterior and not reference.cell.isOrBehavesAsExterior then
                if #this.doorsData.InToIn > 0 then newDoor = this.doorsData.InToIn[math.random(1, #this.doorsData.InToIn)] end
            end

            if newDoor then
                table.insert(doors, newDoor)
            end
        end

        if #doors > 0 then
            local newDoor = doors[math.random(1, #doors)]

            if newDoor ~= reference then
                if shouldChangeReverseDoor then
                    local backDoor = getBackDoorFromReference(reference)
                    local newBackDoor = getBackDoorFromReference(newDoor)

                    if backDoor and newBackDoor then
                        replaceDoorDestinations(backDoor, newBackDoor)
                    end
                end

                replaceDoorDestinations(reference, newDoor)
            end
        end
    end
end

function this.resetDoorDestination(reference)
    local data = dataSaver.getObjectData(reference)
    if this.config.data.doors.restoreOriginal and data ~= nil and data.doorCDTimestamp ~= nil and data.doorCDTimestamp < tes3.getSimulationTimestamp() and
            reference.object.objectType == tes3.objectType.door and reference.destination ~= nil and data.origDestination ~= nil then
        local cell
        local dest = data.origDestination
        if dest.cell.id == nil then
            cell = tes3.getCell{ x = dest.cell.x, y = dest.cell.y }
        else
            cell = tes3.getCell{ id = dest.cell.id }
        end

        tes3.setDestination{ reference = reference, position = tes3vector3.new(dest.x, dest.y, dest.z),
            orientation = tes3vector3.new(0, 0, dest.rotZ), cell = cell }
    end
end

return this