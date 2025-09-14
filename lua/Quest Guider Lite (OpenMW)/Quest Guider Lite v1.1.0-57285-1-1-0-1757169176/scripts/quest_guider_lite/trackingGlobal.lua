local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')

local log = require("scripts.quest_guider_lite.utils.log")

local common = require("scripts.quest_guider_lite.common")

local cellLib = require("scripts.quest_guider_lite.cell")
local tableLib = require("scripts.quest_guider_lite.utils.table")

local l10n = require('openmw.core').l10n(common.l10nKey)


local depthConut = 1
local depthMaxDifference = 1


local this = {}


---@param cellId string
---@param markerByObjectId table<string, questGuider.tracking.objectRecord>
function this.addMarkersForInteriorCell(cellId, markerByObjectId)
    if not cellId or not markerByObjectId then return end

    local cell = world.getCellById(cellId)
    if not cell then return end

    ---@type table<tes3reference, {cells : table<string, { cell: tes3cell, depth: integer }>?, hasExit : any, ref : tes3reference}>
    local doors = {}

    for _, doorRef in pairs(cell:getAll(types.Door)) do
        if types.Door.isTeleport(doorRef) and doorRef.enabled then
            ---@diagnostic disable-next-line: missing-fields
            local reachableCells, hasExit = cellLib.findReachableCellsByNode({cell = types.Door.destCell(doorRef)}, {[cell.id] = {cell = cell, depth = 0}})
            reachableCells[cell.id] = nil

            doors[doorRef] = {cells = reachableCells, hasExit = hasExit, ref = doorRef}
        end
    end

    ---@type table<string, table<tes3reference, { cell: tes3cell, depth: integer }[]>>
    local doorByObjId = {}

    for objId, objData in pairs(markerByObjectId) do
        for qId, markerInfo in pairs(objData.markers) do
            local markerData = markerInfo.data

            if not markerData.localDoorMarkerId then goto continue end

            for cellId, parentCellId in pairs(objData.targetCells or {}) do
                for doorRef, doorData in pairs(doors) do
                    local targetCellDt = doorData.cells[parentCellId]
                    if targetCellDt then
                        if not doorByObjId[objId] then doorByObjId[objId] = {} end
                        if not doorByObjId[objId][doorRef] then doorByObjId[objId][doorRef] = {} end

                        table.insert(doorByObjId[objId][doorRef], targetCellDt)
                    end
                end
            end
        end
        ::continue::
    end

    for objId, objDoorDt in pairs(doorByObjId) do
        local depthHashTable = {}

        for doorRef, doorDt in pairs(objDoorDt) do
            for _, depthData in pairs(doorDt) do
                depthHashTable[depthData.depth] = true
            end
        end

        local depths = tableLib.keys(depthHashTable)
        table.sort(depths)

        if #depths == 0 or depths[1] == 0 then goto continue end

        local lowestDepthHashTable = {}
        if depths[1] == 1 then
            lowestDepthHashTable[1] = true
        else
            local lowestDepth = depths[1]
            for i = 1, util.clamp(#depths, 1, depthConut) do
                if lowestDepth + depthMaxDifference >= depths[i] then
                    lowestDepthHashTable[depths[i]] = true
                end
            end
        end

        ---@type table<string, {description : string, markerData : proximityTool.marker, doors : any[], color : number[], objId : string}>
        local newMarkerData = {}

        for doorRef, doorDt in pairs(objDoorDt) do
            local shouldCreateMarker = false

            local lowestDepth = 999
            for _, depthData in pairs(doorDt) do
                if lowestDepthHashTable[depthData.depth] then
                    shouldCreateMarker = true
                    if lowestDepth > depthData.depth then
                        lowestDepth = depthData.depth
                    end
                end
            end

            if shouldCreateMarker then
                local objData = markerByObjectId[objId]
                if not objData then goto continue end

                for qId, markerInfo in pairs(objData.markers) do

                    local markerData = markerInfo.data
                    if markerData and markerData.localDoorMarkerId then

                        local id = markerData.localDoorMarkerId..tostring(lowestDepth)
                        local markerInf = newMarkerData[id]
                        if not markerInf then
                            markerInf = {
                                markerData = {
                                    record = markerData.localDoorMarkerId,
                                    positions = {},
                                    groupName = markerInfo.groupName,
                                    shortTerm = true,
                                },
                                description = string.format(l10n("cellsAway", {count = lowestDepth})),
                                doors = {},
                                disabled = markerData.disabled,
                                objId = objId,
                            }
                        end

                        table.insert(markerInf.markerData.positions, {
                            cell = {
                                isExterior = doorRef.cell.isExterior,
                                id = doorRef.cell.id,
                                gridX = doorRef.cell.gridX,
                                gridY = doorRef.cell.gridY,
                            },
                            position = doorRef.position,
                        })

                        table.insert(markerInf.doors, doorRef)

                        newMarkerData[id] = markerInf
                    end
                end
            end
        end

        for _, data in pairs(newMarkerData) do
            world.players[1]:sendEvent("QGL:addMarkerForInteriorCellTracking", data)
        end

        ::continue::
    end
end


return this