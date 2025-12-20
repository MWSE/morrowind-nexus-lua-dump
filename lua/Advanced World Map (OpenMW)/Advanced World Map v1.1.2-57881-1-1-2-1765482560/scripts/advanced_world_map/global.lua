local async = require('openmw.async')
local world = require('openmw.world')
local types = require("openmw.types")
local core = require("openmw.core")

local Door = types.Door

local config = require("scripts.advanced_world_map.config.config")

local tableLib = require("scripts.advanced_world_map.utils.table")
local stringLib = require("scripts.advanced_world_map.utils.string")
local cellLib = require("scripts.advanced_world_map.utils.cell")

local log = require("scripts.advanced_world_map.utils.log")

local common = require("scripts.advanced_world_map.common")

local saveStorage = require("scripts.advanced_world_map.storage.localStorage")
local mapDataHandler = require("scripts.advanced_world_map.mapDataHandler")

local disabledDoors = require("scripts.advanced_world_map.disabledDoors")

local l10n = core.l10n(common.l10nKey)


saveStorage.initPlayerStorage()

mapDataHandler.globalInit()


local function onObjectActive(ref)
    if types.Actor.objectIsInstance(ref) then
        if not ref:hasScript("scripts/advanced_world_map/actor.lua") then
            ref:addScript("scripts/advanced_world_map/actor.lua")
        end
    end
end


local function objectInactive(ref)
    if ref:isValid() and ref:hasScript("scripts/advanced_world_map/actor.lua") then
        ref:removeScript("scripts/advanced_world_map/actor.lua")
    end
end


local function checkDoor(ref)
    if Door.objectIsInstance(ref) and Door.isTeleport(ref) then
        local wasDisabled = disabledDoors.contains(ref)

        if not ref.enabled then
            disabledDoors.register(ref)
            if not wasDisabled then
                world.players[1]:sendEvent("AdvWMap:registerDisabledDoor", ref)
            end

        elseif wasDisabled then
            disabledDoors.unregister(ref)
            world.players[1]:sendEvent("AdvWMap:unregisterDisabledDoor", ref)
        end

    end
end


return {
    engineHandlers = {
        onObjectActive = onObjectActive,
        onLoad = function (data)
            saveStorage.initPlayerStorage(data)
            disabledDoors.init()
        end
    },
    eventHandlers = {
        ["AdvWMap:objectInactive"] = objectInactive,

        ["AdvWMap:updateConfigData"] = function (data)
            tableLib.applyChanges(config.data, data)
        end,

        ["AdvWMap:rebuildMapData"] = function ()
            mapDataHandler.globalBuildData()
        end,

        ["AdvWMap:fastTravel"] = function (data)
            local pos = data.pos
            local cellId = data.cellId
            local playerRef = world.players[1]
            local playerCell = playerRef.cell

            local destinations = {}

            local cell = cellId and world.getCellById(cellId) or world.getExteriorCell(cellLib.getGridCoordinates(pos))
            if not cell then
                playerRef:sendEvent("AdvWMap:showMessage",
                    data.onlyReachable and l10n("NoLocationsOrBlockedForFastTravel") or l10n("NoLocationsForFastTravel"))
                return
            end

            local function checkDoorAvailability(ref)
                return ref.enabled and Door.isTeleport(ref) and
                    not (data.onlyReachable and (disabledDoors.contains(ref) or types.Lockable.isLocked(ref)))
            end

            local function processCell(cell)
                for _, ref in pairs(cell:getAll(types.Door)) do

                    if checkDoorAvailability(ref) then
                        local dest = types.Door.destCell(ref)
                        if dest and (not data.availableCells or data.availableCells[dest.id]) then

                            for _, r in pairs(dest:getAll(types.Door)) do
                                if checkDoorAvailability(r) then
                                    local destPos = types.Door.destPosition(r)
                                    local destCell = types.Door.destCell(r)
                                    if (destCell.isExterior and cell.isExterior) or destCell.id == cell.id then
                                        table.insert(destinations, {
                                            ref = r,
                                            destPos = destPos,
                                            destCell = destCell,
                                            dist = common.distance2D(pos, destPos),
                                        })
                                    end
                                end
                            end

                        end
                    end
                end
            end

            if not cellId then
                local gridX, gridY = cellLib.getGridCoordinates(pos)
                for x = gridX - 1, gridX + 1 do
                    for y = gridY - 1, gridY + 1 do
                        local c = world.getExteriorCell(x, y)
                        if not c then goto continue end

                        if data.availableCells and not data.availableCells[c.id] then goto continue end

                        processCell(c)

                        ::continue::
                    end
                end
            elseif cell then
                processCell(cell)
            end

            if not next(destinations) then
                playerRef:sendEvent("AdvWMap:showMessage",
                    data.onlyReachable and l10n("NoLocationsOrBlockedForFastTravel") or l10n("NoLocationsForFastTravel"))
                return
            end

            table.sort(destinations, function (a, b)
                return a.dist < b.dist
            end)


            local ftDestData = destinations[1]
            local targetDoor = ftDestData.ref
            local destCell = ftDestData.destCell
            local destPos = ftDestData.destPos

            local distanceBetween
            local isInSameInteriorBlock = false
            local depthToPoint

            local function inToExDistance(inCell, exPos)
                local distance
                local depth
                local exitsData, cells, exitCells, lowestDepth = cellLib.findExitPositions(inCell, data.onlyReachable)
                if exitsData then
                    table.sort(exitsData, function (a, b)
                        return a.depth < b.depth
                    end)

                    for _, exit in ipairs(exitsData) do
                        local d = common.distance2D(exit.pos, exPos)
                        if (distance or 0) <= d then
                            depth = exit.depth
                            distance = d
                        end
                    end
                end
                return distance, depth
            end


            if destCell.isExterior then

                if playerCell.isExterior then
                    depthToPoint = 0
                    distanceBetween = common.distance2D(playerRef.position, destPos)
                else
                    distanceBetween, depthToPoint = inToExDistance(playerRef.cell, destPos)
                end

            else
                if playerCell.isExterior then
                    distanceBetween, depthToPoint = inToExDistance(destCell, playerRef.position)

                else
                    local dExits, dCells = cellLib.findExitPositions(destCell, data.onlyReachable)
                    if dCells[playerCell.id] then
                        depthToPoint = dCells[playerCell.id]
                        isInSameInteriorBlock = true

                    elseif next(dExits) then
                        local pExits, pCells = cellLib.findExitPositions(playerCell, data.onlyReachable)
                        if next(pExits) then

                            for i = 1, #dExits do
                                for j = 1, #pExits do
                                    local ex1 = dExits[i]
                                    local ex2 = pExits[j]
                                    local d = common.distance2D(ex1.pos, ex2.pos)
                                    if (distanceBetween or math.huge) > d then
                                        distanceBetween = d
                                        depthToPoint = ex1.depth + ex2.depth
                                    end
                                end
                            end

                        end
                    end
                end
            end

            isInSameInteriorBlock = isInSameInteriorBlock or (distanceBetween and distanceBetween < 4096) or false
            distanceBetween = distanceBetween or 0
            depthToPoint = depthToPoint or 999

            if data.onlyReachable and not isInSameInteriorBlock and depthToPoint > 99 then
                playerRef:sendEvent("AdvWMap:showMessage",
                    data.onlyReachable and l10n("NoLocationsOrBlockedForFastTravel") or l10n("NoLocationsForFastTravel"))
                return
            end

            local message
            if cellId then
                local cellName = destCell.displayName or destCell.name or ""
                message = l10n("fastTravelMessageBoxMessage"):format(cellName)
            else
                local cellName = targetDoor.cell.displayName or targetDoor.cell.name or ""
                message = l10n("fastTravelMessageBoxMessage"):format(stringLib.getBeforeComma(cellName))
            end

            -- use the door object to send the position, because cell is not passed
            playerRef:sendEvent("AdvWMap:fastTravelMessage", {
                message = message,
                targetDoor = targetDoor,
                depthToPoint = depthToPoint,
                worldDistance = distanceBetween,
                isInSameInteriorBlock = isInSameInteriorBlock,
            })
        end,

        ["AdvWMap:fastTravelTeleport"] = function (data)
            if not data.targetDoor and not (data.position and data.cellId) then return end

            local playerRef = world.players[1]

            if data.targetDoor then
                playerRef:teleport(types.Door.destCell(data.targetDoor), types.Door.destPosition(data.targetDoor),
                    {rotation = types.Door.destRotation(data.targetDoor), onGround = true})
            else
                playerRef:teleport(world.getCellById(data.cellId), data.position, {onGround = true})
            end
            playerRef:sendEvent("AdvWMap:playSound", {soundId = "mysticism hit"})
            playerRef:sendEvent("AdvWMap:cancelAnimation", {groupName = "spellcast"})
            playerRef:sendEvent("AdvWMap:cancelAnimation", {groupName = "spellturnleft"})
            playerRef:sendEvent("AdvWMap:cancelAnimation", {groupName = "spellturnright"})

            for _, actor in pairs(data.followers or {}) do
                if actor:isValid() then
                    actor:teleport(types.Door.destCell(data.targetDoor), types.Door.destPosition(data.targetDoor),
                        {rotation = types.Door.destRotation(data.targetDoor), onGround = true})
                end
            end
        end,

        ["AdvWMap:cellChanged"] = function ()
            local cell = world.players[1].cell

            if cell.isExterior then
                for x = -1, 1 do
                    for y = -1, 1 do
                        local c = world.getExteriorCell(cell.gridX + x, cell.gridY + y)
                        if c then
                            for _, ref in pairs(c:getAll(Door)) do
                                checkDoor(ref)
                            end
                        end
                    end
                end
            else
                for _, ref in pairs(cell:getAll(Door)) do
                    checkDoor(ref)
                end
            end
        end,

        ["AdvWMap:getMapStatics"] = function (data)
            local cellId = data.cellId or ""
            local cell = world.getCellById(cellId)
            if not cell then return end

            local res = {}
            for _, ref in pairs(cell:getAll(types.Static)) do
                local box = ref:getBoundingBox()
                local center = box.center
                local halfSize = box.halfSize
                local width = halfSize.x * 2
                local height = halfSize.y * 2
                if width < 128 or height < 128 then goto continue end
                table.insert(res, {center.x, center.y, width, height})
                ::continue::
            end
            world.players[1]:sendEvent("AdvWMap:getMapStatics", {res = res})
        end
    },
}