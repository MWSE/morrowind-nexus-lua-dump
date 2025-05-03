local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local types = require('openmw.types')
local world = require('openmw.world')

-- Settings page
I.Settings.registerGroup {
    key = 'Settings/OblivionLockpicking/3_GlobalOptions',
    page = 'OblivionLockpicking',
    l10n = 'OblivionLockpicking',
    name = 'ConfigCategoryGlobalOptions',
    permanentStorage = true,
    settings = {
        {
            key = 'b_EnableMod',
            renderer = 'checkbox',
            name = 'EnableMod',
            description = 'EnableModDesc',
            default = true,
        },
        {
            key = 'b_UseForDisarming',
            renderer = 'checkbox',
            name = 'UseForDisarming',
            description = 'UseForDisarmingDesc',
            default = true,
        },
        {
            key = 'b_TumblerSpeedFollowsPattern',
            renderer = 'checkbox',
            name = 'TumblerSpeedFollowsPattern',
            description = 'TumblerSpeedFollowsPatternDesc',
            default = true,
        },
        {
            key = 'b_SecurityAffectsTumblerDrops',
            renderer = 'checkbox',
            name = 'SecurityAffectsTumblerDrops',
            description = 'SecurityAffectsTumblerDropsDesc',
            default = true,
        },
        {
            key = 'b_MissedRollsDropOtherPins',
            renderer = 'checkbox',
            name = 'MissedRollsDropOtherPins',
            description = 'MissedRollsDropOtherPinsDesc',
            default = false,
        },
        {
            key = 'b_SkillAffectsChance',
            renderer = 'checkbox',
            name = 'SkillAffectsChance',
            description = 'SkillAffectsChanceDesc',
            default = true,
        },
        {
            key = 'b_HardSkillGating',
            renderer = 'checkbox',
            name = 'HardSkillGating',
            description = 'HardSkillGatingDesc',
            default = true,
        },
        {
            key = 'b_SkipIfGuaranteed',
            renderer = 'checkbox',
            name = 'SkipIfGuaranteed',
            description = 'SkipIfGuaranteedDesc',
            default = true,
        },
        {
            key = 'b_PauseTime',
            renderer = 'checkbox',
            name = 'PauseTime',
            description = 'PauseTimeDesc',
            default = false,
        }
    },
}
I.Settings.registerGroup {
    key = 'Settings/OblivionLockpicking/4_Tweaks',
    page = 'OblivionLockpicking',
    l10n = 'OblivionLockpicking',
    name = 'ConfigCategoryTweaks',
    description = 'ConfigCategoryTweaksDesc',
    permanentStorage = true,
    settings = {
        {
            key = 'n_BaseTimeMult',
            renderer = 'number',
            name = 'BaseTimeMult',
            description = 'BaseTimeMultDesc',
            default = 1.0,
            argument = {
                min = 0.25,
                max = 2.0,
            }
        },
        {
            key = 'n_BaseHangTimeMult',
            renderer = 'number',
            name = 'BaseHangTimeMult',
            description = 'BaseHangTimeMultDesc',
            default = 1.0,
            argument = {
                min = 0.25,
                max = 2.0,
            }
        },
        {
            key = 'n_BaseDifficultyMult',
            renderer = 'number',
            name = 'BaseDifficultyMult',
            description = 'BaseDifficultyMultDesc',
            default = 1.0,
            argument = {
                min = 0.25,
                max = 2.0,
            }
        },
        {
            key = 'n_BasePinChanceMult',
            renderer = 'number',
            name = 'BasePinChanceMult',
            description = 'BasePinChanceMultDesc',
            default = 1.0,
            argument = {
                min = 0.1,
                max = 2.0,
            }
        },
        {
            key = 'n_BasePinChanceMin',
            renderer = 'number',
            name = 'BasePinChanceMin',
            description = 'BasePinChanceMinDesc',
            default = 1.0,
            argument = {
                min = 0.0,
                max = 100.0,
            }
        },
        {
            key = 'n_BasePinChanceMax',
            renderer = 'number',
            name = 'BasePinChanceMax',
            description = 'BasePinChanceMaxDesc',
            default = 100.0,
            argument = {
                min = 0.0,
                max = 100.0,
            }
        },
        {
            key = 'n_PickQualityMult',
            renderer = 'number',
            name = 'PickQualityMult',
            description = 'PickQualityMultDesc',
            default = 1.0,
            argument = {
                min = 0,
                max = 3.0,
            }
        },
        {
            key = 'n_TumblerCountScale',
            renderer = 'number',
            name = 'TumblerCountScale',
            description = 'TumblerCountScaleDesc',
            default = 20,
            argument = {
                integer = true,
                min = 0,
                max = 101,
            }
        },
        {
            key = 'n_AutoAttemptSuccessModifier',
            renderer = 'number',
            name = 'AutoAttemptSuccessModifier',
            description = 'AutoAttemptSuccessModifierDesc',
            default = 0.5,
            argument = {
                min = 0.0,
                max = 1.0,
            }
        },
        {
            key = 'n_PatternLengthBaseMin',
            renderer = 'number',
            name = 'PatternLengthBaseMin',
            description = 'PatternLengthBaseMinDesc',
            default = 3,
            argument = {
                integer = true,
                min = 1,
                max = 50,
            }
        },
        {
            key = 'n_PatternLengthBaseMax',
            renderer = 'number',
            name = 'PatternLengthBaseMax',
            description = 'PatternLengthBaseMaxDesc',
            default = 10,
            argument = {
                integer = true,
                min = 1,
                max = 50,
            }
        },
        {
            key = 'n_PatternLengthVariationMin',
            renderer = 'number',
            name = 'PatternLengthVariationMin',
            description = 'PatternLengthVariationMinDesc',
            default = 1,
            argument = {
                integer = true,
                min = 0,
                max = 25,
            }
        },
        {
            key = 'n_PatternLengthVariationMax',
            renderer = 'number',
            name = 'PatternLengthVariationMax',
            description = 'PatternLengthVariationMaxDesc',
            default = 4,
            argument = {
                integer = true,
                min = 0,
                max = 25,
            }
        },
        {
            key = 'n_SecurityAffectsTumblerDropsLevelInterval',
            renderer = 'number',
            name = 'SecurityAffectsTumblerDropsLevelInterval',
            description = 'SecurityAffectsTumblerDropsLevelIntervalDesc',
            default = 25,
            argument = {
                integer = true,
                min = 5,
                max = 50
            }
        }
    }
}