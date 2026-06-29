local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')

local PrisonMarkers = require('scripts.InventoryExtender.util.prisonMarkers')

local validMarkers = {}

for contentFile, markers in pairs(PrisonMarkers) do
    if core.contentFiles.has(contentFile) then
        for _, marker in ipairs(markers) do
            table.insert(validMarkers, marker)
        end
    end
end

local CELL_SIZE_IN_UNITS = 8192
local ESM4_CELL_SIZE_IN_UNITS = 4096

local function isEsm4Ext(worldspaceId)
    return worldspaceId ~= nil
end

local function getCellSize(worldspaceId)
    if isEsm4Ext(worldspaceId) then
        return ESM4_CELL_SIZE_IN_UNITS
    else
        return CELL_SIZE_IN_UNITS
    end
end

local function positionToExteriorCellLocation(x, y, worldspaceId)
    local cellSize = getCellSize(worldspaceId)
    local cellX = math.floor(x / cellSize)
    local cellY = math.floor(y / cellSize)
    return cellX, cellY
end

local function getClosestMarkerFromExteriorPosition(position)
    local cellX, cellY = positionToExteriorCellLocation(position.x, position.y)

    local bestMarkers = {}
    local minGridSize = math.huge

    for _, marker in ipairs(validMarkers) do
        if marker.cell then -- Skip interior markers
            goto continue
        end
        local deltaX = marker.x - cellX
        local deltaY = marker.y - cellY
        local gridSize = math.max(math.abs(deltaX), math.abs(deltaY)) * 2

        if gridSize == 0 then
            -- Immediate match, check existence now as it's the best possible case
            local success = pcall(world.getCellById, marker.interior)
            if success then
                return marker
            end
        elseif gridSize <= minGridSize then
            -- Collect candidates without checking existence yet
            if gridSize < minGridSize then
                bestMarkers = {}
                minGridSize = gridSize
            end
            table.insert(bestMarkers, {
                marker = marker,
                col = gridSize / 2 + deltaX,
                row = gridSize / 2 + deltaY
            })
        end
        ::continue::
    end

    if #bestMarkers == 0 then
        return nil
    elseif #bestMarkers == 1 then
        return bestMarkers[1].marker
    end

    -- Tie-breaking logic: SW -> SE -> NE -> NW -> SW path
    local closestMarker = nil
    local earliestDistance = math.huge

    for _, info in ipairs(bestMarkers) do
        local distance = 0
        if info.row == 0 then               -- South edge
            distance = info.col
        elseif info.col == minGridSize then -- East edge
            distance = minGridSize + info.row
        elseif info.row == minGridSize then -- North edge
            distance = minGridSize * 3 - info.col
        else                                -- West edge
            distance = minGridSize * 4 - info.row
        end

        if distance < earliestDistance then
            closestMarker = info.marker
            earliestDistance = distance
        end
    end
    for _, info in ipairs(bestMarkers) do
        local distance = 0
        if info.row == 0 then               -- South edge
            distance = info.col
        elseif info.col == minGridSize then -- East edge
            distance = minGridSize + info.row
        elseif info.row == minGridSize then -- North edge
            distance = minGridSize * 3 - info.col
        else                                -- West edge
            distance = minGridSize * 4 - info.row
        end
        info.sortDistance = distance
    end

    table.sort(bestMarkers, function(a, b) return a.sortDistance < b.sortDistance end)

    for _, info in ipairs(bestMarkers) do
        local success = pcall(world.getCellById, info.marker.interior)
        if success then
            return info.marker
        end
    end

    return closestMarker
end

local CellUtils = {}

function CellUtils.getClosestMarker(object)
    if object.cell.isExterior then
        return getClosestMarkerFromExteriorPosition(object.position)
    end
    local checkedCells = {}
        local currentCells = {}
        local nextCells = { [object.cell] = true }

        while next(nextCells) do
            currentCells = nextCells
            nextCells = {}

            for cell, _ in pairs(currentCells) do
                checkedCells[cell.id] = true

                -- Search for a marker in this cell
                for _, marker in ipairs(validMarkers) do
                    if marker.cell and marker.cell:lower() == cell.id:lower() then
                        return marker
                    end
                end

                -- Check doors
                for _, door in ipairs(cell:getAll(types.Door)) do
                    if types.Door.isTeleport(door) then
                        local destCell = types.Door.destCell(door)
                        if destCell then
                            if destCell.isExterior then
                                -- If we found an exit to exterior, calculate closest marker from there
                                local pos = types.Door.destPosition(door)
                                return getClosestMarkerFromExteriorPosition(pos)
                            elseif not checkedCells[destCell.id] and not currentCells[destCell] then
                                checkedCells[destCell.id] = true
                                nextCells[destCell] = true
                            end
                        end
                    end
                end
            end
        end

        return nil
end

function CellUtils.getPrisonCells()
    local prisonCells = {}
    for _, marker in ipairs(validMarkers) do
        if marker.interior then
            prisonCells[marker.interior] = true
        end
    end
    return prisonCells
end

return CellUtils