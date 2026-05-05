local I               = require("openmw.interfaces")
local core            = require('openmw.core')
local self            = require('openmw.self')
local types           = require('openmw.types')
local logging         = require('scripts.ngarde.helpers.logger').new()
local parryController = require('scripts.ngarde.controllers.parry').new()
local isDead          = types.Actor.isDead
local getWeaponRecord = types.Weapon.record
local getStance       = types.Actor.getStance
logging:setLoglevel(logging.LOG_LEVELS.OFF)
local function onPerfectParry()
    parryController:onEnemyPerfectParry()
end

I.Combat.addOnHitHandler(function(attack)
    attack = parryController:onHitHandler(attack)
end)

local releaseActor = false
local frameStanceIsWeapon = false
local function onUpdate(dt)
    --#region timers
    local realDeltaT = core.getRealFrameDuration()
    parryController.localTimers.attackWindupTimer:processTimer(realDeltaT)
    parryController.localTimers.perfectParryTimer:processTimer(realDeltaT)
    parryController.localTimers.reactionTimerRaiseGuard:processTimer(realDeltaT)
    parryController.localTimers.reactionTimerLowerGuard:processTimer(realDeltaT)
    parryController.localTimers.currentParryTimer:processTimer(realDeltaT)
    parryController.localTimers.parryCooldownTimer:processTimer(realDeltaT)
    parryController.localTimers.staggerCooldownTimer:processTimer(realDeltaT)

    --#endregion
    if core.isWorldPaused() or
        isDead(self) or
        I.AI.isFleeing() or
        releaseActor then
        if parryController.isParrying then
            parryController:forceLowerGuard()
        end
        if parryController.isStaggered then
            parryController.isStaggered = false
        end
        return
    end
    -- if types.NPC.record(self).id == "sdtrib_savor hlan" or types.NPC.record(self).id == "sdtrib_vonos veri" then
    --     logging:debug(tostring(self))
    --     logging:debug(tostring(self) .. "stance:" .. getStance(self))
    --     logging:debug(parryController)
    --     logging:debug(tostring(self) .. "isStaggered:" .. tostring(parryController.isStaggered))
    --     logging:debug(tostring(self) .. "isParrying:" .. tostring(parryController.isParrying))
    --     logging:debug(tostring(self) .. "isAttacking:" .. tostring(parryController.isAttacking))
    -- end

    local lastFrameStanceIsWeapon = frameStanceIsWeapon
    frameStanceIsWeapon = (getStance(self) == types.Actor.STANCE.Weapon)
    local becameWeaponStance = (not lastFrameStanceIsWeapon and frameStanceIsWeapon)
    local becameNotWeaponStance = (lastFrameStanceIsWeapon and not frameStanceIsWeapon)


    parryController:checkStaggerState()
    parryController:checkAttackState(self.controls.use)
    if becameNotWeaponStance then
        parryController:forceLowerGuard()
        parryController.isStaggered = false
        parryController.isParrying = false
    end
    if frameStanceIsWeapon then
        parryController:updateEquippedIfChanged()
        local weaponRecord = getWeaponRecord(parryController.currentEquippedR.recordId) or Constants
            .HandToHandRecordStub
        local isMelee = (Constants.rangedWeapons[weaponRecord.type] == nil) and frameStanceIsWeapon

        if self.controls.use ~= self.ATTACK_TYPE.NoAttack then
            if isMelee then -- if attack is melee control windup, else just let the game handle it
                parryController:startAttackWindup(self.controls.use)
                logging:debug(tostring(self) .. "starting attack windup")
            end
            for _, target in pairs(parryController.targets) do
                target:sendEvent(
                    "ngarde_onThreat",
                    {
                        actor = self,
                        threatType = weaponRecord.type,
                        threatReach = weaponRecord.reach
                    })
            end
        end

        if (parryController.currentWeaponConfig or parryController.currentShieldConfig) then -- only handle those that have parry tools
            logging:debug(tostring(self) .. "can be processed")
            if isMelee and parryController.localTimers.attackWindupTimer.active and parryController.windup ~= self.ATTACK_TYPE.NoAttack then
                self.controls.use = parryController.windup
                logging:debug(tostring(self) .. "holding windup")
            end
            if (parryController.isStaggered or parryController.isParrying) then
                self.controls.use = self.ATTACK_TYPE.NoAttack
                logging:debug(tostring(self) .. "preventing attack")
            end

            if isMelee and parryController.primaryTarget then -- no handling for ranged
                logging:debug(tostring(self) .. "keeping measure Distance")
                parryController:keepMeasureDistance(parryController.primaryTarget)
            end
            if parryController.isParrying then
                logging:debug(tostring(self) .. "fatigueDrainTimer")
                parryController.localTimers.fatigueDrainTimer:processTimer(realDeltaT)
                parryController:processMoveSpeedPenalty()
            end
            if isMelee then
                if parryController.threatData.threatened then
                    parryController.threatData.notThreatenedFramesCounter = 0
                else
                    parryController.threatData.notThreatenedFramesCounter = parryController.threatData
                        .notThreatenedFramesCounter + 1
                    if parryController.threatData.notThreatenedFramesCounter > 15 and parryController.isParrying then
                        parryController:reactionDelayedLowerGuard()
                    end
                end
            end
        end
    end


    parryController.threatData.threatened = false
end

local function onThreat(eventData)
    if isDead(self) then return end
    if releaseActor then return end
    if getStance(self) ~= types.Actor.STANCE.Weapon then return end                                      -- can't/won't react to threat in magic or nothing stance
    if not (parryController.currentWeaponConfig or parryController.currentShieldConfig) then return end  -- can't/won't react to threat if no weapon/shield equipped
    parryController.threatData.threatened = true
    parryController.targets[eventData.actor.id] = eventData.actor
    logging:debug("I(" .. tostring(self) .. ") am threatened by:" .. tostring(eventData.actor))
    logging:debug("Enemy weapon reach:" .. eventData.threatReach)
    -- check if threatening attacker is within range and visually in front of self
    local threatDistanceLimit = nil
    -- only limit range if the threat is melee
    if Constants.rangedWeapons[eventData.threatType] == nil then
        threatDistanceLimit = (eventData.threatReach * core.getGMST("fCombatDistance"))
        parryController.threatData.melee = true
    else
        parryController.threatData.melee = false
    end
    -- early out - if the attacker is too far (1.5 melee weapon reach), or not in front 160 degrees of actor facing
    -- maybe too far in terms of peripheral vision, but meh.
    if not parryController:allowedThreatDirection(eventData.actor, SettingsConstants.frontArc, 0, threatDistanceLimit) then
        logging:debug("Threat comes from too far, or from behind. Disregard")
        return
    end
    -- early out if threat is ranged and actor doesn't have a shield, or has a shield by has a 2h weapon equipped
    if not (parryController.currentShieldConfig and not parryController.weaponOverridesShield) and Constants.rangedWeapons[eventData.threatType] ~= nil then
        logging:debug("Threat is ranged and I don't have a shield. Don't attempt parry")
        return
    end
    if (parryController.currentWeaponConfig or parryController.currentShieldConfig) then --only try and parry if you theoretically can/have tools to do so
        parryController:reactionDelayedRaiseGuard()
    end
end


local function onScriptAttached(eventData)
    logging:debug(tostring(self) .. " got actor script attached.")
    releaseActor = false
    for _, v in ipairs(eventData.targets) do
        -- there's only ever 1 target comng in here, but technically it's a table/list so iterating.
        parryController.primaryTarget = v
        parryController.targets[v.id] = v
    end
end

local function onScriptDetached()
    if not isDead(self) then
        releaseActor = true
        if self:isActive() then
            parryController:forceLowerGuard()
            parryController.isStaggered = false
        end
    end
end


return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        ngarde_onThreat = onThreat,
        ngarde_onScriptAttached = onScriptAttached,
        ngarde_onScriptDetached = onScriptDetached,
        ngarde_perfectParry = onPerfectParry,
    },
}
