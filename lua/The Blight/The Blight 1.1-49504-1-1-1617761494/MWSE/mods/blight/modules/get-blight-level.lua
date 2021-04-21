local blightedCells = {}

local function getBlightedCells()
    for i, cell in ipairs(tes3.dataHandler.nonDynamicData.cells) do
        if cell.region and cell.region.weatherChanceBlight > 0 then
            table.insert(blightedCells, cell)
        end
    end
end
event.register("loaded", getBlightedCells)

local function gridDistance(c1, c2)
    local dx = c1.gridX - c2.gridX
    local dy = c1.gridY - c2.gridY
    return math.sqrt(dx * dx + dy * dy)
end

local function getAdjacentBlightCells(cell)
    return coroutine.wrap(function()
        for i, blightCell in ipairs(blightedCells) do
            local dist = gridDistance(cell, blightCell)
            if dist < 5 then
                coroutine.yield(blightCell, dist)
            end
        end
    end)
end

local function getAveragedBlightChance(cell)
    local sum = cell.region.weatherChanceBlight
    for blightCell, dist in getAdjacentBlightCells(cell) do
        local chance = blightCell.region.weatherChanceBlight
        local scaled = chance * (5 - dist)
        sum = sum + scaled
    end
    return math.clamp(sum / 50, 0, 100)
end

-- Use a cache to make calling getBlightLevel from individual references fast.
-- Clear cells from the cache when unloaded so mods can update blight chances.
local blightLevelCache = {}
event.register("cellDeactivated", function(e) blightLevelCache[e.cell] = nil end)

-- Get the "Blight Level" of the given cell.
-- Levels range 0 to 5. With 5 being the most-blighted areas.
-- Levels are calculated from the blight chances of surrounding cells.
local function getBlightLevel(cell)
    if not (cell and cell.region) then return 0 end

    if blightLevelCache[cell] == nil then
        local chance = getAveragedBlightChance(cell)
        blightLevelCache[cell] = math.ceil(chance / 20)
    end

    return blightLevelCache[cell]
end

return getBlightLevel
