local I = require('openmw.interfaces')
local input = require('openmw.input')


I.Settings.registerPage {
    key = 'DualWieldingSettingsPage',
    l10n = 'DualWieldingsSettings',
    name = 'Dual Wielding  Settings',
    description = 'Dual Wielding settings.',
}

input.registerAction {
	key = 'EquipSecondWeapon',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'DualWieldingSettings',
	name = '',
	description = '',
	defaultValue = true,
}

I.Settings.registerGroup {
    key = 'DualWieldingscontrols',
    page = 'DualWieldingSettingsPage',
    l10n = 'DualWieldingSettings',
    name = 'Dual Wielding controls',
    description = 'Configuration of controls for Dual Wieldings.',
    permanentStorage = true,
    settings = {
      
        {
            key = "ButtonEquipSecondWeapon",
            renderer = "inputBinding",
            name = "EquipSecondWeapon",
            description = 'Keep the key pressed when equiping a weapon (one hand) to use it as a second weapon.',
            default = "u",
            argument = {
                type = "action",
                key = "EquipSecondWeapon"
        	},
		},
        
        {
            key = 'SecondWeaponUIX',
            renderer = 'number', 
            name = 'Second Weapon UI X size',
            description = 'The X size (in pixels) of the SecondWeapon UI.',
            default = '50',
        },
        
        {
            key = 'SecondWeaponUIY',
            renderer = 'number', 
            name = 'Second Weapon UI Y size',
            description = 'The X size (in pixels) of the SecondWeapon UI.',
            default = '50',
        },


   	},
}


-- ============================================================
-- Off-hand skill scaling (new in this build)
-- Scales the off-hand swing speed, damage, and fatigue cost as
-- a linear interpolation between the "novice" value (skill 0)
-- and the "master" value (skill 100), using the relevant
-- one-handed weapon skill of the left-hand weapon.
-- All values are applied only to the local player by default;
-- NPCs keep the original fixed mod behavior.
-- ============================================================
I.Settings.registerGroup {
    key = 'DualWieldingscaling',
    page = 'DualWieldingSettingsPage',
    l10n = 'DualWieldingSettings',
    name = 'Off-hand skill scaling',
    description = 'Scale off-hand swing speed, damage, and fatigue cost with the weapon skill of the left-hand weapon. Higher skill = more effective off-hand. Disable to restore the original fixed values.',
    permanentStorage = true,
    settings = {
        {
            key = 'EnableOffhandScaling',
            renderer = 'checkbox',
            name = 'Enable off-hand skill scaling',
            description = 'Master switch. When off, the off-hand reverts to the original mod behavior: half-speed swings, fixed light fatigue, full damage.',
            default = true,
        },
        {
            key = 'EnableOffhandSpeedScaling',
            renderer = 'checkbox',
            name = '... scale swing speed',
            description = 'Apply skill scaling to the off-hand animation speed.',
            default = true,
        },
        {
            key = 'EnableOffhandDamageScaling',
            renderer = 'checkbox',
            name = '... scale damage',
            description = 'Apply skill scaling to off-hand damage output.',
            default = true,
        },
        {
            key = 'EnableOffhandFatigueScaling',
            renderer = 'checkbox',
            name = '... scale fatigue cost',
            description = 'Apply skill scaling to off-hand fatigue cost. Novice users tire faster swinging the off-hand.',
            default = true,
        },
        {
            key = 'OffhandSpeedNovice',
            renderer = 'number',
            name = 'Speed multiplier at skill 0',
            description = 'Off-hand animation speed multiplier when the relevant weapon skill is 0. 1.0 = same as right-hand. Original mod behavior = 0.5.',
            default = 0.5,
            argument = { min = 0.10, max = 1.50 },
        },
        {
            key = 'OffhandSpeedMaster',
            renderer = 'number',
            name = 'Speed multiplier at skill 100',
            description = 'Off-hand animation speed multiplier when the relevant weapon skill is 100.',
            default = 1.0,
            argument = { min = 0.10, max = 1.50 },
        },
        {
            key = 'OffhandDamageNovice',
            renderer = 'number',
            name = 'Damage multiplier at skill 0',
            description = 'Damage multiplier on off-hand swings at skill 0. 1.0 = no penalty.',
            default = 0.6,
            argument = { min = 0.10, max = 2.00 },
        },
        {
            key = 'OffhandDamageMaster',
            renderer = 'number',
            name = 'Damage multiplier at skill 100',
            description = 'Damage multiplier on off-hand swings at skill 100.',
            default = 1.0,
            argument = { min = 0.10, max = 2.00 },
        },
        {
            key = 'OffhandFatigueNovice',
            renderer = 'number',
            name = 'Fatigue strength at skill 0',
            description = 'Effective attack strength used in the off-hand fatigue formula at skill 0. Higher = more tiring. Original mod behavior = 0.1 (always).',
            default = 0.5,
            argument = { min = 0.0, max = 2.00 },
        },
        {
            key = 'OffhandFatigueMaster',
            renderer = 'number',
            name = 'Fatigue strength at skill 100',
            description = 'Effective attack strength used in the off-hand fatigue formula at skill 100.',
            default = 0.1,
            argument = { min = 0.0, max = 2.00 },
        },
    },
}