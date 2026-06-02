---@omw-context local
local I                = require("openmw.interfaces")
local core             = require('openmw.core')
local self             = require('openmw.self')
local types            = require('openmw.types')
local logging          = require('scripts.ngarde.helpers.logger').new()
local parryController  = require('scripts.ngarde.controllers.parry').new()
local Constants        = require('scripts.ngarde.helpers.constants')
local modInfo          = require('scripts.ngarde.modinfo')
local isDead           = types.Actor.isDead
local getWeaponRecord  = types.Weapon.record
local getStance        = types.Actor.getStance
local isFleeing        = I.AI.isFleeing
local getActivePackage = I.AI.getActivePackage
local id               = math.random()
local releaseActor     = false

I.Combat.addOnHitHandler(function(attack)
    if not releaseActor then -- turning the onHitHandler into noop if the script is detached
        logging:debug("localid:" .. id)
        logging:debug(tostring(self) .. ":" .. parryController.id)
        attack = parryController:onHitHandler(attack)
    end
end)



local function onEnemyPerfectParry()
    parryController:onEnemyPerfectParry()
end

local function trackPrimaryTarget()
    if not parryController.primaryTarget or
        not parryController.primaryTarget:isValid() then
        parryController.primaryTarget = I.AI.getActivePackage().target
    end
end

local function hasWeirdAIPackage()
    local activeAIPackage = getActivePackage()
    if activeAIPackage then
        if (activeAIPackage.type:lower() == "cast" or
                activeAIPackage.type:lower() == "unknown") then
            return true
        end
    end
    return false
end

-- this is fucking stupid, but nothing else works 100% of the time
-- if an actor changes stance while n'garde was enforcing controls.use and is then controlled by mwscript - it gets stuck with use = 0
-- delaying the stance release by several frames is still unreliable. Hence we are scanning controls.use every fucking frame, and if it's 0 for more than X frames
-- while in combat - we flip it to 1 once.
local stanceReleaseDoneOnce = true
local timeFrozen = 0
local timeFrozenLImit = 1
local function delayedUnfreezeNPC(realDeltaT)
    if not stanceReleaseDoneOnce then
        if hasWeirdAIPackage() then
            -- logging:status("frozen for:"..tostring(timeFrozen))
            -- logging:status("self.controls.use:"..tostring(self.controls.use))

            if self.controls.use == 0 then
                if timeFrozen > timeFrozenLImit then
                    logging:debug(tostring(self) .. "unfreezing")
                    self.controls.use = self.ATTACK_TYPE.Any
                    stanceReleaseDoneOnce = true
                    timeFrozen = 0
                    return
                else
                    -- logging:status("increment by:"..tostring(realDeltaT))
                    timeFrozen = timeFrozen + realDeltaT
                    return
                end
            end
        end
    end
    timeFrozen = 0
end




local frameIsMelee = false
local frameStanceIsWeapon = false
local frameControlsUse = 0
local function onUpdate(dt)
    if core.isWorldPaused() then return end
    --#region timers
    local realDeltaT = core.getRealFrameDuration()
    delayedUnfreezeNPC(realDeltaT)
    parryController.localTimers.attackWindupTimer:processTimer(realDeltaT)
    parryController.localTimers.perfectParryTimer:processTimer(realDeltaT)
    parryController.localTimers.reactionTimerRaiseGuard:processTimer(realDeltaT)
    parryController.localTimers.reactionTimerLowerGuard:processTimer(realDeltaT)
    parryController.localTimers.currentParryTimer:processTimer(realDeltaT)
    parryController.localTimers.parryCooldownTimer:processTimer(realDeltaT)
    parryController.localTimers.staggerCooldownTimer:processTimer(realDeltaT)
    --#endregion
    local activeAIPackage = getActivePackage()
    if isDead(self) or
        isFleeing() or
        releaseActor or
        (activeAIPackage and (activeAIPackage.type:lower() == "cast" or
            activeAIPackage.type:lower() == "unknown")) then
        if parryController.isParrying then
            parryController:forceLowerGuard()
        end
        if parryController.isStaggered then
            parryController.isStaggered = false
        end
        parryController.isAttacking = false
        return
    end

    trackPrimaryTarget()

    parryController:preventStuckParryAnimation()


    if parryController.myRangedThreat.minReached then
        parryController:prepareOrSendRangedThreat(realDeltaT)
    end

    local lastFrameStanceIsWeapon = frameStanceIsWeapon
    frameStanceIsWeapon = (getStance(self) == types.Actor.STANCE.Weapon)
    local becameWeaponStance = (not lastFrameStanceIsWeapon and frameStanceIsWeapon)
    local becameNotWeaponStance = (lastFrameStanceIsWeapon and not frameStanceIsWeapon)


    parryController:checkStaggerState()
    if becameNotWeaponStance then
        self:sendEvent("ngarde_stanceChangeRelease")
        return
    end
    if frameStanceIsWeapon then
        parryController:updateEquippedIfChanged()
        local weaponRecord = getWeaponRecord(parryController.currentEquippedR.recordId) or Constants
            .HandToHandRecordStub
        local wasMelee = frameIsMelee
        frameIsMelee = (Constants.rangedWeapons[weaponRecord.type] == nil) and frameStanceIsWeapon
        local becameMelee = (not wasMelee and frameIsMelee)
        local becameNotMelee = (wasMelee and not frameIsMelee)
        if becameNotMelee then
            self:sendEvent("ngarde_stanceChangeRelease")
            return
        end

        if parryController.myRangedThreat.minReached then
            parryController:prepareOrSendRangedThreat(realDeltaT)
        end
        if parryController.myMeleeThreat.minReached then
            parryController:readMeleeWindup(realDeltaT, self.controls.use)
        end


        local lastFrameControlsUse = frameControlsUse
        frameControlsUse = self.controls.use
        local releasedAttack = (self.controls.use == self.ATTACK_TYPE.NoAttack and lastFrameControlsUse ~= self.ATTACK_TYPE.NoAttack)

        -- if releasedAttack and frameIsMelee then
        --     for _, target in pairs(parryController.targets) do
        --         target:sendEvent(
        --             "ngarde_attackReleased", parryController.myMeleeThreat)
        --     end
        --     parryController.myMeleeThreat.minReached = false
        -- end
        if frameIsMelee then
            if self.controls.use ~= self.ATTACK_TYPE.NoAttack then -- if attack is melee control windup, else just let the game handle it
                parryController:startAttackWindup(self.controls.use)
                parryController:sendMeleeThreat(self)
                -- logging:debug(tostring(self) .. "starting attack windup")
            end

            if (parryController.currentWeaponConfig or parryController.currentShieldConfig) then -- only handle those that have parry tools
                -- logging:debug(tostring(self) .. "can be processed")
                if parryController.localTimers.attackWindupTimer.active and parryController.windup ~= self.ATTACK_TYPE.NoAttack then
                    -- logging:debug(tostring(self) .. "holding windup")
                    self.controls.use = parryController.windup
                end
                if parryController:isAttackForbidden() then
                    self.controls.use = self.ATTACK_TYPE.NoAttack
                end

                if parryController.primaryTarget and not parryController.isParrying then -- no handling for ranged, no handling while guard raised
                    -- logging:debug(tostring(self) .. "keeping measure Distance")
                    parryController:keepMeasureDistance(parryController.primaryTarget)
                end
                if parryController.isParrying then
                    -- logging:debug(tostring(self) .. "fatigueDrainTimer")
                    parryController.localTimers.fatigueDrainTimer:processTimer(realDeltaT)
                    parryController:processMoveSpeedPenalty()
                end
                if parryController.threatData.threatened then
                    parryController.threatData.notThreatenedFramesCounter = 0
                else
                    parryController.threatData.notThreatenedFramesCounter = parryController.threatData
                        .notThreatenedFramesCounter + 1
                    if parryController.threatData.notThreatenedFramesCounter > 60 and parryController.isParrying then
                        parryController:reactionDelayedLowerGuard()
                    end
                end
            end
        end
    end



    parryController.threatData.threatened = false
end

local function processThreatEvent(eventData)
    local threatDistanceLimit = nil
    parryController.threatData.threatened = true
    parryController.targets[eventData.actor.id] = eventData.actor
    if Constants.rangedWeapons[eventData.threatType] == nil then
        threatDistanceLimit = (eventData.threatReach * core.getGMST("fCombatDistance"))
        parryController.threatData.melee = true
    else
        parryController.threatData.melee = false
    end
    return threatDistanceLimit
end

local function processThreatDirection(eventData)
    local threatDistanceLimit = processThreatEvent(eventData)
    local threatArc = 160
    local threatOffset = 0
    if parryController.currentShieldConfig and not parryController.weaponOverridesShield then
        threatArc = parryController.currentShieldConfig.parryArc
        threatOffset = parryController.currentShieldConfig.parryOffset
    elseif parryController.currentWeaponConfig then
        threatArc = parryController.currentWeaponConfig.parryArc
        threatOffset = parryController.currentWeaponConfig.parryOffset
    end
    if not parryController.allowedThreatDirection(self, eventData.actor, threatArc, threatOffset, threatDistanceLimit) then
        -- logging:debug("Threat out of parry sector. Disregard")
        return false
    end
    return true
end

local function onThreat(eventData)
    if isDead(self) then return end
    if releaseActor then return end
    if isFleeing() then return end
    if getStance(self) ~= types.Actor.STANCE.Weapon then return end                                     -- can't/won't react to threat in magic or nothing stance
    if not (parryController.currentWeaponConfig or parryController.currentShieldConfig) then return end -- can't/won't react to threat if no weapon/shield equipped
    -- logging:debug("I(" .. tostring(self) .. ") am threatened by:" .. tostring(eventData.actor))
    -- logging:debug("Enemy weapon reach:" .. eventData.threatReach)
    -- check if threatening attacker is within range and visually in front of self
    -- only limit range if the threat is melee

    -- early out - if the attacker is too far (1.5 melee weapon reach), or not in front 160 degrees of actor facing
    -- maybe too far in terms of peripheral vision, but meh.
    if not processThreatDirection(eventData) then return end
    -- early out if threat is ranged and actor doesn't have a shield, or has a shield by has a 2h weapon equipped
    -- allow if actor can deflect arrows due to skill levels
    if not (parryController.currentShieldConfig and not parryController.weaponOverridesShield) and parryController.threatData.melee == false then
        -- logging:debug("Threat is ranged and I don't have a shield. Don't attempt parry")
        return
    end
    if (parryController.currentWeaponConfig or parryController.currentShieldConfig) then --only try and parry if you theoretically can/have tools to do so
        parryController:reactionDelayedRaiseGuard(eventData, parryController.threatData.melee)
    end
end

local function onEnemyAttackReleased(eventData)
    parryController.enemyAttackData = eventData
end


local function onRangedThreat(eventData)
    if not processThreatDirection(eventData) then return end
    -- logging:debug(tostring(self) .. " got onRangedThreat.")
    local _ = processThreatEvent(eventData) -- this event is for ranged threats only. Not checking the distance
    if ((parryController.currentWeaponConfig and parryController:getCanDeflectArrows()) or (parryController.currentShieldConfig and not parryController.weaponOverridesShield)) then
        parryController:reactionDelayedRaiseGuard(eventData, false)
    end
end


local function onScriptAttached(eventData)
    logging:debug(tostring(self) .. " got actor script attached.")
    releaseActor = false
    for _, v in ipairs(eventData.targets) do
        -- there's only ever 1 target coming in here, but technically it's a table/list so iterating.
        parryController.primaryTarget = v
        parryController.targets[v.id] = v
    end
end

local function onStopProcessing()
    releaseActor = true
    if self:isActive() and self:isValid() then
        local status, _ = pcall(function() parryController:forceLowerGuard() end)
    end
    parryController:resetControllerState()
end

local function onResumeProcessing()
    releaseActor = false
end

local function detachCleanup()
    local cleanupEventData = { actor = self, fencer = true }
    onStopProcessing()
    core.sendGlobalEvent("ngarde_actorCleanedUp", cleanupEventData)
end

local function onScriptDetached()
    detachCleanup()
end

local function onInactive()
    detachCleanup()
end

local function onStanceChangeRelease()
    stanceReleaseDoneOnce = false
    parryController:forceLowerGuard()
    parryController.isStaggered = false
    parryController.isParrying = false
    parryController.isAttacking = false
end


local NGardeFencer = {}

NGardeFencer.version = modInfo.interfaceVersion
NGardeFencer.whoAmI = function()
    return self.recordId
end
NGardeFencer.isStaggered = function()
    return parryController.isStaggered
end
NGardeFencer.isAttacking = function()
    return parryController.isAttacking
end
NGardeFencer.startedParry = function()
    return parryController.startedParry
end
NGardeFencer.isParrying = function()
    return parryController.isParrying
end
NGardeFencer.isAttackForbidden = function()
    return parryController:isAttackForbidden()
end
NGardeFencer.canParry = function()
    return parryController:canParry()
end
NGardeFencer.forceLowerGuard = function()
    parryController:forceLowerGuard()
end
NGardeFencer.tryRaiseGuard = function()
    parryController:tryRaiseGuard()
end
NGardeFencer.tryLowerGuard = function()
    parryController:tryLowerGuard()
end
NGardeFencer.stopProcessing = function()
    onStopProcessing()
end
NGardeFencer.resumeProcessing = function()
    onResumeProcessing()
end

return {
    interfaceName = "NGardeFencer",
    interface = NGardeFencer,
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = onInactive,
    },
    eventHandlers = {
        ngarde_onThreat = onThreat,
        ngarde_scriptAttached = onScriptAttached,
        ngarde_prepareDetach = onScriptDetached,
        ngarde_onRangedThreat = onRangedThreat,
        ngarde_perfectParry = onEnemyPerfectParry,
        ngarde_attackReleased = onEnemyAttackReleased,
        ngarde_stopProcessing = onStopProcessing,
        ngarde_resumeProcessing = onResumeProcessing,
        ngarde_stanceChangeRelease = onStanceChangeRelease,
    },
}
