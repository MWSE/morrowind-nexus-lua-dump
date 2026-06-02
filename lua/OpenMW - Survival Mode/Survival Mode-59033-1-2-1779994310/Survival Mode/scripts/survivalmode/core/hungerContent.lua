local M = {}

M.constants = {
    max = 1000,
    tickSeconds = 0.24 * 60 * 60,
    stepDefault = 5.0,
    stepOrc = 4.25,
    flashDurationSeconds = 0.8,
    flashFadeInRatio = 0.25,
    restorePerWeight = 250,
    restoreSoftCap = 250,
    restoreOverCapEfficiency = 0.40,
    wellFedStageId = 'well_fed',
    wellFedWeaponSkillGainBonusPct = 0.15,
    wellLearningEffectId = 'sn_quicker_learning',
    wellFedLearningEffectMagnitude = 0,
    initialValueFallback = 52,
    weaponSkillIds = {
        'longblade',
        'shortblade',
        'axe',
        'bluntweapon',
        'spear',
        'marksman',
        'handtohand',
    },
}

M.flashIconKeys = {
    hunger_neutral = 'hunger_neutral_flash',
    hunger_0 = 'hunger_0_flash',
    hunger_1 = 'hunger_1_flash',
    hunger_2 = 'hunger_2_flash',
    hunger_3 = 'hunger_3_flash',
    hunger_4 = 'hunger_4_flash',
}

local function resolveTemperatureStaminaDrainInfo(deps)
    local isTemperatureSystemEnabled = deps.isTemperatureSystemEnabled
    local temperature = deps.temperature
    local state = deps.state

    if type(isTemperatureSystemEnabled) ~= 'function'
        or not isTemperatureSystemEnabled()
        or temperature == nil
        or type(temperature.system) ~= 'table'
        or type(temperature.system.getStageByValue) ~= 'function'
        or type(state) ~= 'table' then
        return 0, ''
    end

    local temperatureStage = temperature.system.getStageByValue(state.temperature)
    if type(temperatureStage) ~= 'table' then
        return 0, ''
    end

    local temperatureStaminiaDrainPct = math.max(
        0,
        tonumber(temperatureStage.staminiaDrainPct)
            or tonumber(temperatureStage.staminaDrainPct)
            or 0
    )
    local temperatureStageName = type(temperatureStage.spellName) == 'string' and temperatureStage.spellName or ''

    return temperatureStaminiaDrainPct, temperatureStageName
end

function M.create(deps)
    local core = assert(deps.core)
    local wellFedWeaponSkillGainBonusPct = assert(tonumber(deps.wellFedWeaponSkillGainBonusPct))
    local wellFedLearningSpellName = assert(deps.wellFedLearningSpellName)
    local wellLearningEffectId = assert(deps.wellLearningEffectId)
    local wellFedLearningEffectMagnitude = assert(tonumber(deps.wellFedLearningEffectMagnitude))

    local l10n = core.l10n('SurvivalMode', 'en')

    local stages = {
        {
            id = 'well_fed',
            min = 0,
            max = 51,
            staminaDrainPct = 0,
            weaponSkillDrainPct = 0.00,
            weaponSkillGainBonusPct = wellFedWeaponSkillGainBonusPct,
            spellName = wellFedLearningSpellName,
            learningEffectId = wellLearningEffectId,
            learningEffectMagnitude = wellFedLearningEffectMagnitude,
            hungerIconKey = 'hunger_0',
        },
        {
            id = 'satisfied',
            min = 52,
            max = 166,
            staminaDrainPct = 0,
            weaponSkillDrainPct = 0.00,
            hungerIconKey = nil,
        },
        {
            id = 'peckish',
            min = 167,
            max = 206,
            staminaDrainPct = 25,
            weaponSkillDrainPct = 0.15,
            spellName = l10n('hunger_stage_peckish_name'),
            hungerIconKey = 'hunger_1',
        },
        {
            id = 'hungry',
            min = 207,
            max = 416,
            staminaDrainPct = 50,
            weaponSkillDrainPct = 0.35,
            spellName = l10n('hunger_stage_hungry_name'),
            hungerIconKey = 'hunger_2',
        },
        {
            id = 'famished',
            min = 417,
            max = 832,
            staminaDrainPct = 100,
            weaponSkillDrainPct = 0.60,
            spellName = l10n('hunger_stage_very_hungry_name'),
            hungerIconKey = 'hunger_3',
        },
        {
            id = 'starving',
            min = 833,
            max = M.constants.max,
            staminaDrainPct = 150,
            weaponSkillDrainPct = 0.85,
            spellName = l10n('hunger_stage_starving_name'),
            hungerIconKey = 'hunger_4',
        },
    }

    local stageMessages = {
        well_fed = l10n('hunger_stage_well_fed_message'),
        satisfied = l10n('hunger_stage_satisfied_message'),
        peckish = l10n('hunger_stage_peckish_message'),
        hungry = l10n('hunger_stage_hungry_message'),
        famished = l10n('hunger_stage_very_hungry_message'),
        starving = l10n('hunger_stage_starving_message'),
    }

    return {
        stages = stages,
        stageMessages = stageMessages,
    }
end

function M.buildWellFedLearningSpellName(core)
    local bonusPct = tonumber(M.constants.wellFedWeaponSkillGainBonusPct) or 0
    local bonusValue = math.floor((bonusPct * 100) + 0.5)
    return core.l10n('SurvivalMode', 'en')('quick_learning_stage_bonus', {
        stage = core.l10n('SurvivalMode', 'en')('hunger_stage_well_fed_name'),
        type = core.l10n('SurvivalMode', 'en')('quick_learning_type_weapons'),
        value = bonusValue,
    })
end

function M.appendDynamicEffectsForStage(effects, stage, deps)
    local appendDrainSkillEffects = assert(deps.appendDrainSkillEffects)
    local weaponSkillIds = assert(deps.weaponSkillIds)
    local normalizeKey = assert(deps.normalizeKey)
    local core = assert(deps.core)
    local wellFedStageId = assert(deps.wellFedStageId)
    local learningFallbackEffectId = assert(deps.learningFallbackEffectId)

    local staminaDrainPct = tonumber(stage.staminiaDrainPct) or tonumber(stage.staminaDrainPct) or 0
    local temperatureStaminiaDrainPct = resolveTemperatureStaminaDrainInfo(deps)
    local totalStaminaDrainPct = math.max(0, staminaDrainPct + temperatureStaminiaDrainPct)
    if totalStaminaDrainPct > 0 then
        effects[#effects + 1] = {
            id = 'sn_hunger_stamina_drain_display',
            magnitudeMin = 0,
            magnitudeMax = 0,
            duration = 0,
            range = 'self',
        }
    end
    appendDrainSkillEffects(effects, weaponSkillIds, stage.weaponSkillDrainPct)

    local stageId = normalizeKey(stage.id)
    local bonusPct = tonumber(stage.weaponSkillGainBonusPct) or 0
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
    if stageId == wellFedStageId and bonusPct > 0 and learningEffectId ~= '' then
        effects[#effects + 1] = {
            id = learningEffectId,
            magnitudeMin = learningEffectMagnitude,
            magnitudeMax = learningEffectMagnitude,
            duration = 0,
            range = 'self',
        }
    end
end

function M.resolveHungerMiscSpellName(stage, deps)
    local core = assert(deps.core)

    local hungerStaminaDrainPct = tonumber(stage.staminiaDrainPct) or tonumber(stage.staminaDrainPct) or 0
    local temperatureStaminiaDrainPct, temperatureStageName = resolveTemperatureStaminaDrainInfo(deps)
    local totalStaminiaDrainPct = math.max(0, hungerStaminaDrainPct + temperatureStaminiaDrainPct)
    if totalStaminiaDrainPct <= 0 then
        return nil
    end

    local stageName = type(stage.spellName) == 'string' and stage.spellName or ''
    local spellLines = {}
    if hungerStaminaDrainPct > 0 and stageName ~= '' then
        spellLines[#spellLines + 1] = string.format(
            '%s: %d%%',
            stageName,
            math.floor((tonumber(hungerStaminaDrainPct) or 0) + 0.5)
        )
    end
    if temperatureStaminiaDrainPct > 0 and temperatureStageName ~= '' then
        spellLines[#spellLines + 1] = string.format(
            '%s: %d%%',
            temperatureStageName,
            math.floor((tonumber(temperatureStaminiaDrainPct) or 0) + 0.5)
        )
    end

    if #spellLines > 0 then
        return table.concat(spellLines, '\n')
    end

    return core.l10n('SurvivalMode', 'en')(
        'hunger_penalty_increased_fatigue_drain',
        { value = totalStaminiaDrainPct }
    )
end

return M
