local modInfo           = require('scripts.ngarde.modinfo')
local core              = require("openmw.core")
local I                 = require('openmw.interfaces')
local SettingsConstants = require('scripts.ngarde.helpers.settings_constants')
local logging           = require('scripts.ngarde.helpers.logger').new()
logging:setLoglevel(logging.LOG_LEVELS.OFF)
local l10n = core.l10n(modInfo.l10n)

local RENDERER_SLIDER = "SuperSlider3"


if I.Settings then
    logging:info("Registering Global Settings")
    I.Settings.registerGroup({
        key = SettingsConstants.parrySettingsGroupKey,
        page = modInfo.name,
        order = 0, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('parry_settings_name'),
        description = l10n('parry_settings_desc'),
        permanentStorage = true,
        settings = {
            {
                key = SettingsConstants.allAttacksHitKey,
                renderer = 'checkbox',
                name = l10n("always_hit_setting_name"),
                description = l10n("always_hit_setting_desc"),
                default = SettingsConstants.allAttacksHitDefault,
                trueLabel = l10n("true_string"),
                falseLabel = l10n("false_string"),
            },
            {
                key = SettingsConstants.quickModeKey,
                renderer = 'checkbox',
                name = l10n("quick_mode_setting_name"),
                description = l10n("quick_mode_setting_desc"),
                default = SettingsConstants.quickModeDefault,
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },
            {
                key = SettingsConstants.fatigueEffectsFormulaKey,
                renderer = 'select',
                name = l10n('fatigue_effects_formula_name'),
                description = l10n('fatigue_effects_formula_desc'),
                default = SettingsConstants.fatigueEffectsFormulaDefault,
                argument = {
                    disabled = false,
                    l10n = modInfo.l10n,
                    items = { "With fatigue effects", "Without fatigue effects", "Fatigue effects limited to 50%" }
                }
            },
            {
                key = SettingsConstants.allowParryCreaturesKey,
                renderer = 'select',
                name = l10n('allow_parry_creatures_name'),
                description = l10n('allow_parry_creatures_desc'),
                default = SettingsConstants.allowParryCreaturesDefault,
                argument = {
                    disabled = false,
                    l10n = modInfo.l10n,
                    items = { "Yes", "No", "Shield Only" }
                }
            },
            {
                key = SettingsConstants.enchantParrySettingKey,
                renderer = 'checkbox',
                name = l10n('enchant_parry_setting_name'),
                description = l10n('enchant_parry_setting_desc'),
                default = SettingsConstants.enchantParrySettingDefault,
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },
            {
                key = SettingsConstants.enchantParryAOESettingKey,
                renderer = 'checkbox',
                name = l10n('enchant_aoe_parry_setting_name'),
                description = l10n('enchant_aoe_parry_setting_desc'),
                default = SettingsConstants.enchantParryAOESettingDefault,
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },
            {
                key = SettingsConstants.baseParryDurabilityLossKey,
                renderer = 'number',
                name = l10n('base_parry_durability_loss_setting_name'),
                ---@diagnostic disable-next-line redundant-parameter
                description = l10n('base_parry_durability_loss_setting_desc',{ default = SettingsConstants.baseParryDurabilityLossDefault }),
                default = SettingsConstants.baseParryDurabilityLossDefault,
                argument = { integer = true, min = 0 }
            },
            {
                key = SettingsConstants.baseParryFatigueCostKey,
                renderer = 'number',
                name = l10n('base_parry_fatigue_cost_setting_name'),
                description = l10n('base_parry_fatigue_cost_setting_desc'),
                default = SettingsConstants.baseParryFatigueCostDefault,
                argument = { integer = true, min = 0 }
            },
            {
                key = SettingsConstants.parrySoundVolumeKey,
                name =  l10n('parry_sound_setting_name'),
                description = l10n('parry_sound_setting_desc'),
                renderer = RENDERER_SLIDER,
                default = SettingsConstants.parrySoundVolumeDefault,
                argument = { -- NOTE: maybe argument can't be a reused table
                    min = 0, -- default: 0
                    max = 100, -- default: 100
                    step = 1, -- default: 1
                    default = SettingsConstants.parrySoundVolumeDefault, -- default: some features disabled // NOTE: default needs to be defined here too for the default mark and reset button to show up
                    showDefaultMark = true, -- default: false
                    showResetButton = false, -- default: false
                    bottomRow = true, -- default: false // NOTE: Puts the textbox and the reset button below the slider (
                    minLabel = "Min", -- default: hidden
                    maxLabel = "Max", -- default: hidden
                    -- centerLabel = "Quieter", -- default: hidden
                    labelSize = 12, -- default: max(thickness-2, 10)
                    width = 150, -- default: 200
                    thickness = 14, -- default: 15
                    unit = "%", -- default: none
                },
            },

        },
    })
    I.Settings.registerGroup({
        key = SettingsConstants.balanceSettingsGroupKey,
        page = modInfo.name,
        order = 1, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('balance_settings_name'),
        description = l10n('balance_settings_desc'),
        permanentStorage = true,
        settings = {
            {
                key = SettingsConstants.baseGuardFatigueDrainKey,
                renderer = 'number',
                name = l10n("base_guard_fatigue_drain_name"),
                description = l10n("base_guard_fatigue_drain_desc"),
                default = SettingsConstants.baseGuardFatigueDrainDefault,
                argument = { integer = true, min = 0 },
            },
            {
                key = SettingsConstants.scalingGuardFatigueDrainKey,
                renderer = 'number',
                name = l10n("scaling_guard_fatigue_drain_name"),
                description = l10n("scaling_guard_fatigue_drain_desc"),
                default = SettingsConstants.scalingGuardFatigueDrainDefault,
                argument = { integer = true, min = 0 },
            },
            {
                key = SettingsConstants.perfectParryThresholdKey,
                renderer = 'number',
                name = l10n('perfect_parry_threshold_setting_name'),
                description = l10n('perfect_parry_threshold_setting_desc'),
                default = SettingsConstants.perfectParryThresholdDefault,
                argument = { integer = true, min = 0, max = 100 }
            },
            {
                key = SettingsConstants.ironPalmThresholdKey,
                renderer = 'number',
                name = l10n('iron_palm_threshold_setting_name'),
                description = l10n('iron_palm_threshold_setting_desc'),
                default = SettingsConstants.ironPalmThresholdDefault,
                argument = { integer = true, min = 0, max = 100 }
            },
            --#region Baseline Effectiveness Settigns
            --========================================================
            {
                key = SettingsConstants.baseShortBladeOneHandParryEffectivenessKey,
                renderer = 'number',
                name = l10n("shortbladeonehand_base_effectiveness_setting_name"),
                description = l10n("shortbladeonehand_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseShortBladeOneHandParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseLongBladeOneHandParryEffectivenessKey,
                renderer = 'number',
                name = l10n("longbladeonehand_base_effectiveness_setting_name"),
                description = l10n("longbladeonehand_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseLongBladeOneHandParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseLongBladeTwoHandParryEffectivenessKey,
                renderer = 'number',
                name = l10n("longbladetwohand_base_effectiveness_setting_name"),
                description = l10n("longbladetwohand_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseLongBladeTwoHandParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseBluntOneHandParryEffectivenessKey,
                renderer = 'number',
                name = l10n("bluntonehand_base_effectiveness_setting_name"),
                description = l10n("bluntonehand_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseBluntOneHandParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseBluntTwoCloseParryEffectivenessKey,
                renderer = 'number',
                name = l10n("blunttwoclose_base_effectiveness_setting_name"),
                description = l10n("blunttwoclose_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseBluntTwoCloseParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseBluntTwoWideParryEffectivenessKey,
                renderer = 'number',
                name = l10n("blunttwowide_base_effectiveness_setting_name"),
                description = l10n("blunttwowide_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseBluntTwoWideParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseSpearTwoWideParryEffectivenessKey,
                renderer = 'number',
                name = l10n("speartwowide_base_effectiveness_setting_name"),
                description = l10n("speartwowide_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseSpearTwoWideParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseAxeOneHandParryEffectivenessKey,
                renderer = 'number',
                name = l10n("axeonehand_base_effectiveness_setting_name"),
                description = l10n("axeonehand_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseAxeOneHandParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseAxeTwoHandParryEffectivenessKey,
                renderer = 'number',
                name = l10n("axetwohand_base_effectiveness_setting_name"),
                description = l10n("axetwohand_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseAxeTwoHandParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseHandToHandParryEffectivenessKey,
                renderer = 'number',
                name = l10n("handtohand_base_effectiveness_setting_name"),
                description = l10n("handtohand_base_effectiveness_setting_desc"),
                default = SettingsConstants.baseHandToHandParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            {
                key = SettingsConstants.baseShieldParryEffectivenessKey,
                renderer = 'number',
                name = l10n("shield_base_effectiveness_setting_name"),
                ---@diagnostic disable-next-line redundant-parameter
                description = l10n("shield_base_effectiveness_setting_desc",{ default = SettingsConstants.baseShieldParryEffectivenessDefault }),
                default = SettingsConstants.baseShieldParryEffectivenessDefault,
                argument = { integer = false, min = 0, max = 2 },
            },
            --#endregion
        },

    })
    I.Settings.registerGroup({
        key = SettingsConstants.debugSettingsGroupKey,
        page = modInfo.name,
        order = 2, -- Explicit ordering
        l10n = modInfo.l10n,
        name = l10n('debug_settings_name'),
        description = l10n('debug_settings_desc'),
        permanentStorage = true,
        settings = {
            {
                key = SettingsConstants.debugLogsKey,
                renderer = 'checkbox',
                name = l10n("debug_logs_name"),
                description = l10n("debug_logs_desc"),
                default = SettingsConstants.debugLogsDefault,
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },
            {
                key = SettingsConstants.debugMessagesKey,
                renderer = 'checkbox',
                name = l10n("debug_messages_name"),
                description = l10n("debug_messages_desc"),
                default = SettingsConstants.debugMessagesDefault,
                trueLabel = l10n('true_string'),
                falseLabel = l10n('false_string')
            },
        }
    })
else
    logging:error("I.Settings is not available.")
end
