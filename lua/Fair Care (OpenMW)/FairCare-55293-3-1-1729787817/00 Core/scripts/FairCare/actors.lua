local core = require('openmw.core')
local T = require('openmw.types')
local util = require("openmw.util")
local nearby = require('openmw.nearby')

local mSettings = require('scripts.FairCare.settings')
local mTools = require('scripts.FairCare.tools')

local fFatigueBase = core.getGMST("fFatigueBase")
local fFatigueMult = core.getGMST("fFatigueMult")
local fDispRaceMod = core.getGMST("fDispRaceMod")
local fDispPersonalityMult = core.getGMST("fDispPersonalityMult")
local fDispPersonalityBase = core.getGMST("fDispPersonalityBase")
local fDispFactionRankMult = core.getGMST("fDispFactionRankMult")
local fDispFactionRankBase = core.getGMST("fDispFactionRankBase")
local fDispFactionMod = core.getGMST("fDispFactionMod")

local module = {}

local function getRecord(item)
    if item.type and item.type.record then
        return item.type.record(item)
    end
    return nil
end
module.getRecord = getRecord

local function actorId(actor)
    return string.format("<%s (%s)>", getRecord(actor).id, actor.id)
end
module.actorId = actorId

local function getPath(actor, target)
    local status, path = nearby.findPath(actor.position, target.position, {
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

local function getTravelTimeSec(actor, path)
    if #path == 1 then return 0 end

    local distance = 0
    for i = 1, #path - 1 do
        distance = distance + (path[i + 1] - path[i]):length()
    end
    return distance / T.Actor.getRunSpeed(actor)
end
module.getTravelTimeSec = getTravelTimeSec

local function isOverEncumbered(actor)
    if actor.type == T.Creature then
        return T.Actor.getEncumbrance(actor) > T.Actor.stats.attributes.strength(actor).modified * 5
    else
        return T.Actor.getEncumbrance(actor) > T.NPC.getCapacity(actor)
    end
end
module.isOverEncumbered = isOverEncumbered

local function faceToPoint(controls, actor, actorBox, targetPos)
    local pitch = actor.rotation:getPitch()
    if pitch ~= 0 then
        controls.pitchChange = -pitch
    else
        controls.pitchChange = 0.0
    end
    controls.sideMovement = 0
    local deltaPos = targetPos - actorBox.center
    local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(actor.rotation:getYaw())
    local deltaYaw = math.atan2(destVec.x, destVec.y)
    controls.yawChange = math.abs(deltaYaw) > math.rad(1) and deltaYaw or 0
end

local function travelToActor(controls, actor, path, target, pointDistanceTolerance, targetDistanceTolerance)
    if actor.id == target.id then return true end

    if #path == 1 then
        controls.movement = 0
        return true
    end
    local actorBox, targetBox = actor:getBoundingBox(), target:getBoundingBox()
    if #path == 2 then
        path[2] = targetBox.center - util.vector3(0, 0, targetBox.halfSize.z)
    end
    if (actorBox.center - targetBox.center):length() < targetDistanceTolerance then
        faceToPoint(controls, actor, actorBox, targetBox.center)
        controls.movement = 0
        return true
    end
    if (actorBox.center - util.vector3(0, 0, targetBox.halfSize.z) - path[2]):length() < pointDistanceTolerance then
        table.remove(path, 1)
    end
    faceToPoint(controls, actor, actorBox, path[2])
    controls.movement = 1
    return false
end
module.travelToActor = travelToActor

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
    --mSettings.debugPrint(string.format("Applying controls: run=%s, jump=%s, sneak=%s, movement=%s, sideMovements=%s, yawChange=%s, pitchChange=%s, use=%s",
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

local function getFatigueTerm(actor)
    local fatigue = T.Actor.stats.dynamic.fatigue(actor)
    local normalised = math.floor(fatigue.base) == 0 and 1 or math.max(0, fatigue.current / fatigue.base)
    return fFatigueBase - fFatigueMult * (1 - normalised);
end
module.getFatigueTerm = getFatigueTerm

local function getDisposition(actor, target)
    if actor.type == T.NPC and target.type == T.Player then
        return mTools.clamp(T.NPC.getDisposition(actor, target), 0, 100)
    end

    local actorRecord, targetRecord = getRecord(actor), getRecord(target)
    local disp = actorRecord.baseDisposition or 50

    disp = disp + fDispPersonalityMult * (T.Actor.stats.attributes.personality(target).modified - fDispPersonalityBase);

    if actor.type == T.Creature or target.type == T.Creature then
        if target.type == T.Player then
            disp = disp + T.Actor.activeEffects(actor):getEffect("charm").magnitude
        elseif actor.type == T.Creature and target.type == T.Creature then
            if actorRecord.type == targetRecord.type then
                disp = disp + mSettings.healingTweaksStorage:get("creatureTypeDispositionBoost")
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
        disp = disp + (fDispFactionRankMult * rank + fDispFactionRankBase) * fDispFactionMod * reaction;
    end

    return mTools.clamp(disp, 0, 100)
end
module.getDisposition = getDisposition

local function isHealAgainDelayOk(lastHealAttemptTime, chance)
    return lastHealAttemptTime + (1 - chance) * mSettings.healingTweaksStorage:get("timeBeforeHealAgainMaxChances")
            < core.getSimulationTime()
end
module.isHealAgainDelayOk = isHealAgainDelayOk

return module