local M = {}

local SLEEP_TICK_SECONDS = 0.24 * 60 * 60
local SLEEP_STEP_DEFAULT = 5.0

M.constants = {
    max = 1000,
    tickSeconds = SLEEP_TICK_SECONDS,
    stepDefault = SLEEP_STEP_DEFAULT,
    accumulationPerHour = SLEEP_STEP_DEFAULT * (3600 / SLEEP_TICK_SECONDS),
    recoveryPerHourBed = 50.0,
    recoveryPerHourMenu = 37.5,
    travelMultiplier = 0.60,
    restSleepNeedsMultiplier = 0.70,
    wellRestedStageId = 'well_rested',
    wellRestedArmorSkillGainBonusPct = 0.15,
    wellRestedStaminiaRegenBonusPct = 0.25,
    wellRestedLearningEffectMagnitude = 0,
    wellRestedStaminaRegenDisplayEffectId = 'sn_sleep_stamina_regen_bonus_display',
    initialValueFallback = 42,
}

function M.buildWellRestedLearningSpellName(_core)
    local bonusPct = tonumber(M.constants.wellRestedArmorSkillGainBonusPct) or 0
    return string.format(
        'Well Rested (Armor Skills): %d%%',
        math.floor((bonusPct * 100) + 0.5)
    )
end

function M.create(deps)
    local core = assert(deps.core)
    local wellRestedArmorSkillGainBonusPct = assert(tonumber(deps.wellRestedArmorSkillGainBonusPct))
    local wellRestedStaminiaRegenBonusPct = assert(tonumber(deps.wellRestedStaminiaRegenBonusPct))
    local wellRestedLearningSpellName = assert(deps.wellRestedLearningSpellName)
    local wellLearningEffectId = assert(deps.wellLearningEffectId)
    local wellRestedLearningEffectMagnitude = assert(tonumber(deps.wellRestedLearningEffectMagnitude))

    local l10n = core.l10n('SurvivalMode', 'en')

    local stages = {
        {
            id = 'well_rested',
            min = 0,
            max = 52,
            armorSkillDrainPct = 0.00,
            blockSneakDrainPct = 0.00,
            armorSkillGainBonusPct = wellRestedArmorSkillGainBonusPct,
            staminiaRegenBonusPct = wellRestedStaminiaRegenBonusPct,
            spellName = wellRestedLearningSpellName,
            learningEffectId = wellLearningEffectId,
            learningEffectMagnitude = wellRestedLearningEffectMagnitude,
            sleepIconKey = 'sleep_0',
        },
        {
            id = 'refreshed',
            min = 53,
            max = 247,
            armorSkillDrainPct = 0.00,
            blockSneakDrainPct = 0.00,
            sleepIconKey = nil,
        },
        {
            id = 'drained',
            min = 248,
            max = 291,
            armorSkillDrainPct = 0.15,
            blockSneakDrainPct = 0.10,
            spellName = l10n('sleep_stage_drained_name'),
            sleepBurdenPct = 0.05,
            sleepIconKey = 'sleep_1',
        },
        {
            id = 'tired',
            min = 292,
            max = 583,
            armorSkillDrainPct = 0.45,
            blockSneakDrainPct = 0.30,
            spellName = l10n('sleep_stage_tired_name'),
            sleepBurdenPct = 0.15,
            sleepIconKey = 'sleep_2',
        },
        {
            id = 'weary',
            min = 584,
            max = 874,
            armorSkillDrainPct = 0.60,
            blockSneakDrainPct = 0.50,
            spellName = l10n('sleep_stage_weary_name'),
            sleepBurdenPct = 0.35,
            sleepIconKey = 'sleep_3',
        },
        {
            id = 'debilitated',
            min = 875,
            max = M.constants.max,
            armorSkillDrainPct = 0.85,
            blockSneakDrainPct = 0.65,
            spellName = l10n('sleep_stage_debilitated_name'),
            sleepBurdenPct = 0.50,
            sleepIconKey = 'sleep_4',
        },
    }

    local stageMessages = {
        well_rested = l10n('sleep_stage_well_rested_message'),
        refreshed = l10n('sleep_stage_refreshed_message'),
        drained = l10n('sleep_stage_drained_message'),
        tired = l10n('sleep_stage_tired_message'),
        weary = l10n('sleep_stage_weary_message'),
        debilitated = l10n('sleep_stage_debilitated_message'),
    }

    return {
        stages = stages,
        stageMessages = stageMessages,
    }
end

return M
