---@omw-context local
local core               = require("openmw.core")
local I                  = require('openmw.interfaces')
local types              = require('openmw.types')
local anim               = require('openmw.animation')
local async              = require('openmw.async')
local Constants          = require('scripts.ngarde.helpers.constants')
local SC                 = require('scripts.ngarde.helpers.settings_constants')
local Helpers            = require('scripts.ngarde.helpers.helpers')
local logging            = require('scripts.ngarde.helpers.logger').new()
local timers             = require('scripts.ngarde.helpers.timers')
local storage            = require('openmw.storage')
local actorSelf          = require('openmw.self')
local util               = require('openmw.util')
local attackController   = require('scripts.ngarde.controllers.attack')
local movementController = require('scripts.ngarde.controllers.movement')
local threatController   = require('scripts.ngarde.controllers.threat')
local perWeaponModifiers = require('scripts.ngarde.helpers.weapon_parry_table')
local skillUsed
local SKILL_USE_TYPES
local storageSections    =
{
    [SC.parrySettingsGroupKey] = storage.globalSection(SC.parrySettingsGroupKey),
    [SC.balanceSettingsGroupKey] = storage.globalSection(SC.balanceSettingsGroupKey),
    [SC.debugSettingsGroupKey] = storage.globalSection(SC.debugSettingsGroupKey),
}
ParryController          = {}
ParryController.__index  = ParryController
local min                = math.min
local max                = math.max
local floor              = math.floor
local random             = math.random
local clamp              = util.clamp
local getGMST            = core.getGMST
local fatigue            = actorSelf.type.stats.dynamic.fatigue(actorSelf)
local health             = actorSelf.type.stats.dynamic.health(actorSelf)
local getEquipment       = types.Actor.getEquipment
local skills             = actorSelf.type.stats.skills
local attributes         = actorSelf.type.stats.attributes
local getArmorRecord     = types.Armor.record
local getStance          = types.Actor.getStance
local getWeaponRecord    = types.Weapon.record
local getArmorSkill      = I.Combat.getArmorSkill
local activeEffects      = actorSelf.type.activeEffects(actorSelf)
local activeSpells       = actorSelf.type.activeSpells(actorSelf)
local ui



function ParryController.new()
    local self                       = setmetatable({}, ParryController)
    self.id                          = random()
    self.targets                     = {}
    self.primaryTarget               = nil
    self.startedParry                = false
    self.isParrying                  = false
    self.isStaggered                 = false
    self.isAttacking                 = false
    self.currentEquippedR            = { recordId = "None", id = "none" }
    self.currentEquippedL            = { recordId = "None", id = "none" }
    self.currentGauntletR            = { recordId = "None", id = "none" }
    self.currentGauntletL            = { recordId = "None", id = "none" }
    self.currentGauntlets            = { left = nil, right = nil }
    self.recordGauntlets             = { left = nil, right = nil }
    self.recordEquippedR             = nil
    self.recordEquippedL             = nil
    self.currentWeaponConfig         = nil
    self.currentShieldConfig         = nil
    self.activeParryConfig           = nil
    self.activeParryItem             = nil
    self.perfectParryWindow          = 0
    self.recordSelf                  = actorSelf.type.record(actorSelf)
    self.weaponOverridesShield       = false
    self.enchantParrySetting         = SC.enchantParrySettingDefault
    self.enchantParryAOESetting      = SC.enchantParryAOESettingDefault
    self.baseParryDurabilityLoss     = SC.baseParryDurabilityLossDefault
    self.baseParryFatigueCost        = SC.baseParryFatigueCostDefault
    self.ironPalmThreshold           = SC.ironPalmThresholdDefault
    self.perfectParryThreshold       = SC.perfectParryThresholdDefault
    self.threatData                  = { notThreatenedFramesCounter = 0, threatened = false, melee = true }
    self.amPlayer                    = (actorSelf.type == types.Player)
    self.parrySoundVolume            = SC.parrySoundVolumeDefault / 100
    self.rangedThreatHoldMultiplier  = SC.rangedThreatHoldMultiplier
    self.rangedThreatCooldownDivisor = SC.rangedThreatCooldownDivisor
    self.baseGuardFatigueDrain       = SC.baseGuardFatigueDrainDefault
    self.scalingGuardFatigueDrain    = SC.scalingGuardFatigueDrainDefault
    self.allAttacksHit               = SC.allAttacksHitDefault
    self.quickMode                   = SC.quickModeDefault
    self.allowParryCreatures         = SC.allowParryCreaturesDefault
    self.playMissAnimations          = SC.playMissAnimationsDefault
    self.allowArrowDeflect           = SC.allowArrowDeflectDefault
    self.localAnimationSpeed         = 1
    self.windup                      = actorSelf.ATTACK_TYPE.NoAttack
    self.debugMessages               = SC.debugMessagesDefault
    self.debugLogs                   = SC.debugLogsDefault
    self:getMaxAttackChargeDuration(actorSelf)

    self.myRangedThreat = {
        sent = false,
        actor = actorSelf,
        timeDrawn = 0,
        minReached = false,
    }

    self.myMeleeThreat  = {
        sent = false,
        actor = actorSelf,
        timeDrawn = 0,
        minReached = false,
    }

    self.raisedWithPrio = nil --last prio and mask that the parry was raised with
    self.raisedWithMask = nil

    ---@omw-context-begin player
    if self.amPlayer then
        skillUsed       = I.SkillProgression.skillUsed
        SKILL_USE_TYPES = I.SkillProgression.SKILL_USE_TYPES
        ui              = require("openmw.ui")
    end
    ---@omw-context-end player
    --     -- specifically to match behavior to actor/npc skill getters
    self.creatureSkill         = function()
        return { modified = self.recordSelf.combatSkill }
    end
    self.currentStats          = self:initReadStats()
    self.effectivenessSettings = {}
    self:initReadSettings()
    self:selectGuardWith() -- initial read of equipment

    self.localTimers = {
        currentParryTimer       = timers.new(function()
            self:tryLowerGuard()
        end),
        parryCooldownTimer      = timers.new(),
        perfectParryTimer       = timers.new(function()
            self:startskillGainParryTimer()
        end),
        reactionTimerRaiseGuard = timers.new(function()
            self:tryRaiseGuard()
        end),
        reactionTimerLowerGuard = timers.new(function()
            self:tryLowerGuard()
        end),
        fatigueDrainTimer       = timers.new(function()
            self:raisedGuardDrainFatigue()
        end),
        attackWindupTimer       = timers.new(function()
            attackController.releaseAttackWindup(actorSelf)
            self.windup = actorSelf.ATTACK_TYPE.NoAttack
        end),
        staggerCooldownTimer    = timers.new(),
        skillGainParryTimer     = timers.new(),
    }

    for _, storageSection in pairs(storageSections) do
        storageSection:subscribe(async:callback(function(sectionName, changedKey)
            self:readUpdatedSetting(sectionName, changedKey)
        end))
    end

    I.AnimationController.addTextKeyHandler('', function(groupname, key)
        self:preventConsecutiveStagger(groupname, key)
        self:changeGuardState(groupname, key)
        self:checkAttackState(groupname, key)
    end)

    threatController.registerRangedTextKeyHandler(self)


    logging:debug(("Created ParryController for: %s"):format(tostring(actorSelf)))
    return self
end

function ParryController.resetControllerState(self)
    self.primaryTarget = nil
    self.startedParry  = false
    self.isParrying    = false
    self.isStaggered   = false
    self.isAttacking   = false
end

--#region Movement

ParryController.allowedThreatDirection = function(actorSelf, threatActor, arc, offset, maxDistance)
    return movementController.allowedThreatDirection(actorSelf, threatActor, arc, offset, maxDistance)
end
ParryController.keepMeasureDistance = function(self, threatActor)
    movementController.keepMeasureDistance(actorSelf, threatActor, self)
end
ParryController.processMoveSpeedPenalty = function(self)
    movementController.processMoveSpeedPenalty(actorSelf, self.activeParryConfig.moveSpeedMultiplier)
end

--#endregion

ParryController.startAttackWindup = function(self, use)
    attackController.startAttackWindup(self, use)
end
---# region threat comms

ParryController.prepareOrSendRangedThreat = function(self, dT)
    threatController.prepareOrSendRangedThreat(self, dT)
end

ParryController.sendMeleeThreat = function(self, threatActor)
    threatController.sendMeleeThreat(threatActor, self)
end

ParryController.getMaxAttackChargeDuration = function(self, threatActor)
    threatController.getMaxAttackChargeDuration(threatActor, self)
end

ParryController.readMeleeWindup = function(self, dT, use)
    --threatController.readMeleeWindup(self, dT, use)
    return
end

--#endregion


--#region Stats and Skills


function ParryController.initReadStats(self)
    if actorSelf.type == types.Creature then
        return { --creatures don't have skills except combatSkill and magicSkill, but have attributes
            ["handtohand"] = self.creatureSkill(),
            ["shortblade"] = self.creatureSkill(),
            ["longblade"] = self.creatureSkill(),
            ["axe"] = self.creatureSkill(),
            ["spear"] = self.creatureSkill(),
            ["bluntweapon"] = self.creatureSkill(),
            ["block"] = self.creatureSkill(),
            ["speed"] = attributes.speed(actorSelf),
            ["strength"] = attributes.strength(actorSelf),
            ["endurance"] = attributes.endurance(actorSelf),
            ["agility"] = attributes.agility(actorSelf),
            ["luck"] = attributes.luck(actorSelf),
        }
    else
        return {
            ["handtohand"] = skills.handtohand(actorSelf),
            ["shortblade"] = skills.shortblade(actorSelf),
            ["longblade"] = skills.longblade(actorSelf),
            ["axe"] = skills.axe(actorSelf),
            ["spear"] = skills.spear(actorSelf),
            ["bluntweapon"] = skills.bluntweapon(actorSelf),
            ["block"] = skills.block(actorSelf),
            ["speed"] = attributes.speed(actorSelf),
            ["strength"] = attributes.strength(actorSelf),
            ["endurance"] = attributes.endurance(actorSelf),
            ["agility"] = attributes.agility(actorSelf),
            ["luck"] = attributes.luck(actorSelf),
        }
    end
end

-- function ParryController.statUpdate(self, statArray)
--     for _, statId in ipairs(statArray) do
--         self.currentStats[statId].value = self.currentStats[statId].getter.modified
--     end
-- end

--#endregion

--#region Formulas

local formulaFatigueEffects = {
    [SC.fatigueEffectsFormulaValues[SC.fatigue_effects.partial]] = function(value)
        return clamp(value * 2, 0.15, SC.fortifyFatigueMaxImpact)
    end,
    [SC.fatigueEffectsFormulaValues[SC.fatigue_effects.off]] = function(value)
        return 1
    end,
    [SC.fatigueEffectsFormulaValues[SC.fatigue_effects.full]] = function(value)
        return clamp(value, 0.15, SC.fortifyFatigueMaxImpact)
    end
}

---@param statValue number
---@param factor number
function ParryController.getStatCurve(self, statValue, factor, skillCurveStep)
    local skillCurveLength = floor(statValue / skillCurveStep)
    local skillModulo = statValue % skillCurveStep
    local curve = {}
    local multiplier = factor
    table.insert(curve, min(statValue, skillCurveStep) * multiplier)
    for i = 1, skillCurveLength - 1 do
        multiplier = factor / (1 * (SC.baseSkillCurveDivisor * i))
        table.insert(curve, skillCurveStep * multiplier)
        --logging:debug("multiplier:" .. multiplier)
    end
    if skillModulo < statValue then
        table.insert(curve, skillModulo * (multiplier / SC.baseSkillCurveDivisor))
    end
    -- for _, v in ipairs(curve) do
    --     logging:debug("curveValue:"..v)
    -- end
    return Helpers.sum(curve)
end

function ParryController.getCanDeflectArrows(self)
    if not self.allowArrowDeflect then return false end
    if not self.activeParryConfig.name then return false end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].modified
    local hasMainSkill = (mainSkill >= SC.deflectArrowsMainSkillThreshold)
    local hasFallBackSkills = (mainSkill >= SC.deflectArrowsMainSkillFallbackThreshold and secondarySkill >= SC.deflectArrowsSecondarySkillFallbackThreshold)
    local canDeflect = (hasMainSkill or hasFallBackSkills)
    -- if self.activeParryConfig.name == "handToHand" then -- doesn't do anything because iron palm threshold is lower than skill requirement for deflect
    --     canDeflect = (canDeflect and self:processIronPalmThreshold() > 0)
    -- end
    return canDeflect
end

function ParryController.processIronPalmThreshold(self)
    if not self.activeParryConfig then return 0 end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    --#region IronPalm
    local bonusEffectiveness = 0
    if self.activeParryConfig.mainSkillId == "handtohand" and mainSkill >= self.ironPalmThreshold then
        bonusEffectiveness = (0.5 + (0.05 * min(10, max(0, (mainSkill + 1 - self.ironPalmThreshold)))))
        logging:debug(tostring(actorSelf) ..
            ("IronPalm bonusEffectiveness: %s"):format(tostring(bonusEffectiveness)))
    end
    return bonusEffectiveness
    --#endregion
end

function ParryController.processPerfectParryThreshold(self, mainSkill)
    local multiplier = 0.5
    if mainSkill >= self.perfectParryThreshold then
        multiplier = multiplier + (0.05 * min(10, max(0, (mainSkill + 1 - self.perfectParryThreshold))))
        logging:debug(tostring(actorSelf) .. ("Perfect Parry mastery multiplier: %s"):format(tostring(multiplier)))
    end
    return multiplier
end

function ParryController.getParryFatigueCost(self)
    if not self.activeParryConfig then return self.baseParryFatigueCost end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].modified
    local bonusFatigueFromWeight = 0
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SC.fatiugeCostMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SC.fatiugeCostSecondarySkillRatio,
        skillCurveStep)
    if self.activeParryConfig.name == "handtohand" then
        for _, itemRecord in pairs(self.recordGauntlets) do
            bonusFatigueFromWeight = bonusFatigueFromWeight + itemRecord.weight / 10
        end
    else
        if self.recordEquippedL and self.activeParryConfig.name == "shield" then
            bonusFatigueFromWeight = bonusFatigueFromWeight + self.recordEquippedL.weight / 10
        elseif self.recordEquippedR then
            bonusFatigueFromWeight = bonusFatigueFromWeight + self.recordEquippedR.weight / 10
        end
    end
    local ratio = max(
        1 -
        (((mainSkillCurve + secondarySkillCurve) / 100) + (self.activeParryConfig.effectiveness * SC.fatigueCostEffectivenessRatio)),
        0)
    local cost = (self.baseParryFatigueCost + bonusFatigueFromWeight) * ratio
    logging:debug(tostring(actorSelf) .. "parry fatigue flat cost:" .. cost)
    return cost
end

function ParryController.getPerfectParryWindow(self)
    if not self.activeParryConfig then return 0 end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].modified
    local currentFatigue = fatigue.current
    local maxFatigue = fatigue.base
    local fatiguePercentage = formulaFatigueEffects[self.fatigueEffectsFormula](currentFatigue / maxFatigue)
    local skillCurveStep = 45
    local masteryMultiplier = self:processPerfectParryThreshold(mainSkill)
    local mainSkillCurve = self:getStatCurve(mainSkill, SC.perfectParryMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SC.perfectParrySecondarySkillRatio,
        skillCurveStep)
    local window = masteryMultiplier * min(
        (SC.basePerfectParryWindow + ((mainSkillCurve + secondarySkillCurve) / 100)) *
        fatiguePercentage, SC.maxPerfectParryWindow)
    logging:debug(tostring(actorSelf) .. "Perfect parry window:" .. window)

    return window
end

function ParryController.getParryCooldown(self)
    if not self.activeParryConfig then return 1 end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].modified
    local currentFatigue = fatigue.current
    local maxFatigue = fatigue.base
    local fatiguePercentage = formulaFatigueEffects[self.fatigueEffectsFormula](currentFatigue / maxFatigue)
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SC.parryCooldownMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SC.parryCooldownSecondarySkillRatio,
        skillCurveStep)
    if self.amPlayer then
        return 0
    else
        local parryCooldownRatio = max(1 - ((mainSkillCurve + secondarySkillCurve) / 100) * fatiguePercentage, 0)
        local parryCooldown = max(SC.baseParryCooldown * parryCooldownRatio,
            SC.minParryCooldown)
        if not self.amPlayer and not self.threatData.melee then
            parryCooldown = parryCooldown / self.rangedThreatCooldownDivisor
        end
        logging:debug(tostring(actorSelf) .. "parry cooldown:" .. parryCooldown)
        return parryCooldown
    end
end

function ParryController.getReactionTime(self, eventData, melee)
    if self.amPlayer then return 0 end
    if not self.activeParryConfig then return 0.250 end
    local timeToImpact = 0
    local threatMelee = melee
    if threatMelee ~= nil and eventData.drawStrength ~= nil then
        local threatActor = eventData.actor or nil
        if threatMelee == false then
            if threatActor then
                local inverseRotation = actorSelf.rotation:inverse()
                local relPos = inverseRotation * (threatActor.position - actorSelf.position)
                local distSq = relPos.x * relPos.x + relPos.y * relPos.y
                local projectileMaxSpeed = getGMST("fProjectileMaxSpeed")
                local projectileMinSpeed = getGMST("fProjectileMinSpeed")
                if Constants.weaponToTypeMap[eventData.threatType] == "marksmanthrown" then
                    projectileMaxSpeed = getGMST("fThrownWeaponMaxSpeed")
                    projectileMinSpeed = getGMST("fThrownWeaponMinSpeed")
                end
                local speedGuess = ((projectileMaxSpeed - projectileMinSpeed) * eventData.drawStrength) +
                    projectileMinSpeed
                timeToImpact = distSq / (speedGuess ^ 2)
                return timeToImpact
            end
        end
    end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].modified
    local attrSpeed = self.currentStats["speed"].modified
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SC.npcReactionTimeMainSkillFactor, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SC.npcReactionTimeSecondarySkillFactor,
        skillCurveStep)
    local speedCurve = self:getStatCurve(attrSpeed, SC.npcReactionTimeSpeedFactor, skillCurveStep)
    local factor = max(1 - ((mainSkillCurve + secondarySkillCurve + speedCurve) / 100), 0)
    logging:debug(tostring(actorSelf) .. "reaction time multiplier:" .. factor)

    local reactionTimeExtra = 0.0 +
        (random(-5, 5) / 100) --adding some variability to reaction times 0.0 to 0.05 seconds randomly
    local reactionTime = SC.npcReactionTimeMin + (SC.npcReactionTimeBase * factor) +
        reactionTimeExtra
    if self.quickMode then
        reactionTime = reactionTime + 0.5 -- flat increase for reaction time for quick mode
    end
    if Helpers:rollNdM(1, 100, 93) > 0 then
        reactionTime = reactionTime - 0.1
    end
    reactionTime = max(reactionTime, SC.npcReactionTimeMin)
    logging:debug(tostring(actorSelf) .. "reaction time:" .. reactionTime)
    return reactionTime
end

function ParryController.getParryHoldDuration(self)
    if not self.activeParryConfig then return 0 end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].modified
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SC.parryHoldDurationMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SC.parryHoldDurationSecondarySkillRatio,
        skillCurveStep)
    local ratio = max(1 - ((mainSkillCurve + secondarySkillCurve) / 100), 0)
    logging:debug(tostring(actorSelf) .. "parry hold duration ratio:" .. ratio)
    local holdDuration = SC.parryHoldBaseDuration + (1.5 * ratio)
    if not self.amPlayer and not self.threatData.melee then
        holdDuration = holdDuration * self.rangedThreatHoldMultiplier
    end
    logging:debug(tostring(actorSelf) .. "parry hold duration:" .. holdDuration)
    return holdDuration
end

function ParryController.getStaggerCooldown(self)
    if not self.activeParryConfig then return 1 end
    local attrStrength = self.currentStats["strength"].modified
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].modified
    local attrEndurance = self.currentStats["endurance"].modified
    local skillCurveStep = 100
    local strengthCurve = self:getStatCurve(attrStrength, SC.staggerCooldownStrengthRatio, skillCurveStep)
    local enduranceCurve = self:getStatCurve(attrEndurance, SC.staggerCooldownEnduranceRatio,
        skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SC.staggerCooldownSecondarySkillRatio,
        skillCurveStep)
    local cooldown = min(
        SC.staggerCooldownMin + ((strengthCurve + enduranceCurve + secondarySkillCurve) / 100),
        SC.staggerCooldownMax)
    logging:debug(tostring(actorSelf) .. "stagger cooldown:" .. cooldown)

    return cooldown
end

function ParryController.getParryDefenceFactor(self)
    if not self.activeParryConfig then return 1 end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].modified
    local agility = (self.currentStats["agility"].modified - 30) / 5
    local luck = (self.currentStats["luck"].modified - 40) / 10
    local currentFatigue = fatigue.current
    local maxFatigue = fatigue.base
    local fatiguePercentage = formulaFatigueEffects[self.fatigueEffectsFormula](currentFatigue / maxFatigue)
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SC.defenceMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SC.defenceSecondarySkillRatio,
        skillCurveStep)

    local defenceFactor = (1 - min(SC.baseParryDefenceFactor + (((secondarySkillCurve + mainSkillCurve + agility + luck) * fatiguePercentage) / 100) * self.activeParryConfig.effectiveness, 1))
    logging:debug(tostring(actorSelf) .. "defenceFactor:" .. defenceFactor)

    return defenceFactor
end

function ParryController.willParry(self)
    if self.amPlayer then return true end
    if not self.activeParryConfig then return false end
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].modified
    local agility = self.currentStats["agility"].modified
    local luck = self.currentStats["luck"].modified
    local currentFatigue = fatigue.current
    local maxFatigue = fatigue.base
    local fatiguePercentage = formulaFatigueEffects[self.fatigueEffectsFormula](currentFatigue / maxFatigue)
    local parryChance = (mainSkill + (agility / 5) + (luck / 10)) * (0.1 + (1.25 * fatiguePercentage))
    logging:debug("Parry chance:" .. parryChance)
    return Helpers:rollNdM(1, 100, 100 - parryChance) > 0
end

--#endregion



--#region state control

function ParryController.preventStuckParryAnimation(self)
    if not (self.isParrying or self.startedParry) then
        for _, animation in pairs(Constants.parryAnimations) do
            if self:isAnimationPlaying(animation) then
                anim.cancel(actorSelf, animation)
            end
        end
    end
end

function ParryController.canParry(self)
    local isInWeaponStance = (getStance(actorSelf) == types.Actor.STANCE.Weapon)
    -- can Parry if in Weapon Stance, not staggered, not currently parrying, and if has active weapon that allows it, or shield in hand(but not with weapon that hides shield)
    local parryOnCooldown = (self.localTimers.parryCooldownTimer.active and not self.amPlayer)
    if not self.isAttacking then
        if not parryOnCooldown then
            if isInWeaponStance then
                if not self.isParrying and not self.startedParry then
                    if not self.isStaggered then
                        if (self.currentWeaponConfig or (self.currentShieldConfig and not self.weaponOverridesShield)) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function ParryController.onEnemyPerfectParry(self)
    self.isStaggered = true
    self.isParrying = false
    local hitIndex = "hit" .. tostring(random(1, 5))
    I.AnimationController.playBlendedAnimation(hitIndex, {
        startKey = 'start',
        stopKey = 'stop',
        priority = {
            [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Scripted
        },
        autoDisable = true,
        blendMask = anim.BLEND_MASK.LeftArm +
            anim.BLEND_MASK.RightArm +
            anim.BLEND_MASK.Torso +
            anim.BLEND_MASK.LowerBody,
        speed = 0.70

    })
end

function ParryController.isAnimationPlaying(self, checkFor)
    if type(checkFor) == "table" then
        for _, animation in ipairs(checkFor) do
            if anim.getActiveGroup(actorSelf, anim.BONE_GROUP.RightArm) == animation or
                anim.getActiveGroup(actorSelf, anim.BONE_GROUP.LeftArm) == animation or
                anim.getActiveGroup(actorSelf, anim.BONE_GROUP.Torso) == animation or
                anim.getActiveGroup(actorSelf, anim.BONE_GROUP.LowerBody) == animation then
                return true
            end
        end
    elseif type(checkFor) == "string" then
        if anim.getActiveGroup(actorSelf, anim.BONE_GROUP.RightArm) == checkFor or
            anim.getActiveGroup(actorSelf, anim.BONE_GROUP.LeftArm) == checkFor or
            anim.getActiveGroup(actorSelf, anim.BONE_GROUP.Torso) == checkFor or
            anim.getActiveGroup(actorSelf, anim.BONE_GROUP.LowerBody) == checkFor then
            return true
        end
    end
    return false
end

function ParryController.isAnimationPlayingDeprecated(self, checkFor)
    if type(checkFor) == "table" then
        for _, animation in ipairs(checkFor) do
            if anim.isPlaying(actorSelf, animation) then
                return true
            end
        end
    elseif type(checkFor) == "string" then
        return anim.isPlaying(actorSelf, checkFor)
    end
    return false
end

function ParryController.checkStaggerState(self)
    if (getStance(actorSelf) == types.Actor.STANCE.Weapon) then
        if activeEffects:getEffect(core.magic.EFFECT_TYPE.Paralyze).magnitude > 0 or
            self:isAnimationPlaying(Constants.staggerAnimations) or
            fatigue.current < 0 then
            self.isStaggered = true
            self.isAttacking = false
            self:tryLowerGuard()
            return
        end
    end
    self.isStaggered = false
end

function ParryController.isAttackForbidden(self)
    if self.isStaggered then return true end
    if self.isParrying then return true end
    if self.startedParry then return true end
    return false
end

function ParryController.checkAttackState(self, groupname, key)
    if Helpers.arrayContains(Constants.attackAnimations, groupname) then
        if Helpers.arrayContains(Constants.attackStartKeys, key) then
            self.isAttacking = true -- start the action hold
        end
        if Helpers.arrayContains(Constants.attackEndKeys, key) then
            self.isAttacking = false -- release the action hold
        end
    end
end

function ParryController.startskillGainParryTimer(self)
    self.localTimers.skillGainParryTimer:startTimer(function() return 1 end)
end

function ParryController.reactionDelayedRaiseGuard(self, eventData, melee)
    self:selectGuardWith()
    self.localTimers.reactionTimerRaiseGuard:startTimer(self.getReactionTime, { self, eventData, melee })
end

function ParryController.reactionDelayedLowerGuard(self)
    self.localTimers.reactionTimerLowerGuard:startTimer(self.getReactionTime, { self })
end

function ParryController.preventConsecutiveStagger(self, groupname, key)
    if self.activeParryConfig == nil then
        return
    end
    if Helpers.arrayContains(Constants.staggerAnimations, groupname) and not (groupname == "knockout" or groupname == "knockdown" or groupname == "swimknockdown" or groupname == "swimknockout") then
        if key == "start" then
            if self.localTimers.staggerCooldownTimer.active then
                anim.cancel(actorSelf, groupname)
            end
        elseif key == "stop" then
            -- logging:debug("starting stagger cooldonw timer:"..tostring(self:getStaggerCooldown()))
            self.localTimers.staggerCooldownTimer:startTimer(self.getStaggerCooldown, { self })
        end
    end
end

function ParryController.changeGuardState(self, groupname, key)
    if self.activeParryConfig == nil then
        return
    end
    if groupname == self.activeParryConfig.animation:lower() then
        local targetKey = "start"
        if not self.quickMode then
            targetKey = "stop"
        end
        if key == targetKey then
            logging:debug(("got %s key from %s group"):format(key, groupname))
            self.isParrying = true
            self.localTimers.fatigueDrainTimer:startTimer(function() return 1 end, {}, true) -- repeating fatigue drain timer
            self.lastPerfectParryWindow = self:getPerfectParryWindow()
            logging:debug("starting perfectParryWindow:" .. tostring(self.lastPerfectParryWindow))
            self.localTimers.perfectParryTimer:startTimer(function(s) return s.lastPerfectParryWindow end, { self })
            self.localTimers.currentParryTimer:startTimer(self.getParryHoldDuration, { self })
            self.startedParry = false
        end
    end
end

function ParryController.tryRaiseGuard(self)
    if not self:willParry() then return end
    if not self:canParry() then return end
    self:selectGuardWith()
    logging:debug(self.activeParryConfig)
    if self.activeParryConfig ~= nil then
        self.raisedWithPrio = self.activeParryConfig.priority
        self.raisedWithMask = self.activeParryConfig.blendMask
        if not self.currentEquippedL.record == "None" and not self.currentShieldConfig and not self.weaponOverridesShield then
            self.raisedWithMask = self.raisedWithMask - anim.BLEND_MASK.LeftArm
        end
        self.startedParry = true
        I.AnimationController.playBlendedAnimation(self.activeParryConfig.animation, {
            startKey = 'start',
            stopKey = 'stop',
            priority = self.raisedWithPrio,
            autoDisable = false,
            blendMask = self.raisedWithMask,
            speed = self.localAnimationSpeed,
        })
        logging:debug(tostring(actorSelf) .. "start parry")
    end
end

function ParryController.stopGuard(self)
    if not self.amPlayer then
        self.localTimers.parryCooldownTimer:startTimer(self.getParryCooldown, { self })
    end
    logging:debug(("isParrying:%s"):format(self.isParrying))
    logging:debug(("startedParry:%s"):format(self.startedParry))
    logging:debug("stopping parry")
    I.AnimationController.playBlendedAnimation('idle1', {
        startKey = 'loop start',
        stopKey = 'loop stop',
        priority = self.raisedWithPrio,
        autoDisable = true,
        blendMask = self.raisedWithMask,
    })
    self.isParrying = false
    self.startedParry = false
    self.localTimers.fatigueDrainTimer:stopTimer() -- stopping fatigue drain
    self.localTimers.currentParryTimer:stopTimer()
    logging:debug("stop parry")
end

function ParryController.tryLowerGuard(self)
    if self.startedParry or self.isParrying then
        if not self.amPlayer then
            if self.localTimers.currentParryTimer.elapsed < SC.parryHoldBaseDuration then return end
        end
        self:stopGuard()
    end
end

function ParryController.forceLowerGuard(self)
    self:stopGuard()
end

--#endregion

--#region Equipment

function ParryController.getItemCondition(item)
    local ok, itemData = pcall(types.Item.itemData, item)
    if ok and itemData ~= nil then
        return itemData.condition
    else
        return 0
    end
end

function ParryController.isItemBroken(self, item)
    local condition = self.getItemCondition(item)
    local itemRecord = getWeaponRecord(item.recordId) or getArmorRecord(item.recordId)
    if itemRecord then
        if itemRecord.type == types.Weapon.TYPE.MarksmanThrown then return false end
    end
    if condition == nil then return true end
    return (item ~= nil and condition <= 0)
end

function ParryController.updateEquippedIfChanged(self)
    local changesDetected = false
    local rightEquipped = getEquipment(actorSelf, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if rightEquipped == nil or self:isItemBroken(rightEquipped) then
        rightEquipped = { recordId = "None", id = "none" }
    end

    if (self.currentEquippedR.id ~= rightEquipped.id) or not self.recordEquippedR then
        changesDetected = true
        self.currentEquippedR = rightEquipped
        self.recordEquippedR = getWeaponRecord(rightEquipped.recordId) or Constants.HandToHandRecordStub
        if self.recordEquippedR then
            if Constants.twoHandWeapons[self.recordEquippedR.type] then
                self.weaponOverridesShield = true
            else
                self.weaponOverridesShield = false
            end
            self.currentWeaponConfig = Helpers.tableDeepCopy(Constants.parryAllowedWeaponTypes
                [self.recordEquippedR.type])
        else
            self.currentWeaponConfig = nil
        end
    end
    local leftEquipped = getEquipment(actorSelf, types.Actor.EQUIPMENT_SLOT.CarriedLeft)
    if leftEquipped == nil or self:isItemBroken(leftEquipped) then
        leftEquipped = { recordId = "None", id = "none" }
    end
    if (self.currentEquippedL.id ~= leftEquipped.id) or not self.recordEquippedL then
        changesDetected = true
        self.currentEquippedL = leftEquipped
        self.recordEquippedL = getArmorRecord(leftEquipped.recordId) or Constants.HandToHandRecordStub
        if self.recordEquippedL and self.recordEquippedL.type ~= 99 then
            self.currentShieldConfig = Helpers.tableDeepCopy(Constants.shieldParryConfig)
        else
            self.currentShieldConfig = nil
        end
    end
    if self.currentWeaponConfig ~= nil and self.currentWeaponConfig.name == "handtohand" then
        -- getting gauntlets/bracers if any exist
        local gauntletL = getEquipment(actorSelf, types.Actor.EQUIPMENT_SLOT.LeftGauntlet)
        if gauntletL == nil or self:isItemBroken(gauntletL) then
            gauntletL = { recordId = "None", id = "none" }
        end
        if gauntletL.id ~= self.currentGauntletL.id then
            self.currentGauntletL = gauntletL
            self.recordGauntlets.left = getArmorRecord(gauntletL.recordId)
            if gauntletL.id ~= "none" then
                self.currentGauntlets.left = gauntletL
            else
                self.currentGauntlets.left = nil
            end
        end
        local gauntletR = getEquipment(actorSelf, types.Actor.EQUIPMENT_SLOT.RightGauntlet)
        if gauntletR == nil or self:isItemBroken(gauntletR) then
            gauntletR = { recordId = "None", id = "none" }
        end
        if gauntletR.id ~= self.currentGauntletR.id then
            self.currentGauntletR = gauntletR
            self.recordGauntlets.right = getArmorRecord(gauntletR.recordId)
            if gauntletR.id ~= "none" then
                self.currentGauntlets.right = gauntletR
            else
                self.currentGauntlets.right = nil
            end
        end
    end
    if changesDetected == true then
        self:tryLowerGuard()
    end
end

function ParryController.selectGuardWith(self)
    self:updateEquippedIfChanged()
    self.activeParryConfig = nil
    local localEffectiveness = 0
    if self.currentShieldConfig and not self.weaponOverridesShield then
        local shieldCategory = getArmorSkill(self.currentEquippedL)
        if shieldCategory ~= "unarmored" then
            self.currentShieldConfig.material = shieldCategory
            local armorRating = self.recordEquippedL.baseArmor
            localEffectiveness = min(1 + (armorRating - 5) / 15, 3)
            self.currentShieldConfig.moveSpeedMultiplier = Constants.shieldMoveSpeedMultiplierMap[shieldCategory]
        end
        self.activeParryConfig = self.currentShieldConfig
        self.activeParryItem = self.currentEquippedL
    elseif self.currentWeaponConfig then
        self.activeParryConfig = self.currentWeaponConfig
        self.activeParryItem = self.currentEquippedR
        localEffectiveness = self.currentWeaponConfig.baseEffectiveness
        if self.currentWeaponConfig.name == "handtohand" then
            localEffectiveness = 0
            self.currentWeaponConfig.material = "hands"
            for _, item in pairs(self.currentGauntlets) do
                local gauntletCategory = getArmorSkill(item)
                if gauntletCategory ~= "unarmored" then
                    self.currentWeaponConfig.material = gauntletCategory
                end
            end
            for _, item in pairs(self.recordGauntlets) do
                local armorRating = item.baseArmor
                localEffectiveness = localEffectiveness + min(0.1 + ((armorRating - 5) / 80), 0.65)
            end
            local ironPalmBonusEffectiveness = self:processIronPalmThreshold()
            self.currentWeaponConfig.effectiveness = min(
                self.currentWeaponConfig.baseEffectiveness * (localEffectiveness + ironPalmBonusEffectiveness), 1.1)
            self.activeParryItem = self.currentGauntlets
            logging:debug("HANDTOHAND effectiveness:" .. self.currentWeaponConfig.effectiveness)
        end
    end
    if self.activeParryConfig ~= nil then
        self.activeParryConfig.effectiveness = localEffectiveness *
            self.effectivenessSettings[self.activeParryConfig.name]
        self.localAnimationSpeed = self.activeParryConfig.animationSpeed
    end
end

--#endregion

--#region fatigue cost
function ParryController.fatigueCostAttacker(reflectTarget, fatigueDamage)
    if not reflectTarget then return end
    reflectTarget:sendEvent('ModifyStat', { stat = 'fatigue', amount = -fatigueDamage })
end

function ParryController.raisedGuardDrainFatigue(self)
    if self.baseGuardFatigueDrain == 0 or self.scalingGuardFatigueDrain == 0 then return end
    local drain = self.baseGuardFatigueDrain +
        self.scalingGuardFatigueDrain * (1 - self.currentStats[self.activeParryConfig.secondarySkillId].modified / 100)
    logging:debug(("drain fatige from holding guard: - %s"):format(drain))
    actorSelf:sendEvent('ModifyStat', { stat = 'fatigue', amount = -drain })
end

--#region onHitHandler

function ParryController.onHitHandler(self, attack)
    if not attack.attacker then return attack end -- attacker is nil, likely someone is sending hit events for a reason other than combat. exit
    logging:debug(tostring(actorSelf) .. "entered onHitHandler")
    local isH2HAttack, isThrown, attackerIsCreature, attackerIsWeaponUser, attackerName = attackController
        .getAttackDetails(
            attack)
    logging:debug("isH2HAttack:" .. tostring(isH2HAttack))
    logging:debug("successful:" .. tostring(attack.successful))
    logging:debug("attack.weapon:")
    logging:debug(attack.weapon)


    if not attack.successful then
        if self.allAttacksHit then
            logging:debug(tostring(actorSelf) .. "All attacks hit is ON, attack is a miss, adjusting.")
            attack = attackController.processFumble(actorSelf, attack, isH2HAttack, isThrown, attackerIsCreature,
                attackerIsWeaponUser, self.enemyAttackData)
        end
        if self.playMissAnimations then
            if not self.isParrying then
                if not self.amPlayer then
                    if not self.isStaggered then
                        local dodgeAnimations = Constants.h2hdodgeAnimations
                        if self.activeParryConfig then
                            if self.activeParryConfig.name ~= "handtohand" and getStance(actorSelf) == types.Actor.STANCE.Weapon then
                                dodgeAnimations = Constants.armedDodgeAnimations
                            end
                        end
                        local dodge = dodgeAnimations[random(1, #dodgeAnimations)]
                        I.AnimationController.playBlendedAnimation(dodge, {
                            startKey = 'start',
                            stopKey = 'stop',
                            priority = Constants.dodgePriority,
                            autoDisable = true,
                            blendMask = Constants.dodgeBlendMask,
                            speed = 1
                        })
                    end
                end
            end
        end
    end
    if attackerIsCreature then
        if self.allowParryCreatures == SC.allowParryCreaturesValues[SC.parry_creatures.off] then
            logging:debug(tostring(actorSelf) .. "Can't parry creatures")
            return
        elseif self.allowParryCreatures == SC.allowParryCreaturesValues[SC.parry_creatures.shields] and self.activeParryConfig.name ~= "shield" then
            logging:debug(tostring(actorSelf) .. "Can't parry creatures, without a shield")
            return
        end
    end
    if self.activeParryConfig and self.isParrying then -- have weapon that can parry or shield
        local canDeflectArrows = self:getCanDeflectArrows()
        logging:debug(tostring(actorSelf) .. "Has parry tool and is in parry stance")
        if not self.allowedThreatDirection(actorSelf, attack.attacker, self.activeParryConfig.parryArc, self.activeParryConfig.parryOffset) then
            logging:debug("can't parry strikes outside the weapon parry arc:" .. self.activeParryConfig.parryArc ..
                " degrees")
            return attack
        end

        local storedEffectiveness = self.activeParryConfig.effectiveness
        local parryModifierVsAttackingWeapon = 0

        -- modifing parry effectiveness depending on enemy weapon type
        if self.activeParryConfig.name ~= "shield" and self.activeParryConfig.name ~= "handtohand" then
            if isH2HAttack then
                parryModifierVsAttackingWeapon = perWeaponModifiers[self.activeParryConfig.name]["handtohand"] or 0
                logging:debug(("applying bonus %s effectiveness against hand to hand"):format(
                    parryModifierVsAttackingWeapon))
            elseif attack.weapon and not isThrown then
                local attackWeaponRecord = getWeaponRecord(attack.weapon.recordId)
                local stringWeaponType = nil
                if attackWeaponRecord then
                    stringWeaponType = Constants.weaponToTypeMap[attackWeaponRecord.type]
                end
                parryModifierVsAttackingWeapon = perWeaponModifiers[self.activeParryConfig.name][stringWeaponType] or 0
                logging:debug(("applying bonus %s effectiveness against %s"):format(parryModifierVsAttackingWeapon,
                    stringWeaponType))
            end
            self.activeParryConfig.effectiveness = self.activeParryConfig.effectiveness + parryModifierVsAttackingWeapon
            logging:debug(("final parry effectiveness: %s"):format(self.activeParryConfig.effectiveness))
        end

        --h2h vs h2h is always 1
        if self.activeParryConfig.name == "handtohand" and isH2HAttack then
            self.activeParryConfig.effectiveness = 1
        end

        -- have a shield _or_ the attack is melee, or has high enough skill to deflect arrows with weapons
        if attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee or self.activeParryConfig.name == "shield" or (attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Ranged and canDeflectArrows) then
            attack = self:processParry(attack, attackerName) -- modify the attack, reflect fatigue if any, get attack back.
        end
        self.activeParryConfig.effectiveness = storedEffectiveness
    else
        logging:debug("No parry, passing regular onHit") --no useable weapon or shield
    end
    return attack
end

function ParryController.processRemoveSpells(self, spell, attacker, enchant, attackItem)
    -- logging:status("====================")
    -- logging:status(spell)
    -- logging:status("====================")
    -- logging:status('active spell ' .. tostring(spell.activeSpellId) .. ':')
    -- logging:status('  name: ' .. tostring(spell.name))
    -- logging:status('  id: ' .. tostring(spell.id))
    -- logging:status('  enchant: ' .. tostring(enchant))
    -- logging:status('  item: ' .. tostring(spell.item))
    -- logging:status('  caster: ' .. tostring(spell.caster))
    -- logging:status('  effects: ' .. tostring(spell.effects))
    -- for _, effect in pairs(spell.effects) do
    --     logging:status('  -> effects[' .. tostring(effect) .. ']:')
    --     logging:status('       id: ' .. tostring(effect.id))
    --     logging:status('       name: ' .. tostring(effect.name))
    --     logging:status('       affectedSkill: ' .. tostring(effect.affectedSkill))
    --     logging:status('       affectedAttribute: ' .. tostring(effect.affectedAttribute))
    --     logging:status('       magnitudeThisFrame: ' .. tostring(effect.magnitudeThisFrame))
    --     logging:status('       minMagnitude: ' .. tostring(effect.minMagnitude))
    --     logging:status('       maxMagnitude: ' .. tostring(effect.maxMagnitude))
    --     logging:status('       duration: ' .. tostring(effect.duration))
    --     logging:status('       durationLeft: ' .. tostring(effect.durationLeft))
    -- end
    if spell.item == attackItem then
        logging:debug("enchant is from enemy weapon")
        if spell.caster == attacker then
            logging:debug("attacker is caster")
            local cancel = false
            for _, effect in pairs(spell.effects) do
                if effect.area == 0 or self.enchantParryAOESetting then
                    local magicEffect = core.magic.effects.records[effect.id]
                    if magicEffect.harmful then
                        cancel = true
                        local vfxId = magicEffect.hitStatic
                        local vfxArea = magicEffect.areaStatic
                        if vfxId then
                            anim.removeVfx(actorSelf, vfxId)
                        end
                        if vfxArea then
                            anim.removeVfx(actorSelf, vfxArea)
                        end
                        local fallback = ""
                        if magicEffect.school then
                            fallback = magicEffect.school
                        end
                        core.sendGlobalEvent("ngarde_stopSFX",
                            {
                                magicEffect = {
                                    hitSound = magicEffect.hitSound or ("%s hit"):format(fallback),
                                    areaSound = magicEffect.areaSound or ("%s area"):format(fallback), -- ???????
                                    boltSound = magicEffect.boltSound or ("%s bolt"):format(fallback),
                                },
                                object = actorSelf
                            })
                    end
                end
            end
            if cancel then
                logging:debug("removing enchant spell:" .. tostring(spell.id))
                activeSpells:remove(spell.activeSpellId)
            end
        end
    end
end

function ParryController:tryGuardEnchant(attack)
    if not attack.weapon then return end
    if not self.enchantParrySetting then return end
    local weaponRecordId = "none"
    if attack.weapon.id ~= "@0x0" then
        weaponRecordId = attack.weapon.recordId
    end
    local attackWeaponRecord = getWeaponRecord(weaponRecordId)
    local weaponEnchantRecord
    local ammoEnchantRecord
    local attackAmmoRecord = nil
    if attack.ammo ~= nil then
        attackAmmoRecord = getWeaponRecord(attack.ammo)
    end
    if attackAmmoRecord then
        if attackAmmoRecord.enchant ~= nil then
            logging:debug("Parrying ammo enchants")
            ammoEnchantRecord = core.magic.enchantments.records[attackAmmoRecord.enchant]
            if ammoEnchantRecord.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
                if activeSpells:isSpellActive(attackAmmoRecord.enchant) then
                    logging:debug("enchant spell present:" .. attackAmmoRecord.enchant)
                    for _, spell in pairs(activeSpells) do
                        self:processRemoveSpells(spell, attack.attacker, attackAmmoRecord.enchant, attack.ammo)
                    end
                end
            end
        end
    end
    if attackWeaponRecord then
        if attackWeaponRecord.enchant ~= nil then
            logging:debug("Parrying weapon enchants")
            weaponEnchantRecord = core.magic.enchantments.records[attackWeaponRecord.enchant]
            if weaponEnchantRecord.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
                if activeSpells:isSpellActive(attackWeaponRecord.enchant) then
                    logging:debug("enchant spell present:" .. attackWeaponRecord.enchant)
                    for _, spell in pairs(activeSpells) do
                        self:processRemoveSpells(spell, attack.attacker, attackWeaponRecord.enchant, attack.weapon)
                    end
                end
            end
        end
    end
end

function ParryController.processParry(self, attack, attackerName)
    if self.targets[attack.attacker.id] == nil then
        self.targets[attack.attacker.id] = attack.attacker
    end
    local playShieldHitAnim = true
    logging:debug("parry pre-check")
    local debugMsg = ""
    local currentFatigue = fatigue.current

    local soundData = Helpers.tableDeepCopy(Constants.materialToSoundMap[self.activeParryConfig.material].parry)
    logging:debug("parrying, starting calcs and adjustments")

    local parryCost = self:getParryFatigueCost()
    local factor = self:getParryDefenceFactor()

    if self.localTimers.skillGainParryTimer.active and factor > 0.35 then
        factor = factor - (0.25 - self.localTimers.skillGainParryTimer.elapsed / 4)
    end
    local reflectedFatigue = 0
    local durabilityDamage = 0
    local skillGainScale = 1
    local negatedDamage = { health = 0, fatigue = 0 }
    local timing = 1
    local perfect = false
    local damageNegatedStringValue = ""
    if not attack.successful then
        parryCost = parryCost / 4
        skillGainScale = skillGainScale - 0.9
    end
    if attack.damage then
        logging:debug("incoming damage:")
        logging:debug(attack.damage)
    end
    logging:debug("self.baseParryFatigueCost:" .. tostring(self.baseParryFatigueCost))
    logging:debug("self.activeParryConfig.effectiveness:" .. tostring(self.activeParryConfig.effectiveness))
    --perfectParry only possible on melee attacks or when deflecting arrows
    if self.localTimers.perfectParryTimer.active and (attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee or self:getCanDeflectArrows()) then
        --setting variables necessary for the parry to count as Perfect
        logging:debug("perfect parry")
        factor = 0
        timing = 1
        perfect = true
        attack.ngarde_perfectParry = true
        soundData = Helpers.tableDeepCopy(Constants.materialToSoundMap[self.activeParryConfig.material].perfectParry)
        parryCost = parryCost / 3
        skillGainScale = skillGainScale + 0.5
        if attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee then
            attack.attacker:sendEvent("ngarde_perfectParry")
        end
        self.localTimers.perfectParryTimer:stopTimer() --can perfect parry only once
        if not self.amPlayer then
            self:tryLowerGuard()                       -- NPC perfect parried player - lower guard and try to counter attack
        end
        playShieldHitAnim = false
    end
    if factor == 0 then
        self:tryGuardEnchant(attack)
    end
    if attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Ranged and not ((self.activeParryConfig.name == "shield" and not self.weaponOverridesShield) or perfect) then
        return attack
    end
    logging:debug(tostring(actorSelf) .. "parry defence multiplier:" .. factor)
    -- converting portion of health damage into fatigue damage
    -- half of converted damage is reflected as fatigue to the attacker.
    -- What's left is dealt as durability damage to the item we used to parry
    -- but defender only takes partial fatigue damage further reduced by parry multiplier `factor`.
    -- this way as defender skill gets higher - attacker gets more fatigue damage and defender less
    local originalDamage = Helpers.tableDeepCopy(attack.damage)
    if attack.damage.health and not attack.damage.fatigue then
        negatedDamage.health = attack.damage.health - (attack.damage.health * factor)
        attack.damage.health = attack.damage.health - negatedDamage.health
        attack.damage.fatigue = negatedDamage.health * factor
        damageNegatedStringValue = ("%s HP"):format(Helpers.roundTo(negatedDamage.health, 2))
    elseif attack.damage.fatigue and not attack.damage.health then
        negatedDamage.fatigue = attack.damage.fatigue - (attack.damage.fatigue * factor)
        attack.damage.fatigue = attack.damage.fatigue - negatedDamage.fatigue
        attack.damage.health = 0
        damageNegatedStringValue = ("%s FP"):format(Helpers.roundTo(negatedDamage.fatigue, 2))
    elseif attack.damage.fatigue and attack.damage.health then
        negatedDamage.health = attack.damage.health - (attack.damage.health * factor)
        negatedDamage.fatigue = attack.damage.fatigue - (attack.damage.fatigue * factor)
        attack.damage.health = attack.damage.health - negatedDamage.health
        attack.damage.fatigue = (attack.damage.fatigue - negatedDamage.fatigue) + (negatedDamage.health * factor)
        damageNegatedStringValue = ("%s HP ; %s FP"):format(Helpers.roundTo(negatedDamage.health, 2),
            Helpers.roundTo(negatedDamage.fatigue, 2))
    else
        damageNegatedStringValue = ("miss"):format(Helpers.roundTo(negatedDamage.health, 2),
            Helpers.roundTo(negatedDamage.fatigue, 2))
    end
    logging:debug(tostring(actorSelf) .. "remaining health damage:" .. attack.damage.health)
    logging:debug(tostring(actorSelf) .. "remaining fatigue damage:" .. attack.damage.fatigue)
    logging:debug(tostring(actorSelf) .. "negated health damage:" .. negatedDamage.health)
    logging:debug(tostring(actorSelf) .. "negated fatigue damage:" .. negatedDamage.fatigue)
    logging:debug(tostring(actorSelf) .. "reflected as fatigue damage to attacker:" .. reflectedFatigue)
    durabilityDamage                   = durabilityDamage + attack.damage.fatigue + attack.damage.health
    attack.damage.fatigue              = attack.damage.fatigue + (negatedDamage.fatigue * factor)
    attack.ngarde_parry                = true
    attack.ngarde_damageRemainingRatio = factor
    local parryEventData               = {
        damageRemainingRatio = factor,
        isPerfect = perfect,
        originalDamage = originalDamage,
    }
    actorSelf:sendEvent("ngarde_parrySelf", parryEventData)
    debugMsg = debugMsg ..
        (". Health damage negated: %s. Fatigue damage negated: %s."):format(Helpers.roundTo(negatedDamage.health, 2),
            Helpers.roundTo(negatedDamage.fatigue, 2))
    debugMsg = debugMsg ..
        (". Damage received: %s. Fatigue damage received: %s. "):format(attack.damage.health, attack.damage.fatigue)
    debugMsg = debugMsg .. (". Fatigue parry cost: %s"):format(Helpers.roundTo(parryCost, 2))
    local factorText = ""
    if perfect then
        factorText = "Perfect"
    else
        factorText = tostring(((1 - Helpers.roundTo(factor, 4)) * 100)) .. "%"
        if not self.localTimers.skillGainParryTimer.active then
            skillGainScale = skillGainScale - 1
            timing = 0
        else
            skillGainScale = skillGainScale - self.localTimers.skillGainParryTimer.elapsed
            timing = timing - self.localTimers.skillGainParryTimer.elapsed
        end
    end
    debugMsg = debugMsg ..
        (". Perfect parry window was: %ss"):format(Helpers.roundTo(self.lastPerfectParryWindow, 6))
    debugMsg = debugMsg .. (". Timing: %s%%"):format(Helpers.roundTo(timing * 100, 2))
    debugMsg = ("Parry. Defence factor: %s."):format(factorText) .. debugMsg


    skillGainScale = skillGainScale + ((negatedDamage.health / health.base) / 2) +
        ((negatedDamage.fatigue / fatigue.base) / 4)
    reflectedFatigue = (negatedDamage.health + negatedDamage.fatigue) / 2

    debugMsg = debugMsg .. (". skillGainScale: %s"):format(max(0.20, Helpers.roundTo(skillGainScale, 2)))



    if attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee and reflectedFatigue > 0 then
        logging:debug("reflecting fatigue to attacker:" .. tostring(reflectedFatigue))
        self.fatigueCostAttacker(attack.attacker, reflectedFatigue)
        debugMsg = debugMsg ..
            (". Damage Reflected as fatigue to attacker: %s"):format(Helpers.roundTo(reflectedFatigue, 2))
    else
        reflectedFatigue = 0
    end

    if self.baseParryDurabilityLoss > 0 or durabilityDamage > 0 then
        logging:debug("durabilityDamage:" .. tostring(durabilityDamage))
        if self.activeParryConfig.name == "handtohand" then
            logging:debug("h2h block. Applying durabilityDamage to gauntlets if there are any")
            local gauntletDamage = (self.baseParryDurabilityLoss + durabilityDamage)
            if #self.activeParryItem >= 1 then
                gauntletDamage = gauntletDamage / #self.activeParryItem
            end
            for _, item in pairs(self.activeParryItem) do
                core.sendGlobalEvent("ngarde_parryItemCondition",
                    { item = item, damage = gauntletDamage })
            end
        else
            logging:debug("Weapon/shield parry. Applying durabilityDamage to the item")
            core.sendGlobalEvent("ngarde_parryItemCondition",
                { item = self.activeParryItem, damage = self.baseParryDurabilityLoss + durabilityDamage })
        end
    end

    logging:debug(tostring(actorSelf) .. "Applying cost to current fatigue:" .. currentFatigue)
    if currentFatigue >= 0 then
        fatigue.current = math.max(0, currentFatigue - parryCost)
    else
        fatigue.current = currentFatigue - parryCost
    end
    logging:debug(tostring(actorSelf) .. "New fatigue value:" .. fatigue.current)
    if playShieldHitAnim then
        if self.activeParryConfig.name == "shield" then
            logging:debug(tostring(actorSelf) .. "playing shield hit animation")
            I.AnimationController.playBlendedAnimation("shield", {
                startKey = 'block start',
                stopKey = 'block stop',
                priority = {
                    [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Block,
                    [anim.BONE_GROUP.Torso] = anim.PRIORITY.Block,
                },
                autoDisable = true,
                blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso,
                speed = 2
            })
        end
    end
    local params = {
        hitObj = attack.weapon,
        effectPos = attack.hitPos,
        playSoundAt = actorSelf,
        soundData = soundData,
        baseSoundData = Helpers.tableDeepCopy(Constants.materialToSoundMap[self.activeParryConfig.material]
            .parry)
    }
    params.soundData.options.volume = params.soundData.options.volume * self.parrySoundVolume
    params.baseSoundData.options.volume = params.baseSoundData.options.volume * self.parrySoundVolume
    logging:debug(tostring(actorSelf) .. "sending parry success event. This will play sound")
    core.sendGlobalEvent("ngarde_ParrySuccess", params)
    --  For I.ImpactEffects
    ---@diagnostic disable-next-line undefined-fiield
    if self.activeParryConfig.name ~= "shield" or (self.activeParryConfig.name == "shield" and not I.impactEffects) or (self.activeParryConfig.name == "shield" and not playShieldHitAnim) then
        local eventParams = {
            model = self.activeParryConfig.vfxModel,
            options = {
                boneName = self.activeParryConfig.vfxBone
            },
        }
        actorSelf:sendEvent('AddVfx', eventParams)
    end
    if self.amPlayer then
        local skillUseSuccess, err
        skillGainScale = max(skillGainScale, 0.20)
        local skillUsedOptions = {
            scale = skillGainScale,
            useType = SKILL_USE_TYPES.Block_Success,
            stats = {
                { name = "Dmg Negated", value = damageNegatedStringValue },                                    -- raw damage number
                { name = "Timing",      value = tostring(Helpers.roundTo(timing * 100, 2)):sub(1, 4) .. "%" }, -- value between 1 and 0, depending on how close to perfect the parry was. 1 is best,
                { name = "Enemy",       value = ("%s (Lvl %s)"):format(attackerName, types.Actor.stats.level(attack.attacker).current) },
            },
            statsId = "ngarde_parry",
        }
        -- logging:debug("stats for SE:")
        -- logging:debug(skillUsedOptions)
        if self.activeParryConfig.secondarySkillId ~= self.activeParryConfig.mainSkillId then
            skillUsedOptions.scale = skillGainScale / 2
            skillUseSuccess, err = pcall(skillUsed, self.activeParryConfig.secondarySkillId, skillUsedOptions)
        end
        skillUseSuccess, err = pcall(skillUsed, self.activeParryConfig.mainSkillId, skillUsedOptions)
        if not skillUseSuccess then
            logging:debug("skillUsedHandler handler failed. Check your skill/leveling mods.")
            logging:debug(err)
        end
    end

    if self.debugMessages and self.amPlayer then
        ui.showMessage(debugMsg)
    end
    logging:debug(debugMsg)

    return attack
end

--#endregion


--#region Settings
function ParryController.initReadSettings(self)
    for _, settingsGroup in pairs(storageSections) do
        self:readGroupSettings(settingsGroup)
    end
end

function ParryController.readUpdatedSetting(self, sectionName, changedKey)
    local settingsGroup = storageSections[sectionName]
    -- logging:status(("Settings changed: %s; Key: %s"):format(sectionName, tostring(changedKey)))
    if changedKey ~= nil then
        if string.match(changedKey, "ParryEffectivenessKey") then
            self.effectivenessSettings[SC.eSettingsKeyToType[changedKey]] =
                SC.readSetting(settingsGroup, changedKey)
        elseif changedKey == SC.parrySoundVolumeKey then
            self[SC.keyToLocal(changedKey)] = SC.readSetting(settingsGroup, changedKey) / 100
        else
            self[SC.keyToLocal(changedKey)] = SC.readSetting(settingsGroup, changedKey)
        end
    else
        self:readGroupSettings(settingsGroup)
    end
end

function ParryController.readGroupSettings(self, settingsGroup)
    for key, _ in pairs(settingsGroup:asTable()) do
        if string.match(key, "ParryEffectivenessKey") then
            self.effectivenessSettings[SC.eSettingsKeyToType[key]] = SC.readSetting(settingsGroup, key)
        elseif key == SC.parrySoundVolumeKey then
            self[SC.keyToLocal(key)] = SC.readSetting(settingsGroup, key) / 100
        else
            self[SC.keyToLocal(key)] = SC.readSetting(settingsGroup, key)
        end
    end
end

--#endregion

return {
    new = ParryController.new
}
