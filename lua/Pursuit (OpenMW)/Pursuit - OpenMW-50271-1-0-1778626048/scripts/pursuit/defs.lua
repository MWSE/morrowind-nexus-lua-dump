local types = require("openmw.types")
local core = require("openmw.core")
local world = require("openmw.world")
local storage = require("openmw.storage")
local aux_util = require("openmw_aux.util")
local time = require("openmw_aux.time")

local fAthleticsRunBonus = core.getGMST("fAthleticsRunBonus") or 1
local fBaseRunMultiplier = core.getGMST("fBaseRunMultiplier") or 1.75

getGlobalStore = storage.globalSection

log = function(debugMessage)
    if not getGlobalStore("Settings!_PursuitDebug_!"):get("Debug") then return end
    world.players[1]:sendEvent("Pursuit_debugMessage", { message = debugMessage })
end

isVampire = function(actor)
    return types.Actor.activeEffects(actor):getEffect("Vampirism").magnitude > 0
end

isDayTime = function()
    local toss = math.random(0, 1) -- which is faster? a store lookup or math? (let fate decide; even this costs time)
    if toss == 0 then
        local gameHour = world.mwscript.getGlobalVariables()["gamehour"]
        return gameHour > 6 and gameHour < 20
    else
        local gameHour = core.getGameTime() / time.hour % 24
        return gameHour > 6 and gameHour < 20
    end
end

cellIsExterior = function(cell)
    return cell.isExterior or cell:hasTag("QuasiExterior")
end

actorHasKeyForDoor = function(actor, door)
    local doorKey = types.Lockable.getKeyRecord(door)
    return doorKey and types.Actor.inventory(actor):find(doorKey.id) or false
end

doorLocked = function(door)
    if door.type == types.ESM4Door and types.ESM4Door.record(door).isAutomatic then
        return false
    end
    return types.Lockable.isLocked(door)
end

getActorSpeed = function(actor, isWalking)
    assert(actor.type.baseType == types.Actor)
    if actor.type == types.NPC then
        return isWalking and types.Actor.getWalkSpeed(actor) or types.Actor.getRunSpeed(actor)
    elseif actor.type == types.Creature then
        local athleticsSkill = actor.type.record(actor).combatSkill
        return types.Actor.walkSpeed(actor) * (0.01 * athleticsSkill * fAthleticsRunBonus + fBaseRunMultiplier)
    end
end

canOpenDoor = function(door, actor)
    local canOpenDoor = not doorLocked(door)
    local settings = storage.globalSection("Settings!_PursuitExtra_!")
    local lockedDoorBlocksPursuit = settings:get("lockedDoorBlocksPursuit")
    return canOpenDoor or not lockedDoorBlocksPursuit
end

getPathDistance = function(path)
    local distance = 0
    for i = 1, #path - 1 do
        local segment = path[i] - path[i + 1]
        distance = distance + segment:length()
    end
    return distance
end

getDoorToCell = function(data)
    local pursuer = data.pursuer
    local target = data.target
    local targetCell = target.cell

    if data.pathUpdated then
        -- Navigation-aware version
        local pathsToDoors = data.pathDoor
        local doorsToTargetCell = {}

        for doorId, pathData in pairs(pathsToDoors) do
            if types.Door.destCell(pathData.door) == targetCell then
                doorsToTargetCell[#doorsToTargetCell + 1] = pathData.door
            end
        end

        local door, distance = aux_util.findMinScore(doorsToTargetCell, function(door)
            local distanceFromDestPositionToTarget =
                (types.Door.destPosition(door) - target.position):length()
            local canPath = data.pathDoor[door.id].canPath
            local distance = getPathDistance(pathsToDoors[door.id].pathList)
                + distanceFromDestPositionToTarget
            local canOpenDoor = canOpenDoor(door, pursuer)
            return canPath and canOpenDoor and distance
        end)

        if door then
            data.doorToTargetCell = door
            data.distanceToDoor = getPathDistance(pathsToDoors[door.id].pathList)
            return true
        else
            log(("[%s] has no path to %s!"):format(pursuer, targetCell.name))
        end
    else
        -- Original cell-based version
        local currentCell = pursuer.cell
        local doorsInCell = currentCell:getAll(types.Door)

        local door, distance = aux_util.findMinScore(doorsInCell, function(door)
            local distanceFromDestPositionToTarget =
                (types.Door.destPosition(door) - target.position):length()
            local doorDestIsTargetCell = types.Door.destCell(door) == targetCell
            local distance = (pursuer.position - door.position):length()
                + distanceFromDestPositionToTarget
            local canOpenDoor = canOpenDoor(door, pursuer)
            return doorDestIsTargetCell and canOpenDoor and distance
        end)

        if door then
            data.doorToTargetCell = door
            data.distanceToDoor = (pursuer.position - door.position):length()
            return true
        else
            log(("[%s] did not find any doors to %s!"):format(pursuer, targetCell.name))
        end
    end
end

getDoorDestination = function(door)
    local destCellName = door.type.destCell(door).name
    local destPosition = door.type.destPosition(door)
    local destRotation = door.type.destRotation(door)
    return destCellName, destPosition, destRotation
end

safeTeleport = function(t)
    local object, destCellName, destPosition, destRotation = table.unpack(t)
    local ok, err = pcall(object.teleport, object, destCellName, destPosition, {
        rotation = destRotation,
        onGround = true
    })
    return ok, err
end
