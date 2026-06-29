local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')
local async = require('openmw.async')

local mDef = require("scripts.TakeCover.config.definition")
local mStore = require('scripts.TakeCover.config.store')
local mCore = require('scripts.TakeCover.util.core')
local mHelpers = require('scripts.TakeCover.util.helpers')
local log = require('scripts.TakeCover.util.log')

local state = {
    targets = {},
    fleeing = false,
    stopped = false,
    hidden = false,
    enableHiding = true,
    healthHidden = nil,
    fleeDuringSec = 0,
}

local canFly = self.type.record(self).canFly
local refreshTime = 0.5
local lastRefreshTime = 0
local fleeTime = 0.1
local lastFleeTime = 0
local turnAroundAndSneak = false

local function enableOtherMods(enable)
    -- When another disable hiding, we should not enable Mercy.
    -- Other mods disabling Take Cover hiding have to handle actor AI and Mercy enabling.
    if enable and not state.enableHiding then return end
    if I.MercyCAO then
        log(string.format("Mercy CAO control for %s", enable and "Enabling" or "Disabling"))
        I.MercyCAO.setEnabled(enable)
    end
end

local delayedEnableOtherMods = async:registerTimerCallback("delayedEnableOtherMods", function()
    if not state.stopped and not state.fleeing then
        enableOtherMods(true)
    end
end)

-- Ensure the actor will flee if he cannot attack his enemy
local function flee()
    if state.fleeing then return end
    log("Is probably fleeing")
    enableOtherMods(false)
    self:enableAI(true)
    state.fleeing = true
end

local function unFlee()
    if not state.fleeing then return end
    log("Has probably stopped fleeing")
    async:newSimulationTimer(0.1, delayedEnableOtherMods)
    state.fleeing = false
end

local function stop()
    if state.stopped then return end
    log("Stops his AI")
    self:enableAI(false)
    state.stopped = true
    self.controls.movement = 0
end

local function unStop()
    if not state.stopped then return end
    log("Resumes his AI")
    self:enableAI(true)
    state.stopped = false
    self.controls.use = self.ATTACK_TYPE.NoAttack
    self.controls.sneak = false
end

local function hide()
    state.fleeing = false
    stop()
    if state.hidden then return end
    log("Hides himself")
    enableOtherMods(false)
    state.healthHidden = T.Actor.stats.dynamic.health(self).current
    turnAroundAndSneak = true
    state.hidden = true
end

local function unHide()
    unStop()
    if not state.hidden then return end
    log("Stops hiding himself")
    state.healthHidden = nil
    state.hidden = false
    async:newSimulationTimer(0.1, delayedEnableOtherMods)
end

local function isAttackedWhileHidden()
    if state.healthHidden ~= T.Actor.stats.dynamic.health(self).current then
        log("Is attacked while hidden")
        return true
    end
    return false
end

local function handleCrouching(deltaTime)
    if not turnAroundAndSneak then return end
    if #state.targets == 0 then
        turnAroundAndSneak = false
        return
    end
    self.controls.use = self.ATTACK_TYPE.NoAttack
    turnAroundAndSneak = mCore.turnAround(self, state.targets[1], deltaTime)
    if not turnAroundAndSneak and state.stopped then
        self.controls.sneak = true
    end
end

local function isUnseen()
    for i = 1, #state.targets do
        if mCore.seenByTarget(self, state.targets[i]) then
            return false
        end
    end
    return true
end

local function isSeen()
    for i = 1, #state.targets do
        if mCore.seenByTarget(self, state.targets[i]) then
            return true
        end
    end
    return false
end

local function isSafe()
    for i = 1, #state.targets do
        local target = state.targets[i]
        local targetIsRanged, _ = mCore.getAttackInfo(target)
        if targetIsRanged and not mCore.canAttackTarget(self, target) then
            return false
        end
    end
    return true
end

local function handleFleeing(deltaTime)
    if not state.fleeing or #state.targets == 0 then return end
    lastFleeTime = lastFleeTime + deltaTime
    if lastFleeTime < fleeTime or lastFleeTime < state.fleeDuringSec then return end

    if state.enableHiding and isUnseen() then
        hide()
    end
    lastFleeTime = 0
    state.fleeDuringSec = 0
end

local function unHandle()
    unFlee()
    unHide()
end

local function onUpdate(deltaTime)
    if deltaTime == 0 or not mStore.settings.enabled.get() then return end

    handleCrouching(deltaTime)
    handleFleeing(deltaTime)

    lastRefreshTime = lastRefreshTime + deltaTime
    if lastRefreshTime < refreshTime then return end
    lastRefreshTime = 0

    if #state.targets == 0 then
        unHandle()
        return
    end

    if canFly then
        --log(string.format("Actor %s can fly", actorId))
        unHandle()
        return
    end
    if not T.Actor.isInActorsProcessingRange(self) then
        unHandle()
        return
    end
    if mCore.isLevitating(self) then
        log("Is levitating")
        unHandle()
        return
    end

    if state.hidden then
        if isAttackedWhileHidden() then
            state.fleeDuringSec = 5
            unHide()
        elseif isSeen() then
            state.fleeDuringSec = 2
            unHide()
        end
    end

    if isSafe() then
        unHandle()
        return
    end

    if not state.hidden then
        flee()
    end
end

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if not data then return end

    state = data.state
    if data.version < 1.6 then
        state.targets = {}
    end

    if state.stopped then
        -- Restore lost disabled AI state
        state.stopped = false
        stop()
    end
end

local function enableHiding(enable)
    if not mStore.settings.enabled.get() then return end
    state.enableHiding = enable
    if not enable then
        unHide()
    end
end

local function onInactive()
    unHide()
end

local function onTargetsChanged(targets)
    log(string.format("Got new targets: ", mHelpers.objectIds(targets)))
    state.targets = targets
    if #targets == 0 then
        unHide()
    end
end

local function onInit(targets)
    onTargetsChanged(targets)
end

mStore.addTrackerCallback(function(key, oldValue)
    if key == mStore.settings.enabled.key and oldValue then
        unHide()
    end
end)

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
        isFleeing = function() return state.fleeDuringSec end,
        isHidden = function() return state.hidden end,
        enableHiding = enableHiding,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onInit = onInit,
        onInactive = onInactive,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        [mDef.events.onTargetsChanged] = onTargetsChanged,
    },
}
