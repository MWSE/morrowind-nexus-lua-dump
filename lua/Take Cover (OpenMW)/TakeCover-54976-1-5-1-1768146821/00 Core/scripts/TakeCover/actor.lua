local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')
local async = require('openmw.async')

local mDef = require("scripts.TakeCover.definition")
local mU = require('scripts.TakeCover.util')

local state = {
    handled = false,
    fleeing = false,
    stopped = false,
    hidden = false,
    enableHiding = true,
    healthHidden = nil,
    fleeDuringSec = 0,
}

local canFly = self.type.record(self).canFly
local updateTime = 0.5
local lastUpdateTime = 0
local fleeTime = 0.1
local lastFleeTime = 0
local turnAroundAndSneak = false
local targets = {}
local targetsString

local function enableOtherMods(enable)
    -- When another disable hiding, we should not enable Mercy.
    -- Other mods disabling Take Cover hiding have to handle actor AI and Mercy enabling.
    if enable and not state.enableHiding then return end
    if I.MercyCAO then
        mU.log(string.format("Mercy CAO control for %s", enable and "Enabling" or "Disabling"))
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
    mU.log("Is probably fleeing")
    enableOtherMods(false)
    self:enableAI(true)
    state.fleeing = true
end

local function unFlee()
    if not state.fleeing then return end
    mU.log("Has probably stopped fleeing")
    async:newSimulationTimer(0.1, delayedEnableOtherMods)
    state.fleeing = false
end

local function stop()
    if state.stopped then return end
    mU.log("Stops his AI")
    self:enableAI(false)
    state.stopped = true
end

local function unStop()
    if not state.stopped then return end
    mU.log("Resumes his AI")
    self:enableAI(true)
    state.stopped = false
    self.controls.use = self.ATTACK_TYPE.NoAttack
    self.controls.sneak = false
end

local function hide()
    state.fleeing = false
    stop()
    if state.hidden then return end
    mU.log("Hides himself")
    enableOtherMods(false)
    state.healthHidden = T.Actor.stats.dynamic.health(self).current
    turnAroundAndSneak = true
    state.hidden = true
end

local function unHide()
    unStop()
    if not state.hidden then return end
    mU.log("Stops hiding himself")
    state.healthHidden = nil
    state.hidden = false
    async:newSimulationTimer(0.1, delayedEnableOtherMods)
end

local function isAttackedWhileHidden()
    if state.healthHidden ~= T.Actor.stats.dynamic.health(self).current then
        mU.log("Is attacked while hidden")
        return true
    end
    return false
end

local function handleCrouching(deltaTime)
    if not turnAroundAndSneak then return end
    if #targets == 0 then
        turnAroundAndSneak = false
        return
    end
    self.controls.use = self.ATTACK_TYPE.NoAttack
    turnAroundAndSneak = mU.turnAround(self, targets[1], deltaTime)
    if not turnAroundAndSneak and state.stopped then
        self.controls.sneak = true
    end
end

local function isUnseen()
    for _, target in ipairs(targets) do
        if mU.seenByTarget(self, target) then
            return false
        end
    end
    return true
end

local function isSeen()
    for _, target in ipairs(targets) do
        if mU.seenByTarget(self, target) then
            return true
        end
    end
    return false
end

local function isSafe()
    for _, target in ipairs(targets) do
        local targetIsRanged, _ = mU.getAttackInfo(target)
        if targetIsRanged and not mU.canAttackTarget(self, target) then
            return false
        end
    end
    return true
end

local function handleFleeing(deltaTime)
    if not state.fleeing or #targets == 0 then return end
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
    state.handled = false
end

-- Remove duplicate targets (I've seen the player duplicated)
local function setCombatTargets()
    local ids = {}
    targets = {}
    for _, target in ipairs(I.AI.getTargets("Combat")) do
        if not ids[target.id] then
            ids[target.id] = true
            table.insert(targets, target)
        end
    end
end

local function onUpdate(deltaTime)
    if deltaTime == 0 or not state.handled then return end

    handleCrouching(deltaTime)
    handleFleeing(deltaTime)

    lastUpdateTime = lastUpdateTime + deltaTime

    if lastUpdateTime < updateTime then return end

    lastUpdateTime = 0

    if canFly then
        --U.debugPrint(string.format("Actor %s can fly", actorId))
        unHandle()
        return
    end
    if not T.Actor.isInActorsProcessingRange(self) then
        unHandle()
        return
    end
    if mU.isLevitating(self) then
        mU.log("Is levitating")
        unHandle()
        return
    end

    setCombatTargets()

    local prevTargetsString = targetsString
    targetsString = mU.targetsToString(targets)
    if targetsString ~= prevTargetsString then
        mU.log(string.format("Targets changed from %s to %s", prevTargetsString, targetsString))
    end

    if #targets == 0 then
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
    if not state.handled then return end
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    state = (data and data.state) and data.state or state
    if state.stopped then
        -- Restore lost disabled AI state
        state.stopped = false
        stop()
    end
end

local function enableHiding(enable)
    state.enableHiding = enable
    if not enable and state.isHidden then
        unHide()
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        [mDef.events.handle_actor] = function() state.handled = true end,
    },
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
        isFleeing = function() return state.fleeDuringSec end,
        isHidden = function() return state.hidden end,
        enableHiding = enableHiding,
    }
}
