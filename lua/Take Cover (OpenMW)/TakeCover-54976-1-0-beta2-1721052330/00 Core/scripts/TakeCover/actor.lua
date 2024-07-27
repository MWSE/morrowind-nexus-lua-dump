local self = require('openmw.self')
local types = require('openmw.types')
local ai = require('openmw.interfaces').AI

local S = require('scripts.TakeCover.settings')
local U = require('scripts.TakeCover.util')

local interfaceVersion = 1.0
local updateRate = 0.5
local seenUpdateRate = 0.2
local lastUpdateTime = 0
local lastFleeTime = 0
local turnAroundAndSneak = false

local actorId = U.getRecord(self).id

local state = {
    handled = false,
    fleeing = false,
    stopped = false,
    hidden = false,
    healthHidden = nil,
    notOnGroundTime = 0,
    hasFliesTrait = false,
    fleeDuringSec = 0,
}

local target

-- Ensure the actor will flee if he cannot attack the player
local function flee()
    if state.fleeing then return end
    U.debugPrint(string.format("Actor \"%s\" is probably fleeing", actorId))
    state.fleeing = true
end

local function unFlee()
    if not state.fleeing then return end
    U.debugPrint(string.format("Actor \"%s\" has probably stopped fleeing", actorId))
    state.fleeing = false
end

local function stop()
    if state.stopped then return end
    U.debugPrint(string.format("Actor \"%s\" stops his AI", actorId))
    self:enableAI(false)
    state.stopped = true
end

local function unStop()
    if not state.stopped then return end
    U.debugPrint(string.format("Actor \"%s\" resumes his AI", actorId))
    self.controls.sneak = false
    self:enableAI(true)
    state.stopped = false
end

local function hide()
    stop()
    unFlee()
    if state.hidden then return end
    U.debugPrint(string.format("Actor \"%s\" hides himself", actorId))
    state.healthHidden = types.Actor.stats.dynamic.health(self).current
    turnAroundAndSneak = true
    state.hidden = true
end

local function unHide()
    unStop()
    if not state.hidden then return end
    U.debugPrint(string.format("Actor \"%s\" stops hiding himself", actorId))
    state.healthHidden = nil
    state.hidden = false
end

local function isAttackedWhileHidden()
    if state.healthHidden ~= types.Actor.stats.dynamic.health(self).current then
        state.fleeDuringSec = 5
        U.debugPrint(string.format("Actor \"%s\" is attacked while hidden", actorId))
        return true
    end
    return false
end

local function getCombatTarget()
    local aiPackage = ai.getActivePackage()
    return (aiPackage and aiPackage.type == "Combat") and aiPackage.target or nil
end

local function turnAround(deltaTime)
    if not turnAroundAndSneak then return end
    if not target then
        turnAroundAndSneak = false
    else
        turnAroundAndSneak = U.turnAround(self, target, deltaTime)
        if not turnAroundAndSneak and state.stopped then
            self.controls.sneak = true
        end
    end
end

local function isFlying(deltaTime)
    if state.hasFliesTrait then return true end

    if not types.Actor.isOnGround(self) and not types.Actor.isSwimming(self) then
        state.notOnGroundTime = state.notOnGroundTime + deltaTime
        if state.notOnGroundTime > 3 then
            U.debugPrint(string.format("Actor \"%s\" probably has flies trait", actorId))
            state.notOnGroundTime = 0
            state.hasFliesTrait = true
            return true
        end
    else
        state.notOnGroundTime = 0
    end
    return false
end

local function handleFleeing(deltaTime)
    if not state.fleeing or target == nil then return end

    lastFleeTime = lastFleeTime + deltaTime
    if lastFleeTime < seenUpdateRate or lastFleeTime < state.fleeDuringSec then return end

    if not U.seenByTarget(self, actorId, target) then
        hide()
    end
    lastFleeTime = 0
    state.fleeDuringSec = 0
end

local function unHandle()
    unFlee()
    unHide()
    state.handled = false
end

local function onUpdate(deltaTime)
    if not state.handled then return end

    turnAround(deltaTime)
    handleFleeing(deltaTime)

    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < updateRate then return end

    if U.isLevitating(self) then
        U.debugPrint(string.format("Actor \"%s\" is levitating", actorId))
        return
    end
    if isFlying(lastUpdateTime) then
        unHandle()
        return
    end

    lastUpdateTime = 0

    local prevTarget = target

    target = getCombatTarget()

    if not target then
        if prevTarget then
            U.debugPrint(string.format("Target %s dropped for actor \"%s\"", prevTarget.id, actorId))
        end
        unHandle()
        return
    end

    local targetIsRangedAttack, _ = U.getAttackInfo(target)

    if state.hidden and (not targetIsRangedAttack
            or isAttackedWhileHidden()
            or not types.Actor.isInActorsProcessingRange(self)
            or U.seenByTarget(self, actorId, target)) then
        unHide()
    end

    if targetIsRangedAttack and not U.canAttackTarget(self, actorId, target) then
        if not state.hidden then
            flee()
        end
    else
        unHandle()
    end
end

local function handle()
    state.handled = true
end

local function onSave()
    if state.handled then
        return {
            state = state
        }
    end
end

local function onLoad(data)
    state = (data and data.state) and data.state or state
    if state.stopped then
        -- Restore lost disabled AI state
        state.stopped = false
        stop()
    end
end

local function IsFleeing()
    return state.fleeing
end

local function IsHidden()
    return state.hidden
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        handle = handle,
    },
    interfaceName = S.MOD_NAME,
    interface = {
        version = interfaceVersion,
        IsFleeing = IsFleeing,
        IsHidden = IsHidden,
    }
}
