local mp = "scripts/MaxYari/animated_lanterns/"

local I = require('openmw.interfaces')

local SettingsHelper = require(mp .. "utils/settings_helper")

I.Settings.registerGroup {
    key = 'SettingsAnimatedLanterns',
    page = 'AnimatedLanternsPage',
    l10n = 'AnimatedLanterns',
    name = 'Settings',    
    permanentStorage = true,
    settings = {
        {
            key = "StormWindMult",
            renderer = "number",
            default = 1,
            argument = {
                min = 0,
                max = 10
            },
            name = "Stormy weather wind strength multiplier"
        },
        {
            key = "CalmWindMult",
            renderer = "number",
            default = 1,
            argument = {
                min = 0,
                max = 10
            },
            name = "Calm weather wind strength multiplier"
        },
        {
            key = "InteriorWindMult",
            renderer = "number",
            default = 1,
            argument = {
                min = 0,
                max = 10
            },
            name = "Interior wind strength multiplier"
        }
    }
}

return {
    settings = SettingsHelper:new('SettingsAnimatedLanterns')
}


