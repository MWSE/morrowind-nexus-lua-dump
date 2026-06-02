local core = require('openmw.core')
local ok, content = pcall(require, 'openmw.content')
if not ok then
    print('[SurvivalMode] openmw.content is unavailable; custom Well and temperature debuff effects were not created.')
    return
end
local l10n = core.l10n('SurvivalMode', 'en')

local WELL_QUICK_LEARNING_EFFECT_ID = 'sn_quicker_learning'
local WARMTH_DISPLAY_EFFECT_ID = 'sn_warmth_display'
local SLEEP_STAMINA_REGEN_BONUS_DISPLAY_EFFECT_ID = 'sn_sleep_stamina_regen_bonus_display'
local HUNGER_STAMINA_DRAIN_DISPLAY_EFFECT_ID = 'sn_hunger_stamina_drain_display'
local THIRST_STAMINA_REGEN_PENALTY_DISPLAY_EFFECT_ID = 'sn_thirst_stamina_regen_penalty_display'
local TEMPLATE_ID = 'restorefatigue'
local ICON_TEMPLATE_ID = 'fortifyskill'
local FORTIFY_FATIGUE_ICON_TEMPLATE_ID = 'fortifyfatigue'
local HOT_DEBUFF_ICON_TEMPLATE_ID = 'firedamage'
local COLD_DEBUFF_ICON_TEMPLATE_ID = 'frostdamage'
local WARMTH_ICON_TEMPLATE_ID = 'frostshield'
local HUNGER_STAMINA_DRAIN_ICON_TEMPLATE_ID = 'drainfatigue'
local STAMINA_DAMAGE_TEMPLATE_ID = 'damagefatigue'
local SLOWNESS_ICON_TEMPLATE_ID = 'damageattribute'
local HEALTH_ICON_TEMPLATE_ID = 'damagehealth'

local function localize(key, data)
    if data == nil then
        return l10n(key)
    end

    return l10n(key, data)
end

local template = content.magicEffects.records[TEMPLATE_ID]
if template == nil then
    print('[SurvivalMode] Missing restorefatigue template; custom Well and temperature debuff effects were not created.')
    return
end
local iconTemplate = content.magicEffects.records[ICON_TEMPLATE_ID]
local effectIcon = template.icon
if iconTemplate ~= nil and type(iconTemplate.icon) == 'string' and iconTemplate.icon ~= '' then
    effectIcon = iconTemplate.icon
end
local fortifyFatigueIconTemplate = content.magicEffects.records[FORTIFY_FATIGUE_ICON_TEMPLATE_ID]
local fortifyFatigueIcon = effectIcon
if fortifyFatigueIconTemplate ~= nil
    and type(fortifyFatigueIconTemplate.icon) == 'string'
    and fortifyFatigueIconTemplate.icon ~= '' then
    fortifyFatigueIcon = fortifyFatigueIconTemplate.icon
end
local hotDebuffIconTemplate = content.magicEffects.records[HOT_DEBUFF_ICON_TEMPLATE_ID]
local hotDebuffIcon = effectIcon
if hotDebuffIconTemplate ~= nil
    and type(hotDebuffIconTemplate.icon) == 'string'
    and hotDebuffIconTemplate.icon ~= '' then
    hotDebuffIcon = hotDebuffIconTemplate.icon
end
local coldDebuffIconTemplate = content.magicEffects.records[COLD_DEBUFF_ICON_TEMPLATE_ID]
local coldDebuffIcon = effectIcon
if coldDebuffIconTemplate ~= nil
    and type(coldDebuffIconTemplate.icon) == 'string'
    and coldDebuffIconTemplate.icon ~= '' then
    coldDebuffIcon = coldDebuffIconTemplate.icon
end
local warmthIconTemplate = content.magicEffects.records[WARMTH_ICON_TEMPLATE_ID]
local warmthIcon = effectIcon
if warmthIconTemplate ~= nil
    and type(warmthIconTemplate.icon) == 'string'
    and warmthIconTemplate.icon ~= '' then
    warmthIcon = warmthIconTemplate.icon
end
local hungerStaminaDrainIconTemplate = content.magicEffects.records[HUNGER_STAMINA_DRAIN_ICON_TEMPLATE_ID]
local hungerStaminaDrainIcon = effectIcon
if hungerStaminaDrainIconTemplate ~= nil
    and type(hungerStaminaDrainIconTemplate.icon) == 'string'
    and hungerStaminaDrainIconTemplate.icon ~= '' then
    hungerStaminaDrainIcon = hungerStaminaDrainIconTemplate.icon
end
local staminaDamageTemplate = content.magicEffects.records[STAMINA_DAMAGE_TEMPLATE_ID] or template
local staminaDamageIcon = effectIcon
if staminaDamageTemplate ~= nil
    and type(staminaDamageTemplate.icon) == 'string'
    and staminaDamageTemplate.icon ~= '' then
    staminaDamageIcon = staminaDamageTemplate.icon
end
local slownessIconTemplate = content.magicEffects.records[SLOWNESS_ICON_TEMPLATE_ID]
local slownessIcon = hotDebuffIcon
if slownessIconTemplate ~= nil
    and type(slownessIconTemplate.icon) == 'string'
    and slownessIconTemplate.icon ~= '' then
    slownessIcon = slownessIconTemplate.icon
end
local healthIconTemplate = content.magicEffects.records[HEALTH_ICON_TEMPLATE_ID]
local healthIcon = hotDebuffIcon
if healthIconTemplate ~= nil
    and type(healthIconTemplate.icon) == 'string'
    and healthIconTemplate.icon ~= '' then
    healthIcon = healthIconTemplate.icon
end

local function upsertDisplayEffect(effectId, effectName, description, iconPath, harmful, school, templateOverride, hasMagnitude)
    local existing = content.magicEffects.records[effectId]
    if existing ~= nil then
        -- Do not modify vanilla game records. Only update records that belong to this mod (prefix 'sn_')
        if string.sub(effectId, 1, 3) ~= 'sn_' then
            return
        end
        -- Update existing mod record in-place
        existing.template = templateOverride or existing.template or template
        existing.name = effectName
        existing.icon = iconPath or existing.icon or effectIcon
        existing.school = school or existing.school or 'restoration'
        existing.hasMagnitude = hasMagnitude == true
        existing.description = description
        existing.harmful = harmful == true
        content.magicEffects.records[effectId] = existing
        return
    end

    local effectRecord = {}
    effectRecord.template = templateOverride or template
    effectRecord.name = effectName
    effectRecord.icon = iconPath or effectIcon
    effectRecord.school = school or 'restoration'
    effectRecord.hasMagnitude = hasMagnitude == true
    effectRecord.description = description
    effectRecord.harmful = harmful == true
    content.magicEffects.records[effectId] = effectRecord
end

local function upsertLearningEffect(effectId, effectName, description, iconPath)
    upsertDisplayEffect(effectId, effectName, description, iconPath, false, 'restoration', template, false)
end

upsertLearningEffect(
    WELL_QUICK_LEARNING_EFFECT_ID,
    localize('quick_learning_effect_name'),
    localize('quick_learning_effect_description'),
    effectIcon
)

upsertLearningEffect(
    WARMTH_DISPLAY_EFFECT_ID,
    localize('warmth_effect_name'),
    localize('warmth_effect_description'),
    warmthIcon
)

upsertDisplayEffect(
    SLEEP_STAMINA_REGEN_BONUS_DISPLAY_EFFECT_ID,
    localize('sleep_fatigue_regen_bonus_effect_name'),
    localize('sleep_fatigue_regen_bonus_effect_description'),
    fortifyFatigueIcon,
    false,
    'restoration',
    template,
    false
)

upsertDisplayEffect(
    HUNGER_STAMINA_DRAIN_DISPLAY_EFFECT_ID,
    localize('hunger_fatigue_drain_effect_name'),
    localize('hunger_fatigue_drain_effect_description'),
    hungerStaminaDrainIcon,
    true,
    'destruction',
    hungerStaminaDrainIconTemplate or template,
    false
)

upsertDisplayEffect(
    THIRST_STAMINA_REGEN_PENALTY_DISPLAY_EFFECT_ID,
    localize('thirst_fatigue_regen_penalty_effect_name'),
    localize('thirst_fatigue_regen_penalty_effect_description'),
    staminaDamageIcon,
    true,
    'destruction',
    staminaDamageTemplate,
    false
)

local TEMPERATURE_SPLIT_PENALTY_DISPLAY_EFFECTS = {
    {
        id = 'sn_tmp_penalty_hunger_display',
        name = localize('temperature_penalty_increased_hunger_effect_name'),
        description = localize('temperature_penalty_increased_hunger_effect_description'),
    },
    {
        id = 'sn_tmp_penalty_thirst_display',
        name = localize('temperature_penalty_increased_thirst_effect_name'),
        description = localize('temperature_penalty_increased_thirst_effect_description'),
    },
    {
        id = 'sn_tmp_penalty_slowness_display',
        name = localize('temperature_penalty_slowness_effect_name'),
        description = localize('temperature_penalty_slowness_effect_description'),
        icon = slownessIcon,
    },
    {
        id = 'sn_tmp_penalty_health_display',
        name = localize('temperature_penalty_reduced_health_effect_name'),
        description = localize('temperature_penalty_reduced_health_effect_description'),
        icon = healthIcon,
    },
}

local function pickTemperatureTemplate()
    local candidateIds = {
        'damagehealth',
        'drainhealth',
        'damagemagicka',
        'drainmagicka',
        TEMPLATE_ID,
    }
    for _, candidateId in ipairs(candidateIds) do
        local candidate = content.magicEffects.records[candidateId]
        if candidate ~= nil then
            return candidate
        end
    end
    return template
end

local temperatureTemplate = pickTemperatureTemplate()

for _, effect in ipairs(TEMPERATURE_SPLIT_PENALTY_DISPLAY_EFFECTS) do
    upsertDisplayEffect(
        effect.id,
        effect.name,
        effect.description or effect.name,
        effect.icon or hotDebuffIcon,
        true,
        'destruction',
        temperatureTemplate,
        false
    )
end
