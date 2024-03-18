local world = require('openmw.world')
local Door = require('openmw.types').Door
local Lockable = require('openmw.types').Lockable

local stringLib = require("scripts.fancy_door_randomizer.utils.string")

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

---@type fdr.doorDB
this.storage = nil

function this.init(storage)
    this.storage = storage
end

function this.isExterior(cell)
    if cell.isExterior or cell:hasTag("QuasiExterior") then
        return true
    end
    return false
end

local function isValidPosition(position)
    local pos = position
    return not (pos == nil or (pos.x == 0 and pos.y == 0 and pos.z == 0))
end

---@param doorData fdr.doorDB
local function fillStorageFromCell(cell, doorData, storage, config)
    local excludeLocked = not config.data.allowLockedExit
    for _, door in pairs(cell:getAll(Door)) do
        local storageData = storage.getData(door.id)
        if Door.isTeleport(door) and not this.forbiddenDoorIds[door.recordId] and isValidPosition(Door.destPosition(door)) and
                door.enabled and not (excludeLocked and Lockable.isLocked(door)) and
                not (storageData and storageData.timestamp + config.data.interval * 3600 > world.getGameTime()) then
            local posExterior = this.isExterior(door.cell)
            local destExterior = this.isExterior(Door.destCell(door))
            if posExterior and destExterior then
                table.insert(doorData.ExToEx, door)
            elseif posExterior and not destExterior then
                table.insert(doorData.ExToIn, door)
            elseif not posExterior and destExterior then
                table.insert(doorData.InToEx, door)
            elseif not posExterior and not destExterior then
                table.insert(doorData.InToIn, door)
            end
        end
    end
end

---@param storage fdr.doorDataStorage
function this.fingDoors(storage, config)
    ---@class fdr.doorDB
    local out = {InToIn = {}, InToEx = {}, ExToIn = {}, ExToEx = {}}
    for _, cell in pairs(world.cells) do
        fillStorageFromCell(cell, out, storage, config)
    end
    return out
end

local function findInteriorCells(cell, cellTable, depth)
    if not depth then depth = 20 end
    if depth <= 0 then return end
    for _, door in pairs(cell:getAll(Door)) do
        if Door.isTeleport(door) then
            local dest = Door.destCell(door)
            local cellName = stringLib.getCellName(dest)
            if not this.isExterior(dest) and not cellTable[cellName] then
                cellTable[cellName] = dest
                findInteriorCells(dest, cellTable, depth - 1)
            end
        end
    end
end

local function getExteriorCell(cell, depth, list)
    if this.isExterior(cell) then
        return cell
    else
        if not depth then depth = 20 end
        if not list then list = {} end
        if depth <= 0 then return nil end
        local res
        for _, door in pairs(cell:getAll(Door)) do
            if Door.isTeleport(door) then
                local dest = Door.destCell(door)
                local cellName = stringLib.getCellName(dest)
                if not list[cellName] then
                    list[cellName] = true
                    res = getExteriorCell(dest, depth - 1, list)
                    if res then break end
                end
            end
        end
        return res
    end
end

---@return fdr.doorDB|nil
function this.findDoorsInRange(cell, range, storage, config)
    ---@class fdr.doorDB
    local out = {InToIn = {}, InToEx = {}, ExToIn = {}, ExToEx = {}}
    cell = getExteriorCell(cell)
    if not cell then return end
    local cellTable = {}
    for x = cell.gridX - range, cell.gridX + range do
        for y = cell.gridY - range, cell.gridY + range do
            local cl = world.getExteriorCell(x, y)
            if cl then
                local cellName = stringLib.getCellName(cl)
                cellTable[cellName] = cl
                findInteriorCells(cl, cellTable)
            end
        end
    end
    for name, cl in pairs(cellTable) do
        fillStorageFromCell(cl, out, storage, config)
    end
    return out
end

function this.getDoorList(door, array)
    local posExterior = this.isExterior(door.cell)
    local destExterior = this.isExterior(Door.destCell(door))
    if posExterior and destExterior then
        return array.ExToEx
    elseif posExterior and not destExterior then
        return array.ExToIn
    elseif not posExterior and destExterior then
        return array.InToEx
    elseif not posExterior and not destExterior then
        return array.InToIn
    end
end

function this.getDistance(vec1, vec2)
    return math.sqrt((vec1.x - vec2.x) ^ 2 + (vec1.y - vec2.y) ^ 2 + (vec1.z - vec2.z) ^ 2)
end

function this.getBackDoor(door)
    if Door.objectIsInstance(door) and Door.isTeleport(door) and not this.forbiddenDoorIds[door.recordId] then
        local cell = Door.destCell(door)
        if not cell then return end
        local nearestDoor = nil
        local distance = math.huge
        local doorDestPos = Door.destPosition(door)
        for _, cdoor in pairs(cell:getAll(Door)) do
            if Door.isTeleport(cdoor) then
                local distBetween = this.getDistance(doorDestPos, cdoor.position)
                if Door.isTeleport(cdoor) and not this.forbiddenDoorIds[cdoor.recordId] and distBetween < distance then
                    distance = distBetween
                    nearestDoor = cdoor
                end
            end
        end
        return nearestDoor
    end
end

return this