local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
local log = include("Morrowind_World_Randomizer.log")

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
            if not door.deleted and not door.disabled and not door.baseObject.script and not this.forbiddenDoorIds[door.id:lower()] and isValidDestination(door.destination) then
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


function this.isTimeExpiered(reference)
    local data = dataSaver.getObjectData(reference)
    if data ~= nil and (data.doorCDTimestamp == nil or data.doorCDTimestamp < tes3.getSimulationTimestamp()) then
        return true
    end
    return false
end

function this.setCDTime(reference, addTime)
    if reference then
        local cd = addTime and addTime or this.config.data.doors.cooldown
        dataSaver.getObjectData(reference).doorCDTimestamp = tes3.getSimulationTimestamp() + cd
    end
end

local function findingCells_asEx(cells, cell, depth)
    depth = depth - 1
    if depth >= 0 then
        if cell.behavesAsExterior then
            cells[cell.editorName] = cell
            for door in cell:iterateReferences(tes3.objectType.door) do
                if door.destination and not cells[door.destination.cell.editorName] then
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
            cells[cell.editorName] = cell
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
            cells[cell.editorName] = cell
            for door in cell:iterateReferences(tes3.objectType.door) do
                if door.destination and not cells[door.destination.cell.editorName] then
                    findingCells_In(cells, door.destination.cell, depth)
                end
            end
        end
    end
end

local function saveDoorOrigDestination(reference)
    if reference == nil or reference.destination == nil then
        return
    end
    local data = dataSaver.getObjectData(reference)
    if data.origDestination == nil then
        local cellData = {id = reference.destination.cell.isInterior and reference.destination.cell.editorName or nil,
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
    elseif reference.destination then
        local marker = reference.destination.marker
        return {cell = reference.destination.cell, marker = {
            position = tes3vector3.new(marker.position.x, marker.position.y, marker.position.z),
            orientation = tes3vector3.new(0, 0, marker.orientation.z)}}
    end
end

local function getBackDoorFromReference(reference)
    if reference and reference.destination then
        local origDestinationData = getDoorOriginalDestinationData(reference)
        if origDestinationData ~= nil then
            local nearestDoor
            local minDistance = math.huge
            for door in origDestinationData.cell:iterateReferences(tes3.objectType.door) do
                if door.destination then
                    local distance = door.position:distance(origDestinationData.marker.position)
                    if minDistance > distance then
                        nearestDoor = door
                        minDistance = distance
                    end
                end
            end
            return nearestDoor
        end
    end
    return nil
end

local function findDoorCellData_InToIn(cellData, cell, step)
    step = step + 1
    if not cell.isOrBehavesAsExterior then
        cellData[cell.editorName] = {step = step, doors = {}, hasExit = false}
        local data = cellData[cell.editorName]
        for door in cell:iterateReferences(tes3.objectType.door) do
            if not door.deleted and not door.disabled and not door.baseObject.script and
                    isValidDestination(door.destination) and this.isTimeExpiered(door) then
                local destination = getDoorOriginalDestinationData(door)
                if destination.cell.isOrBehavesAsExterior then
                    data.hasExit = true
                else
                    local marker = destination.marker
                    table.insert(data.doors, {door = door, backDoor = getBackDoorFromReference(door), cell = destination.cell,
                        marker = {position = tes3vector3.new(marker.position.x, marker.position.y, marker.position.z),
                        orientation = tes3vector3.new(marker.orientation.x, marker.orientation.y, marker.orientation.z)}})
                end
                if not cellData[destination.cell.editorName] then
                    findDoorCellData_InToIn(cellData, destination.cell, step)
                end
            end
        end
        if #data.doors == 0 then
            cellData[cell.editorName] = nil
        end
    end
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function isCanFindExit(cellData, cellEditorName, iteraction, pathTable)
    if iteraction > 0 and cellData[cellEditorName] then
        if cellData[cellEditorName].hasExit then
            return true
        else
            pathTable[cellEditorName] = true
            if #cellData[cellEditorName].doors > 0 then
                for i, data in pairs(cellData[cellEditorName].doors) do
                    if not pathTable[data.cell.editorName] and isCanFindExit(cellData, data.cell.editorName, iteraction - 1, pathTable) then
                        return true
                    end
                end
                return false
            else
                return false
            end
        end
    end
    return false
end

local function findBackDoorData(cellData)
    for cellName, cdata in pairs(cellData) do
        for _, doorData in pairs(cdata.doors) do
            if doorData.backDoor then
                local destCellData = cellData[doorData.backDoor.cell.editorName]
                if destCellData then
                    for _, fDoorData in pairs(destCellData.doors) do
                        if fDoorData.door == doorData.backDoor then
                            doorData.backDoorData = deepcopy(fDoorData)
                        end
                    end
                end
            end
        end
    end
end

local function removeFromTable(fromTable, varName, valToRemove, once)
    for pos, name in pairs(fromTable) do
        if (varName ~= nil and name[varName] == valToRemove) or
                name == valToRemove then
            table.remove(fromTable, pos)
            if once then break end
        end
    end
end

local function randomizeSmart_InToIn(cellData)
    local newData = deepcopy(cellData)
    local newFullData = {}
    local cellNames = {}
    for cellName, cdata in pairs(cellData) do
        table.insert(cellNames, cellName)
    end

    for cellName, cdata in pairs(newData) do
        for i, doorData in pairs(cdata.doors) do
            if this.config.data.doors.chance >= math.random() then
                for j = 1, 20 do
                    local randCellId = math.random(1, #cellNames)
                    local rndCellName = cellNames[randCellId]
                    if not rndCellName then table.remove(cellNames, randCellId) end --fast bug fix
                    if rndCellName and not (#cdata.doors == 1 and #cellData[rndCellName].doors == 1) then
                        local rndDoorData = newData[rndCellName].doors[math.random(1, #newData[rndCellName].doors)]

                        if this.config.data.doors.smartInToInRandomization.backDoorMode then
                            local backDoorData1 = doorData.backDoorData
                            local backDoorData2 = rndDoorData.backDoorData

                            if backDoorData1 and backDoorData2 then
                                local bDoorCellName1 = backDoorData1.door.cell.editorName
                                local bDoorCellName2 = backDoorData2.door.cell.editorName
                                --create all necessary tables
                                if newFullData[cellName] == nil then newFullData[cellName] = {step = cdata.step, doors = {}, hasExit = cdata.hasExit} end
                                if newFullData[rndCellName] == nil then newFullData[rndCellName] = {step = newData[rndCellName].step, doors = {},
                                    hasExit = newData[rndCellName].hasExit} end
                                if newFullData[bDoorCellName1] == nil then newFullData[bDoorCellName1] =
                                    {step = newData[bDoorCellName1].step, doors = {}, hasExit = newData[bDoorCellName1].hasExit} end
                                if newFullData[bDoorCellName2] == nil then newFullData[bDoorCellName2] =
                                    {step = newData[bDoorCellName2].step, doors = {}, hasExit = newData[bDoorCellName2].hasExit} end

                                --add new door destinations
                                table.insert(newFullData[cellName].doors, {door = doorData.door, cell = rndDoorData.cell, marker = {
                                    position = rndDoorData.marker.position, orientation = rndDoorData.marker.orientation}})
                                table.insert(newFullData[rndCellName].doors, {door = rndDoorData.door, cell = doorData.cell, marker = {
                                    position = doorData.marker.position, orientation = doorData.marker.orientation}})

                                table.insert(newFullData[bDoorCellName1].doors, {door = backDoorData1.door, cell = backDoorData2.cell, marker = {
                                    position = backDoorData2.marker.position, orientation = backDoorData2.marker.orientation}})
                                table.insert(newFullData[bDoorCellName2].doors, {door = backDoorData2.door, cell = backDoorData1.cell, marker = {
                                    position = backDoorData1.marker.position, orientation = backDoorData1.marker.orientation}})

                                --delete to prevent re-randomization
                                if #newData[rndCellName].doors > 1 then
                                    removeFromTable(newData[rndCellName].doors, "door", rndDoorData.door)
                                else
                                    table.remove(cellNames, randCellId)
                                end
                                if #newData[cellName].doors > 1 then
                                    table.remove(newData[cellName].doors, i)
                                else
                                    removeFromTable(cellNames, nil, cellName)
                                end
                                if #newData[bDoorCellName1].doors > 1 then
                                    removeFromTable(newData[bDoorCellName1].doors, "door", backDoorData1.door)
                                else
                                    removeFromTable(cellNames, nil, bDoorCellName1)
                                end
                                if #newData[bDoorCellName2].doors > 1 then
                                    removeFromTable(newData[bDoorCellName2].doors, "door", backDoorData2.door)
                                else
                                    removeFromTable(cellNames, nil, bDoorCellName2)
                                end

                            end
                        else
                            if newFullData[cellName] == nil then newFullData[cellName] = {step = cdata.step, doors = {}, hasExit = cdata.hasExit} end
                            table.insert(newFullData[cellName].doors, {door = doorData.door, cell = rndDoorData.cell, marker = {
                                position = rndDoorData.marker.position, orientation = rndDoorData.marker.orientation}})

                            if #newData[rndCellName].doors > 1 then
                                removeFromTable(newData[rndCellName].doors, "door", rndDoorData.door)
                            else
                                table.remove(cellNames, randCellId)
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    for cellName, cdata in pairs(newData) do
        if newFullData[cellName] == nil then newFullData[cellName] = {step = cdata.step, doors = {}, hasExit = cdata.hasExit} end
        for i, doorData in pairs(cdata.doors) do
            table.insert(newFullData[cellName].doors, doorData)
        end
    end
    local canFindExit = true
    for cellName, cdata in pairs(newFullData) do
        if not isCanFindExit(newFullData, cellName, this.config.data.doors.smartInToInRandomization.cellDepth, {}) then
            canFindExit = false
        end
    end
    if not canFindExit then
        return nil
    end
    return newFullData
end

local function replaceDoorDestinations(door1, door2)
    if door1 and door2 and not this.forbiddenDoorIds[door1.baseObject.id:lower()] and
            not this.forbiddenDoorIds[door2.baseObject.id:lower()] then
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

            this.setCDTime(door1)
            this.setCDTime(door2)

            log("Door destination swap %s (%s (%s, %s, %s)) %s (%s (%s, %s, %s))", tostring(door1), tostring(oldDoorCell),
                tostring(oldDoorPos.x), tostring(oldDoorPos.y), tostring(oldDoorPos.z), tostring(door2),
                tostring(newDoorCell), tostring(newDoorPos.x), tostring(newDoorPos.y), tostring(newDoorPos.z))

            tes3.setDestination{ reference = door1, position = newDoorPos, orientation = newDoorOrient, cell = newDoorCell }
            tes3.setDestination{ reference = door2, position = oldDoorPos, orientation = oldDoorOrient, cell = oldDoorCell }
        end
    end
end

local function setDoorDestination(door, newCell, newMark)
    if door and newCell and newMark and not this.forbiddenDoorIds[door.baseObject.id:lower()] then
        saveDoorOrigDestination(door)
        local doorDest = door.destination

        log("Door destination %s (%s (%s, %s, %s)) to (%s (%s, %s, %s))", tostring(door), tostring(doorDest.cell),
            tostring(doorDest.marker.position.x), tostring(doorDest.marker.position.y), tostring(doorDest.marker.position.z),
            tostring(newCell), tostring(newMark.position.x), tostring(newMark.position.y), tostring(newMark.position.z))

        this.setCDTime(door)
        tes3.setDestination{ reference = door, position = newMark.position, orientation = newMark.orientation, cell = newCell }
    end
end

function this.randomizeDoor(reference)
    if not this.forbiddenDoorIds[reference.baseObject.id:lower()] and this.config.data.doors.randomize and
            this.isTimeExpiered(reference) and reference.object.objectType == tes3.objectType.door and reference.destination ~= nil and
            not (this.config.data.doors.doNotRandomizeInToIn and not reference.cell.isOrBehavesAsExterior and
            not reference.destination.cell.isOrBehavesAsExterior) then

        local doors = {}

        if this.config.data.doors.chance >= math.random() then

            saveDoorOrigDestination(reference)

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
                            if door.destination and not door.deleted and not door.disabled and not door.baseObject.script then
                                for ndoor in door.destination.cell:iterateReferences(tes3.objectType.door) do
                                    if isValidDestination(ndoor.destination) and ndoor.destination.cell.editorName == cell.editorName and
                                            not ndoor.deleted and not ndoor.disabled and not ndoor.baseObject.script then
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
                            if isValidDestination(door.destination) and not door.disabled and not door.destination.cell.isOrBehavesAsExterior and
                                    not door.deleted and not door.disabled and not door.baseObject.script then
                                local newDoorData = dataSaver.getObjectData(door)
                                if (newDoorData and not this.forbiddenDoorIds[door.baseObject.id:lower()] and
                                        (newDoorData.doorCDTimestamp == nil or newDoorData.doorCDTimestamp < tes3.getSimulationTimestamp())) then
                                    table.insert(doors, door)
                                end
                            end
                        end
                    end

                elseif not reference.cell.isOrBehavesAsExterior and not reference.destination.cell.isOrBehavesAsExterior and
                        not this.config.data.doors.smartInToInRandomization.enabled and not this.config.data.doors.doNotRandomizeInToIn then
                    local cellsToCheck = {}

                    findingCells_In(cellsToCheck, reference.destination.cell, this.config.data.doors.nearestCellDepth)

                    for cellId, cell in pairs(cellsToCheck) do
                        for door in cell:iterateReferences(tes3.objectType.door) do
                            if door.destination and not door.deleted and not door.disabled and not door.baseObject.script then
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
        else
            local backDoor = getBackDoorFromReference(reference)
            if backDoor then
                this.setCDTime(backDoor)
            end
            this.setCDTime(reference)
        end

        local newDoor
        local backDoor
        local newBackDoor
        if #doors > 0 then
            newDoor = doors[math.random(1, #doors)]

            local shouldChangeReverseDoor = (reference.cell.isOrBehavesAsExterior == reference.destination.cell.isOrBehavesAsExterior) and false or true
            if newDoor ~= reference then
                if shouldChangeReverseDoor then
                    backDoor = getBackDoorFromReference(reference)
                    newBackDoor = getBackDoorFromReference(newDoor)

                    if backDoor and newBackDoor then
                        replaceDoorDestinations(backDoor, newBackDoor)
                    end
                end

                replaceDoorDestinations(reference, newDoor)
            end
        end

        --smart door randomizing
        if this.config.data.doors.onlyNearest and this.config.data.doors.smartInToInRandomization.enabled and not this.config.data.doors.doNotRandomizeInToIn and
                reference.cell.isOrBehavesAsExterior and not reference.destination.cell.isOrBehavesAsExterior then

            local initialCell = reference.cell
            if newBackDoor then
                initialCell = newBackDoor.destination.cell
            end
            local cellsToCheck = {}
            if initialCell.behavesAsExterior then
                findingCells_asEx(cellsToCheck, initialCell, this.config.data.doors.nearestCellDepth)
            else
                findingCells_Ex(cellsToCheck, initialCell, this.config.data.doors.nearestCellDepth)
            end

            local intrCells = {}
            for cellId, cell in pairs(cellsToCheck) do
                for door in cell:iterateReferences(tes3.objectType.door) do
                    if not door.deleted and not door.disabled and not door.baseObject.script and isValidDestination(door.destination) and
                            not door.destination.cell.isOrBehavesAsExterior then
                        intrCells[door.destination.cell.editorName] = door.destination.cell
                    end
                end
            end

            local cellData = {}
            for name, cell in pairs(intrCells) do
                findDoorCellData_InToIn(cellData, cell, 0)
            end
            findBackDoorData(cellData)

            for i = 1, this.config.data.doors.smartInToInRandomization.iterations do
                log("Searching for a doors pattern "..tostring(i))
                local randData = randomizeSmart_InToIn(cellData)
                if randData then
                    for cellEditorName, cellDoorData in pairs(randData) do
                        for _, doorData in pairs(cellDoorData.doors) do
                            this.setCDTime(doorData.door)
                        end
                    end
                    log("The doors pattern found "..tostring(i))
                    for cellEditorName, cellDoorData in pairs(randData) do
                        for _, doorData in pairs(cellDoorData.doors) do
                            setDoorDestination(doorData.door, doorData.cell, doorData.marker)
                        end
                    end
                    break
                end
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