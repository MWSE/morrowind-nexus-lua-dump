local I = require("openmw.interfaces")
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local ai = require('openmw.interfaces').AI

local S = require('scripts.TakeCover.settings')
local U = require('scripts.TakeCover.util')

local interfaceVersion = 1.0
local updateRate = 0.5
local seenUpdateRate = 0.1
local lastUpdateTime = 0
local lastFleeTime = 0
local turnAroundAndSneak = false

local actorId = U.actorId(self)
local actorCanFly = U.getRecord(self).canFly

local state = {
    handled = false,
    fleeing = false,
    stopped = false,
    hidden = false,
    enableHiding = true,
    healthHidden = nil,
    fleeDuringSec = 0,
}

local target

local function enableOtherMods(enable)
    -- When another disable hiding, we should not enable Mercy.
    -- Other mods disabling Take Cover hiding have to handle actor AI and Mercy enabling.
    if enable and not state.enableHiding then return end
    if I.MercyCAO then
        U.debugPrint(string.format("%s Mercy CAO control for %s", enable and "Enabling" or "Disabling", actorId))
        I.MercyCAO.setEnabled(enable)
    end
end

local delayedEnableOtherMods = async:registerTimerCallback("delayedEnableOtherMods", function()
    if not state.stopped and not state.fleeing then
        enableOtherMods(true)
    end
end)

-- Ensure the actor will flee if he cannot attack the player
local function flee()
    if state.fleeing then return end
    U.debugPrint(string.format("Actor %s is probably fleeing", actorId))
    enableOtherMods(false)
    self:enableAI(true)
    state.fleeing = true
end

local function unFlee()
    if not state.fleeing then return end
    U.debugPrint(string.format("Actor %s has probably stopped fleeing", actorId))
    async:newSimulationTimer(0.1, delayedEnableOtherMods)
    state.fleeing = false
end

local function stop()
    if state.stopped then return end
    U.debugPrint(string.format("Actor %s stops his AI", actorId))
    self:enableAI(false)
    state.stopped = true
end

local function unStop()
    if not state.stopped then return end
    U.debugPrint(string.format("Actor %s resumes his AI", actorId))
    self:enableAI(true)
    state.stopped = false
    self.controls.use = self.ATTACK_TYPE.NoAttack
    self.controls.sneak = false
end

local function hide()
    state.fleeing = false
    stop()
    if state.hidden then return end
    U.debugPrint(string.format("Actor %s hides himself", actorId))
    enableOtherMods(false)
    state.healthHidden = types.Actor.stats.dynamic.health(self).current
    turnAroundAndSneak = true
    state.hidden = true
end

local function unHide()
    unStop()
    if not state.hidden then return end
    U.debugPrint(string.format("Actor %s stops hiding himself", actorId))
    state.healthHidden = nil
    state.hidden = false
    async:newSimulationTimer(0.1, delayedEnableOtherMods)
end

local function isAttackedWhileHidden()
    if state.healthHidden ~= types.Actor.stats.dynamic.health(self).current then
        U.debugPrint(string.format("Actor %s is attacked while hidden", actorId))
        return true
    end
    return false
end

local function getCombatTarget()
    local aiPackage = ai.getActivePackage()
    return (aiPackage and aiPackage.type == "Combat") and aiPackage.target or nil
end

local function crouch(deltaTime)
    if not turnAroundAndSneak then return end
    if not target then
        turnAroundAndSneak = false
        return
    end
    self.controls.use = self.ATTACK_TYPE.NoAttack
    turnAroundAndSneak = U.turnAround(self, target, deltaTime)
    if not turnAroundAndSneak and state.stopped then
        self.controls.sneak = true
    end
end

local function handleFleeing(deltaTime)
    if not state.fleeing or target == nil then return end

    lastFleeTime = lastFleeTime + deltaTime
    if lastFleeTime < seenUpdateRate or lastFleeTime < state.fleeDuringSec then return end

    if state.enableHiding and not U.seenByTarget(self, target) then
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
    if deltaTime == 0 or not state.handled then return end

    crouch(deltaTime)
    handleFleeing(deltaTime)

    lastUpdateTime = lastUpdateTime + deltaTime

    if lastUpdateTime < updateRate then return end

    lastUpdateTime = 0

    if not types.Actor.isInActorsProcessingRange(self) then
        unHandle()
        return
    end
    if U.isLevitating(self) then
        U.debugPrint(string.format("Actor %s is levitating", actorId))
        unHandle()
        return
    end
    if actorCanFly then
        --U.debugPrint(string.format("Actor %s can fly", actorId))
        unHandle()
        return
    end

    local prevTarget = target

    target = getCombatTarget()

    if not target then
        if prevTarget then
            U.debugPrint(string.format("Target %s dropped for actor %s", prevTarget.id, actorId))
        end
        unHandle()
        return
    end

    if state.hidden then
        if isAttackedWhileHidden() then
            state.fleeDuringSec = 5
            unHide()
        elseif U.seenByTarget(self, target) then
            state.fleeDuringSec = 2
            unHide()
        end
    end

    local targetIsRangedAttack, _ = U.getAttackInfo(target)

    if not targetIsRangedAttack or U.canAttackTarget(self, target) then
        unHandle()
        return
    end

    if not state.hidden then
        flee()
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

local function isFleeing()
    return state.fleeing
end

local function isHidden()
    return state.hidden
end

local function enableHiding(enable)
    state.enableHiding = enable
    if not enable and state.isHidden then
        unHide()
    end
end

local function getState()
    return state
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        tc_handle = handle,
    },
    interfaceName = S.MOD_NAME,
    interface = {
        version = interfaceVersion,
        isFleeing = isFleeing,
        isHidden = isHidden,
        enableHiding = enableHiding,
        getState = getState,
    }
}
