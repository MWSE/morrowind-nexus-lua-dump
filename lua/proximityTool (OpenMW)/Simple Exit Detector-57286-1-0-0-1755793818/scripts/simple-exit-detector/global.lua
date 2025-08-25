require("scripts.simple-exit-detector.annotations")

local core = require("openmw.core")
local async = require("openmw.async")
local world = require("openmw.world")
local types = require("openmw.types")
local time = require("openmw_aux.time")

local cellLib = require("scripts.simple-exit-detector.cellLib")

local l10n = core.l10n("simpleExitDetector")


local function getCellName(cell)
    local str = cell.region and cell.region ~= "" and cell.region
        or cell.name and cell.name ~= "" and cell.name
        or "Exit"

    return str:gsub("^.", string.upper)
end


local function createMarkersForCell()
    local playerRef = world.players[1]
    local cell = playerRef.cell

    local doorData = cellLib.getExits(cell)
    if not next(doorData) then return end

    table.sort(doorData, function (a, b)
        return a.distanceInCells < b.distanceInCells
    end)

    ---@type {path : {cell : any, position : any}[], door : any, distance : number, distanceInCells : number}[]
    local closest = {}
    for _, dt in ipairs(doorData) do
        if dt.distanceInCells == doorData[1].distanceInCells then
            table.insert(closest, dt)
        else
            break
        end
    end

    local markerInfo = {}

    for _, dt in ipairs(closest) do

        local exitCell = dt.path[#dt.path].cell
        local exitCellName = getCellName(exitCell)
        local description
        for _, pathDt in ipairs(dt.path) do
            if not description then
                description = string.format("\"%s\"", getCellName(pathDt.cell))
            else
                description = string.format("%s => \"%s\"", description, getCellName(pathDt.cell))
            end
        end

        local hash = exitCellName..(description or "")
        local info = markerInfo[hash]
        if not info then
            markerInfo[hash] = {
                refs = {dt.door},
                name = exitCellName,
                description = description
            }
        else
            table.insert(info.refs, dt.door)
        end
    end

    playerRef:sendEvent("Simple-Exit-Detector:createMarkers", markerInfo)
end


return {
    eventHandlers = {
        ["Simple-Exit-Detector:createMarkersForPlayerCell"] = createMarkersForCell,
    },
}