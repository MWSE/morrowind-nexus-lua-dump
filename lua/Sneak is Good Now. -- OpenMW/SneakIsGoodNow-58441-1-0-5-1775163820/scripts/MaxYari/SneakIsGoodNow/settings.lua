local mp = "scripts/MaxYari/SneakIsGoodNow/"

local I = require('openmw.interfaces')
local input = require('openmw.input')

local SettingsHelper = require(mp .. "utils/settings_helper")


I.Settings.registerPage {
    key = 'SneakIsGoodNowPage',
    l10n = 'SneakIsGoodNow',
    name = 'Sneak! Sneak Is Good Now.',
    description = "The mod is active. Go sneak now.",
}
I.Settings.registerGroup {
    key = 'SettingsSneakIsGoodNow',
    page = 'SneakIsGoodNowPage',
    l10n = 'SneakIsGoodNow',
    name = 'Settings',    
    permanentStorage = true,
    settings = {
        {
            key = "MarkersAlpha",
            renderer = "number",
            default = 1,
            argument = {
                min = 0,
                max = 1
            },
            name = "Detection marker opacity"
        },
        {
            key = "WeaponBonus",
            renderer = "number",
            default = 0.5,
            argument = {
                min = 0,
                max = 1
            },
            name = "Weapon skill bonus while sneaking",
            description = "A percentile value (0.5 = 50%) that determines the bonus to weapon skill while sneaking."
        },
        {
            key = "DifficultyMultiplier",
            renderer = "number",
            default = 1.0,
            argument = {
                min = 0.1,
                max = 5.0
            },
            name = "Difficulty multiplier",
            description = "Multiplies enemy attentiveness. Higher values make enemies more attentive."
        }
    },
}

return {
    settings = SettingsHelper:new('SettingsSneakIsGoodNow')
}


