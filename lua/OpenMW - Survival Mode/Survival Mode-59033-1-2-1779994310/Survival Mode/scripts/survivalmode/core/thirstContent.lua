local M = {}

M.constants = {
    max = 1000,
    tickSeconds = 0.24 * 60 * 60,
    stepDefault = 4.8,
    stepOrc = 4.08,
    flashDurationSeconds = 0.8,
    flashFadeInRatio = 0.25,
    wellHydratedStageId = 'well_hydrated',
    wellHydratedMagicSkillGainBonusPct = 0.15,
    wellHydratedLearningEffectMagnitude = 0,
    initialValueFallback = 52,
}

M.flashIconKeys = {
    thirst_neutral = 'thirst_neutral_flash',
    thirst_0 = 'thirst_0_flash',
    thirst_1 = 'thirst_1_flash',
    -- No dedicated thirst-2 flash icon exists, so reuse thirst-1 flash.
    thirst_2 = 'thirst_1_flash',
    thirst_3 = 'thirst_3_flash',
    thirst_4 = 'thirst_4_flash',
}

function M.create(deps)
    local core = assert(deps.core)
    local wellHydratedMagicSkillGainBonusPct = assert(tonumber(deps.wellHydratedMagicSkillGainBonusPct))
    local wellHydratedLearningSpellName = assert(deps.wellHydratedLearningSpellName)
    local wellLearningEffectId = assert(deps.wellLearningEffectId)
    local wellHydratedLearningEffectMagnitude = assert(tonumber(deps.wellHydratedLearningEffectMagnitude))

    local l10n = core.l10n('SurvivalMode', 'en')

    local stages = {
        {
            id = 'well_hydrated',
            min = 0,
            max = 51,
            staminaRegenPenaltyPct = 0,
            magicSkillDrainPct = 0.00,
            magicSkillGainBonusPct = wellHydratedMagicSkillGainBonusPct,
            spellName = wellHydratedLearningSpellName,
            learningEffectId = wellLearningEffectId,
            learningEffectMagnitude = wellHydratedLearningEffectMagnitude,
            thirstIconKey = 'thirst_0',
        },
        {
            id = 'hydrated',
            min = 52,
            max = 147,
            staminaRegenPenaltyPct = 0,
            magicSkillDrainPct = 0.00,
            thirstIconKey = nil,
        },
        {
            id = 'thirsty',
            min = 148,
            max = 185,
            staminaRegenPenaltyPct = 25,
            magicSkillDrainPct = 0.15,
            spellName = l10n('thirst_stage_thirsty_name'),
            thirstIconKey = 'thirst_1',
        },
        {
            id = 'parched',
            min = 186,
            max = 319,
            staminaRegenPenaltyPct = 50,
            magicSkillDrainPct = 0.35,
            spellName = l10n('thirst_stage_parched_name'),
            thirstIconKey = 'thirst_2',
        },
        {
            id = 'dehydrated',
            min = 320,
            max = 639,
            staminaRegenPenaltyPct = 75,
            magicSkillDrainPct = 0.60,
            spellName = l10n('thirst_stage_dehydrated_name'),
            thirstIconKey = 'thirst_3',
        },
        {
            id = 'severely_dehydrated',
            min = 640,
            max = M.constants.max,
            staminaRegenPenaltyPct = 100,
            magicSkillDrainPct = 0.85,
            spellName = l10n('thirst_stage_severely_dehydrated_name'),
            thirstIconKey = 'thirst_4',
        },
    }

    local stageMessages = {
        well_hydrated = l10n('thirst_stage_well_hydrated_message'),
        hydrated = l10n('thirst_stage_hydrated_message'),
        thirsty = l10n('thirst_stage_thirsty_message'),
        parched = l10n('thirst_stage_parched_message'),
        dehydrated = l10n('thirst_stage_dehydrated_message'),
        severely_dehydrated = l10n('thirst_stage_severely_dehydrated_message'),
    }

    return {
        stages = stages,
        stageMessages = stageMessages,
    }
end

function M.buildWellHydratedLearningSpellName(core)
    local bonusPct = tonumber(M.constants.wellHydratedMagicSkillGainBonusPct) or 0
    local bonusValue = math.floor((bonusPct * 100) + 0.5)
    return core.l10n('SurvivalMode', 'en')('quick_learning_stage_bonus', {
        stage = core.l10n('SurvivalMode', 'en')('thirst_stage_well_hydrated_name'),
        type = core.l10n('SurvivalMode', 'en')('quick_learning_type_magicka'),
        value = bonusValue,
    })
end

function M.appendDynamicEffectsForStage(effects, stage, deps)
    local appendDrainSkillEffects = assert(deps.appendDrainSkillEffects)
    local magicSkillIds = assert(deps.magicSkillIds)
    local normalizeKey = assert(deps.normalizeKey)
    local core = assert(deps.core)
    local wellHydratedStageId = assert(deps.wellHydratedStageId)
    local learningFallbackEffectId = assert(deps.learningFallbackEffectId)

    local staminaRegenPenaltyPct = tonumber(stage.staminiaRegenPenaltyPct) or tonumber(stage.staminaRegenPenaltyPct) or 0
    if staminaRegenPenaltyPct > 0 then
        effects[#effects + 1] = {
            id = 'sn_thirst_stamina_regen_penalty_display',
            magnitudeMin = 0,
            magnitudeMax = 0,
            duration = 0,
            range = 'self',
        }
    end
    appendDrainSkillEffects(effects, magicSkillIds, stage.magicSkillDrainPct)

    local stageId = normalizeKey(stage.id)
    local bonusPct = tonumber(stage.magicSkillGainBonusPct) or 0
    local learningEffectId = normalizeKey(stage.learningEffectId)
    if learningEffectId ~= '' and core.magic.effects.records[learningEffectId] == nil then
        local fallbackEffectId = normalizeKey(learningFallbackEffectId)
        if fallbackEffectId ~= '' and core.magic.effects.records[fallbackEffectId] ~= nil then
            learningEffectId = fallbackEffectId
        else
            learningEffectId = ''
        end
    end
    local learningEffectMagnitude = math.max(0, tonumber(stage.learningEffectMagnitude) or 0)
    if stageId == wellHydratedStageId and bonusPct > 0 and learningEffectId ~= '' then
        effects[#effects + 1] = {
            id = learningEffectId,
            magnitudeMin = learningEffectMagnitude,
            magnitudeMax = learningEffectMagnitude,
            duration = 0,
            range = 'self',
        }
    end
end

function M.resolveThirstMiscSpellName(stage, deps)
    local core = assert(deps.core)

    local staminaRegenPenaltyPct = tonumber(stage.staminiaRegenPenaltyPct) or tonumber(stage.staminaRegenPenaltyPct) or 0
    if staminaRegenPenaltyPct <= 0 then
        return nil
    end

    local stageName = type(stage.spellName) == 'string' and stage.spellName or ''
    if stageName ~= '' then
        return string.format('%s: %d%%', stageName, math.floor((tonumber(staminaRegenPenaltyPct) or 0) + 0.5))
    end

    return core.l10n('SurvivalMode', 'en')(
        'thirst_penalty_reduced_fatigue_regeneration',
        { value = staminaRegenPenaltyPct }
    )
end

return M
