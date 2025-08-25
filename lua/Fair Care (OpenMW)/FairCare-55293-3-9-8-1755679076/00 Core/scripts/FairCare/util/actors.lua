local core = require('openmw.core')
local T = require('openmw.types')
local util = require("openmw.util")
local nearby = require('openmw.nearby')
local aux_util = require('openmw_aux.util')

local mStore = require('scripts.FairCare.config.store')
local mCfg = require('scripts.FairCare.config.config')
local mMagic = require('scripts.FairCare.util.magic')
local mTools = require('scripts.FairCare.util.tools')
local log = require('scripts.FairCare.util.log')

local fDispRaceMod = core.getGMST("fDispRaceMod")
local fDispPersonalityMult = core.getGMST("fDispPersonalityMult")
local fDispPersonalityBase = core.getGMST("fDispPersonalityBase")
local fDispFactionRankMult = core.getGMST("fDispFactionRankMult")
local fDispFactionRankBase = core.getGMST("fDispFactionRankBase")
local fDispFactionMod = core.getGMST("fDispFactionMod")

local module = {}

local function isOverEncumbered(actor)
    if actor.type == T.Creature then
        return T.Actor.getEncumbrance(actor) > T.Actor.stats.attributes.strength(actor).modified * 5
    else
        return T.Actor.getEncumbrance(actor) > T.NPC.getCapacity(actor)
    end
end
module.isOverEncumbered = isOverEncumbered

local function canAct(actor)
    if mMagic.isParalyzed(actor) then
        log(string.format("%s cannot heal because he is paralyzed", mTools.objectId(actor)))
        return false
    end

    local fatigue = T.Actor.stats.dynamic.fatigue(actor)
    if fatigue.current <= 0 or fatigue.base == 0 then
        log(string.format("%s cannot heal because he is knocked out", mTools.objectId(actor)))
        return false
    end

    if not isOverEncumbered(actor) and not T.Actor.canMove(actor) then
        log(string.format("%s cannot heal because seems to be knocked down", mTools.objectId(actor)))
        return false
    end

    return true
end
module.canAct = canAct

local function getPath(actor, position)
    local status, path = nearby.findPath(
            actor.position,
            position,
            {
                agentBounds = T.Actor.getPathfindingAgentBounds(actor),
                includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.Swim,
                destinationTolerance = 0,
            })
    if status == nearby.FIND_PATH_STATUS.PartialPath then
        local distance = (actor.position - path[#path]):length()
        log(string.format("%s found a partial path distant from %d to his destination", mTools.objectId(actor), distance))
    elseif status ~= nearby.FIND_PATH_STATUS.Success then
        return nil
    end
    -- path is userdata, needs to convert it to a proper table to allow serialization
    local points = {}
    for _, point in ipairs(path) do
        table.insert(points, point)
    end
    return points
end
module.getPath = getPath

local function getPathToTarget(actor, target, distanceTolerance)
    local status, path = nearby.findPath(
            actor.position,
            target.position,
            {
                agentBounds = T.Actor.getPathfindingAgentBounds(actor),
                includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.Swim,
                destinationTolerance = 0,
            })
    if status == nearby.FIND_PATH_STATUS.PartialPath then
        local distance = (actor.position - path[#path]):length()
        if distance <= distanceTolerance then
            log(string.format("%s found a partial path distant from %d to %s", mTools.objectId(actor), distance, mTools.objectId(target)))
        else
            return nil
        end
    elseif status ~= nearby.FIND_PATH_STATUS.Success then
        return nil
    end

    -- path is userdata, needs to convert it to a proper table to allow serialization
    local points = {}
    for _, point in ipairs(path) do
        table.insert(points, point)
    end
    return points
end
module.getPathToTarget = getPathToTarget

local function getCloseActors(actor, maxDistance)
    local actorBounds = T.Actor.getPathfindingAgentBounds(actor)
    local neighbors = {}
    for _, neighbor in pairs(nearby.actors) do
        local neighborBounds = T.Actor.getPathfindingAgentBounds(neighbor)
        if actor.id ~= neighbor.id and (actor.position - neighbor.position):length()
                < maxDistance + actorBounds.halfExtents.x + neighborBounds.halfExtents.x then
            table.insert(neighbors, neighbor)
        end
    end
    return neighbors
end

local function getValidAngleRanges(excludedAngles)
    if #excludedAngles == 0 then
        return { { -math.pi, math.pi } }
    end
    table.sort(excludedAngles, function(a, b) return a.angle < b.angle end)
    local validAngles = {}
    local startAngle = -math.pi
    local lastAngle = excludedAngles[#excludedAngles]
    if lastAngle.angle + lastAngle.delta > math.pi then
        startAngle = -2 * math.pi + lastAngle.angle + lastAngle.delta
    end
    for _, angle in ipairs(excludedAngles) do
        if angle.angle - angle.delta > startAngle then
            table.insert(validAngles, { startAngle, angle.angle - angle.delta })
        end
        startAngle = angle.angle + angle.delta
    end
    if startAngle < math.pi then
        local endAngle = math.pi
        local firstAngle = excludedAngles[1]
        if firstAngle.angle - firstAngle.delta < -math.pi then
            endAngle = 2 * math.pi - (firstAngle.angle - firstAngle.delta)
        end
        if endAngle > startAngle then
            table.insert(validAngles, { startAngle, endAngle })
        end
    end
    return validAngles
end

local function getRandomAngleFromRanges(angleRanges)
    local angleSum = 0
    for _, angle in ipairs(angleRanges) do
        angleSum = angleSum + angle[2] - angle[1]
    end
    local escapeAngle = math.random() * angleSum
    for _, angle in ipairs(angleRanges) do
        escapeAngle = escapeAngle + angle[1]
        if escapeAngle < angle[2] then
            return escapeAngle
        end
        escapeAngle = escapeAngle - angle[2]
    end
    error("Could not find a valid angle from ranges %s", aux_util.deepToString(angleRanges))
end

local function getTargetCoveringAngle(actorPos, targetPos, target)
    local deltaPos = targetPos - actorPos
    local deltaYaw = math.atan2(deltaPos.x, deltaPos.y)
    local targetBounds = T.Actor.getPathfindingAgentBounds(target)
    local right = targetPos + util.transform.rotateZ(deltaYaw + math.pi) * util.vector3(2 * targetBounds.halfExtents.x, 0, 0)
    local deltaPosRight = right - actorPos
    local deltaYawRight = math.atan2(deltaPosRight.x, deltaPosRight.y)
    local left = targetPos + util.transform.rotateZ(deltaYaw) * util.vector3(2 * targetBounds.halfExtents.x, 0, 0)
    local deltaPosLeft = left - actorPos
    local deltaYawLeft = math.atan2(deltaPosLeft.x, deltaPosLeft.y)
    return (deltaYawLeft - deltaYawRight) % (2 * math.pi)
end

local function getRandomDestinationAvoidingTargets(actor)
    local escapeDistance = mCfg.minEscapePathSegment + math.random() * (mCfg.maxEscapePathSegment - mCfg.minEscapePathSegment)
    local targetAngles = {}
    local targets = getCloseActors(actor, escapeDistance)
    for _, target in ipairs(targets) do
        local deltaPos = target.position - actor.position
        local coveringAngle = getTargetCoveringAngle(actor.position, target.position, target)
        table.insert(targetAngles, { angle = math.atan2(deltaPos.y, deltaPos.x), delta = coveringAngle / 2, target = target })
    end
    local escapeAngles = getValidAngleRanges(targetAngles)
    --log(string.format("%s found escape angles from %d targets\nAngles %s\nTargets %s",
    --        mTools.objectId(actor), #targets, aux_util.deepToString(targetAngles, 3), aux_util.deepToString(escapeAngles, 3)))

    if #escapeAngles == 0 then return { targets = targets } end

    local escapeAngle = getRandomAngleFromRanges(escapeAngles)

    local destination = util.vector3(
            actor.position.x + escapeDistance * math.cos(escapeAngle),
            actor.position.y + escapeDistance * math.sin(escapeAngle),
            actor.position.z)

    --log(string.format("%s found escape point %s with angle %d", mTools.objectId(actor), destination, escapeAngle))
    return {
        destination = destination,
        angle = escapeAngle,
        distance = (actor.position - destination):length(),
        targets = targets,
    }
end

local function getRetreatPosition(actor)
    local data = getRandomDestinationAvoidingTargets(actor)
    if not data.destination then return data end
    data.position = nearby.findRandomPointAroundCircle(data.destination, mCfg.validPointSearchRadius, {
        agentBounds = T.Actor.getPathfindingAgentBounds(actor),
        includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.Swim,
    })
    return data
end
module.getRetreatPosition = getRetreatPosition

local function isCloseEnough(actor, target, distance)
    return (actor.position - target.position):length() <= distance
end
module.isCloseEnough = isCloseEnough

local function actorHalfHeight(actor)
    return actor.position + util.vector3(0, 0, actor:getBoundingBox().halfSize.z)
end
module.actorHalfHeight = actorHalfHeight

local function actorDistantHalfHeight(actor, position)
    return position + util.vector3(0, 0, actor:getBoundingBox().halfSize.z)
end

local function getPathTravelTime(actor, path)
    if #path == 1 then return 0 end

    local distance = 0
    for i = 1, #path - 1 do
        distance = distance + (path[i + 1] - path[i]):length()
    end
    return distance / T.Actor.getRunSpeed(actor)
end
module.getPathTravelTime = getPathTravelTime

local function faceToPoint(controls, actor, target, deltaTime)
    local pitch, yaw = actor.rotation:getAnglesXZ()
    local position = target.position and actorHalfHeight(target) or actorDistantHalfHeight(actor, target)
    local deltaPos = position - actorHalfHeight(actor)

    local deltaPitch = -pitch - math.asin(deltaPos.z / deltaPos:length())
    controls.pitchChange = math.abs(deltaPitch) > math.pi / 32 and util.clamp(deltaPitch, -deltaTime * 10, deltaTime * 10) or 0

    local destYawVec = util.vector2(deltaPos.x, deltaPos.y):rotate(yaw)
    local deltaYaw = math.atan2(destYawVec.x, destYawVec.y)
    controls.yawChange = math.abs(deltaYaw) > math.pi / 32 and util.clamp(deltaYaw, -deltaTime * 10, deltaTime * 10) or 0
end
module.faceToPoint = faceToPoint

local function travel(controls, actor, path, deltaTime)
    if #path == 1 then
        controls.movement = 0
        return true
    end
    if (actor.position - path[2]):length() < (#path == 2
            and T.Actor.getPathfindingAgentBounds(actor).halfExtents.x
            or mCfg.distanceToPathPointTolerance) then
        table.remove(path, 1)
    else
        faceToPoint(controls, actor, path[2], deltaTime)
    end
    controls.movement = 1
    return false
end
module.travel = travel

local function travelToTarget(controls, actor, path, target, targetDistanceTolerance, deltaTime)
    if #path == 1 or (actor.position - target.position):length() < targetDistanceTolerance then
        faceToPoint(controls, actor, actorHalfHeight(target), deltaTime)
        controls.movement = 0
        return controls.pitchChange == 0 and controls.yawChange == 0
    end
    if (actor.position - path[2]):length() < mCfg.distanceToPathPointTolerance then
        table.remove(path, 1)
    else
        faceToPoint(controls, actor, path[2], deltaTime)
    end
    controls.movement = 1
    return false
end
module.travelToTarget = travelToTarget

local function getDisposition(state, actor, target)
    if actor.type == T.NPC and target.type == T.Player then
        return mTools.clamp(T.NPC.getDisposition(actor, target), 0, 100)
    end

    local actorRecord, targetRecord = mTools.getRecord(actor), mTools.getRecord(target)
    local disp = actorRecord.baseDisposition or 50

    disp = disp + fDispPersonalityMult * (T.Actor.stats.attributes.personality(target).modified - fDispPersonalityBase);

    if actor.type == T.Creature or target.type == T.Creature then
        if target.type == T.Player then
            disp = disp + T.Actor.activeEffects(actor):getEffect(core.magic.EFFECT_TYPE.Charm).magnitude
        elseif actor.type == T.Creature and target.type == T.Creature then
            if actorRecord.type == targetRecord.type then
                disp = disp + state.settings[mStore.groups.healing.key].creatureTypeDispositionBoost
            end
        end
        return mTools.clamp(disp, 0, 100)
    end
    if actorRecord.race == targetRecord.race then
        disp = disp + fDispRaceMod
    end

    local actorFactions, targetFactions = T.NPC.getFactions(actor), T.NPC.getFactions(target)
    if #actorFactions > 0 and #targetFactions > 0 then
        local actorFaction = core.factions.records[actorFactions[1]]
        local reaction = actorFaction.reactions[targetFactions[1]]
        local rank = T.NPC.getFactionRank(actor, actorFactions[1])
        if actorFaction and reaction and rank then
            disp = disp + (fDispFactionRankMult * rank + fDispFactionRankBase) * fDispFactionMod * reaction;
        end
    end

    return mTools.clamp(disp, 0, 100)
end
module.getDisposition = getDisposition

local function isHealAgainDelayOk(state, chance)
    return state.healDelayStartTime + state.settings[mStore.groups.healing.key].timeBeforeHealAgainMaxChances
            * (1 - chance) ^ 0.5 < core.getSimulationTime()
end
module.isHealAgainDelayOk = isHealAgainDelayOk

local function getCastAnimationConfig(attackAnimations, forcedSpellcastKey, isSelfSpell)
    if attackAnimations then
        return {
            groupName = mTools.pick(attackAnimations),
            startKey = "start",
            releaseKey = "stop",
            stopKey = "stop",
        }
    end
    if forcedSpellcastKey then
        return {
            groupName = "spellcast",
            startKey = forcedSpellcastKey .. " start",
            releaseKey = forcedSpellcastKey .. " release",
            stopKey = forcedSpellcastKey .. " stop",
        }
    end
    if isSelfSpell then
        return {
            groupName = "spellcast",
            startKey = "self start",
            releaseKey = "self release",
            stopKey = "self stop",
        }
    else
        return {
            groupName = "spellcast",
            startKey = "touch start",
            releaseKey = "touch release",
            stopKey = "touch stop",
        }
    end
end
module.getCastAnimationConfig = getCastAnimationConfig

local function canRegen(state, actor, record)
    return state.settings[mStore.groups.global.key].healthRegenEnabled
            and (not state.selfHealSpellId or state.settings[mStore.groups.healthRegen.key].healthRegenForHealers)
            and state.settings[mStore.groups.healthRegen.key][mStore.getActorTypeRegenKey(actor, record)]
end
module.canRegen = canRegen

local function doRegen(state, actor, deltaTime)
    state.health.current = math.min(
            state.health.base,
            state.health.current
                    + mStore.getHealthRegenRatio(state.settings[mStore.groups.healthRegen.key].healthRegenRatio)
                    * deltaTime
                    * (T.Actor.stats.attributes.endurance(actor).modified + T.Actor.stats.attributes.strength(actor).modified) / 200)
end
module.doRegen = doRegen

return module