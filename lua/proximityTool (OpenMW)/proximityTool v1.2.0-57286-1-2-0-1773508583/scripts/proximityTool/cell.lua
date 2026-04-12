local player = require('openmw.self')
local util = require('openmw.util')

local this = {}


---@param positions proximityTool.position[]
function this.getClosestPosition(positions)
    local plCell = player.cell
    local plPos = player.position
    local isExterior = plCell.isExterior

    local closestPos
    local minDistance = math.huge
    for _, posDt in pairs(positions) do
        if isExterior ~= posDt.cell.isExterior or (not isExterior and plCell.id ~= posDt.cell.id) then goto continue end

        local pos = util.vector3(posDt.position.x, posDt.position.y, posDt.position.z)

        local distance = (plPos - pos):length()

        if minDistance > distance then
            minDistance = distance
            closestPos = pos
        end

        ::continue::
    end

    return closestPos, minDistance
end


---@param positions proximityTool.position[]
function this.isContainValidPosition(positions)
    local plCell = player.cell
    local plPos = player.position
    local isExterior = plCell.isExterior

    local res = false
    for _, posDt in pairs(positions) do
        if isExterior == posDt.cell.isExterior and (isExterior or plCell.id == posDt.cell.id) then
            return true
        end
    end
    return false
end


return this