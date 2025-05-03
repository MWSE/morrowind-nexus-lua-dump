if not require("scripts.TamrielData.utils.version_check").isFeatureSupported("miscSpells") then
    return
end

local self = require('openmw.self')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local types = require('openmw.types')
local ui = require('openmw.ui')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local l10n = core.l10n("TamrielData")
local debug = require("scripts.TamrielData.utils.debug_logging")

local FT_TO_UNITS = 22.1
local maxSpellDistance = 25 * FT_TO_UNITS -- 25ft is a default Passwall spell range in the MWSE version
local maxSpellDistanceSquared = maxSpellDistance * maxSpellDistance
local veryCloseSquared = 11 * 11 -- an arbitrary value representing a close enough object that no wall is between
local passwallSpellId = "t_com_mys_uni_passwall"
local passwallFailureSound = core.stats.Skill.records[core.magic.spells.records[passwallSpellId].effects[1].effect.school].school.failureSound

local function calculatePlayerHeight()
    local playerRecord = types.NPC.record(self)
    local playerRaceHeights = types.NPC.races.record(playerRecord.race).height
    -- 134 is calculated backwards from MWSE version: castPosition -> player position z subtracted -> divided by 0.7
    if playerRecord.isMale then
        return playerRaceHeights.male * 134
    else
        return playerRaceHeights.female * 134
    end
end

local function getActivationVector()
    -- Camera direction cast on a XY plane
    local cameraVector = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    return util.vector3(cameraVector.x, cameraVector.y, 0.0):normalize()
end

local function getActivationDistance()
    return core.getGMST("iMaxActivateDist") + 0.1
end

local function getRaycastingInputData()
    local activationVector = getActivationVector()
    local activateDistance = getActivationDistance()
    return {
        startPos = self.position + util.vector3(0, 0, calculatePlayerHeight() * 0.7), -- castPosition as in MWSE version
        directionVector = activationVector,
        activateDistance = activateDistance
    }
end

local function startTeleporting(newPosition, newCell, newRotation, targetObject)
    core.sendGlobalEvent("T_Passwall_teleportPlayer",
    {
        player = self,
        position = newPosition,
        cell = newCell,
        rotation = newRotation,
        targetObject = targetObject,
        vfxStatic = core.magic.spells.records[passwallSpellId].effects[1].effect.hitStatic
    })
end

local function isDoorForbiddenFromPasswall(object)
    local recordName = types.Door.records[object.recordId].name
    -- compared to other ids, uppercase letters matter for object names
    local forbiddenDoorNames = { "Trap", "Cell", "Tent", "Grate", "Bearskin", "Mystical", "Skyrender", "Vault" }
    for _, value in pairs(forbiddenDoorNames) do
        if recordName:find(value) then
            return true
        end
    end
    return false
end

local function onPasswallFail()
    async:newSimulationTimer(
        0.3,
        async:registerTimerCallback(
            "T_Passwall_playSpellFailureSound",
            function()
                ambient.playSound(passwallFailureSound)
            end
        )
    )
end

local function handleAsDoor(object)
    local doorHandled = false
    if types.Door.objectIsInstance(object) then
        if types.Door.isTeleport(object) then
            local destCell = types.Door.destCell(object)
            if destCell.isExterior or destCell.isQuasiExterior then
                ui.showMessage(l10n("TamrielData_magic_passwallDoorExterior"))
                onPasswallFail()
            else
                local destPos = types.Door.destPosition(object)
                local destRotation = types.Door.destRotation(object)
                startTeleporting(destPos, destCell.name, destRotation, object)
            end
            doorHandled = true
        elseif isDoorForbiddenFromPasswall(object) then
            debug.log(
                string.format("Door '%s' is forbidden from being passed by a Passwall spell", object.recordId),
                passwallSpellId
            )
            onPasswallFail()
            doorHandled = true
        end
    end
    return doorHandled
end

local function isObjectReachable(from, targetObject)
    local to = targetObject:getBoundingBox().center

    if (from - to):length2() > 1024 * 1024 then -- Probably no need to look for further objects
        return false
    end

    -- Find a walkable navmesh path to the object
    local status, path = nearby.findPath(
        from,
        to,
        { includeFlags = nearby.NAVIGATOR_FLAGS.Walk, destinationTolerance = 0.0 })

    if status == nearby.FIND_PATH_STATUS.Success or status == nearby.FIND_PATH_STATUS.PartialPath then
        -- Even though a navmesh path is found, it still could have hopped through an obstacle,
        -- so try a raycast from path end to targetObject - if it doesn't collide with anything else,
        -- we could assume the object is reachable
        local lastRayCheck = nearby.castRay(
            path[#path],
            to,
            { collisionType = nearby.COLLISION_TYPE.AnyPhysical + nearby.COLLISION_TYPE.VisualOnly })

        local lastCheckResult = (lastRayCheck.hitObject and lastRayCheck.hitObject == targetObject)
        if not lastCheckResult then
            -- However, the raycast doesn't work on some objects, like items. Last chance check is just a distance one.
            -- If path end and targetObject are very close, we could assume the player can go from one to another.
            -- For this check it seems that comparing the distance with the bottom of the targetObject yields best results.
            lastCheckResult = util.vector3(
                to.x - path[#path].x,
                to.y - path[#path].y,
                to.z - path[#path].z - targetObject:getBoundingBox().halfSize.z
            ):length2() < veryCloseSquared
        end

        return lastCheckResult
    end
    return false
end

local function isBlockedByWard(object)
    local isWardPresent = object.recordId:find("t_aid_passwallward_")
    if isWardPresent then
        ui.showMessage(l10n("TamrielData_magic_passwallWard"))
    end
    return isWardPresent
end

local function isBlockedByIllegalActivator(object)
    if not types.Activator.objectIsInstance(object) then
        return false
    end
    local objectRecord = types.Activator.records[object.recordId]

    local forbiddenModels = { "force", "gg_", "water", "blight", "_grille_", "field", "editormarker", "barrier",
        "_portcullis_", "bm_ice_wall", "_mist", "_web", "_cryst", "collision", "grate", "shield", "smoke",
        "ex_colony_ouside_tend01", "akula", "act_sotha_green", "act_sotha_red", "lava", "bug", "clearbox" }
    for _, value in pairs(forbiddenModels) do
        if objectRecord.model:find(value) then
            ui.showMessage(l10n("TamrielData_magic_passwallAlpha"))
            debug.log(
                string.format("Object '%s' (%s) is an illegal activator you can't pass through with Passwall.", object.recordId, objectRecord.model),
                passwallSpellId
            )
            return true
        end
    end
    return false
end

local function isThereAReachableItemFromPosition(startPosition)
    -- If no other check passed until now, then perhaps there is nothing of interest except items in that area.
    -- In that case a reachable item hopefully is close by, so no need for far checks.

    for _, object in pairs(nearby.items) do
        if (startPosition - object:getBoundingBox().center):length2() <= maxSpellDistanceSquared then
            -- lights are excluded from checking, because their radius often bleeds through walls and floors, leading to false positives
            if not types.Light.objectIsInstance(object) then
                if isObjectReachable(startPosition, object) then
                    return true
                end
            end
        end
    end
    return false
end

local function isCalculatedPositionIntendedForThePlayer(position)
    if not position then
        return false
    end
    -- Look for any "useful" object that is reachable via navmesh from this position.
    -- If there is one, we could assume that the position was intended to be reachable by the player.
    for _, object in ipairs(nearby.doors) do
        if isObjectReachable(position, object) then
            return true
        end
    end
    for _, object in ipairs(nearby.actors) do
        if not types.Player.objectIsInstance(object) then
            if isObjectReachable(position, object) then
                return true
            end
        end
    end
    for _, object in ipairs(nearby.activators) do
        if isObjectReachable(position, object) then
            return true
        end
    end
    for _, object in ipairs(nearby.containers) do
        if isObjectReachable(position, object) then
            return true
        end
    end
    return isThereAReachableItemFromPosition(position)
end

local function isRayHitOnBlocker(rayHit)
    local object = rayHit.hitObject
    return isBlockedByWard(object) or isBlockedByIllegalActivator(object)
end

local function calculatePasswallPosition(intermediateRayHits, limitingPosition, directionVector)
    local rayTestOffset = 19 -- We could say that a 2*19 square is enough to fit the player in
    local minDistanceSquared = 108 * 108 -- minDistance from the MWSE version but squared
    local maxZDifference = 105 -- upCoord from the MWSE version
    local maxDistanceAllowedSquared = intermediateRayHits[1] and (
        util.vector3(
            intermediateRayHits[1].hitPos.x - limitingPosition.x,
            intermediateRayHits[1].hitPos.y - limitingPosition.y,
            0
        ):length2() + (160*160)) -- triangle hypotenuse^2 using rightCoord from MWSE version
    local rayTestIterate = rayTestOffset * 2

    for i = 1, #intermediateRayHits do
        local thisRayHit = intermediateRayHits[i]

        if isRayHitOnBlocker(thisRayHit) then
            return nil
        end

        local nextPosition = limitingPosition
        if i < #intermediateRayHits then
            nextPosition = intermediateRayHits[i+1].hitPos
        end

        -- Starting from rayHit i till rayHit i+1 iterate by rayTestIterate
        -- and do a findNearestNavMeshPosition with halfExtents sligthly bigger than rayTestIterate/2
        -- which are getting bigger with every rayHit further from the player
        local halfExtentForThisPart = rayTestIterate * 0.7 * i

        local distanceToNext = (nextPosition - thisRayHit.hitPos):length()
        local potentialPosition = thisRayHit.hitPos + directionVector * rayTestIterate

        while distanceToNext >= rayTestIterate do
            local navMeshPosition = nearby.findNearestNavMeshPosition(
                potentialPosition,
                {
                    includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
                    searchAreaHalfExtents = util.vector3(halfExtentForThisPart, halfExtentForThisPart, maxZDifference * 10),
                    agentBounds = types.Actor.getPathfindingAgentBounds(self)
                }
            )
            if navMeshPosition ~= nil then

                local isPositionNotTooHighOrLow = math.abs(self.position.z - navMeshPosition.z) < maxZDifference

                local isPositionNotTooClose = false
                if isPositionNotTooHighOrLow then
                    isPositionNotTooClose = (self.position - navMeshPosition):length2() >= minDistanceSquared
                end

                local isPositionNotTooFar = false
                if isPositionNotTooClose then
                    isPositionNotTooFar = util.vector3(
                        intermediateRayHits[1].hitPos.x - navMeshPosition.x,
                        intermediateRayHits[1].hitPos.y - navMeshPosition.y,
                        0
                    ):length2() <= maxDistanceAllowedSquared
                end

                local isIntendedForThePlayer = isPositionNotTooClose and isPositionNotTooHighOrLow and isPositionNotTooFar
                if isIntendedForThePlayer then
                    isIntendedForThePlayer = isCalculatedPositionIntendedForThePlayer(navMeshPosition)
                end
                if isIntendedForThePlayer then
                    return navMeshPosition
                else
                    potentialPosition = potentialPosition + directionVector * rayTestIterate
                    distanceToNext = (nextPosition - potentialPosition):length()
                end
            else
                potentialPosition = potentialPosition + directionVector * rayTestIterate
                distanceToNext = (nextPosition - potentialPosition):length()
            end
        end

    end

    return nil
end

local function gatherAllRayHitsAndLimitingPosition(raycastingInputData, firstRaycastHit)
    local remainingTeleportDistance = maxSpellDistance
    local intermediateRayHits = {firstRaycastHit}
    local limitingPosition = firstRaycastHit.hitPos + raycastingInputData.directionVector * maxSpellDistance

    local previousRaycastSourceObjects = {}
    while remainingTeleportDistance > 0 do
        local prevHit = intermediateRayHits[#intermediateRayHits]
        table.insert(previousRaycastSourceObjects, prevHit.hitObject)
        local thisHit = nearby.castRay(
            prevHit.hitPos,
            limitingPosition,
            {
                collisionType = nearby.COLLISION_TYPE.AnyPhysical + nearby.COLLISION_TYPE.VisualOnly,
                ignore = previousRaycastSourceObjects
            })
        if thisHit.hitObject then
            table.insert(intermediateRayHits, thisHit)
            remainingTeleportDistance = remainingTeleportDistance - (thisHit.hitPos - prevHit.hitPos):length()
        else
            remainingTeleportDistance = -1
        end
    end

    return intermediateRayHits, limitingPosition
end

local PSW = {}

function PSW.onCastPasswall()
    debug.log(
        string.format(
            "START: pos:%s, cell:%s, rotation:%s, race:%s, isMale:%s",
            self.position,
            self.cell,
            self.rotation,
            types.NPC.record(self).race,
            types.NPC.record(self).isMale
        ),
        passwallSpellId
    )

    if self.cell.isExterior then
        ui.showMessage(l10n("TamrielData_magic_passwallExterior"))
        return onPasswallFail()
    elseif types.Actor.isSwimming(self) then
        ui.showMessage(l10n("TamrielData_magic_passwallUnderwater"))
        return onPasswallFail()
    elseif not types.Player.isTeleportingEnabled(self) then
        ui.showMessage(core.getGMST("sTeleportDisabled"))
        return onPasswallFail()
    end

    local raycastingInputData = getRaycastingInputData()
    local raycastingEnd = raycastingInputData.startPos + raycastingInputData.directionVector * raycastingInputData.activateDistance

    local firstRaycastHit = nearby.castRay(
        raycastingInputData.startPos,
        raycastingEnd,
        {
            ignore = self,
            collisionType =nearby.COLLISION_TYPE.AnyPhysical + nearby.COLLISION_TYPE.VisualOnly
        })

    if not firstRaycastHit.hitObject or isRayHitOnBlocker(firstRaycastHit) then
        debug.log("No target detected on spell cast.", passwallSpellId)
        return onPasswallFail()
    end

    local targetObject = firstRaycastHit.hitObject

    if not (types.Static.objectIsInstance(targetObject) or types.Activator.objectIsInstance(targetObject) or types.Door.objectIsInstance(targetObject)) then
        debug.log(
            string.format("Object '%s' is not a legal spell target. You need to hit an activator or a static or a door.", targetObject.recordId),
            passwallSpellId
        )
        return onPasswallFail()
    end

    if handleAsDoor(targetObject) then
        return
    end

    local hitObjectHalfHeight = targetObject:getBoundingBox().halfSize.z
    local minObstacleHeight = 93 -- MWSE version uses 96, but In_impsmall_d_hidden_01 needs these additional 3 points in OpenMW
    if hitObjectHalfHeight < minObstacleHeight then
        debug.log(string.format("Object '%s' height (%s) is too low for Passwall (need %s).", targetObject.recordId, hitObjectHalfHeight, minObstacleHeight), passwallSpellId)
        return onPasswallFail()
    end

    local intermediateRayHits, limitingPosition = gatherAllRayHitsAndLimitingPosition(raycastingInputData, firstRaycastHit)
    -- intermediateRayHits include the first raycast hit (a spell target object, i.e. wall) as element [1]
    -- limitingPosition is the max distance the spell could reach: should be farther from the player than (or as far as) all intermediateRayHits

    local finalTeleportPosition = calculatePasswallPosition(intermediateRayHits, limitingPosition, raycastingInputData.directionVector)

    if finalTeleportPosition then
        startTeleporting(finalTeleportPosition, self.cell.name, self.rotation, targetObject)
    else
        debug.log("No valid teleport position for Passwall found", passwallSpellId)
        return onPasswallFail()
    end
end

return PSW