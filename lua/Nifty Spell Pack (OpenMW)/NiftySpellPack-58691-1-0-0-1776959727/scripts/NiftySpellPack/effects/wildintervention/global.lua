local types = require('openmw.types')
local util = require('openmw.util')
local core = require('openmw.core')
local world = require('openmw.world')

local l10n = core.l10n('NiftySpellPack')

local MIN_GRID_DISTANCE = 2
local MAX_GRID_DISTANCE = 6
local MAX_CELL_TRIES = 20
local MAX_RANDOM_TRIES = 16
local CELL_SIZE_IN_UNITS = 8192
local ESM4_CELL_SIZE_IN_UNITS = 4096

local function isEsm4Ext(worldspaceId)
    return worldspaceId ~= nil and worldspaceId ~= 'sys::default'
end

local function getCellSize(worldspaceId)
    if isEsm4Ext(worldspaceId) then
        return ESM4_CELL_SIZE_IN_UNITS
    else
        return CELL_SIZE_IN_UNITS
    end
end

local function gridToWorldPos(gridX, gridY, worldspaceId)
    local cellSize = getCellSize(worldspaceId)
    local worldX = util.round(gridX * cellSize)
    local worldY = util.round(gridY * cellSize)
    return worldX, worldY
end

local function buildCandidateOffsets()
    local offsets = {}
    local minDistanceSq = MIN_GRID_DISTANCE * MIN_GRID_DISTANCE
    local maxDistanceSq = MAX_GRID_DISTANCE * MAX_GRID_DISTANCE

    for offsetX = -MAX_GRID_DISTANCE, MAX_GRID_DISTANCE do
        for offsetY = -MAX_GRID_DISTANCE, MAX_GRID_DISTANCE do
            local distanceSq = (offsetX * offsetX) + (offsetY * offsetY)
            if distanceSq >= minDistanceSq and distanceSq <= maxDistanceSq then
                table.insert(offsets, { x = offsetX, y = offsetY })
            end
        end
    end

    return offsets
end

local function findValidLandingPos(cell)
    local originX, originY = gridToWorldPos(cell.gridX, cell.gridY, cell.worldSpaceId)
    local cellSize = getCellSize(cell.worldSpaceId)

    for i = 1, MAX_RANDOM_TRIES do
        local randomX = originX + math.random() * cellSize
        local randomY = originY + math.random() * cellSize
        local z = core.land.getHeightAt(util.vector3(randomX, randomY, 0), cell)
        if not cell.waterLevel or z >= cell.waterLevel then
            z = cell.waterLevel and math.max(z, cell.waterLevel) or z
            return util.vector3(randomX, randomY, z)
        end
    end

    return nil
end

local function getConnectedExterior(cell)
    if cell.isExterior then
        return cell
    end

    local visited = {}
    local queue = { { cell = cell, depth = 0 } }
    local maxDepth = 10
    while #queue > 0 do
        local entry = table.remove(queue, 1)
        local currentCell = entry.cell
        local depth = entry.depth
        if not visited[currentCell.id] and depth <= maxDepth then
            visited[currentCell.id] = true
            if currentCell.isExterior then
                return currentCell
            end

            -- To get neighbor cells, search for load doors in the current cell
            local Door = types.Door
            local doors = currentCell:getAll(Door)
            for _, door in ipairs(doors) do
                if Door.isTeleport(door) then
                    local destCell = Door.destCell(door)
                    if destCell and not visited[destCell.id] then
                        table.insert(queue, {cell = destCell, depth = depth + 1})
                    end
                end
            end
        end
    end

    return nil
end

return {
    onMagnitudeChange = function(ctx)
        if ctx.oldMagnitude ~= 0 or ctx.newMagnitude == 0 then return end

        local target = ctx.target
        if not target then return end

        if target.type.isTeleportingEnabled and not target.type.isTeleportingEnabled(target) then
            target:sendEvent('ShowMessage', { message = core.getGMST('sTeleportDisabled') })
            return
        end

        local cell = target.cell
        if not cell then return end

        local exteriorCell = getConnectedExterior(cell, ctx)
        if not exteriorCell then 
            target:sendEvent('ShowMessage', { message = l10n('UI_WildIntervention_Failed') })    
            return 
        end

        local x, y = exteriorCell.gridX, exteriorCell.gridY
        local candidateOffsets = buildCandidateOffsets()
        local maxCellTries = math.min(MAX_CELL_TRIES, #candidateOffsets)
        local targetCell
        local finalPos
        local finalRot = target.rotation * util.transform.rotateZ(math.random() * math.pi * 2)

        for i = 1, maxCellTries do
            local candidateIndex = math.random(#candidateOffsets)
            local offset = table.remove(candidateOffsets, candidateIndex)
            local targetGridX = x + offset.x
            local targetGridY = y + offset.y

            local candidateCell = world.getExteriorCell(targetGridX, targetGridY, exteriorCell)
            if candidateCell and candidateCell.region ~= nil then
                local candidatePos = findValidLandingPos(candidateCell)
                if candidatePos then
                    targetCell = candidateCell
                    finalPos = candidatePos
                    break
                end
            end
        end

        if not targetCell or not finalPos then
            target:sendEvent('ShowMessage', { message = l10n('UI_WildIntervention_Failed') })
            return
        end

        if math.random() < 0.2 then
            local Door = types.Door
            local doors = targetCell:getAll(Door)
            local unlockedDoors = {}
            for _, door in ipairs(doors) do
                if not Door.record(door).mwscript and Door.isTeleport(door) and not types.Lockable.isLocked(door) then
                    table.insert(unlockedDoors, door)
                end
            end
            if #unlockedDoors > 0 then
                local chosenDoor = unlockedDoors[math.random(#unlockedDoors)]
                targetCell = Door.destCell(chosenDoor)
                finalPos = Door.destPosition(chosenDoor)
                finalRot = Door.destRotation(chosenDoor)
                if math.random() < 0.2 then
                    finalRot = finalRot * util.transform.rotateZ(math.pi) -- Why not
                end
            end
        end

        target:teleport(targetCell, finalPos, { onGround = true, rotation = finalRot })
        target:sendEvent('NSP_EffectEvent', { type = 'onTeleport', effectId = 'nsp_wildintervention' })
    end,
}