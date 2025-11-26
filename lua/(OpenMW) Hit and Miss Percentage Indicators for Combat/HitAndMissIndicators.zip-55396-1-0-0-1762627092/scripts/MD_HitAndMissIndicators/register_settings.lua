local util = require('openmw.util')
local I = require('openmw.interfaces')
local Options = require('scripts.MD_HitAndMissIndicators.lib.options')

I.Settings.registerPage {
    key = Options.MOD_SETTINGS_ID,
    l10n = Options.MOD_SETTINGS_ID,
    name = 'Hit and Miss Indicators',
    description = 'Enabling hit & miss indicators to provide players feedback for when a swing hits/misses and the damage/odds of the swing'
}
I.Settings.registerGroup {
    key = Options.MISS_INDICATOR_SECTION_KEY,
    page = Options.MOD_SETTINGS_ID,
    l10n = Options.MOD_SETTINGS_ID,
    name = 'Miss Indicator',
    permanentStorage = false,
    settings = {
        {
            key = 'ENABLED',
            renderer = 'checkbox',
            name = 'Enabled',
            default = true
        },

        {
            key = 'COLOR',
            renderer = 'color',
            name = 'Color',
            default = util.color.hex("ffffff")
        },
        {
            key = 'TEXT_SIZE',
            renderer = 'number',
            name = 'Text Size',
            default = 18
        },
        {
            key = 'DURATION',
            renderer = 'number',
            name = 'Duration',
            default = 1.0
        },
        {
            key = 'FLOAT_SPEED',
            renderer = 'number',
            name = 'Speed',
            default = 0.1
        }
    }
}
I.Settings.registerGroup {
    key = Options.HIT_INDICATOR_SECTION_KEY,
    page = Options.MOD_SETTINGS_ID,
    l10n = Options.MOD_SETTINGS_ID,
    name = 'Hit Indicator',
    permanentStorage = false,
    settings = {
        {
            key = 'ENABLED',
            renderer = 'checkbox',
            name = 'Enabled',
            default = true
        },

        {
            key = 'COLOR',
            renderer = 'color',
            name = 'Color',
            default = util.color.hex("ff334c")
        },
        {
            key = 'TEXT_SIZE',
            renderer = 'number',
            name = 'Text Size',
            default = 18
        },
        {
            key = 'DURATION',
            renderer = 'number',
            name = 'Duration',
            default = 1.0
        },
        {
            key = 'FLOAT_SPEED',
            renderer = 'number',
            name = 'Speed',
            default = 0.1
        }
    }
}

I.Settings.registerGroup {
    key = Options.PUNCH_INDICATOR_SECTION_KEY,
    page = Options.MOD_SETTINGS_ID,
    l10n = Options.MOD_SETTINGS_ID,
    name = 'Punch Indicator',
    permanentStorage = false,
    settings = {
        {
            key = 'ENABLED',
            renderer = 'checkbox',
            name = 'Enabled',
            default = true
        },

        {
            key = 'COLOR',
            renderer = 'color',
            name = 'Color',
            default = util.color.hex("33cc4c")
        },
        {
            key = 'TEXT_SIZE',
            renderer = 'number',
            name = 'Text Size',
            default = 18
        },
        {
            key = 'DURATION',
            renderer = 'number',
            name = 'Duration',
            default = 1.0
        },
        {
            key = 'FLOAT_SPEED',
            renderer = 'number',
            name = 'Speed',
            default = 0.1
        }
    }
}
