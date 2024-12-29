local interfaces = require('openmw.interfaces')
local util = require('openmw.util')
local v2 = util.vector2

interfaces.Settings.registerPage { -- Modernized UI
    key = 'ModernizedUI',
	l10n = 'ModernizedUI',
    name = 'Modernized HUD',
    description = 'Version 0.6\n\n - by Xander',
}

interfaces.Settings.registerGroup { -- Smooth Transitions
    key = 'MUISmoothTransitions',
	l10n = 'ModernizedUI',
    page = 'ModernizedUI',
    name = 'Smooth Transitions',
	order = 0,
	-- description = 'Integer values are not possible to input at the moment, which is why the number inputs had to be scaled up by a factor of 10.',
    permanentStorage = true,
    settings = {
		{
			key = 'SmoothTransitions',
			renderer = 'checkbox',
			name = 'Smooth Transitions',
			description = 'When toggled on, the bars will smoothly transition. This effect may be prone to unnatural behaviour during lagspikes and when switching cells. It is recommended to turn this off if you experience any issues. May also make the restoration overlay on the bars not quite line up when moving quickly.',
			default = true,
		},
		{
			key = 'LerpSpeed',
			renderer = 'number',
			name = 'Smoothness & Drain Speed',
			description = 'This value determines the "smoothness" and how fast the bars will drain. The default value is 32.',
			default = 32,
		},
    },
}

interfaces.Settings.registerGroup { -- Yellow Remainder
    key = 'MUIYellowRemainder',
	l10n = 'ModernizedUI',
    page = 'ModernizedUI',
    name = 'Yellow Remainder',
	order = 1,
	-- description = 'Configuration of the yellow remainder.',
    permanentStorage = true,
    settings = {
        {
            key = 'YellowRemainder',
            renderer = 'checkbox',
            name = 'Yellow Remainder',
            description = 'This feature is an indicator of recently spent health, fatigue, and magicka. When toggled on, a yellow segment will lag behind the current values, providing a visual representation of recent spendings.',
            default = true,
        },
		{
			key = 'YellowRemainderTimer',
			renderer = 'number',
			name = 'Timer',
			description = 'This value determines how long the yellow segment will remain visible after the player has spent health, fatigue, or magicka. The default value is 10, which equals 1 second.',
			default = 10,
		},
		{
			key = 'YellowRemainderDrainSpeed',
			renderer = 'number',
			name = 'Speed',
			description = 'This value determines how fast the yellow segment will drain. The default value is 32.',
			default = 32,
		},
    },
}

interfaces.Settings.registerGroup { -- Enemy healthbar
    key = 'MUIEnemy',
	l10n = 'ModernizedUI',
    page = 'ModernizedUI',
    name = 'Enemy Healthbar',
	order = 2,
	--description = 'Enemy Healthbar.',
    permanentStorage = true,
    settings = {
		{
			key = 'EnableEnemyHealthbar',
			renderer = 'checkbox',
			name = 'Enable Enemy Healthbar',
			description = 'Displays the health of the enemy in combat.',
			default = true,
		},
        {
            key = 'ShowEnemyLevels',
            renderer = 'checkbox',
            name = 'Show Enemy Levels',
            description = 'Displays the level of the enemy in combat.',
            default = true,
        },
		{
			key = 'ShowEnemyClass',
			renderer = 'checkbox',
			name = 'Show Enemy Class',
			description = 'Displays the class of the enemy in combat.',
			default = false,
		},
		{
			key = 'PositionAnchor',
			renderer = 'checkbox',
			name = 'Anchor Healthbar to Enemy',
			description = "When toggled on, the healthbar will be anchored right over your target's head. Otherwise the healthbar will stay put on the screen.",
			default = false,
		},
		{
			key = 'TargetWithCrosshair',
			renderer = 'checkbox',
			name = 'Target Enemy with Crosshair',
			description = "When toggled on, enemies are targeted using the crosshair. Otherwise, it's lika vanilla Morrowind, where you have to damage the enemy to target it.",
			default = false,
		},
		{
			key = 'VerticalOffset',
			renderer = 'number',
			name = 'Vertical Offset',
			description = 'Negative values move the healthbar up, positive values move it down. The default value is 80 / 100.',
			default = 80,
		},
    },
}

interfaces.Settings.registerGroup { -- Miscellaneous
    key = 'MUIMisc',
	l10n = 'ModernizedUI',
    page = 'ModernizedUI',
    name = 'Miscellaneous',
	order = 3,
	description = 'General configuration.',
    permanentStorage = true,
    settings = {
		{
			key = 'ShowValues',
			renderer = 'checkbox',
			name = 'Show Stat Values',
			description = 'Displays the current values of health, fatigue, and magicka.',
			default = false,
		},
        {
            key = 'FlashWhenLow',
            renderer = 'checkbox',
            name = 'Flash When Low',
            description = 'The background will flash red when the player has low health, fatigue, or magicka. Only applies in combat stance (when holding weapon or spell).',
            default = true,
        },
		{
			key = 'Position',
			name = 'Place in upper left corner',
			renderer = 'checkbox',
			description = 'Places the bars in the upper left corner of the screen.',
			default = false,
		},
		{
			key = 'LengthMultiplier',
			name = 'Length Multiplier',
			renderer = 'number',
			description = 'Adjust the length of the bars.\nThe default value is 10, meaning that a value of 5 would correspond to 50% of the default length.',
			default = 10,
			integer = false,
			min = 1
		},
		{
			key = 'LengthCap',
			name = 'Length Cap',
			renderer = 'number',
			description = 'This value determines the maximum length of the bars. Takes priority over Length Multiplier. \nThe default value is 5000 (essentially uncapped).',
			default = 5000,
			integer = true,
			min = 1
		},
    },
}

interfaces.Settings.registerGroup { -- Experimental
    key = 'MUIExperimental',
	l10n = 'ModernizedUI',
    page = 'ModernizedUI',
    name = 'Experimental',
	order = 4,
	description = 'WARNING! Experimental features mainly for testing.', 
    permanentStorage = true,
    settings = {
		{
			key = 'SegmentedNotches',
			renderer = 'checkbox',
			name = 'Segmented Notches - OpenMW 0.49 only!',
			description = "Alternative to Stat Values. When toggled on, the bars will have evenly spaced notches for 50 and 100 units of the respective stat.\n\nImportant! Does not update/refresh changed values in max HP/FP/MP properly when used in tandem with Length Cap, *unless* you either: \n1. Temporarily change the Length Cap to another value and then back, OR \n2. Manually reload the scripts.\n\nWorks absolutely fine uncapped, and in tandem with Length Multiplier.",
			default = false,
		},
    },
}