local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = 'SettingsLuckyStrike_chance',
    page = 'LuckyStrike',
    l10n = 'LuckyStrike',
    name = 'chance_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'formula',
            name = 'formula_name',
            description = 'formula_description',
            renderer = 'select',
            argument = {
                l10n = "LuckyStrike",
                items = {
                    "Linear",
                    "Classic",
                },
            },
            default = "Linear",
        },
        {
            key = 'luckMult',
            name = 'luckMult_name',
            renderer = 'number',
            integer = false,
            default = .1,
            min = 0,
        },
        {
            key = 'backstabBonus',
            name = 'backstabBonus_name',
            renderer = 'number',
            integer = false,
            default = 5,
            min = 0,
        },
        {
            key = 'actorFov',
            name = 'actorFov_name',
            renderer = 'number',
            integer = false,
            default = 220,
            min = 0,
            max = 360
        },
        {
            key = 'baseChance',
            name = 'baseChance_name',
            renderer = 'number',
            integer = false,
            default = 5,
            min = 0,
        },
        {
            key = 'minChance',
            name = 'minChance_name',
            renderer = 'number',
            integer = false,
            default = .01,
            min = 0,
            max = 1,
        },
        {
            key = 'maxChance',
            name = 'maxChance_name',
            renderer = 'number',
            integer = false,
            default = .15,
            min = 0,
            max = 1,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsLuckyStrike_damage',
    page = 'LuckyStrike',
    l10n = 'LuckyStrike',
    name = 'damage_groupName',
    description = 'damage_groupDescription',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'weaponSkillMult',
            name = 'weaponSkillMult_name',
            description = 'weaponSkillMult_description',
            renderer = 'number',
            integer = false,
            default = .02,
            min = 0,
        },
        {
            key = 'weaponSpeedMult',
            name = 'weaponSpeedMult_name',
            description = 'weaponSpeedMult_description',
            renderer = 'number',
            integer = false,
            default = 0,
            min = 0,
        },
        {
            key = 'baseHpCritDmg',
            name = 'baseHpCritDmg_name',
            renderer = 'number',
            integer = false,
            default = 1.5,
            min = 0,
        },
        {
            key = 'baseFatCritDmg',
            name = 'baseFatCritDmg_name',
            renderer = 'number',
            integer = false,
            default = 1.5,
            min = 0,
        },
        {
            key = 'baseMagCritDmg',
            name = 'baseMagCritDmg_name',
            renderer = 'number',
            integer = false,
            default = 1.5,
            min = 0,
        },
        {
            key = 'minMult',
            name = 'minMult_name',
            renderer = 'number',
            integer = false,
            default = 1,
            min = 0,
        },
        {
            key = 'maxMult',
            name = 'maxMult_name',
            renderer = 'number',
            integer = false,
            default = 4,
            min = 0,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsLuckyStrike_onCrit',
    page = 'LuckyStrike',
    l10n = 'LuckyStrike',
    name = 'onCrit_groupName',
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'playSound',
            name = 'playSound_name',
            renderer = 'checkbox',
            default = true,
        },
        {
            key = 'showMessage',
            name = 'showMessage_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsLuckyStrike_debug',
    page = 'LuckyStrike',
    l10n = 'LuckyStrike',
    name = 'debug_groupName',
    permanentStorage = true,
    order = 100,
    settings = {
        {
            key = 'log',
            name = 'log_name',
            renderer = 'checkbox',
            default = false,
        },
    }
}
