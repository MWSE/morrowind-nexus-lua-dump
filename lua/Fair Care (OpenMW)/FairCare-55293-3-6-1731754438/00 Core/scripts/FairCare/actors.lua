local core = require('openmw.core')
local T = require('openmw.types')
local util = require("openmw.util")
local nearby = require('openmw.nearby')
local aux_util = require('openmw_aux.util')

local mSettings = require('scripts.FairCare.settings')
local mCfg = require('scripts.FairCare.configuration')
local mTools = require('scripts.FairCare.tools')
local mMagic = require('scripts.FairCare.magic')

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
        mTools.debugPrint(string.format("%s cannot heal because he is paralyzed", mTools.actorId(actor)))
        return false
    end

    local fatigue = T.Actor.stats.dynamic.fatigue(actor)
    if fatigue.current <= 0 or fatigue.base == 0 then
        mTools.debugPrint(string.format("%s cannot heal because he is knocked out", mTools.actorId(actor)))
        return false
    end

    if not isOverEncumbered(actor) and not T.Actor.canMove(actor) then
        mTools.debugPrint(string.format("%s cannot heal because seems to be knocked down", mTools.actorId(actor)))
        return false
    end

    return true
end
module.canAct = canAct

local function getPath(actor, position)
    local actorBox = actor:getBoundingBox()
    local status, path = nearby.findPath(
            actorBox.center - util.vector3(0, 0, actorBox.halfSize.z),
            position,
            {
                agentBounds = T.Actor.getPathfindingAgentBounds(actor),
                includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.Swim,
                destinationTolerance = 0,
            })
    if status ~= nearby.FIND_PATH_STATUS.Success or path == nil or #path == 0 then
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
    local actorBox, targetBox = actor:getBoundingBox(), target:getBoundingBox()
    local status, path = nearby.findPath(
            actorBox.center - util.vector3(0, 0, actorBox.halfSize.z),
            targetBox.center - util.vector3(0, 0, targetBox.halfSize.z),
            {
                agentBounds = T.Actor.getPathfindingAgentBounds(actor),
                includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.Swim,
                destinationTolerance = 0,
            })
    if status ~= nearby.FIND_PATH_STATUS.Success or path == nil or #path == 0 then
        if (actorBox.center - targetBox.center):length() <= distanceTolerance then
            mTools.debugPrint(string.format("%s has no path to %s but is close enough", mTools.actorId(actor), mTools.actorId(target)))
            return { actorBox.center - util.vector3(0, 0, actorBox.halfSize.z) }
        end
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
    local actorPos = actor:getBoundingBox().center
    local neighbors = {}
    for _, neighbor in pairs(nearby.actors) do
        if actor.id ~= neighbor.id and (actorPos - neighbor:getBoundingBox().center):length() < maxDistance then
            table.insert(neighbors, neighbor)
        end
    end
    return neighbors
end
module.getCloseActors = getCloseActors

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

local function getRandomPointAtAngle(position, angle, minRadius, maxRadius)
    local radius = minRadius + math.random() * (maxRadius - minRadius)
    return util.vector3(
            position.x + radius * math.cos(angle),
            position.y + radius * math.sin(angle),
            position.z)
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

local function getTravelDistanceFromTime(actor, time)
    return time * T.Actor.getRunSpeed(actor)
end
module.getTravelDistanceFromTime = getTravelDistanceFromTime

local function getRandomDestinationAvoidingTargets(actor, targets)
    local targetAngles = {}
    local actorCenter = actor:getBoundingBox().center
    for _, target in ipairs(targets) do
        local targetCenter = target:getBoundingBox().center
        local deltaPos = targetCenter - actorCenter
        local coveringAngle = getTargetCoveringAngle(actorCenter, targetCenter, target)
        table.insert(targetAngles, { angle = math.atan2(deltaPos.y, deltaPos.x), delta = coveringAngle / 2 })
    end
    local escapeAngles = getValidAngleRanges(targetAngles)
    --mTools.debugPrint(string.format("%s found escape angles %s", mTools.actorId(actor), aux_util.deepToString(escapeAngles, 3)))

    if #escapeAngles == 0 then return nil, nil end

    local escapeAngle = getRandomAngleFromRanges(escapeAngles)

    local destination = getRandomPointAtAngle(
            actorCenter,
            escapeAngle,
            getTravelDistanceFromTime(actor, mCfg.minEscapeTime),
            getTravelDistanceFromTime(actor, mCfg.maxEscapeTime))
    return destination, escapeAngle, (actorCenter - destination):length()
end

local function getRetreatPosition(actor, targets)
    --mTools.debugPrint(string.format("%s will try to escape and avoid %s", mTools.actorId(actor), mTools.actorIds(targets)))
    local position, angle, distance = getRandomDestinationAvoidingTargets(actor, targets)
    if not position then return nil, nil, nil end
    return nearby.findRandomPointAroundCircle(position, mCfg.validPointSearchRadius, {
        agentBounds = T.Actor.getPathfindingAgentBounds(actor),
        includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.Swim,
    }), angle, distance
end
module.getRetreatPosition = getRetreatPosition

local function isCloseEnoughForTouchSpell(actor, target, touchSpellDistance)
    return (actor:getBoundingBox().center - target:getBoundingBox().center):length() <= touchSpellDistance
end
module.isCloseEnoughForTouchSpell = isCloseEnoughForTouchSpell

local function getPathTravelTime(actor, path)
    if #path == 1 then return 0 end

    local distance = 0
    for i = 1, #path - 1 do
        distance = distance + (path[i + 1] - path[i]):length()
    end
    return distance / T.Actor.getRunSpeed(actor)
end
module.getPathTravelTime = getPathTravelTime

local function faceToPoint(controls, actor, targetPos, pitchToTarget, deltaTime)
    local pitch, yaw = actor.rotation:getAnglesXZ()
    local deltaPos = targetPos - actor:getBoundingBox().center

    local deltaPitch = -pitch - (pitchToTarget and math.asin(deltaPos.z / deltaPos:length()) or 0)
    controls.pitchChange = math.abs(deltaPitch) > math.rad(1) and util.clamp(deltaPitch, -deltaTime * 5, deltaTime * 5) or 0

    local destYawVec = util.vector2(deltaPos.x, deltaPos.y):rotate(yaw)
    local deltaYaw = math.atan2(destYawVec.x, destYawVec.y)
    controls.yawChange = math.abs(deltaYaw) > math.rad(1) and util.clamp(deltaYaw, -deltaTime * 5, deltaTime * 5) or 0
end
module.faceToPoint = faceToPoint

local function travel(controls, actor, path, deltaTime)
    if #path == 1 then
        controls.movement = 0
        return true
    end
    local actorBox = actor:getBoundingBox()
    if (actorBox.center - util.vector3(0, 0, actorBox.halfSize.z) - path[2]):length() < mCfg.distanceToPathPointTolerance then
        table.remove(path, 1)
    else
        faceToPoint(controls, actor, path[2], false, deltaTime)
    end
    controls.movement = 1
    return false
end
module.travel = travel

local function travelToTarget(controls, actor, path, target, targetDistanceTolerance, deltaTime)
    local actorBox, targetBox = actor:getBoundingBox(), target:getBoundingBox()
    if #path == 1 then
        faceToPoint(controls, actor, targetBox.center, true, deltaTime)
        controls.movement = 0
        return true
    end
    if #path == 2 then
        path[2] = targetBox.center - util.vector3(0, 0, targetBox.halfSize.z)
    end
    if (actorBox.center - targetBox.center):length() < targetDistanceTolerance then
        faceToPoint(controls, actor, targetBox.center, true, deltaTime)
        controls.movement = 0
        return true
    end
    if (actorBox.center - util.vector3(0, 0, targetBox.halfSize.z) - path[2]):length() < mCfg.distanceToPathPointTolerance then
        table.remove(path, 1)
    else
        faceToPoint(controls, actor, path[2], false, deltaTime)
    end
    controls.movement = 1
    return false
end
module.travelToTarget = travelToTarget

local function newControls(actor)
    return {
        run = false,
        jump = false,
        sneak = false,
        movement = 0,
        sideMovement = 0,
        yawChange = 0,
        pitchChange = 0,
        use = actor.ATTACK_TYPE.NoAttack,
    }
end
module.newControls = newControls

local function applyControls(controls, actor)
    --mTools.debugPrint(string.format("Applying controls: run=%s, jump=%s, sneak=%s, movement=%s, sideMovements=%s, yawChange=%s, pitchChange=%s, use=%s",
    --        controls.run, controls.jump, controls.sneak, controls.movement, controls.sideMovement, controls.yawChange, controls.pitchChange, controls.use))
    actor.controls.run = controls.run
    actor.controls.jump = controls.jump
    actor.controls.sneak = controls.sneak
    actor.controls.movement = controls.movement
    actor.controls.sideMovement = controls.sideMovement
    actor.controls.yawChange = controls.yawChange
    actor.controls.pitchChange = controls.pitchChange
    actor.controls.use = controls.use
end
module.applyControls = applyControls

local function getDisposition(actor, target)
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
                disp = disp + mSettings.getStorage(mSettings.healingTweaksKey):get("creatureTypeDispositionBoost")
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

local function isHealAgainDelayOk(healDelayStartTime, chance)
    return healDelayStartTime + mSettings.getStorage(mSettings.healingTweaksKey):get("timeBeforeHealAgainMaxChances")
            * (1 - chance) ^ 0.5 < core.getSimulationTime()
end
module.isHealAgainDelayOk = isHealAgainDelayOk

local function getCastAnimationConfig(attackAnimations, isSelfSpell)
    if attackAnimations then
        return { groupName = mTools.pick(attackAnimations), startKey = "start", releaseKey = "stop" }
    end
    if isSelfSpell then
        return { groupName = "spellcast", startKey = "self start", releaseKey = "self release" }
    else
        return { groupName = "spellcast", startKey = "touch start", releaseKey = "touch release" }
    end
end
module.getCastAnimationConfig = getCastAnimationConfig

local function getActor(id)
    for _, actor in pairs(nearby.actors) do
        if mTools.getRecord(actor).id == id then
            return actor
        end
    end
end
module.getActor = getActor

local function canRegen(actor, record, state)
    return mSettings.getStorage(mSettings.globalKey):get("healthRegenEnabled")
            and (not state.selfHealSpellId or mSettings.getStorage(mSettings.globalKey):get("healthRegenForHealers"))
            and mSettings.canActorTypeRegen(actor, record)
end
module.canRegen = canRegen

local function doRegen(actor, deltaTime)
    local health = T.Actor.stats.dynamic.health(actor)
    health.current = math.min(
            health.base,
            health.current
                    + mSettings.getHealthRegenRatio()
                    * deltaTime
                    * (T.Actor.stats.attributes.endurance(actor).modified + T.Actor.stats.attributes.strength(actor).modified) / 200)
end
module.doRegen = doRegen

return module