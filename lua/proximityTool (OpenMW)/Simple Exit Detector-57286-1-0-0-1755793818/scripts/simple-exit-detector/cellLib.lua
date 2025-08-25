local types = require('openmw.types')
local util = require("openmw.util")

local this = {}


local function tableCopy(tb)
    local res = {}
    for i, v in pairs(tb) do
        res[i] = v
    end
    return res
end


---@return {cell : any, position : any}[]?
---@return number? distance
---@return number? distanceInCells
function this.getExit(cell, position, distance, distanceInCells, path, checkedCells, depth)
    if not distanceInCells then distanceInCells = 0 end
    if not distance then distance = 0 end
    if not path then path = {} end
    if not checkedCells then checkedCells = {} end
    if not depth then depth = 10 end

    if depth <= 0 or checkedCells[cell.id] then return end

    depth = depth - 1
    checkedCells[cell.id] = true

    table.insert(path, {cell = cell, position = position})

    if cell.isExterior or cell:hasTag("QuasiExterior") then
        return path, distance, distanceInCells
    end

    local doors = cell:getAll(types.Door)
    if #doors <= 1 then return end

    local results = {}
    for _, door in pairs(doors) do
        if not types.Door.isTeleport(door) or not door.enabled then goto continue end

        local destCell = types.Door.destCell(door)
        local destPos = types.Door.destPosition(door)
        if not destCell or not destPos then goto continue end

        local resPath, dist, distInCell = this.getExit(destCell, destPos, distance + (destPos - door.position):length(),
            distanceInCells + 1, tableCopy(path), checkedCells, depth)

        if resPath then
            table.insert(results, {path = resPath, distance = dist, distanceInCells = distInCell})
        end

        ::continue::
    end

    if next(results) then
        table.sort(results, function (a, b)
            return a.distanceInCells < b.distanceInCells
        end)

        local resultsWithEqualDistance = {}
        for i, dt in ipairs(results) do
            if dt.distanceInCells == results[1].distanceInCells then
                table.insert(resultsWithEqualDistance, dt)
            else
                break
            end
        end

        table.sort(resultsWithEqualDistance, function (a, b)
            return a.distance < b.distance
        end)
        local res = resultsWithEqualDistance[1] or {}

        return res.path, res.distance, res.distanceInCells
    end
end


---@return {path : {cell : any, position : any}[], door : any, distance : number, distanceInCells : number}[]
function this.getExits(cell)
    local results = {}
    for _, door in pairs(cell:getAll(types.Door)) do
        if not types.Door.isTeleport(door) or not door.enabled then goto continue end

        local destCell = types.Door.destCell(door)
        local destPos = types.Door.destPosition(door)
        if not destCell or not destPos then goto continue end

        local resPath, dist, distInCell = this.getExit(destCell, destPos, 0, 0, {}, {[cell.id] = true}, 10)

        if resPath then
            table.insert(results, {door = door, path = resPath, distance = dist, distanceInCells = distInCell})
        end

        ::continue::
    end

    return results
end


return this