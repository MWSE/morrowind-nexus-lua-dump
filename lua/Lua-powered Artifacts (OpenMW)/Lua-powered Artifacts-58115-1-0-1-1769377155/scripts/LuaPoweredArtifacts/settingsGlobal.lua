local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsLuaPoweredArtifacts_razor',
    page = 'LuaPoweredArtifacts',
    l10n = 'LuaPoweredArtifacts',
    name = 'razor_name',
    description = "razor_desc",
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'enabled',
            name = 'enabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'preset',
            name = 'preset_name',
            description = 'preset_desc',
            renderer = 'select',
            argument = {
                l10n = "LuaPoweredArtifacts",
                items = {
                    "Oblivion",
                    "Skyrim",
                    "Custom",
                },
            },
            default = "Custom"
        },
        {
            key = 'baseChance',
            name = 'baseChance_name',
            description = 'baseChance_desc',
            renderer = 'number',
            integer = false,
            default = 1,
        },
        {
            key = 'luckModifier',
            name = 'luckModifier_name',
            description = 'luckModifier_desc',
            renderer = 'number',
            integer = false,
            default = 0.05,
        },
        {
            key = 'counterRollEnabled',
            name = 'counterRollEnabled_name',
            description = 'counterRollEnabled_desc',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'counterRollModifier',
            name = 'counterRollModifier_name',
            renderer = 'number',
            integer = false,
            default = 0.01,
        },
        {
            key = 'razorPlaySFX',
            name = 'razorPlaySFX_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'razorShowMessage',
            name = 'razorShowMessage_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsLuaPoweredArtifacts_umbra',
    page = 'LuaPoweredArtifacts',
    l10n = 'LuaPoweredArtifacts',
    name = 'umbra_name',
    description = "umbra_desc",
    order = 2,
    permanentStorage = true,
    settings = {
        {
            key = 'enabled',
            name = 'enabled_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsLuaPoweredArtifacts_scourge',
    page = 'LuaPoweredArtifacts',
    l10n = 'LuaPoweredArtifacts',
    name = 'scourge_name',
    description = "scourge_desc",
    order = 3,
    permanentStorage = true,
    settings = {
        {
            key = 'enabled',
            name = 'enabled_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'normalDaedraDmgModifier',
            name = 'normalDaedraDmgModifier_name',
            description = 'normalDaedraDmgModifier_desc',
            renderer = 'number',
            integer = false,
            default = 2,
            min = -1,
        },
        {
            key = 'summonedDaedraDmgModifier',
            name = 'summonedDaedraDmgModifier_name',
            description = 'summonedDaedraDmgModifier_desc',
            renderer = 'number',
            integer = false,
            default = -1,
            min = -1,
        },
        {
            key = 'instakillPreventsSoultrap',
            name = 'instakillPreventsSoultrap_name',
            description = "instakillPreventsSoultrap_desc",
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'scourgePlaySFX',
            name = 'scourgePlaySFX_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsLuaPoweredArtifacts_debug',
    page = 'LuaPoweredArtifacts',
    l10n = 'LuaPoweredArtifacts',
    name = 'debug_name',
    order = 4,
    permanentStorage = true,
    settings = {
        {
            key = 'log',
            name = 'log_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}
