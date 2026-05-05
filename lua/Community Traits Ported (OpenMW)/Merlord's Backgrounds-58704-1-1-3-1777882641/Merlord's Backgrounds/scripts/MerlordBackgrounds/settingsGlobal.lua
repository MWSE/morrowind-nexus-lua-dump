local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = 'SettingsMerlordBackgrounds_framed',
    page = 'MerlordBackgrounds',
    l10n = 'MerlordBackgrounds',
    name = 'framed_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'minBounty',
            name = 'minBounty_name',
            renderer = 'number',
            default = 20,
        },
        {
            key = 'maxBounty',
            name = 'maxBounty_name',
            renderer = 'number',
            default = 120,
        },
        {
            key = 'bountyLimit',
            name = 'bountyLimit_name',
            description = 'bountyLimit_desc',
            renderer = 'number',
            default = 300,
        },
        {
            key = 'minInterval',
            name = 'minInterval_name',
            renderer = 'number',
            default = 2,
        },
        {
            key = 'maxInterval',
            name = 'maxInterval_name',
            renderer = 'number',
            default = 6,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsMerlordBackgrounds_ratKing',
    page = 'MerlordBackgrounds',
    l10n = 'MerlordBackgrounds',
    name = 'ratKing_groupName',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'spawnCooldown',
            name = 'spawnCooldown_name',
            renderer = 'number',
            default = 12,
        },
        {
            key = 'spawnChance',
            name = 'spawnChance_name',
            description = "spawnChance_desc",
            renderer = 'number',
            default = 10,
        },
        {
            key = 'minSpawn',
            name = 'minSpawn_name',
            renderer = 'number',
            default = 3,
        },
        {
            key = 'maxSpawn',
            name = 'maxSpawn_name',
            renderer = 'number',
            default = 5,
        },
        {
            key = 'hordeLimit',
            name = 'hordeLimit_name',
            description = 'hordeLimit_desc',
            renderer = 'number',
            default = 15,
            min = 0,
        },
    }
}
