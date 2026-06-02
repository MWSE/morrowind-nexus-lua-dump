---@omw-context all
local modInfo = require('scripts.ngarde.modinfo')
local core = require('openmw.core')
local l10n = core.l10n(modInfo.l10n)

local function stringToKey(suffix)
    return ('%s_%s'):format(modInfo.modKey, suffix)
end

local function keyToDefault(key)
    local defaultKey = key:gsub(modInfo.modKey .. "_", "")
    defaultKey = defaultKey:gsub("Key", "Default")
    return defaultKey
end

local SettingsConstants = {}



--#region tuning
SettingsConstants.frontArc = 160
SettingsConstants.defenceMainSkillRatio = 0.65
SettingsConstants.defenceSecondarySkillRatio = 0.30
SettingsConstants.perfectParryMainSkillRatio = 0.33
SettingsConstants.perfectParrySecondarySkillRatio = 0.1
SettingsConstants.maxPerfectParryWindow = 0.4
SettingsConstants.basePerfectParryWindow = 0.05
SettingsConstants.baseParryDefenceFactor = 0.15
SettingsConstants.baseSkillCurveDivisor = 1.05
SettingsConstants.fatiugeCostMainSkillRatio = 0.4
SettingsConstants.fatiugeCostSecondarySkillRatio = 0.2
SettingsConstants.fatigueCostEffectivenessRatio = 0.10
--#region ranged Threat adjustments
SettingsConstants.rangedThreatHoldMultiplier = 2
SettingsConstants.rangedThreatCooldownDivisor = 1.5
--#endregion
SettingsConstants.staggerCooldownMin = 0.5
SettingsConstants.staggerCooldownMax = 3.0
SettingsConstants.staggerCooldownStrengthRatio = 0.75
SettingsConstants.staggerCooldownSecondarySkillRatio = 0.1
SettingsConstants.staggerCooldownEnduranceRatio = 0.8

--#region parryCooldown
SettingsConstants.parryCooldownMainSkillRatio = 0.75
SettingsConstants.parryCooldownSecondarySkillRatio = 0.35
SettingsConstants.minParryCooldown = 0.5
SettingsConstants.baseParryCooldown = 2.5
--#endregion
--#region reaction time
SettingsConstants.npcReactionTimeMin = 0.1
SettingsConstants.npcReactionTimeBase = 0.6
SettingsConstants.npcReactionTimeSpeedFactor = 0.5
SettingsConstants.npcReactionTimeMainSkillFactor = 0.5
SettingsConstants.npcReactionTimeSecondarySkillFactor = 0.2
--#endregion
SettingsConstants.parryHoldBaseDuration = 0.7
SettingsConstants.parryHoldDurationMainSkillRatio = 0.55
SettingsConstants.parryHoldDurationSecondarySkillRatio = 0.45


--#region Deflect Arrows
SettingsConstants.deflectArrowsMainSkillThreshold              = 125
SettingsConstants.deflectArrowsMainSkillFallbackThreshold      = 90
SettingsConstants.deflectArrowsSecondarySkillFallbackThreshold = 90

--#endregion


--#endregion
SettingsConstants.fortifyFatigueMaxImpact                    = 1.2
SettingsConstants.obstacleDetectionRange                     = 200
SettingsConstants.obstacleVerticalOffest                     = 0

--#region Settings
--#region action Keys
SettingsConstants.parryActionKey                             = stringToKey("parryActionKey")
--#endregion
--#region Settings Keys
SettingsConstants.generalSettingsStorageKey                  = ("Settings_%s"):format(stringToKey(
    "generalSettingsKey"))
SettingsConstants.parrySettingsGroupKey                      = ("Settings_%s"):format(stringToKey(
    "parrySettingsGroupKey"))
SettingsConstants.balanceSettingsGroupKey                    = ("Settings_%s"):format(stringToKey(
    "balanceSettingsGroupKey"))
SettingsConstants.debugSettingsGroupKey                      = ("Settings_%s"):format(stringToKey(
    "debugSettingsGroupKey"))

SettingsConstants.settingsParryKeyBindKey                    = stringToKey("settingsParryKeyBindKey")
SettingsConstants.enchantParrySettingKey                     = stringToKey("enchantParrySettingKey")
SettingsConstants.enchantParryAOESettingKey                  = stringToKey("enchantParryAOESettingKey")
SettingsConstants.baseParryDurabilityLossKey                 = stringToKey("baseParryDurabilityLossKey")
SettingsConstants.baseParryFatigueCostKey                    = stringToKey('baseParryFatigueCostKey')
SettingsConstants.ironPalmThresholdKey                       = stringToKey("ironPalmThresholdKey")
SettingsConstants.perfectParryThresholdKey                   = stringToKey("perfectParryThresholdKey")
SettingsConstants.parryEffectivenessGroupKey                 = stringToKey("parryEffectivenessGroupKey")
SettingsConstants.baseShortBladeOneHandParryEffectivenessKey = stringToKey(
    "baseShortBladeOneHandParryEffectivenessKey")
SettingsConstants.baseLongBladeOneHandParryEffectivenessKey  = stringToKey(
    "baseLongBladeOneHandParryEffectivenessKey")
SettingsConstants.baseLongBladeTwoHandParryEffectivenessKey  = stringToKey(
    "baseLongBladeTwoHandParryEffectivenessKey")
SettingsConstants.baseBluntOneHandParryEffectivenessKey      = stringToKey("baseBluntOneHandParryEffectivenessKey")
SettingsConstants.baseBluntTwoCloseParryEffectivenessKey     = stringToKey("baseBluntTwoCloseParryEffectivenessKey")
SettingsConstants.baseBluntTwoWideParryEffectivenessKey      = stringToKey("baseBluntTwoWideParryEffectivenessKey")
SettingsConstants.baseSpearTwoWideParryEffectivenessKey      = stringToKey("baseSpearTwoWideParryEffectivenessKey")
SettingsConstants.baseAxeOneHandParryEffectivenessKey        = stringToKey("baseAxeOneHandParryEffectivenessKey")
SettingsConstants.baseAxeTwoHandParryEffectivenessKey        = stringToKey("baseAxeTwoHandParryEffectivenessKey")
SettingsConstants.baseHandToHandParryEffectivenessKey        = stringToKey("baseHandToHandParryEffectivenessKey")
SettingsConstants.baseShieldParryEffectivenessKey            = stringToKey("baseShieldParryEffectivenessKey")
SettingsConstants.allAttacksHitKey                           = stringToKey("allAttacksHitKey")
SettingsConstants.parrySoundVolumeKey                        = stringToKey("parrySoundVolumeKey")
SettingsConstants.quickModeKey                               = stringToKey("quickModeKey")
SettingsConstants.fatigueEffectsFormulaKey                   = stringToKey("fatigueEffectsFormulaKey")
SettingsConstants.baseGuardFatigueDrainKey                   = stringToKey("baseGuardFatigueDrainKey")
SettingsConstants.scalingGuardFatigueDrainKey                = stringToKey("scalingGuardFatigueDrainKey")
SettingsConstants.allowParryCreaturesKey                     = stringToKey("allowParryCreaturesKey")
SettingsConstants.debugMessagesKey                           = stringToKey("debugMessagesKey")
SettingsConstants.debugLogsKey                               = stringToKey("debugLogsKey")
SettingsConstants.playMissAnimationsKey                      = stringToKey("playMissAnimationsKey")
SettingsConstants.allowArrowDeflectKey                       = stringToKey("allowArrowDeflectKey")
SettingsConstants.controllerTriggerKey                       = stringToKey("controllerTriggerKey")
SettingsConstants.triggerSensitivityKey                      = stringToKey("triggerSensitivityKey")

--#endregion
--#region Defaults


--#region select values
---@enum controller_triggers
SettingsConstants.controller_triggers         = {
    lt = 1,
    rt = 2,
    off = 3,
}

SettingsConstants.controllerTriggerValues     = {
    [SettingsConstants.controller_triggers.lt] = l10n("controller_left_trigger"),
    [SettingsConstants.controller_triggers.rt] = l10n("controller_right_trigger"),
    [SettingsConstants.controller_triggers.off] = l10n("controller_off")
}

---@enum fatigue_effects
SettingsConstants.fatigue_effects             = {
    full = 1,
    partial = 2,
    off = 3,
}

SettingsConstants.fatigueEffectsFormulaValues = {
    [SettingsConstants.fatigue_effects.full] = l10n("fatigue_effects_full"),
    [SettingsConstants.fatigue_effects.partial] = l10n("fatigue_effects_partial"),
    [SettingsConstants.fatigue_effects.off] = l10n("fatigue_effects_off"),
}

---@enum parry_creatures
SettingsConstants.parry_creatures             = {
    all = 1,
    shields = 2,
    off = 3,
}


SettingsConstants.allowParryCreaturesValues                      = {
    [SettingsConstants.parry_creatures.all] = l10n("parry_creatures_all"),
    [SettingsConstants.parry_creatures.shields] = l10n("parry_creatures_shields"),
    [SettingsConstants.parry_creatures.off] = l10n("parry_creatures_off"),
}

--#endregion

SettingsConstants.enchantParrySettingDefault                     = true
SettingsConstants.enchantParryAOESettingDefault                  = false
SettingsConstants.baseParryDurabilityLossDefault                 = 3
SettingsConstants.baseParryFatigueCostDefault                    = 25
SettingsConstants.ironPalmThresholdDefault                       = 70
SettingsConstants.perfectParryThresholdDefault                   = 40
SettingsConstants.allAttacksHitDefault                           = false
SettingsConstants.parrySoundVolumeDefault                        = 100
--#region baseline effectiveness
SettingsConstants.baseShortBladeOneHandParryEffectivenessDefault = 0.9
SettingsConstants.baseLongBladeOneHandParryEffectivenessDefault  = 1.05
SettingsConstants.baseLongBladeTwoHandParryEffectivenessDefault  = 1.3
SettingsConstants.baseBluntOneHandParryEffectivenessDefault      = 1
SettingsConstants.baseBluntTwoCloseParryEffectivenessDefault     = 1.05
SettingsConstants.baseBluntTwoWideParryEffectivenessDefault      = 1.3
SettingsConstants.baseSpearTwoWideParryEffectivenessDefault      = 1.3
SettingsConstants.baseAxeOneHandParryEffectivenessDefault        = 1
SettingsConstants.baseAxeTwoHandParryEffectivenessDefault        = 1.1
SettingsConstants.baseHandToHandParryEffectivenessDefault        = 1
SettingsConstants.baseShieldParryEffectivenessDefault            = 1
SettingsConstants.baseGuardFatigueDrainDefault                   = 3
SettingsConstants.quickModeDefault                               = false
SettingsConstants.scalingGuardFatigueDrainDefault                = 4
SettingsConstants.debugMessagesDefault                           = false
SettingsConstants.debugLogsDefault                               = false
SettingsConstants.playMissAnimationsDefault                      = true
SettingsConstants.allowArrowDeflectDefault                       = true
SettingsConstants.triggerSensitivityDefault                      = 40
SettingsConstants.fatigueEffectsFormulaDefault                   = SettingsConstants.fatigueEffectsFormulaValues
    [SettingsConstants.fatigue_effects.full]
SettingsConstants.controllerTriggerDefault                       = SettingsConstants.controllerTriggerValues
    [SettingsConstants.controller_triggers.lt]
SettingsConstants.allowParryCreaturesDefault                     = SettingsConstants.allowParryCreaturesValues
    [SettingsConstants.parry_creatures.shields]


--read Setting with fallback
SettingsConstants.readSetting = function(settings, key)
    local value = settings:get(key)
    if value == nil then
        value = SettingsConstants[keyToDefault(key)]
    end
    return value
end

SettingsConstants.keyToLocal = function(key)
    local localName = key:gsub(modInfo.modKey .. "_", "")
    return localName:gsub("Key", "")
end

SettingsConstants.eSettingsKeyToType = {
    [SettingsConstants.baseShortBladeOneHandParryEffectivenessKey] = "shortbladeonehand",
    [SettingsConstants.baseLongBladeOneHandParryEffectivenessKey] = "longbladeonehand",
    [SettingsConstants.baseLongBladeTwoHandParryEffectivenessKey] = "longbladetwohand",
    [SettingsConstants.baseBluntOneHandParryEffectivenessKey] = "bluntonehand",
    [SettingsConstants.baseBluntTwoCloseParryEffectivenessKey] = "blunttwoclose",
    [SettingsConstants.baseBluntTwoWideParryEffectivenessKey] = "blunttwowide",
    [SettingsConstants.baseSpearTwoWideParryEffectivenessKey] = "speartwowide",
    [SettingsConstants.baseAxeOneHandParryEffectivenessKey] = "axeonehand",
    [SettingsConstants.baseAxeTwoHandParryEffectivenessKey] = "axetwohand",
    [SettingsConstants.baseHandToHandParryEffectivenessKey] = "handtohand",
    [SettingsConstants.baseShieldParryEffectivenessKey] = "shield",
}


--#endregion


--#endregion
--#endregion

return SettingsConstants
