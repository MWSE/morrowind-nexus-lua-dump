local core               = require("openmw.core")
local I                  = require('openmw.interfaces')
local types              = require('openmw.types')
local anim               = require('openmw.animation')
local async              = require('openmw.async')
local Constants          = require('scripts.ngarde.helpers.constants')
local SettingsConstants  = require('scripts.ngarde.helpers.settings_constants')
local Helpers            = require('scripts.ngarde.helpers.helpers')
local logging            = require('scripts.ngarde.helpers.logger').new()
local timers             = require('scripts.ngarde.helpers.timers')
local storage            = require('openmw.storage')
local actorSelf          = require('openmw.self')
local attackController   = require('scripts.ngarde.controllers.attack')
local util               = require('openmw.util')
local targetRaycast      = require('scripts.ngarde.helpers.target_raycast').new()
local perWeaponModifiers = require('scripts.ngarde.helpers.weapon_parry_table')
local skillUsed
local SKILL_USE_TYPES
local parrySettings      = storage.globalSection(SettingsConstants.parrySettingsGroupKey)
local balanceSettings    = storage.globalSection(SettingsConstants.balanceSettingsGroupKey)
local debugSettings      = storage.globalSection(SettingsConstants.debugSettingsGroupKey)
ParryController          = {}
ParryController.__index  = ParryController
local min                = math.min
local max                = math.max
local floor              = math.floor
local random             = math.random
local sin                = math.sin
local cos                = math.cos
local rad                = math.rad
local fatigue            = types.Actor.stats.dynamic.fatigue
local health             = types.Actor.stats.dynamic.health
local getEquipment       = types.Actor.getEquipment
local skills             = types.NPC.stats.skills
local attributes         = types.NPC.stats.attributes
local getArmorRecord     = types.Armor.record
local getStance          = types.Actor.getStance
local getWeaponRecord    = types.Weapon.record
local getArmorSkill      = I.Combat.getArmorSkill
local activeEffects      = types.Actor.activeEffects
local ui



function ParryController.new()
    local self                       = setmetatable({}, ParryController)
    self.targets                     = {}
    self.primaryTarget               = nil
    self.startedParry                = false
    self.isParrying                  = false
    self.isStaggered                 = false
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
    self.parryEnchants               = SettingsConstants.enchantParrySettingDefault
    self.parryAOEEnchants            = SettingsConstants.enchantParryAOESettingDefault
    self.baseParryDurabilityLoss     = SettingsConstants.baseParryDurabilityLossDefault
    self.baseParryFatigueCost        = SettingsConstants.baseParryFatigueCostDefault
    self.ironPalmThreshold           = SettingsConstants.ironPalmThresholdDefault
    self.perfectParryThreshold       = SettingsConstants.perfectParryThresholdDefault
    self.threatData                  = { notThreatenedFramesCounter = 0, threatened = false, melee = true }
    self.amPlayer                    = (actorSelf.type == types.Player)
    self.parrySoundVolume            = SettingsConstants.parrySoundVolumeDefault / 100
    self.rangedThreatHoldMultiplier  = SettingsConstants.rangedThreatHoldMultiplier
    self.rangedThreatCooldownDivisor = SettingsConstants.rangedThreatCooldownDivisor
    self.baseGuardFatigueDrain       = SettingsConstants.baseGuardFatigueDrainDefault
    self.scalingGuardFatigueDrain    = SettingsConstants.scalingGuardFatigueDrainDefault
    self.allAttacksHit               = SettingsConstants.allAttacksHitDefault
    self.quickMode                   = SettingsConstants.quickModeDefault
    self.allowParryCreatures         = SettingsConstants.allowParryCreaturesDefault
    self.localAnimationSpeed         = 1
    self.windup                      = actorSelf.ATTACK_TYPE.NoAttack
    self.debugMessages               = SettingsConstants.debugMessagesDefault
    self.debugLogs                   = SettingsConstants.debugLogsDefault

    self.raisedWithPrio              = nil --last prio and mask that the parry was raised with
    self.raisedWithMask              = nil
    if self.amPlayer then
        skillUsed       = I.SkillProgression.skillUsed
        SKILL_USE_TYPES = I.SkillProgression.SKILL_USE_TYPES
        ui              = require("openmw.ui")
    end
    --     -- specifically to match behavior to actor/npc skill getters
    self.creatureSkill         = function(blank)
        return { modified = self.recordSelf.combatSkill }
    end
    self.currentStats          = self:initReadStats()
    self.effectivenessSettings = self:initEffectivenessSettings()
    self:readSettings()
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
        staggerCooldownTimer    = timers.new(),
        attackWindupTimer       = timers.new(function()
            self.releaseAttackWindup()
        end),
        skillGainParryTimer     = timers.new(),
    }
    storage.globalSection(SettingsConstants.parrySettingsGroupKey):subscribe(
        async:callback(function()
            self:readParrySettings()
        end))
    storage.globalSection(SettingsConstants.balanceSettingsGroupKey):subscribe(
        async:callback(function()
            self:readBalanceSettings()
        end))

    storage.globalSection(SettingsConstants.debugSettingsGroupKey):subscribe(
        async:callback(function()
            self:readDebugSettings()
        end))

    I.AnimationController.addTextKeyHandler('', function(groupname, key)
        self:preventConsecutiveStagger(groupname, key)
        self:changeGuardState(groupname, key)
    end)
    logging:debug(("Created ParryController for: %s"):format(tostring(actorSelf)))
    return self
end

function ParryController.initEffectivenessSettings(self)
    return {
        ["shortbladeonehand"] = SettingsConstants.baseShortBladeOneHandParryEffectivenessDefault,
        ["longbladeonehand"] = SettingsConstants.baseLongBladeOneHandParryEffectivenessDefault,
        ["longbladetwohand"] = SettingsConstants.baseLongBladeTwoHandParryEffectivenessDefault,
        ["bluntonehand"] = SettingsConstants.baseBluntOneHandParryEffectivenessDefault,
        ["blunttwoclose"] = SettingsConstants.baseBluntTwoCloseParryEffectivenessDefault,
        ["blunttwowide"] = SettingsConstants.baseBluntTwoWideParryEffectivenessDefault,
        ["speartwowide"] = SettingsConstants.baseSpearTwoWideParryEffectivenessDefault,
        ["axeonehand"] = SettingsConstants.baseAxeOneHandParryEffectivenessDefault,
        ["axetwohand"] = SettingsConstants.baseAxeTwoHandParryEffectivenessDefault,
        ["handtohand"] = SettingsConstants.baseHandToHandParryEffectivenessDefault,
        ["shield"] = SettingsConstants.baseShieldParryEffectivenessDefault,
    }
end

function ParryController.initReadStats(self)
    if actorSelf.type == types.Creature then
        return { --creatures don't have skills except combatSkill and magicSkill, but have attributes
            ["handtohand"] = { value = self.creatureSkill(), getter = self.creatureSkill },
            ["shortblade"] = { value = self.creatureSkill(), getter = self.creatureSkill },
            ["longblade"] = { value = self.creatureSkill(), getter = self.creatureSkill },
            ["axe"] = { value = self.creatureSkill(), getter = self.creatureSkill },
            ["spear"] = { value = self.creatureSkill(), getter = self.creatureSkill },
            ["bluntweapon"] = { value = self.creatureSkill(), getter = self.creatureSkill },
            ["block"] = { value = self.creatureSkill(), getter = self.creatureSkill },
            ["speed"] = { value = attributes.speed(actorSelf).modified, getter = attributes.speed },
            ["strength"] = { value = attributes.strength(actorSelf).modified, getter = attributes.strength },
            ["endurance"] = { value = attributes.endurance(actorSelf).modified, getter = attributes.endurance },
            ["agility"] = { value = attributes.agility(actorSelf).modified, getter = attributes.agility },
            ["luck"] = { value = attributes.luck(actorSelf).modified, getter = attributes.luck },
        }
    else
        return {
            ["handtohand"] = { value = skills.handtohand(actorSelf).modified, getter = skills.handtohand },
            ["shortblade"] = { value = skills.shortblade(actorSelf).modified, getter = skills.shortblade },
            ["longblade"] = { value = skills.longblade(actorSelf).modified, getter = skills.longblade },
            ["axe"] = { value = skills.axe(actorSelf).modified, getter = skills.axe },
            ["spear"] = { value = skills.spear(actorSelf).modified, getter = skills.spear },
            ["bluntweapon"] = { value = skills.bluntweapon(actorSelf).modified, getter = skills.bluntweapon },
            ["block"] = { value = skills.block(actorSelf).modified, getter = skills.block },
            ["speed"] = { value = attributes.speed(actorSelf).modified, getter = attributes.speed },
            ["strength"] = { value = attributes.strength(actorSelf).modified, getter = attributes.strength },
            ["endurance"] = { value = attributes.endurance(actorSelf).modified, getter = attributes.endurance },
            ["agility"] = { value = attributes.agility(actorSelf).modified, getter = attributes.agility },
            ["luck"] = { value = attributes.luck(actorSelf).modified, getter = attributes.luck },
        }
    end
end

local formulaFatigueEffects = {
    ["Fatigue effects limited to 50%"] = function(value)
        if value > 1 then
            return min(value, SettingsConstants.fortifyFatigueMaxImpact)
        else
            return min(value * 2, 1)
        end
    end,
    ["Without fatigue effects"] = function(value)
        return 1
    end,
    ["With fatigue effects"] = function(value)
        return min(max(value, 0.15), SettingsConstants.fortifyFatigueMaxImpact)
    end
}

function ParryController.statUpdate(self, statArray)
    for _, statId in ipairs(statArray) do
        self.currentStats[statId].value = self.currentStats[statId].getter(actorSelf).modified
    end
end

--#region Formulas


---@param statValue number
---@param factor number
function ParryController.getStatCurve(self, statValue, factor, skillCurveStep)
    local skillCurveLength = floor(statValue / skillCurveStep)
    local skillModulo = statValue % skillCurveStep
    local curve = {}
    local multiplier = factor
    table.insert(curve, min(statValue, skillCurveStep) * multiplier)
    for i = 1, skillCurveLength - 1 do
        multiplier = factor / (1 * (SettingsConstants.baseSkillCurveDivisor * i))
        table.insert(curve, skillCurveStep * multiplier)
        --logging:debug("multiplier:" .. multiplier)
    end
    if skillModulo < statValue then
        table.insert(curve, skillModulo * (multiplier / SettingsConstants.baseSkillCurveDivisor))
    end
    -- for _, v in ipairs(curve) do
    --     logging:debug("curveValue:"..v)
    -- end
    return Helpers.sum(curve)
end

function ParryController.processIronPalmThreshold(self)
    if not self.activeParryConfig then return 0 end
    self:statUpdate({ self.activeParryConfig.mainSkillId })
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].value
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
    self:statUpdate({ self.activeParryConfig.mainSkillId, self.activeParryConfig.secondarySkillId })
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].value
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].value
    local bonusFatigueFromWeight = 0
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SettingsConstants.fatiugeCostMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SettingsConstants.fatiugeCostSecondarySkillRatio,
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
        (((mainSkillCurve + secondarySkillCurve) / 100) + (self.activeParryConfig.effectiveness * SettingsConstants.fatigueCostEffectivenessRatio)),
        0)
    local cost = (self.baseParryFatigueCost + bonusFatigueFromWeight) * ratio
    logging:debug(tostring(actorSelf) .. "parry fatigue flat cost:" .. cost)
    return cost
end

function ParryController.getPerfectParryWindow(self)
    if not self.activeParryConfig then return 0 end
    self:statUpdate({ self.activeParryConfig.mainSkillId, self.activeParryConfig.secondarySkillId })
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].value
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].value
    local currentFatigue = fatigue(actorSelf).current
    local maxFatigue = fatigue(actorSelf).base
    local fatiguePercentage = formulaFatigueEffects[self.fatigueEffectsFormula](currentFatigue / maxFatigue)
    local skillCurveStep = 45
    local masteryMultiplier = self:processPerfectParryThreshold(mainSkill)
    local mainSkillCurve = self:getStatCurve(mainSkill, SettingsConstants.perfectParryMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SettingsConstants.perfectParrySecondarySkillRatio,
        skillCurveStep)
    local window = masteryMultiplier * min(
        (SettingsConstants.basePerfectParryWindow + ((mainSkillCurve + secondarySkillCurve) / 100)) *
        fatiguePercentage, SettingsConstants.maxPerfectParryWindow)
    logging:debug(tostring(actorSelf) .. "Perfect parry window:" .. window)

    return window
end

function ParryController.getParryCooldown(self)
    if not self.activeParryConfig then return 1 end
    self:statUpdate({ self.activeParryConfig.mainSkillId, self.activeParryConfig.secondarySkillId })
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].value
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].value
    local currentFatigue = fatigue(actorSelf).current
    local maxFatigue = fatigue(actorSelf).base
    local fatiguePercentage = formulaFatigueEffects[self.fatigueEffectsFormula](currentFatigue / maxFatigue)
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SettingsConstants.parryCooldownMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SettingsConstants.parryCooldownSecondarySkillRatio,
        skillCurveStep)
    if self.amPlayer then
        return 0
    else
        local parryCooldownRatio = max(1 - ((mainSkillCurve + secondarySkillCurve) / 100) * fatiguePercentage, 0)
        local parryCooldown = max(SettingsConstants.baseParryCooldown * parryCooldownRatio,
            SettingsConstants.minParryCooldown)
        if not self.amPlayer and not self.threatData.melee then
            parryCooldown = parryCooldown / self.rangedThreatCooldownDivisor
        end
        logging:debug(tostring(actorSelf) .. "parry cooldown:" .. parryCooldown)
        return parryCooldown
    end
end

function ParryController.getReactionTime(self)
    if self.amPlayer then return 0 end
    if not self.activeParryConfig then return 0.250 end
    self:statUpdate({ self.activeParryConfig.mainSkillId, self.activeParryConfig.secondarySkillId, "speed" })
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].value
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].value
    local attrSpeed = self.currentStats["speed"].value
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SettingsConstants.npcReactionTimeMainSkillFactor, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SettingsConstants.npcReactionTimeSecondarySkillFactor,
        skillCurveStep)
    local speedCurve = self:getStatCurve(attrSpeed, SettingsConstants.npcReactionTimeSpeedFactor, skillCurveStep)
    local factor = max(1 - ((mainSkillCurve + secondarySkillCurve + speedCurve) / 100), 0)
    logging:debug(tostring(actorSelf) .. "reaction time multiplier:" .. factor)

    local reactionTimeExtra = 0.0 +
        (random(-5, 5) / 100) --adding some variability to reaction times 0.0 to 0.05 seconds randomly
    local reactionTime = SettingsConstants.npcReactionTimeMin + (SettingsConstants.npcReactionTimeBase * factor) +
        reactionTimeExtra
    if self.quickMode then
        reactionTime = reactionTime + 0.5 -- flat increase for reaction time for quick mode
    end
    if Helpers:rollNdM(1, 100, 93) > 0 then
        reactionTime = reactionTime - 0.1
    end
    reactionTime = max(reactionTime, SettingsConstants.npcReactionTimeMin)
    logging:debug(tostring(actorSelf) .. "reaction time:" .. reactionTime)
    return reactionTime
end

function ParryController.getParryHoldDuration(self)
    if not self.activeParryConfig then return 0 end
    self:statUpdate({ self.activeParryConfig.mainSkillId, self.activeParryConfig.secondarySkillId })
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].value
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].value
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SettingsConstants.parryHoldDurationMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SettingsConstants.parryHoldDurationSecondarySkillRatio,
        skillCurveStep)
    local ratio = max(1 - ((mainSkillCurve + secondarySkillCurve) / 100), 0)
    logging:debug(tostring(actorSelf) .. "parry hold duration ratio:" .. ratio)
    local holdDuration = SettingsConstants.parryHoldBaseDuration + (1.5 * ratio)
    if not self.amPlayer and not self.threatData.melee then
        holdDuration = holdDuration * self.rangedThreatHoldMultiplier
    end
    logging:debug(tostring(actorSelf) .. "parry hold duration:" .. holdDuration)
    return holdDuration
end

function ParryController.getStaggerCooldown(self)
    if not self.activeParryConfig then return 1 end
    self:statUpdate({ "strength", self.activeParryConfig.secondarySkillId, "endurance" })
    local attrStrength = self.currentStats["strength"].value
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].value
    local attrEndurance = self.currentStats["endurance"].value
    local skillCurveStep = 100
    local strengthCurve = self:getStatCurve(attrStrength, SettingsConstants.staggerCooldownStrengthRatio, skillCurveStep)
    local enduranceCurve = self:getStatCurve(attrEndurance, SettingsConstants.staggerCooldownEnduranceRatio,
        skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SettingsConstants.staggerCooldownSecondarySkillRatio,
        skillCurveStep)
    local cooldown = min(
        SettingsConstants.staggerCooldownMin + ((strengthCurve + enduranceCurve + secondarySkillCurve) / 100),
        SettingsConstants.staggerCooldownMax)
    logging:debug(tostring(actorSelf) .. "stagger cooldown:" .. cooldown)

    return cooldown
end

function ParryController.getParryDefenceFactor(self)
    if not self.activeParryConfig then return 1 end
    self:statUpdate({ self.activeParryConfig.mainSkillId, self.activeParryConfig.secondarySkillId, "agility", "luck" })
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].value
    local secondarySkill = self.currentStats[self.activeParryConfig.secondarySkillId].value
    local agility = (self.currentStats["agility"].value - 30) / 5
    local luck = (self.currentStats["luck"].value - 40) / 10
    local currentFatigue = fatigue(actorSelf).current
    local maxFatigue = fatigue(actorSelf).base
    local fatiguePercentage = formulaFatigueEffects[self.fatigueEffectsFormula](currentFatigue / maxFatigue)
    local skillCurveStep = 60
    local mainSkillCurve = self:getStatCurve(mainSkill, SettingsConstants.defenceMainSkillRatio, skillCurveStep)
    local secondarySkillCurve = self:getStatCurve(secondarySkill, SettingsConstants.defenceSecondarySkillRatio,
        skillCurveStep)
    -- logging:debug("mainSkillCurve:"..mainSkillCurve)
    -- logging:debug("secondarySkillCurve:"..secondarySkillCurve)
    -- logging:debug("skillCurveStep:"..skillCurveStep)
    -- logging:debug("fatiguePercentage:"..fatiguePercentage)
    -- logging:debug("effectiveness:"..self.activeParryConfig.effectiveness)
    local defenceFactor = (1 - min(SettingsConstants.baseParryDefenceFactor + (((secondarySkillCurve + mainSkillCurve + agility + luck) * fatiguePercentage) / 100) * self.activeParryConfig.effectiveness, 1))
    logging:debug(tostring(actorSelf) .. "defenceFactor:" .. defenceFactor)

    return defenceFactor
end

function ParryController.getWindupDuration(self)
    local windupMin = 175 --ms
    local wundupMax = 450 --ms
    if not self.quickMode then
        windupMin = windupMin * 2
    end
    local windup = random(windupMin, wundupMax) / 1000
    return windup
end

function ParryController.willParry(self)
    if self.amPlayer then return true end
    if not self.activeParryConfig then return false end
    self:statUpdate({ self.activeParryConfig.mainSkillId, "agility", "luck" })
    local mainSkill = self.currentStats[self.activeParryConfig.mainSkillId].value
    local agility = self.currentStats["agility"].value
    local luck = self.currentStats["luck"].value
    local currentFatigue = fatigue(actorSelf).current
    local maxFatigue = fatigue(actorSelf).base
    local fatiguePercentage = formulaFatigueEffects[self.fatigueEffectsFormula](currentFatigue / maxFatigue)
    local parryChance = (mainSkill + (agility / 5) + (luck / 10)) * (0.1 + (1.25 * fatiguePercentage))
    logging:debug("Parry chance:" .. parryChance)
    return Helpers:rollNdM(1, 100, 100 - parryChance) > 0
end

--#endregion


--#region feint

function ParryController.tryFeint(self)
    if not self.isParrying then return end
    print("huh")
    for _, target in pairs(self.targets) do
        target:sendEvent("NGarde_tryFeint")
    end
    I.AnimationController.playBlendedAnimation(self.activeParryConfig.animation, {
        startKey = 'stop',
        stopKey = 'feintstop',
        ---@diagnostic disable-next-line: assign-type-mismatch
        priority = anim.PRIORITY.Scripted,
        autoDisable = true,
        blendMask = self.activeParryConfig.blendMask,
        speed = 1
    })
end

--#endregion

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
    logging:debug(tostring(actorSelf) .. "playing:" .. hitIndex)
    I.AnimationController.playBlendedAnimation(hitIndex, {
        startKey = 'start',
        stopKey = 'stop',
        ---@diagnostic disable-next-line: assign-type-mismatch
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

function ParryController.getItemCondition(item)
    local ok, itemData = pcall(types.Item.itemData, item)
    if ok then
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
        ---@diagnostic disable-next-line: missing-fields
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
        ---@diagnostic disable-next-line: missing-fields
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
            ---@diagnostic disable-next-line: missing-fields
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
            ---@diagnostic disable-next-line: missing-fields
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

function ParryController.isAnimationPlaying(self, checkFor)
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
        ---@diagnostic disable-next-line missing-parameter
        if activeEffects(actorSelf):getEffect(core.magic.EFFECT_TYPE.Paralyze).magnitude > 0 or
            self:isAnimationPlaying(Constants.staggerAnimations) then
            self.isStaggered = true
            self:tryLowerGuard()
            return
        end
    end
    self.isStaggered = false
end

function ParryController.checkAttackState(self, use)
    if (getStance(actorSelf) == types.Actor.STANCE.Weapon) then
        if use ~= 0 or self:isAnimationPlaying(Constants.attackAnimations) then
            self.isAttacking = true;
            return
        end
    end
    self.isAttacking = false
end

function ParryController.processMoveSpeedPenalty(self)
    local movement = actorSelf.controls.movement
    local sideMovement = actorSelf.controls.sideMovement
    if movement ~= 0 then
        local absMove = min(math.abs(movement), self.activeParryConfig.moveSpeedMultiplier)
        if actorSelf.controls.movement < 0 then
            actorSelf.controls.movement = -absMove
        else
            actorSelf.controls.movement = absMove
        end
    end
    if sideMovement ~= 0 then
        local absSideMove = min(math.abs(sideMovement), self.activeParryConfig.moveSpeedMultiplier)
        if actorSelf.controls.sideMovement < 0 then
            actorSelf.controls.sideMovement = -absSideMove
        else
            actorSelf.controls.sideMovement = absSideMove
        end
    end
end

function ParryController.startskillGainParryTimer(self)
    self.localTimers.skillGainParryTimer:startTimer(1)
end

function ParryController.reactionDelayedRaiseGuard(self)
    self:selectGuardWith()
    if not self.localTimers.reactionTimerRaiseGuard.active then
        self.localTimers.reactionTimerRaiseGuard:startTimer(self:getReactionTime())
    end
end

function ParryController.reactionDelayedLowerGuard(self)
    if not self.localTimers.reactionTimerLowerGuard.active then
        self.localTimers.reactionTimerLowerGuard:startTimer(self:getReactionTime())
    end
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
            self.localTimers.staggerCooldownTimer:startTimer(self:getStaggerCooldown())
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
            self.localTimers.fatigueDrainTimer:startTimer(1, true) -- repeating fatigue drain timer
            self.lastPerfectParryWindow = self:getPerfectParryWindow()
            logging:debug("starting perfectParryWindow:" .. tostring(self.lastPerfectParryWindow))
            self.localTimers.perfectParryTimer:startTimer(self.lastPerfectParryWindow)
            self.localTimers.currentParryTimer:startTimer(self:getParryHoldDuration())
            self.startedParry = false
        end
    end
end

function ParryController.tryRaiseGuard(self)
    if not self:willParry() then return end
    if not self:canParry() then return end
    if self.shieldStrike then return end
    self:selectGuardWith()
    -- logging:debug(self.activeParryConfig)
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
            priority = self.activeParryConfig.priority,
            autoDisable = false,
            blendMask = self.raisedWithMask,
            speed = self.localAnimationSpeed,
        })
        logging:debug(tostring(actorSelf) .. "can parry")
    end
end

function ParryController.tryLowerGuard(self)
    if self.startedParry or self.isParrying then
        if not self.amPlayer then
            logging:debug("parryCooldown:" .. tostring(self:getParryCooldown()))
            self.localTimers.parryCooldownTimer:startTimer(self:getParryCooldown())
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
        self.localTimers.currentParryTimer:stopTimer() -- stopping parry timer if it's not already
        logging:debug("stop parry")
    end
end

function ParryController.forceLowerGuard(self)
    -- if not self.amPlayer then
    --     logging:debug("parryCooldown:" .. tostring(self:getParryCooldown()))
    --     self.localTimers.parryCooldownTimer:startTimer(self:getParryCooldown())
    -- end
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
    self.localTimers.currentParryTimer:stopTimer() -- stopping parry timer if it's not already
    logging:debug("stop parry")
end

function ParryController.fatigueCostAttacker(reflectTarget, fatigueDamage)
    if not reflectTarget then return end
    reflectTarget:sendEvent('ModifyStat', { stat = 'fatigue', amount = -fatigueDamage })
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
            self.currentShieldConfig.parrySpeedMultiplier = Constants.shieldMoveSpeedMultiplierMap[shieldCategory]
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
        self.localAnimationSpeed = self.activeParryConfig.animationSpeed *
            SettingsConstants.quickModeAnimationSpeedDivisor
    end
end

---@enum MEASURE
ParryController.MEASURE = {
    TooClose = 0,
    InMeasure = 1,
    WalkInDistance = 2,
    RunInDistance = 3,
}


ParryController.measureManagement = {
    [0] = function(possibleDirections, actor)
        actor.controls.run = false
        if possibleDirections.back.allowed then
            actor.controls.movement = -1
        else
            if possibleDirections.right.allowed then
                actor.controls.sideMovement = 1
            else
                if possibleDirections.left.allowed then
                    actor.controls.sideMovement = -1
                end
            end
        end
    end,
    [1] = function(possibleDirections, actor)
        return
    end,
    [2] = function(possibleDirections, actor)
        actor.controls.run = false
        return
    end,
    [3] = function(possibleDirections, actor)
        return
    end,
}

function ParryController.keepMeasureDistance(self, threatActor)
    if self.activeParryConfig then --generally means we are melee
        local keep = ParryController.measureManagement[self:isInMeasure(threatActor)]
        if keep then
            keep(self:findDirectionToMove(), actorSelf)
        end
    end
end

function ParryController.findDirectionToMove(self)
    local flanks = self:getFlankingPositions(SettingsConstants.obstacleDetectionRange)
    local moveDirections = {
        right = { allowed = false, vector = nil },
        left = { allowed = false, vector = nil },
        back = { allowed = false, vector = nil },
        forward = { allowed = false, vector = nil },
    }
    for direction, flank in pairs(flanks) do
        targetRaycast:setRayType("castRay")
        local result = targetRaycast:castFromToTarget(actorSelf, actorSelf.position, flank)
        if result.hit then
            -- logging:debug("Can't move " .. direction)
        else
            result = targetRaycast:castNavigationRay(actorSelf.position, flank)
            if result then
                -- logging:debug(direction)
                -- logging:debug("Can move " .. direction)
                -- logging:debug(result)
                moveDirections[direction].vector = result
                moveDirections[direction].allowed = true
            end
        end
    end
    return moveDirections
end

function ParryController.isInMeasure(self, threatActor)
    local measureDistance = self.recordEquippedR.reach * core.getGMST("fCombatDistance")
    local inverseRotation = actorSelf.rotation:inverse()                                   -- converting to local frame of reference
    local relativePosition = inverseRotation * (threatActor.position - actorSelf.position) -- relative position
    local currentDistSq = relativePosition.x ^ 2 + relativePosition.y ^ 2

    local halfSize = actorSelf:getBoundingBox().halfSize.y
    local maxMeasureDistance = measureDistance + halfSize
    local minMeasureDistance = measureDistance


    if currentDistSq >= maxMeasureDistance ^ 2 + halfSize ^ 2 then
        return ParryController.MEASURE.RunInDistance
    elseif currentDistSq >= maxMeasureDistance ^ 2 then
        return ParryController.MEASURE.WalkInDistance
    elseif currentDistSq < minMeasureDistance ^ 2 then
        return ParryController.MEASURE.TooClose
    else
        return ParryController.MEASURE.InMeasure
    end
end

function ParryController.getFlankingPositions(self, distance)
    -- Define offsets in LOCAL space (Y = forward, X = right)
    local offsetRight   = util.vector3(distance, 0, 0)
    local offsetLeft    = util.vector3(-distance, 0, 0)
    local offsetBack    = util.vector3(0, -distance, 0)
    local offsetForward = util.vector3(0, distance, 0)

    -- Convert local offsets back to WORLD space by applying the actorSelf's rotation
    -- (inverse of what allowedThreatDirection does: world->local, here we go local->world)
    local worldRight    = actorSelf.rotation * offsetRight
    local worldLeft     = actorSelf.rotation * offsetLeft
    local worldBack     = actorSelf.rotation * offsetBack
    local worldForward  = actorSelf.rotation * offsetForward

    return {
        right   = actorSelf.position + worldRight,
        left    = actorSelf.position + worldLeft,
        back    = actorSelf.position + worldBack,
        forward = actorSelf.position + worldForward,
    }
end

function ParryController.allowedThreatDirection(self, threatActor, arc, offset, maxDistance)
    -- Directional Check (N deg Arc, skewed M deg Left)
    local maxDst = maxDistance or nil
    local inverseRotation = actorSelf.rotation:inverse()                         -- converting to local frame of reference
    local relPos = inverseRotation * (threatActor.position - actorSelf.position) -- relative position
    -- sqare of distance to avoid sqrt. we'll need it later. But calculating now to allow earlier out if distance is over max
    local distSq = relPos.x * relPos.x + relPos.y * relPos.y
    -- early out if max distance is specified (e.g. for threat reaction to a charge). If we are too far - no reason to check direction, just return false
    if maxDst then
        maxDst = (maxDst + actorSelf:getBoundingBox().halfSize.y + threatActor:getBoundingBox().halfSize.y) *
            1.1 -- good enough, I suppose
        -- logging:debug(maxDst)
        -- logging:debug(maxDst * maxDst)
        -- logging:debug(distSq)
        if (maxDst ^ 2) < distSq then --if current distance is bigger than max distance
            return false
        end
    end

    -- Apply N deg Left Skew to the facing
    -- cos(7deg) * relative Y - sin(7deg) * relative X
    -- substraction moves it left, addition will move it right
    local skewAngle = rad(offset)
    -- rotating relative position axis by offset degrees left
    local skewY = (cos(skewAngle) * relPos.y) - (sin(skewAngle) * relPos.x)

    -- Check N degree half-angle
    -- Condition: dot / distance(magnitude) > cos(theta)
    -- multiplying both sides by mag to simplify:
    -- dot > cos(theta) * mag
    -- squaring both sides to avoid square root in magnitude(distance)
    -- becomes dot^2 > cos^2 * mag^2
    local halfAngle = rad(arc / 2) -- taking half angle of the possible threat/parry arc. checking n/2 degrees in each direction from front facing axis:  "N/2<--|-->N/2"
    local halfAngleCosSquared = cos(halfAngle) * cos(halfAngle)
    -- skewY > 0 - only forward.
    -- actual condition - skewY^2 > (cos(N deg)^2 * distance squared)
    local isFrontHitWithinTheArc = (skewY > 0)               -- is in front
        and (skewY * skewY > (halfAngleCosSquared * distSq)) -- is within the arc
    return isFrontHitWithinTheArc
end

function ParryController.startAttackWindup(self, use)
    self.localTimers.attackWindupTimer:startTimer(self:getWindupDuration())
    self.windup = use
end

---callback of the timer started in the method above, defined when timer was created
function ParryController.releaseAttackWindup()
    if actorSelf.controls.use ~= actorSelf.ATTACK_TYPE.NoAttack then
        actorSelf.controls.use = actorSelf.ATTACK_TYPE.NoAttack
    end
end

function ParryController.onHitHandler(self, attack)
    if not attack.attacker then return attack end -- attacker is nil, likely someone is sending hit events for a reason other than combat. exit
    logging:debug(tostring(actorSelf) .. "entered onHitHandler")
    local isH2HAttack, isThrown, attackerIsCreature, attackerIsWeaponUser, attackerName = Helpers.getAttackDetails(attack)
    logging:debug("isH2HAttack:" .. tostring(isH2HAttack))
    logging:debug("successful:" .. tostring(attack.successful))
    logging:debug("attack.weapon:")
    logging:debug(attack.weapon)


    if self.allAttacksHit then
        if not attack.successful then
            logging:debug(tostring(actorSelf) .. "All attacks hit is ON, attack is a miss, adjusting.")
            attack = attackController.processFumble(attack, isH2HAttack, isThrown, attackerIsCreature,
                attackerIsWeaponUser)
        end
    end
    if attackerIsCreature then
        if self.allowParryCreatures == "No" then
            logging:debug(tostring(actorSelf) .. "Can't parry creatures")
            return
        elseif self.allowParryCreatures == "Shield Only" and self.activeParryConfig.name ~= "shield" then
            logging:debug(tostring(actorSelf) .. "Can't parry creatures, without a shield")

            return
        end
    end
    if self.activeParryConfig and self.isParrying then -- have weapon that can parry or shield
        logging:debug(tostring(actorSelf) .. "Has parry tool and is in parry stance")
        if not self:allowedThreatDirection(attack.attacker, self.activeParryConfig.parryArc, self.activeParryConfig.parryOffset) then
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
                local stringWeaponType = Constants.weaponToTypeMap[attackWeaponRecord.type]
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


        if attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee or self.activeParryConfig.name == "shield" then -- have a shield _or_ the attack is melee
            attack = self:processParry(attack, attackerName)                                                     -- modify the attack, reflect fatigue if any, get attack back.
        end
        self.activeParryConfig.effectiveness = storedEffectiveness
    else
        logging:debug("No parry, passing regular onHit") --no useable weapon or shield
    end
    return attack
end

function ParryController:tryGuardEnchant(attack)
    if not attack.weapon then return end
    if not self.parryEnchants then return end
    local weaponRecordId = "none"
    if attack.weapon.id ~= "@0x0" then
        weaponRecordId = attack.weapon.recordId
    end
    local attackWeaponRecord = getWeaponRecord(weaponRecordId)
    local weaponEnchantRecord
    local ammoEnchantRecord
    local attackAmmoRecord = nil
    if attackWeaponRecord ~= nil then
        if attack.ammo ~= nil then
            attackAmmoRecord = getWeaponRecord(attack.ammo)
        end

        local currentEffects = activeEffects(actorSelf)
        local enchantRecords = {}
        if attackAmmoRecord ~= nil then
            if attackAmmoRecord.enchant ~= nil then
                logging:debug("Parrying ammo enchants")

                ammoEnchantRecord = core.magic.enchantments.records[attackAmmoRecord.enchant]
                table.insert(enchantRecords, { itemRecord = attackAmmoRecord, enchantRecord = ammoEnchantRecord })
            end
        end
        if attackWeaponRecord then
            if attackWeaponRecord.enchant ~= nil then
                logging:debug("Parrying weapon enchants")
                weaponEnchantRecord = core.magic.enchantments.records[attackWeaponRecord.enchant]
                table.insert(enchantRecords, { itemRecord = attackWeaponRecord, enchantRecord = weaponEnchantRecord })
            end
        end
        for _, t in ipairs(enchantRecords) do
            for _, effect in ipairs(t.enchantRecord.effects) do
                if effect.area == 0 or self.parryAOEEnchants then
                    local magicEffect = effect.effect
                    local strId = effect.id
                    if type(magicEffect) == 'string' then
                        strId = magicEffect
                    end
                    magicEffect = core.magic.effects.records[strId] or core.magic.effects[strId]
                    if magicEffect then
                        if not string.find(magicEffect.id, "bound") then
                            ---@diagnostic disable-next-line: missing-parameter
                            currentEffects:remove(magicEffect.id)
                            logging:debug("Canceling magic effect:" .. magicEffect.id)

                            local vfxId = magicEffect.hitStatic
                            local vfxArea = magicEffect.areaStatic
                            if vfxId then
                                anim.removeVfx(actorSelf, vfxId)
                            end
                            if vfxArea then
                                anim.removeVfx(actorSelf, vfxArea)
                            end
                            if magicEffect then
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
                end
            end
        end
    end
end

function ParryController.raisedGuardDrainFatigue(self)
    if self.baseGuardFatigueDrain == 0 or self.scalingGuardFatigueDrain == 0 then return end
    local drain = self.baseGuardFatigueDrain +
        self.scalingGuardFatigueDrain * (1 - self.currentStats[self.activeParryConfig.secondarySkillId].value / 100)
    logging:debug(("drain fatige from holding guard: - %s"):format(drain))
    actorSelf:sendEvent('ModifyStat', { stat = 'fatigue', amount = -drain })
end

function ParryController.processParry(self, attack, attackerName)
    if self.targets[attack.attacker.id] == nil then
        self.targets[attack.attacker.id] = attack.attacker
    end
    local playShieldHitAnim = true
    logging:debug("parry pre-check")
    local debugMsg = ""
    local currentFatigue = fatigue(actorSelf).current

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
    --perfectParry only possible on melee attacks
    if self.localTimers.perfectParryTimer.active and attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee then
        --setting variables necessary for the parry to count as Perfect
        logging:debug("perfect parry")
        factor = 0
        timing = 1
        perfect = true
        attack.ngarde_perfectParry = true
        soundData = Helpers.tableDeepCopy(Constants.materialToSoundMap[self.activeParryConfig.material].perfectParry)
        parryCost = parryCost / 3
        skillGainScale = skillGainScale + 0.5
        -- self.localTimers.perfectParryTimer:stopTimer() --can perfect parry only once
        attack.attacker:sendEvent("ngarde_perfectParry")
        actorSelf:sendEvent("ngarde_perfectParrySelf")
        if not self.amPlayer then
            self:tryLowerGuard() -- NPC perfect parried player - lower guard and try to counter attack
        end
        playShieldHitAnim = false
    end
    logging:debug(tostring(actorSelf) .. "parry defence multiplier:" .. factor)
    -- converting portion of health damage into fatigue damage
    -- half of converted damage is reflected as fatigue to the attacker.
    -- What's left is dealt as durability damage to the item we used to parry
    -- but defender only takes partial fatigue damage further reduced by parry multiplier `factor`.
    -- this way as defender skill gets higher - attacker gets more fatigue damage and defender less
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
        attack.damage.fatigue = attack.damage.fatigue - negatedDamage.fatigue
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
    durabilityDamage = durabilityDamage + attack.damage.fatigue + attack.damage.health
    attack.damage.fatigue = negatedDamage.fatigue * factor
    if factor == 0 then
        self:tryGuardEnchant(attack)
    end
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


    skillGainScale = skillGainScale + ((negatedDamage.health / health(actorSelf).base) / 2) +
        ((negatedDamage.fatigue / fatigue(actorSelf).base) / 4)
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
        fatigue(actorSelf).current = math.max(0, currentFatigue - parryCost)
    else
        fatigue(actorSelf).current = currentFatigue - parryCost
    end
    logging:debug(tostring(actorSelf) .. "New fatigue value:" .. fatigue(actorSelf).current)
    if playShieldHitAnim then
        if self.activeParryConfig.name == "shield" then
            logging:debug(tostring(actorSelf) .. "playing shield hit animation")
            I.AnimationController.playBlendedAnimation("shield", {
                startKey = 'block start',
                stopKey = 'block stop',
                ---@diagnostic disable-next-line: assign-type-mismatch
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
            skillUsed(self.activeParryConfig.secondarySkillId, skillUsedOptions)
        end
        skillUsed(self.activeParryConfig.mainSkillId, skillUsedOptions)
    end
    if self.debugMessages and self.amPlayer then
        ui.showMessage(debugMsg)
    end
    logging:debug(debugMsg)

    return attack
end

function ParryController.readSettings(self)
    self:readParrySettings()
    self:readBalanceSettings()
    self:readDebugSettings()
end

function ParryController.readParrySettings(self)
    self.parryEnchants           = parrySettings:get(SettingsConstants.enchantParrySettingKey)
    self.parryAOEEnchants        = parrySettings:get(SettingsConstants.enchantParryAOESettingKey)
    self.baseParryDurabilityLoss = parrySettings:get(SettingsConstants.baseParryDurabilityLossKey)
    self.baseParryFatigueCost    = parrySettings:get(SettingsConstants.baseParryFatigueCostKey)
    self.allAttacksHit           = parrySettings:get(SettingsConstants.allAttacksHitKey)
    self.parrySoundVolume        = parrySettings:get(SettingsConstants.parrySoundVolumeKey)
    if self.parrySoundVolume == nil then -- this is ass, but is necessary to make slider renderer work
        self.parrySoundVolume = SettingsConstants.parrySoundVolumeDefault / 100
    else
        self.parrySoundVolume = self.parrySoundVolume / 100
    end

    self.quickMode             = parrySettings:get(SettingsConstants.quickModeKey)
    self.fatigueEffectsFormula = parrySettings:get(SettingsConstants.fatigueEffectsFormulaKey)
    self.allowParryCreatures   = parrySettings:get(SettingsConstants.allowParryCreaturesKey)
end

function ParryController.readBalanceSettings(self)
    self.ironPalmThreshold                          = balanceSettings:get(SettingsConstants.ironPalmThresholdKey)
    self.perfectParryThreshold                      = balanceSettings:get(SettingsConstants.perfectParryThresholdKey)
    self.baseGuardFatigueDrain                      = balanceSettings:get(SettingsConstants.baseGuardFatigueDrainKey)
    self.scalingGuardFatigueDrain                   = balanceSettings:get(SettingsConstants.scalingGuardFatigueDrainKey)
    self.effectivenessSettings["shortbladeonehand"] = balanceSettings:get(SettingsConstants
        .baseShortBladeOneHandParryEffectivenessKey)
    self.effectivenessSettings["longbladeonehand"]  = balanceSettings:get(SettingsConstants
        .baseLongBladeOneHandParryEffectivenessKey)
    self.effectivenessSettings["longbladetwohand"]  = balanceSettings:get(SettingsConstants
        .baseLongBladeTwoHandParryEffectivenessKey)
    self.effectivenessSettings["bluntonehand"]      = balanceSettings:get(SettingsConstants
        .baseBluntOneHandParryEffectivenessKey)
    self.effectivenessSettings["blunttwoclose"]     = balanceSettings:get(SettingsConstants
        .baseBluntTwoCloseParryEffectivenessKey)
    self.effectivenessSettings["blunttwowide"]      = balanceSettings:get(SettingsConstants
        .baseBluntTwoWideParryEffectivenessKey)
    self.effectivenessSettings["speartwowide"]      = balanceSettings:get(SettingsConstants
        .baseSpearTwoWideParryEffectivenessKey)
    self.effectivenessSettings["axeonehand"]        = balanceSettings:get(SettingsConstants
        .baseAxeOneHandParryEffectivenessKey)
    self.effectivenessSettings["axetwohand"]        = balanceSettings:get(SettingsConstants
        .baseAxeTwoHandParryEffectivenessKey)
    self.effectivenessSettings["handtohand"]        = balanceSettings:get(SettingsConstants
        .baseHandToHandParryEffectivenessKey)
    self.effectivenessSettings["shield"]            = balanceSettings:get(SettingsConstants
        .baseShieldParryEffectivenessKey)
end

function ParryController.readDebugSettings(self)
    self.debugMessages = debugSettings:get(SettingsConstants.debugMessagesKey)
    self.debugLogs = debugSettings:get(SettingsConstants.debugLogsKey)
    if self.debugLogs then
        logging:setLoglevel(logging.LOG_LEVELS.DEBUG)
        logging:status("Enabling debug logs")
    else
        logging:setLoglevel(logging.LOG_LEVELS.OFF)
        logging:status("Debug logging disabled")
    end
end

return ParryController
