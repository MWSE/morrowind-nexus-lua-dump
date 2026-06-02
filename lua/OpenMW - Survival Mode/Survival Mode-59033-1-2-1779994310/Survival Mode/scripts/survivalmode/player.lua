local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local playerConfig = require('scripts.survivalmode.player.playerConfig')
local playerUtils = require('scripts.survivalmode.player.playerUtils')
local playerSettingsModule = require('scripts.survivalmode.player.playerSettings')
local playerRegistryLoaderModule = require('scripts.survivalmode.player.playerRegistryLoader')
local playerStageHelpersModule = require('scripts.survivalmode.player.playerStageHelpers')
local skillEvolutionPatchModule = require('scripts.survivalmode.player.skillEvolutionPatch')
local playerStateModule = require('scripts.survivalmode.player.playerState')
local playerPersistenceModule = require('scripts.survivalmode.player.playerPersistence')
local playerHudModule = require('scripts.survivalmode.player.playerHud')
local abilitiesModule = require('scripts.survivalmode.abilities')
hungerContentModule = require('scripts.survivalmode.core.hungerContent')
hungerSystemModule = require('scripts.survivalmode.core.hungerSystem')
thirstContentModule = require('scripts.survivalmode.core.thirstContent')
thirstSystemModule = require('scripts.survivalmode.core.thirstSystem')
sleepContentModule = require('scripts.survivalmode.core.sleepContent')
sleepSystemModule = require('scripts.survivalmode.core.sleepSystem')
temperatureContentModule = require('scripts.survivalmode.temperature.temperatureContent')
temperaturePlayerRuntimeModule = require('scripts.survivalmode.temperature.temperaturePlayerRuntime')
temperatureModifierModule = require('scripts.survivalmode.temperature.temperatureModifier')
tempDebugOverlayModule = require('scripts.survivalmode.temperature.tempDebugOverlay')
temperatureDebugRuntimeModule = require('scripts.survivalmode.temperature.temperatureDebugRuntime')
temperatureBootstrapModule = require('scripts.survivalmode.temperature.temperature_bootstrap')
local temperatureBalanceConfig = require('scripts.survivalmode.temperature.temperatureBalanceConfig')
local wetnessSystem = require('scripts.survivalmode.temperature.wetnessSystem')
local temperature = temperatureBootstrapModule

HUNGER_MAX = hungerContentModule.constants.max
HUNGER_TICK_SECONDS = hungerContentModule.constants.tickSeconds
HUNGER_STEP_DEFAULT = hungerContentModule.constants.stepDefault
HUNGER_STEP_ORC = hungerContentModule.constants.stepOrc
HUNGER_FLASH_DURATION_SECONDS = hungerContentModule.constants.flashDurationSeconds
HUNGER_FLASH_FADE_IN_RATIO = hungerContentModule.constants.flashFadeInRatio
HUNGER_RESTORE_PER_WEIGHT = hungerContentModule.constants.restorePerWeight
HUNGER_RESTORE_SOFT_CAP = hungerContentModule.constants.restoreSoftCap
HUNGER_RESTORE_OVER_CAP_EFFICIENCY = hungerContentModule.constants.restoreOverCapEfficiency
local HUNGER_INITIAL_VALUE_FALLBACK = hungerContentModule.constants.initialValueFallback

THIRST_MAX = thirstContentModule.constants.max
THIRST_TICK_SECONDS = thirstContentModule.constants.tickSeconds
THIRST_STEP_DEFAULT = thirstContentModule.constants.stepDefault
THIRST_STEP_ORC = thirstContentModule.constants.stepOrc
THIRST_FLASH_DURATION_SECONDS = thirstContentModule.constants.flashDurationSeconds
THIRST_FLASH_FADE_IN_RATIO = thirstContentModule.constants.flashFadeInRatio
local THIRST_INITIAL_VALUE_FALLBACK = thirstContentModule.constants.initialValueFallback

local SLEEP_MAX = sleepContentModule.constants.max
local SLEEP_TICK_SECONDS = sleepContentModule.constants.tickSeconds
local SLEEP_STEP_DEFAULT = sleepContentModule.constants.stepDefault
local SLEEP_ACCUMULATION_PER_HOUR = sleepContentModule.constants.accumulationPerHour
local SLEEP_RECOVERY_PER_HOUR_BED = sleepContentModule.constants.recoveryPerHourBed
local SLEEP_RECOVERY_PER_HOUR_MENU = sleepContentModule.constants.recoveryPerHourMenu
local SLEEP_TRAVEL_MULTIPLIER = sleepContentModule.constants.travelMultiplier
local REST_SLEEP_NEEDS_MULTIPLIER = sleepContentModule.constants.restSleepNeedsMultiplier
local SLEEP_INITIAL_VALUE_FALLBACK = sleepContentModule.constants.initialValueFallback
local NEEDS_DEBUFF_SPELL_ID_PREFIX = 'sn_needs_'
local NEEDS_DYNAMIC_SPELL_REQUEST_EVENT = 'SurvivalNeeds_RequestDynamicDebuffSpell'
local NEEDS_DYNAMIC_SPELL_READY_EVENT = 'SurvivalNeeds_DynamicDebuffSpellReady'
local NEEDS_DEBUG_LOGGING_EVENT = 'SurvivalNeeds_SetDebugLoggingEnabled'
local HBFS_DISABLE_CONJURATION_DRAIN_SETTING_KEY = 'hbfsDisableConjurationDrain'
local TEMPERATURE_DEBUG = temperatureContentModule.createDebugConfig({
    util = util,
    temperatureBalanceConfig = temperatureBalanceConfig,
    temperature = temperature,
})
local WELL_FED_STAGE_ID = hungerContentModule.constants.wellFedStageId
local WELL_FED_WEAPON_SKILL_GAIN_BONUS_PCT = hungerContentModule.constants.wellFedWeaponSkillGainBonusPct
local WELL_LEARNING_EFFECT_ID = hungerContentModule.constants.wellLearningEffectId
local WELL_FED_LEARNING_SPELL_NAME = hungerContentModule.buildWellFedLearningSpellName(core)
local WELL_FED_LEARNING_FALLBACK_EFFECT_ID = 'restorefatigue'
local WELL_FED_LEARNING_EFFECT_MAGNITUDE = hungerContentModule.constants.wellFedLearningEffectMagnitude
local WELL_HYDRATED_STAGE_ID = thirstContentModule.constants.wellHydratedStageId
local WELL_HYDRATED_MAGIC_SKILL_GAIN_BONUS_PCT = thirstContentModule.constants.wellHydratedMagicSkillGainBonusPct
local WELL_HYDRATED_LEARNING_SPELL_NAME = thirstContentModule.buildWellHydratedLearningSpellName(core)
local WELL_HYDRATED_LEARNING_EFFECT_MAGNITUDE = thirstContentModule.constants.wellHydratedLearningEffectMagnitude
local WELL_RESTED_STAGE_ID = sleepContentModule.constants.wellRestedStageId
local WELL_RESTED_ARMOR_SKILL_GAIN_BONUS_PCT = sleepContentModule.constants.wellRestedArmorSkillGainBonusPct
local WELL_RESTED_STAMINIA_REGEN_BONUS_PCT = sleepContentModule.constants.wellRestedStaminiaRegenBonusPct
local WELL_RESTED_LEARNING_SPELL_NAME = sleepContentModule.buildWellRestedLearningSpellName(core)
local WELL_RESTED_LEARNING_EFFECT_MAGNITUDE = sleepContentModule.constants.wellRestedLearningEffectMagnitude
local WELL_RESTED_STAMINA_REGEN_DISPLAY_EFFECT_ID = sleepContentModule.constants.wellRestedStaminaRegenDisplayEffectId
local SKILL_DAMAGE_SCAN_INTERVAL_SECONDS = 1.0

local WEAPON_SKILL_IDS = hungerContentModule.constants.weaponSkillIds

local MAGIC_SKILL_IDS = {
    'destruction',
    'restoration',
    'alteration',
    'illusion',
    'conjuration',
    'mysticism',
}

local ARMOR_SKILL_IDS = {
    'lightarmor',
    'mediumarmor',
    'heavyarmor',
}

local MAGIC_SKILL_IDS_NO_CONJURATION = {
    'destruction',
    'restoration',
    'alteration',
    'illusion',
    'mysticism',
}

local ARMOR_AND_UNARMORED_SKILL_IDS = {
    'lightarmor',
    'mediumarmor',
    'heavyarmor',
    'unarmored',
}

hungerContentApi = hungerContentModule.create({
    core = core,
    wellFedWeaponSkillGainBonusPct = WELL_FED_WEAPON_SKILL_GAIN_BONUS_PCT,
    wellFedLearningSpellName = WELL_FED_LEARNING_SPELL_NAME,
    wellLearningEffectId = WELL_LEARNING_EFFECT_ID,
    wellFedLearningEffectMagnitude = WELL_FED_LEARNING_EFFECT_MAGNITUDE,
})

HUNGER_STAGES = hungerContentApi.stages

thirstContentApi = thirstContentModule.create({
    core = core,
    wellHydratedMagicSkillGainBonusPct = WELL_HYDRATED_MAGIC_SKILL_GAIN_BONUS_PCT,
    wellHydratedLearningSpellName = WELL_HYDRATED_LEARNING_SPELL_NAME,
    wellLearningEffectId = WELL_LEARNING_EFFECT_ID,
    wellHydratedLearningEffectMagnitude = WELL_HYDRATED_LEARNING_EFFECT_MAGNITUDE,
})

THIRST_STAGES = thirstContentApi.stages

sleepContentApi = sleepContentModule.create({
    core = core,
    wellRestedArmorSkillGainBonusPct = WELL_RESTED_ARMOR_SKILL_GAIN_BONUS_PCT,
    wellRestedStaminiaRegenBonusPct = WELL_RESTED_STAMINIA_REGEN_BONUS_PCT,
    wellRestedLearningSpellName = WELL_RESTED_LEARNING_SPELL_NAME,
    wellLearningEffectId = WELL_LEARNING_EFFECT_ID,
    wellRestedLearningEffectMagnitude = WELL_RESTED_LEARNING_EFFECT_MAGNITUDE,
})

SLEEP_STAGES = sleepContentApi.stages

local hudConfig = playerConfig.createHudConfig({
    util = util,
    playerConfig = playerConfig,
    temperature = temperature,
    hungerFlashIconKeys = hungerContentModule.flashIconKeys,
    thirstFlashIconKeys = thirstContentModule.flashIconKeys,
})

HUNGER_STAGE_MESSAGES = hungerContentApi.stageMessages

THIRST_STAGE_MESSAGES = thirstContentApi.stageMessages

local SLEEP_STAGE_MESSAGES = sleepContentApi.stageMessages

local hudSettings = storage.playerSection('SettingsSurvivalNeedsHUD')
local settingsSections = {
    gameplay = storage.playerSection('SettingsSurvivalNeedsGameplay'),
    debug = storage.playerSection('SettingsSurvivalNeedsZZDebug'),
    legacyDebug = storage.playerSection('SettingsSurvivalNeedsDebug'),
}

TEMPERATURE_DEBUG.createTemperaturemultiplier = temperatureContentModule.createTemperaturemultiplier
TEMPERATURE_DEBUG.hydrateTemperaturemultiplier = temperatureContentModule.hydrateTemperaturemultiplier

local playerStateApi = playerStateModule.create({
    temperatureDebug = TEMPERATURE_DEBUG,
    temperatureBalanceConfig = temperatureBalanceConfig,
})

local state = playerStateApi.createInitialState()

local clamp = playerUtils.clamp
local round = playerUtils.round
local trim = playerUtils.trim
local normalizePath = playerUtils.normalizePath
local normalizeKey = playerUtils.normalizeKey
local tryGetEnumValue = playerUtils.tryGetEnumValue
local normalizeWeatherKey = playerUtils.normalizeWeatherKey


local function now()
    return core.getGameTime()
end

local settingsApi = playerSettingsModule.create({
    hudSettings = hudSettings,
    settingsSections = settingsSections,
    playerConfig = playerConfig,
    defaultHudPosition = hudConfig.defaultHudPosition,
    normalizeKey = normalizeKey,
    hbfsSettingKey = HBFS_DISABLE_CONJURATION_DRAIN_SETTING_KEY,
})

local getHudPosition = settingsApi.getHudPosition
local isHorizontal = settingsApi.isHorizontal
local isHudEnabled = settingsApi.isHudEnabled
local getIconSizeValue = settingsApi.getIconSizeValue
local getIconSpacingValue = settingsApi.getIconSpacingValue
local getHudOffsetX = settingsApi.getHudOffsetX
local getHudOffsetY = settingsApi.getHudOffsetY
local isRawValuesDebugEnabled = settingsApi.isRawValuesDebugEnabled

function TEMPERATURE_DEBUG.isOverlayEnabled()
    return settingsApi.isOverlayEnabled(TEMPERATURE_DEBUG.settingKey)
end

local areProgressBarsEnabled = settingsApi.areProgressBarsEnabled
local isNeutralImagesSettingEnabled = settingsApi.isNeutralImagesSettingEnabled
local isThickerIconFrameEnabled = settingsApi.isThickerIconFrameEnabled
local isTemperatureEffectOverlayEnabled = settingsApi.isTemperatureEffectOverlayEnabled
local areStageMessagesEnabled = settingsApi.areStageMessagesEnabled
local isHbfsDisableConjurationDrainEnabled = settingsApi.isHbfsDisableConjurationDrainEnabled
local isSeasonalTemperatureVariationsEnabled = settingsApi.isSeasonalTemperatureVariationsEnabled
local isTemperatureBasedHealthPenaltiesEnabled = settingsApi.isTemperatureBasedHealthPenaltiesEnabled

function isNeedSystemSettingEnabled(settingKey)
    return settingsApi.isNeedSystemSettingEnabled(settingKey)
end

function isHungerSystemEnabled()
    return settingsApi.isHungerSystemEnabled()
end

function isThirstSystemEnabled()
    return settingsApi.isThirstSystemEnabled()
end

function isSleepSystemEnabled()
    return settingsApi.isSleepSystemEnabled()
end

function isTemperatureSystemEnabled()
    return settingsApi.isTemperatureSystemEnabled()
end

local function getThirstMagicSkillIds()
    if isHbfsDisableConjurationDrainEnabled() then
        return MAGIC_SKILL_IDS_NO_CONJURATION
    end

    return MAGIC_SKILL_IDS
end

local getInitialNeedValue = function(stages, fallback)
    if type(stages) == 'table' and type(stages[2]) == 'table' and type(stages[2].min) == 'number' then
        return stages[2].min
    end
    return fallback
end

local playerHudControllerApi = playerHudModule.createController({
    state = state,
    ui = ui,
    clamp = clamp,
    normalizeKey = normalizeKey,
    trim = trim,
    iconPaths = hudConfig.iconPaths,
    iconFadeInSeconds = hudConfig.iconFadeInSeconds,
    iconFadeOutSeconds = hudConfig.iconFadeOutSeconds,
    hungerFlashDurationSeconds = HUNGER_FLASH_DURATION_SECONDS,
    hungerFlashFadeInRatio = HUNGER_FLASH_FADE_IN_RATIO,
    thirstFlashDurationSeconds = THIRST_FLASH_DURATION_SECONDS,
    thirstFlashFadeInRatio = THIRST_FLASH_FADE_IN_RATIO,
    wellRestedStageId = WELL_RESTED_STAGE_ID,
})
local ensureIconResources = playerHudControllerApi.ensureIconResources
local getNeedIcons = playerHudControllerApi.getNeedIcons
local syncNeedIconFadeState = playerHudControllerApi.syncNeedIconFadeState
local updateNeedFlashes = playerHudControllerApi.updateNeedFlashes
local updateNeedIconFades = playerHudControllerApi.updateNeedIconFades
local getNeedIconAlpha = playerHudControllerApi.getNeedIconAlpha
local getNeedLeavingIconAlpha = playerHudControllerApi.getNeedLeavingIconAlpha
local getHungerFlashAlpha = playerHudControllerApi.getHungerFlashAlpha
local getThirstFlashAlpha = playerHudControllerApi.getThirstFlashAlpha
local invalidateHud = playerHudControllerApi.invalidateHud
local resetNeedIconState = playerHudControllerApi.resetNeedIconState
local resetNeedFlashState = playerHudControllerApi.resetNeedFlashState
playerHudControllerApi.initializeState()

local registryLoaderApi = playerRegistryLoaderModule.create({
    markup = require('openmw.markup'),
    vfs = require('openmw.vfs'),
    playerConfig = playerConfig,
    state = state,
    normalizePath = normalizePath,
    normalizeKey = normalizeKey,
})
local loadFoodList = registryLoaderApi.loadFoodList
local loadThirstList = registryLoaderApi.loadThirstList

local stageHelpersApi = playerStageHelpersModule.create({
    state = state,
    hungerStages = HUNGER_STAGES,
    thirstStages = THIRST_STAGES,
    sleepStages = SLEEP_STAGES,
    normalizeKey = normalizeKey,
    wellFedStageId = WELL_FED_STAGE_ID,
    wellHydratedStageId = WELL_HYDRATED_STAGE_ID,
    wellRestedStageId = WELL_RESTED_STAGE_ID,
    wellFedWeaponSkillGainBonusPct = WELL_FED_WEAPON_SKILL_GAIN_BONUS_PCT,
    wellHydratedMagicSkillGainBonusPct = WELL_HYDRATED_MAGIC_SKILL_GAIN_BONUS_PCT,
    wellRestedArmorSkillGainBonusPct = WELL_RESTED_ARMOR_SKILL_GAIN_BONUS_PCT,
    wellRestedStaminiaRegenBonusPct = WELL_RESTED_STAMINIA_REGEN_BONUS_PCT,
    isHungerSystemEnabled = isHungerSystemEnabled,
    isThirstSystemEnabled = isThirstSystemEnabled,
    isSleepSystemEnabled = isSleepSystemEnabled,
    weaponSkillIds = WEAPON_SKILL_IDS,
    magicSkillIds = MAGIC_SKILL_IDS,
    armorSkillIds = ARMOR_SKILL_IDS,
})
local skillEvolutionPatchApi = skillEvolutionPatchModule.create({
    interfaces = I,
    stageHelpersApi = stageHelpersApi,
})

getInitialNeedValue = stageHelpersApi.getInitialNeedValue
local getHungerStage = stageHelpersApi.getHungerStage
local getThirstStage = stageHelpersApi.getThirstStage
local getSleepStage = stageHelpersApi.getSleepStage
local getActiveWellHydratedStage = stageHelpersApi.getActiveWellHydratedStage
local getWellRestedStaminiaRegenBonusPct = stageHelpersApi.getWellRestedStaminiaRegenBonusPct
hungerSystemApi = hungerSystemModule.create({
    state = state,
    clamp = clamp,
    isHungerSystemEnabled = isHungerSystemEnabled,
    isTemperatureSystemEnabled = isTemperatureSystemEnabled,
    temperature = temperature,
    hungerTickSeconds = HUNGER_TICK_SECONDS,
    hungerStepDefault = HUNGER_STEP_DEFAULT,
    hungerStepOrc = HUNGER_STEP_ORC,
    hungerMax = HUNGER_MAX,
    hungerFlashDuration = HUNGER_FLASH_DURATION_SECONDS,
})
thirstSystemApi = thirstSystemModule.create({
    state = state,
    clamp = clamp,
    isThirstSystemEnabled = isThirstSystemEnabled,
    isTemperatureSystemEnabled = isTemperatureSystemEnabled,
    temperature = temperature,
    thirstTickSeconds = THIRST_TICK_SECONDS,
    thirstStepDefault = THIRST_STEP_DEFAULT,
    thirstStepOrc = THIRST_STEP_ORC,
    thirstMax = THIRST_MAX,
    thirstFlashDuration = THIRST_FLASH_DURATION_SECONDS,
})
sleepSystemApi = sleepSystemModule.create({
    state = state,
    core = core,
    self = self,
    types = types,
    clamp = clamp,
    isSleepSystemEnabled = isSleepSystemEnabled,
    isHungerSystemEnabled = isHungerSystemEnabled,
    isThirstSystemEnabled = isThirstSystemEnabled,
    isTemperatureSystemEnabled = isTemperatureSystemEnabled,
    getHungerStage = getHungerStage,
    getThirstStage = getThirstStage,
    getWellRestedStaminiaRegenBonusPct = getWellRestedStaminiaRegenBonusPct,
    sleepTickSeconds = SLEEP_TICK_SECONDS,
    sleepMax = SLEEP_MAX,
    sleepStepDefault = SLEEP_STEP_DEFAULT,
    sleepAccumulationPerHour = SLEEP_ACCUMULATION_PER_HOUR,
    sleepRecoveryPerHourMenu = SLEEP_RECOVERY_PER_HOUR_MENU,
    sleepRecoveryPerHourBed = SLEEP_RECOVERY_PER_HOUR_BED,
    temperature = temperature,
    restSleepNeedsMultiplier = REST_SLEEP_NEEDS_MULTIPLIER,
    getInitialNeedValue = getInitialNeedValue,
    sleepStages = SLEEP_STAGES,
})

local runtimeInitApi = playerStateModule.createRuntimeInit({
    state = state,
    now = now,
    hungerSystemApi = hungerSystemApi,
    thirstSystemApi = thirstSystemApi,
    getInitialNeedValue = getInitialNeedValue,
    hungerStages = HUNGER_STAGES,
    thirstStages = THIRST_STAGES,
    sleepStages = SLEEP_STAGES,
    hungerInitialValueFallback = HUNGER_INITIAL_VALUE_FALLBACK,
    thirstInitialValueFallback = THIRST_INITIAL_VALUE_FALLBACK,
    sleepInitialValueFallback = SLEEP_INITIAL_VALUE_FALLBACK,
    clamp = clamp,
    sleepMax = SLEEP_MAX,
    self = self,
    types = types,
})
local ensureInitialized = runtimeInitApi.ensureInitialized

temperatureModifierModule.create({
    core = core,
    self = self,
    types = types,
    temperature = temperature,
    temperatureBalanceConfig = temperatureBalanceConfig,
    temperatureDebug = TEMPERATURE_DEBUG,
    state = state,
    wetnessSystem = wetnessSystem,
    isTemperatureSystemEnabled = isTemperatureSystemEnabled,
    isSeasonalTemperatureVariationsEnabled = isSeasonalTemperatureVariationsEnabled,
    getActiveWellHydratedStage = getActiveWellHydratedStage,
    clamp = clamp,
    trim = trim,
    normalizeKey = normalizeKey,
    normalizeWeatherKey = normalizeWeatherKey,
    tryGetEnumValue = tryGetEnumValue,
})

tempDebugOverlayModule.create({
    temperatureDebug = TEMPERATURE_DEBUG,
    temperature = temperature,
    state = state,
    normalizeKey = normalizeKey,
    trim = trim,
    isSeasonalTemperatureVariationsEnabled = isSeasonalTemperatureVariationsEnabled,
})

local function advanceHunger(currentTime)
    return hungerSystemApi.advanceHunger(currentTime)
end

local function advanceHungerByElapsed(elapsedSeconds, multiplier)
    return hungerSystemApi.advanceHungerByElapsed(elapsedSeconds, multiplier)
end

TEMPERATURE_DEBUG.getTemperatureHealthDrainProfile = function(temperatureValue, temperatureStage)
    return temperatureContentModule.getTemperatureHealthDrainProfile(temperatureValue, temperatureStage, {
        clamp = clamp,
        temperature = temperature,
    })
end

function TEMPERATURE_DEBUG.getTemperatureHealthLossPct(temperatureValue, temperatureStage)
    return temperatureContentModule.getTemperatureHealthLossPct(temperatureValue, temperatureStage, {
        clamp = clamp,
        temperature = temperature,
    })
end

local function advanceThirst(currentTime)
    return thirstSystemApi.advanceThirst(currentTime)
end

local function advanceThirstByElapsed(elapsedSeconds, multiplier)
    return thirstSystemApi.advanceThirstByElapsed(elapsedSeconds, multiplier)
end

local function advanceSleep(currentTime)
    return sleepSystemApi.advanceSleep(currentTime)
end

local function getFatigueMaxValue(fatigueStat)
    if fatigueStat == nil then
        return 0
    end

    local baseValue = tonumber(fatigueStat.base) or 0
    local modifierValue = tonumber(fatigueStat.modifier) or 0
    return math.max(0, baseValue + modifierValue)
end

local function applyWellRestedStaminiaRegeneration(dt)
    return sleepSystemApi.applyWellRestedStaminiaRegeneration(dt)
end

state.applyTemperatureHealthDrain = function(temperatureStage, elapsedSeconds, ignorePause)
    return temperatureRuntimeApi.applyHealthDrain(temperatureStage, elapsedSeconds, ignorePause)
end

local abilitiesApi = abilitiesModule.create({
    core = core,
    self = self,
    types = types,
    state = state,
    now = now,
    round = round,
    trim = trim,
    normalizeKey = normalizeKey,
    hungerContentModule = hungerContentModule,
    thirstContentModule = thirstContentModule,
    temperatureContentModule = temperatureContentModule,
    temperature = temperature,
    temperatureDebug = TEMPERATURE_DEBUG,
    isTemperatureSystemEnabled = isTemperatureSystemEnabled,
    isTemperatureBasedHealthPenaltiesEnabled = isTemperatureBasedHealthPenaltiesEnabled,
    isHbfsDisableConjurationDrainEnabled = isHbfsDisableConjurationDrainEnabled,
    getThirstMagicSkillIds = getThirstMagicSkillIds,
    wellFedStageId = WELL_FED_STAGE_ID,
    wellHydratedStageId = WELL_HYDRATED_STAGE_ID,
    wellRestedStageId = WELL_RESTED_STAGE_ID,
    wellFedLearningFallbackEffectId = WELL_FED_LEARNING_FALLBACK_EFFECT_ID,
    wellRestedArmorSkillGainBonusPct = WELL_RESTED_ARMOR_SKILL_GAIN_BONUS_PCT,
    wellRestedStaminiaRegenBonusPct = WELL_RESTED_STAMINIA_REGEN_BONUS_PCT,
    wellRestedStaminaRegenDisplayEffectId = WELL_RESTED_STAMINA_REGEN_DISPLAY_EFFECT_ID,
    weaponSkillIds = WEAPON_SKILL_IDS,
    armorAndUnarmoredSkillIds = ARMOR_AND_UNARMORED_SKILL_IDS,
    hungerStages = HUNGER_STAGES,
    thirstStages = THIRST_STAGES,
    sleepStages = SLEEP_STAGES,
    needsDebuffSpellIdPrefix = NEEDS_DEBUFF_SPELL_ID_PREFIX,
    needsDynamicSpellRequestEvent = NEEDS_DYNAMIC_SPELL_REQUEST_EVENT,
})
local clearNeedDynamicCategories = abilitiesApi.clearNeedDynamicCategories
local processDebuffConfigChanges = abilitiesApi.processDebuffConfigChanges
local syncNeedsDebuffSpells = abilitiesApi.syncNeedsDebuffSpells
local onDynamicDebuffSpellReady = abilitiesApi.onDynamicDebuffSpellReady

function clearHungerSystemState(currentTime)
    hungerSystemApi.clearRuntimeState(currentTime)
    resetNeedFlashState('hunger')
    state.lastHungerStageId = nil
    resetNeedIconState('hunger')
    clearNeedDynamicCategories({ 'hunger_skill', 'hunger_misc', 'hunger_learning' })
end

function clearThirstSystemState(currentTime)
    thirstSystemApi.clearRuntimeState(currentTime)
    resetNeedFlashState('thirst')
    state.lastThirstStageId = nil
    resetNeedIconState('thirst')
    clearNeedDynamicCategories({ 'thirst_skill', 'thirst_misc', 'thirst_learning' })
end

temperatureRuntimeApi = temperaturePlayerRuntimeModule.create({
    state = state,
    core = core,
    self = self,
    types = types,
    now = now,
    trim = trim,
    clamp = clamp,
    normalizeKey = normalizeKey,
    temperature = temperature,
    temperatureDebug = TEMPERATURE_DEBUG,
    temperatureBalanceConfig = temperatureBalanceConfig,
    wetnessSystem = wetnessSystem,
    isTemperatureSystemEnabled = isTemperatureSystemEnabled,
    isTemperatureBasedHealthPenaltiesEnabled = isTemperatureBasedHealthPenaltiesEnabled,
    getDynamicMaxValue = getFatigueMaxValue,
    clearNeedDynamicCategories = clearNeedDynamicCategories,
    resetNeedIconState = resetNeedIconState,
})

local temperatureDebugRuntimeApi = temperatureDebugRuntimeModule.create({
    state = state,
    core = core,
    temperature = temperature,
    temperatureDebug = TEMPERATURE_DEBUG,
    temperatureRuntimeApi = temperatureRuntimeApi,
    isOverlayEnabled = TEMPERATURE_DEBUG.isOverlayEnabled,
    debugLoggingEventName = NEEDS_DEBUG_LOGGING_EVENT,
})
temperatureDebugRuntimeApi.bindRuntimeBridge()
local syncDebugLoggingState = temperatureDebugRuntimeApi.syncDebugLoggingState

function resetTemperatureRuntimeState()
    return temperatureRuntimeApi.resetRuntimeState()
end

function clearSleepSystemState(currentTime)
    state.sleepTimeRemainder = 0
    state.sleepLastUpdateTime = currentTime
    state.sleepWellRestedBonusMultiplier = 1.0
    state.lastSleepStageId = nil
    resetNeedIconState('sleep')
    clearNeedDynamicCategories({ 'sleep_skill', 'sleep_misc', 'sleep_learning' })
end

function clearTemperatureSystemState(currentTime)
    temperatureRuntimeApi.clearSystemState(currentTime)
    require('scripts.survivalmode.temperature.warmthAbility').reset(state.knownNeedsDynamicSpellIds)
    require('scripts.survivalmode.temperature.temperatureScreenEffect').reset()
    require('scripts.survivalmode.temperature.wetnessHud').reset()
end

function syncNeedSystemToggleState(currentTime)
    local hungerEnabled = isHungerSystemEnabled()
    local thirstEnabled = isThirstSystemEnabled()
    local sleepEnabled = isSleepSystemEnabled()
    local temperatureEnabled = isTemperatureSystemEnabled()
    local changed = false

    local previousHungerEnabled = state.lastHungerSystemEnabled
    if previousHungerEnabled == nil then
        previousHungerEnabled = true
    end
    if previousHungerEnabled ~= hungerEnabled then
        changed = true
        if hungerEnabled then
            hungerSystemApi.clearRuntimeState(currentTime)
            state.lastHungerStageId = nil
        else
            clearHungerSystemState(currentTime)
        end
    end
    state.lastHungerSystemEnabled = hungerEnabled

    local previousThirstEnabled = state.lastThirstSystemEnabled
    if previousThirstEnabled == nil then
        previousThirstEnabled = true
    end
    if previousThirstEnabled ~= thirstEnabled then
        changed = true
        if thirstEnabled then
            thirstSystemApi.clearRuntimeState(currentTime)
            state.lastThirstStageId = nil
        else
            clearThirstSystemState(currentTime)
        end
    end
    state.lastThirstSystemEnabled = thirstEnabled

    local previousSleepEnabled = state.lastSleepSystemEnabled
    if previousSleepEnabled == nil then
        previousSleepEnabled = true
    end
    if previousSleepEnabled ~= sleepEnabled then
        changed = true
        if sleepEnabled then
            state.sleepTimeRemainder = 0
            state.sleepLastUpdateTime = currentTime
            state.lastSleepStageId = nil
        else
            clearSleepSystemState(currentTime)
        end
    end
    state.lastSleepSystemEnabled = sleepEnabled

    local previousTemperatureEnabled = state.lastTemperatureSystemEnabled
    if previousTemperatureEnabled == nil then
        previousTemperatureEnabled = true
    end
    if previousTemperatureEnabled ~= temperatureEnabled then
        changed = true
        if temperatureEnabled then
            state.temperatureLastUpdateTime = currentTime
            temperatureRuntimeApi.resetRuntimeState()
            state.lastTemperatureStageId = nil
        else
            clearTemperatureSystemState(currentTime)
        end
    end
    state.lastTemperatureSystemEnabled = temperatureEnabled

    if changed then
        invalidateHud()
    end

    return hungerEnabled, thirstEnabled, sleepEnabled, temperatureEnabled
end

local function getStageProgressNormalized(value, stage, useEffectiveTemperature)
    if stage == nil then
        return 0
    end

    local stageMin = tonumber(stage.min) or 0
    local stageMax = tonumber(stage.max) or stageMin
    local range = stageMax - stageMin
    if range <= 0 then
        return 1
    end

    local currentValue = tonumber(value) or stageMin
    if useEffectiveTemperature == true
        and temperature ~= nil
        and type(temperature.system) == 'table'
        and type(temperature.system.getEffectiveStageTemperature) == 'function' then
        currentValue = temperature.system.getEffectiveStageTemperature(currentValue)
    end
    return clamp((currentValue - stageMin) / range, 0, 1)
end

local playerHudApi = playerHudModule.create({
    state = state,
    ui = ui,
    util = util,
    temperatureDebug = TEMPERATURE_DEBUG,
    hudSettings = hudSettings,
    now = now,
    round = round,
    clamp = clamp,
    normalizeKey = normalizeKey,
    ensureIconResources = ensureIconResources,
    isHorizontal = isHorizontal,
    isHudEnabled = isHudEnabled,
    isRawValuesDebugEnabled = isRawValuesDebugEnabled,
    areProgressBarsEnabled = areProgressBarsEnabled,
    isNeutralImagesSettingEnabled = isNeutralImagesSettingEnabled,
    isThickerIconFrameEnabled = isThickerIconFrameEnabled,
    isHungerSystemEnabled = isHungerSystemEnabled,
    isThirstSystemEnabled = isThirstSystemEnabled,
    isSleepSystemEnabled = isSleepSystemEnabled,
    isTemperatureSystemEnabled = isTemperatureSystemEnabled,
    getNeedIcons = getNeedIcons,
    syncNeedIconFadeState = syncNeedIconFadeState,
    getHudPosition = getHudPosition,
    getHudOffsetX = getHudOffsetX,
    getHudOffsetY = getHudOffsetY,
    getIconSizeValue = getIconSizeValue,
    getIconSpacingValue = getIconSpacingValue,
    getHungerFlashAlpha = getHungerFlashAlpha,
    getThirstFlashAlpha = getThirstFlashAlpha,
    getNeedIconAlpha = getNeedIconAlpha,
    getNeedLeavingIconAlpha = getNeedLeavingIconAlpha,
    getStageProgressNormalized = getStageProgressNormalized,
    needNeutralIconKeys = hudConfig.needNeutralIconKeys,
    needNeutralFlashSourceIconKeys = hudConfig.needNeutralFlashSourceIconKeys,
    hungerFlashIconKeys = hudConfig.hungerFlashIconKeys,
    thirstFlashIconKeys = hudConfig.thirstFlashIconKeys,
    minNeedBarHeight = hudConfig.minNeedBarHeight,
    needBarHeightRatio = hudConfig.needBarHeightRatio,
    needBarOffsetPixels = hudConfig.needBarOffsetPixels,
    rawValueTextSize = hudConfig.rawValueTextSize,
    rawValueTextHeight = hudConfig.rawValueTextHeight,
    hudDynamicRebuildIntervalSeconds = hudConfig.hudDynamicRebuildIntervalSeconds,
    hudPadding = hudConfig.hudPadding,
})
local refreshHud = playerHudApi.refreshHud

local consumptionApi = playerRegistryLoaderModule.createConsumption({
    types = types,
    state = state,
    normalizeKey = normalizeKey,
    loadFoodList = loadFoodList,
    loadThirstList = loadThirstList,
    hungerRestorePerWeight = HUNGER_RESTORE_PER_WEIGHT,
    hungerRestoreSoftCap = HUNGER_RESTORE_SOFT_CAP,
    hungerRestoreOverCapEfficiency = HUNGER_RESTORE_OVER_CAP_EFFICIENCY,
})
local getFoodHungerReduction = consumptionApi.getFoodHungerReduction
local getThirstDrinkRestoreAmount = consumptionApi.getThirstDrinkRestoreAmount

local function notifyStageTransition(previousStageId, currentStageId, stageMessages)
    if not areStageMessagesEnabled() then
        return
    end

    if previousStageId == nil or previousStageId == currentStageId then
        return
    end

    local message = stageMessages[currentStageId]
    if type(message) ~= 'string' or message == '' then
        return
    end

    ui.showMessage(message)
end

local function notifyStageEntryMessages(hungerStage, thirstStage, sleepStage, temperatureStage)
    local currentHungerStageId = hungerStage ~= nil and hungerStage.id or nil
    local currentThirstStageId = thirstStage ~= nil and thirstStage.id or nil
    local currentSleepStageId = sleepStage ~= nil and sleepStage.id or nil
    local currentTemperatureStageId = temperatureStage ~= nil and temperatureStage.id or nil

    local restUiActive = state.restUiSession ~= nil and state.restUiSession.active == true
    if restUiActive then
        -- Don't emit or advance stage-message state while rest/wait UI is active.
        -- This makes messages reflect final post-menu values only.
        return
    end

    notifyStageTransition(state.lastHungerStageId, currentHungerStageId, HUNGER_STAGE_MESSAGES)
    notifyStageTransition(state.lastThirstStageId, currentThirstStageId, THIRST_STAGE_MESSAGES)
    notifyStageTransition(state.lastSleepStageId, currentSleepStageId, SLEEP_STAGE_MESSAGES)
    notifyStageTransition(state.lastTemperatureStageId, currentTemperatureStageId, temperature.system.STAGE_MESSAGES)

    state.lastHungerStageId = currentHungerStageId
    state.lastThirstStageId = currentThirstStageId
    state.lastSleepStageId = currentSleepStageId
    state.lastTemperatureStageId = currentTemperatureStageId
end

local DEBUFF_UPDATE_INTERVAL_SECONDS = 0.20
local SLUGGISH_UPDATE_JOB_ORDER = {
    'temperatureScreenEffect',
    'warmthAbility',
    'refreshHud',
}

local function ensureUpdateCadenceState()
    if type(state.debuffUpdateElapsedSeconds) ~= 'number' then
        state.debuffUpdateElapsedSeconds = 0
    end
    if type(state.sluggishUpdateJobIndex) ~= 'number' then
        state.sluggishUpdateJobIndex = 1
    end
    if state.sluggishUpdateJobIndex < 1 or state.sluggishUpdateJobIndex > #SLUGGISH_UPDATE_JOB_ORDER then
        state.sluggishUpdateJobIndex = 1
    end
end

local function shouldRunCadence(elapsedSeconds, intervalSeconds, force)
    if force == true then
        return true, 0
    end
    if elapsedSeconds >= intervalSeconds then
        return true, elapsedSeconds % intervalSeconds
    end
    return false, elapsedSeconds
end

local function scanRestoreSkillAndSkillDamage(stepSeconds)
    local restoreSkillEffectActive = false

    if types.Actor.objectIsInstance(self) then
        local activeSpells = types.Actor.activeSpells(self)
        if type(activeSpells) ~= 'table' then
            activeSpells = {}
        end

        for _, activeSpell in pairs(activeSpells) do
            if type(activeSpell) == 'table' and type(activeSpell.effects) == 'table' then
                for _, effect in pairs(activeSpell.effects) do
                    if type(effect) == 'table' and normalizeKey(effect.id) == 'restoreskill' then
                        restoreSkillEffectActive = true
                        break
                    end
                end
            end

            if restoreSkillEffectActive then
                break
            end
        end
    end

    local sawSkillDamageReduction = false
    local shouldScanSkillDamage = true
    if stepSeconds > 0 then
        local elapsedSinceSkillDamageScan = tonumber(state.skillDamageScanElapsedSeconds) or 0
        elapsedSinceSkillDamageScan = elapsedSinceSkillDamageScan + stepSeconds
        if elapsedSinceSkillDamageScan < SKILL_DAMAGE_SCAN_INTERVAL_SECONDS then
            shouldScanSkillDamage = false
            state.skillDamageScanElapsedSeconds = elapsedSinceSkillDamageScan
        else
            state.skillDamageScanElapsedSeconds = elapsedSinceSkillDamageScan % SKILL_DAMAGE_SCAN_INTERVAL_SECONDS
        end
    else
        state.skillDamageScanElapsedSeconds = 0
    end

    if not types.NPC.objectIsInstance(self) then
        state.skillDamageSnapshotById = {}
    else
        if type(state.skillDamageSnapshotById) ~= 'table' then
            state.skillDamageSnapshotById = {}
        end

        if shouldScanSkillDamage then
            local nextSkillDamageSnapshot = {}
            local function scanSkillDamage(skillIds)
                if type(skillIds) ~= 'table' then
                    return
                end

                for _, skillId in ipairs(skillIds) do
                    if type(skillId) == 'string' and nextSkillDamageSnapshot[skillId] == nil then
                        local skillDamage = 0
                        local skillGetter = types.NPC.stats.skills[skillId]
                        if type(skillGetter) == 'function' then
                            local skillStat = skillGetter(self)
                            if skillStat ~= nil and type(skillStat.damage) == 'number' then
                                skillDamage = math.max(0, skillStat.damage)
                            end
                        end

                        local previousDamage = tonumber(state.skillDamageSnapshotById[skillId])
                        if previousDamage ~= nil and skillDamage < previousDamage then
                            sawSkillDamageReduction = true
                        end
                        nextSkillDamageSnapshot[skillId] = skillDamage
                    end
                end
            end

            scanSkillDamage(WEAPON_SKILL_IDS)
            scanSkillDamage(getThirstMagicSkillIds())
            scanSkillDamage(ARMOR_AND_UNARMORED_SKILL_IDS)
            scanSkillDamage({ 'block', 'sneak' })
            state.skillDamageSnapshotById = nextSkillDamageSnapshot
        end
    end

    return restoreSkillEffectActive, sawSkillDamageReduction
end

local function runDebuffUpdate(stepSeconds, hungerStage, thirstStage, sleepStage, temperatureStage)
    processDebuffConfigChanges()

    local restoreSkillEffectActive, sawSkillDamageReduction = scanRestoreSkillAndSkillDamage(stepSeconds)
    local restoreSkillBecameActive = restoreSkillEffectActive and state.restoreSkillEffectActive ~= true
    local restoreSkillEnded = not restoreSkillEffectActive and state.restoreSkillEffectActive == true
    state.restoreSkillEffectActive = restoreSkillEffectActive

    if restoreSkillBecameActive then
        abilitiesApi.clearSkillDynamicCategories()
    elseif restoreSkillEnded then
        abilitiesApi.resetSkillCategoryRequestState()
    elseif sawSkillDamageReduction then
        abilitiesApi.resetSkillCategoryRequestState()
    end

    syncNeedsDebuffSpells(hungerStage, thirstStage, sleepStage, temperatureStage, restoreSkillEffectActive)
end

local function runSluggishUpdateJob(jobName, dt, hungerStage, thirstStage, sleepStage, temperatureStage, temperatureSystemEnabled, temperatureModifierState)
    if jobName == 'temperatureScreenEffect' then
        local temperatureScreenEffect = require('scripts.survivalmode.temperature.temperatureScreenEffect')
        if temperatureSystemEnabled and isTemperatureEffectOverlayEnabled() then
            TEMPERATURE_DEBUG.runSystemSection('temperatureScreenEffect.sync', function()
                temperatureScreenEffect.sync(temperatureStage ~= nil and temperatureStage.id or nil, dt)
            end)
        else
            TEMPERATURE_DEBUG.runSystemSection('temperatureScreenEffect.reset', function()
                temperatureScreenEffect.reset()
            end)
        end
    elseif jobName == 'warmthAbility' then
        local warmthAbilitySetting = hudSettings:get('enableWarmthIndicatorAbility')
        if warmthAbilitySetting == nil then
            -- Legacy fallback in case an older config stored this key elsewhere.
            warmthAbilitySetting = settingsSections.gameplay:get('enableWarmthIndicatorAbility')
        end
        if temperatureSystemEnabled and warmthAbilitySetting == true then
            TEMPERATURE_DEBUG.runSystemSection('warmthAbility.sync', function()
                require('scripts.survivalmode.temperature.warmthAbility').sync({
                    regionCategory = temperatureModifierState.regionCategory,
                    usesInteriorBase = temperatureModifierState.usesInteriorBase == true,
                    targetTemperatureBeforeArmorBonus = temperatureModifierState.targetTemperatureBeforeArmorBonus,
                    campfireWarmModifier = temperatureModifierState.campfireWarmModifier,
                    campfireDominantSourceType = temperatureModifierState.campfireDominantSourceType,
                    weatherKey = temperatureModifierState.weatherKey,
                    equipmentSignature = temperatureModifierState.equipmentSignature,
                    knownSpellIds = state.knownNeedsDynamicSpellIds,
                })
            end)
        else
            TEMPERATURE_DEBUG.runSystemSection('warmthAbility.reset', function()
                require('scripts.survivalmode.temperature.warmthAbility').reset(state.knownNeedsDynamicSpellIds)
            end)
        end
    elseif jobName == 'refreshHud' then
        TEMPERATURE_DEBUG.runSystemSection('refreshHud', function()
            refreshHud(hungerStage, thirstStage, sleepStage, temperatureStage)
        end)
    end
end

local function updateSystems(dt)
    ensureInitialized()
    local stepSeconds = tonumber(dt)
    if stepSeconds == nil or stepSeconds < 0 then
        stepSeconds = 0
    end
    local currentTime = now()
    local hungerSystemEnabled, thirstSystemEnabled, sleepSystemEnabled, temperatureSystemEnabled =
        syncNeedSystemToggleState(currentTime)
    local restUiActive = state.restUiSession ~= nil and state.restUiSession.active == true
    local temperatureElapsed = 0
    local modifierElapsed = 0
    local temperatureElapsedForProcessing = 0
    local hasPendingImmediateTemperatureTick = false
    if temperatureSystemEnabled and type(wetnessSystem.hasPendingImmediateTemperatureTick) == 'function' then
        hasPendingImmediateTemperatureTick = wetnessSystem.hasPendingImmediateTemperatureTick()
    end
    if temperatureSystemEnabled and not restUiActive then
        temperatureElapsed = currentTime - state.temperatureLastUpdateTime
        if temperatureElapsed < 0 then
            temperatureElapsed = 0
        end

        local lastModifierUpdateTime = tonumber(state.temperatureModifierLastUpdateTime)
        if lastModifierUpdateTime == nil then
            state.temperatureModifierLastUpdateTime = currentTime
        else
            modifierElapsed = currentTime - lastModifierUpdateTime
            if modifierElapsed < 0 then
                modifierElapsed = 0
            end
            state.temperatureModifierLastUpdateTime = currentTime
        end
    else
        state.temperatureModifierLastUpdateTime = currentTime
    end
    local shouldRunTemperatureUpdate = false
    if temperatureSystemEnabled and not restUiActive then
        local updateInterval = math.max(0.05, tonumber(state.temperatureUpdateIntervalSeconds) or 0.5)
        shouldRunTemperatureUpdate = hasPendingImmediateTemperatureTick or temperatureElapsed >= updateInterval
        if shouldRunTemperatureUpdate then
            temperatureElapsedForProcessing = temperatureElapsed
        end
    end
    local temperatureModifierState = TEMPERATURE_DEBUG.refreshModifierState(modifierElapsed)
    updateNeedFlashes(dt)
    updateNeedIconFades(dt)
    local wetnessHud = require('scripts.survivalmode.temperature.wetnessHud')
    TEMPERATURE_DEBUG.runSystemSection('wetnessHud.update', function()
        wetnessHud.update(dt)
    end)

    if restUiActive then
        -- Rest/wait progression is applied on menu close from the tracked elapsed session time.
        -- Keep last-update anchors current so per-frame updates don't accumulate full-rate drain.
        state.hungerLastUpdateTime = currentTime
        state.thirstLastUpdateTime = currentTime
        state.sleepLastUpdateTime = currentTime
        state.temperatureLastUpdateTime = currentTime
    else
        advanceHunger(currentTime)
        advanceThirst(currentTime)
        advanceSleep(currentTime)
        if temperatureSystemEnabled and shouldRunTemperatureUpdate then
            state.temperatureLastUpdateTime = currentTime
            TEMPERATURE_DEBUG.advanceByElapsed(temperatureElapsedForProcessing, temperatureModifierState, false)
        elseif not temperatureSystemEnabled then
            state.temperatureLastUpdateTime = currentTime
        end
    end

    local hungerStage = hungerSystemEnabled and getHungerStage(state.hunger) or nil
    local thirstStage = thirstSystemEnabled and getThirstStage(state.thirst) or nil
    local sleepStage = sleepSystemEnabled and getSleepStage(state.sleep) or nil
    local temperatureStage = temperatureSystemEnabled and temperature.system.getStageByValue(state.temperature) or nil
    state.applyTemperatureHealthDrain(temperatureStage, temperatureElapsedForProcessing)
    notifyStageEntryMessages(hungerStage, thirstStage, sleepStage, temperatureStage)
    ensureUpdateCadenceState()
    local forceCadence = stepSeconds <= 0

    local debuffElapsed = (tonumber(state.debuffUpdateElapsedSeconds) or 0) + stepSeconds
    local runDebuffUpdateNow
    runDebuffUpdateNow, state.debuffUpdateElapsedSeconds = shouldRunCadence(
        debuffElapsed,
        DEBUFF_UPDATE_INTERVAL_SECONDS,
        forceCadence
    )
    if runDebuffUpdateNow then
        runDebuffUpdate(stepSeconds, hungerStage, thirstStage, sleepStage, temperatureStage)
    end

    if forceCadence then
        for _, jobName in ipairs(SLUGGISH_UPDATE_JOB_ORDER) do
            runSluggishUpdateJob(
                jobName,
                dt,
                hungerStage,
                thirstStage,
                sleepStage,
                temperatureStage,
                temperatureSystemEnabled,
                temperatureModifierState
            )
        end
        state.sluggishUpdateJobIndex = 1
    else
        local jobName = SLUGGISH_UPDATE_JOB_ORDER[state.sluggishUpdateJobIndex]
        if type(jobName) ~= 'string' or jobName == '' then
            jobName = SLUGGISH_UPDATE_JOB_ORDER[1]
            state.sluggishUpdateJobIndex = 1
        end

        runSluggishUpdateJob(
            jobName,
            dt,
            hungerStage,
            thirstStage,
            sleepStage,
            temperatureStage,
            temperatureSystemEnabled,
            temperatureModifierState
        )
        state.sluggishUpdateJobIndex = state.sluggishUpdateJobIndex + 1
        if state.sluggishUpdateJobIndex > #SLUGGISH_UPDATE_JOB_ORDER then
            state.sluggishUpdateJobIndex = 1
        end
    end
end

local persistenceApi = playerPersistenceModule.create({
    state = state,
    now = now,
    clamp = clamp,
    trim = trim,
    getInitialNeedValue = getInitialNeedValue,
    hungerSystemApi = hungerSystemApi,
    thirstSystemApi = thirstSystemApi,
    temperatureRuntimeApi = temperatureRuntimeApi,
    playerStateApi = playerStateApi,
    playerHudControllerApi = playerHudControllerApi,
    wetnessSystem = wetnessSystem,
    abilitiesApi = abilitiesApi,
    syncDebugLoggingState = syncDebugLoggingState,
    updateSystems = updateSystems,
    invalidateHud = invalidateHud,
    resetWarmthAbility = function(knownNeedsDynamicSpellIds)
        require('scripts.survivalmode.temperature.warmthAbility').reset(knownNeedsDynamicSpellIds)
    end,
    resetWetnessHud = function()
        require('scripts.survivalmode.temperature.wetnessHud').reset()
    end,
    resetTemperatureScreenEffect = function()
        require('scripts.survivalmode.temperature.temperatureScreenEffect').reset()
    end,
    hungerStages = HUNGER_STAGES,
    thirstStages = THIRST_STAGES,
    sleepStages = SLEEP_STAGES,
    sleepMax = SLEEP_MAX,
    hungerInitialValueFallback = HUNGER_INITIAL_VALUE_FALLBACK,
    thirstInitialValueFallback = THIRST_INITIAL_VALUE_FALLBACK,
    sleepInitialValueFallback = SLEEP_INITIAL_VALUE_FALLBACK,
})

sleepSystemApi.setRuntimeDeps({
    ui = ui,
    interfaces = I,
    now = now,
    sleepTravelMultiplier = SLEEP_TRAVEL_MULTIPLIER,
    advanceHungerByElapsed = advanceHungerByElapsed,
    advanceThirstByElapsed = advanceThirstByElapsed,
    updateSystems = updateSystems,
    getInitialNeedValue = getInitialNeedValue,
    sleepStages = SLEEP_STAGES,
    getSleepWellRestedBonusMultiplierOnSleep = stageHelpersApi.getSleepWellRestedBonusMultiplierOnSleep,
    isCurrentSleepWellRestedBonusEligible = function()
        return TEMPERATURE_DEBUG.isCurrentSleepWellRestedBonusEligible()
    end,
    temperatureDebug = TEMPERATURE_DEBUG,
    sendGlobalEvent = core.sendGlobalEvent,
    invalidateHud = invalidateHud,
    markSkipNextRegionTransitionDelay = function()
        return temperatureRuntimeApi.markSkipNextRegionTransitionDelay()
    end,
    applyTravelTemperatureCatchup = function(elapsed)
        return temperatureRuntimeApi.applyTravelTemperatureCatchup(elapsed)
    end,
})

local didLogSkillGainRegistrationWarning = false
local didLogSkillEvolutionPatchState = false

local function ensureSkillGainHandlerRegistered()
    local isRegistered, registrationBackend = skillEvolutionPatchApi.ensureRegistered()
    if isRegistered then
        if not didLogSkillEvolutionPatchState then
            didLogSkillEvolutionPatchState = true
            if registrationBackend == 'SkillEvolution' then
                print('[SurvivalMode] Skill Evolution Patch Enabled')
            else
                print('[SurvivalMode] Skill Evolution Patch Disabled')
            end
        end
        return true
    end

    if registrationBackend == 'pending_skill_evolution' then
        return false
    end

    if not didLogSkillEvolutionPatchState then
        didLogSkillEvolutionPatchState = true
        print('[SurvivalMode] Skill Evolution Patch Disabled')
    end

    if didLogSkillGainRegistrationWarning then
        return false
    end

    didLogSkillGainRegistrationWarning = true
    return false
end

local function onInit()
    ensureInitialized()
    ensureSkillGainHandlerRegistered()
    abilitiesApi.resetLearningAndTemperatureCategories()
    temperatureRuntimeApi.resetCellInfoState()
    require('scripts.survivalmode.temperature.warmthAbility').reset(state.knownNeedsDynamicSpellIds)
    syncDebugLoggingState(true)
    temperatureRuntimeApi.requestCellInfoFromGlobal(true)
    require('scripts.survivalmode.temperature.wetnessHud').reset()
    require('scripts.survivalmode.temperature.temperatureScreenEffect').reset()
    updateSystems()

    playerHudControllerApi.subscribeSettings({
        async = async,
        hudSettings = hudSettings,
        settingsSections = settingsSections,
        syncDebugLoggingState = syncDebugLoggingState,
        updateSystems = updateSystems,
    })
end

state.applyTemperatureMovementScale = function()
    return temperatureRuntimeApi.applyMovementScale()
end

local function onUpdate(dt)
    ensureSkillGainHandlerRegistered()

    local step = tonumber(dt)
    if step == nil or step <= 0 then
        step = 1 / 60
    end

    temperatureRuntimeApi.tickCellInfoRequestCooldown(step)

    updateSystems(step)
    applyWellRestedStaminiaRegeneration(step)
end

local function onConsume(item)
    ensureInitialized()

    local currentTime = now()
    advanceHunger(currentTime)
    advanceThirst(currentTime)

    hungerSystemApi.applyConsumedItem(item, getFoodHungerReduction)

    thirstSystemApi.applyConsumedItem(item, getThirstDrinkRestoreAmount)

    invalidateHud()
    updateSystems()
end

local function onJailTimeServed(_days)
    persistenceApi.resetNeedsAfterJail()
end

local onSave = persistenceApi.onSave

local function onLoad(savedData)
    persistenceApi.onLoad(savedData)
    ensureSkillGainHandlerRegistered()
end

local function onTeleported()
    temperatureRuntimeApi.queueTeleportRegionTransitionBypass()
end

return {
    engineHandlers = {
        onInit = onInit,
        onFrame = state.applyTemperatureMovementScale,
        onUpdate = onUpdate,
        onTeleported = onTeleported,
        onConsume = onConsume,
        _onJailTimeServed = onJailTimeServed,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        UiModeChanged = sleepSystemApi.handleUiModeChanged,
        OMWMusicCombatTargetsChanged = function(eventData)
            sleepSystemApi.updatePlayerCombatState(eventData, self.object or self)
        end,
        [NEEDS_DYNAMIC_SPELL_READY_EVENT] = function(data)
            if require('scripts.survivalmode.temperature.warmthAbility').onDynamicSpellReady(data, state.knownNeedsDynamicSpellIds) then
                return
            end
            onDynamicDebuffSpellReady(data)
        end,
        ['SurvivalNeeds_CellInfoReady'] = function(data)
            if type(data) ~= 'table' then
                return
            end
            temperatureRuntimeApi.setLatestCellInfo(data)
            invalidateHud()
        end,
    },
}
