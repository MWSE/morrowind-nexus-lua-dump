local I = require("openmw.interfaces")

I.Settings.registerGroup {
    key = 'SettingsBullseye_playerStats',
    page = 'Bullseye',
    l10n = 'Bullseye',
    name = 'playerStats_groupName',
    description = 'playerStats_groupDesc',
    permanentStorage = true,
    order  = 1,
    settings = {
        {
            key = 'movementDebuff',
            name = 'movementDebuff_name',
            description = 'movementDebuff_desc',
            renderer = 'number',
            default = 15,
        },
        {
            key = 'sneakBuff',
            name = 'sneakBuff_name',
            description = 'sneakBuff_desc',
            renderer = 'number',
            default = 10,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBullseye_fatigue',
    page = 'Bullseye',
    l10n = 'Bullseye',
    name = 'fatigue_groupName',
    description = 'fatigue_groupDesc',
    permanentStorage = true,
    order  = 2,
    settings = {
        {
            key = 'bowDrawFatigueDrainRate',
            name = 'bowDrawFatigueDrainRate_name',
            description = 'bowDrawFatigueDrainRate_desc',
            renderer = 'number',
            default = 10,
            min = 0,
        },
        {
            key = 'bowFatigueDrainDelay',
            name = 'bowFatigueDrainDelay_name',
            description = 'bowFatigueDrainDelay_desc',
            renderer = 'number',
            default = 1,
            min = 0,
        },
        {
            key = 'bowHoldFatigueDrainRate',
            name = 'bowHoldFatigueDrainRate_name',
            description = 'bowHoldFatigueDrainRate_desc',
            renderer = 'number',
            default = 20,
            min = 0,
        },
        {
            key = 'crossbowFatigueDrainRate',
            name = 'crossbowFatigueDrainRate_name',
            description = 'crossbowFatigueDrainRate_desc',
            renderer = 'number',
            default = 15,
            min = 0,
        },
        {
            key = 'thrownFatigueDrainRate',
            name = 'thrownFatigueDrainRate_name',
            description = 'thrownFatigueDrainRate_desc',
            renderer = 'number',
            default = 10,
            min = 0,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBullseye_damageMult',
    page = 'Bullseye',
    l10n = 'Bullseye',
    name = 'damageMult_groupName',
    description = "damageMult_groupDesc",
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'baseMult',
            name = 'baseMult_name',
            renderer = 'number',
            default = 1,
        },
        {
            key = 'defaultDmgMinDistance',
            name = 'defaultDmgMinDistance_name',
            description = "defaultDmgMinDistance_desc",
            renderer = 'number',
            default = 800,
            min = 0,
        },
        {
            key = 'defaultDmgMaxDistance',
            name = 'defaultDmgMaxDistance_name',
            description = "defaultDmgMaxDistance_desc",
            renderer = 'number',
            default = 1500,
            min = 0,
        },
        {
            key = 'distanceDamageFalloff',
            name = 'distanceDamageFalloff_name',
            description = "distanceDamageFalloff_desc",
            renderer = 'number',
            default = 1,
            min = 0,
        },
        {
            key = 'distanceDamageBuildup',
            name = 'distanceDamageBuildup_name',
            description = "distanceDamageBuildup_desc",
            renderer = 'number',
            default = .25,
            min = 0,
        },
        {
            key  = 'headshotMultiplier',
            name = 'headshotMultiplier_name',
            description = "headshotMultiplier_desc",
            renderer = 'number',
            default = .5,
            min = 0,
        },
        {
            key  = 'maxTotalMult',
            name = 'maxTotalMult_name',
            renderer = 'number',
            default = 3,
            min = 0,
        },
        {
            key  = 'minTotalMult',
            name = 'minTotalMult_name',
            renderer = 'number',
            default = .25,
            min = 0,
        },
        {
            key = 'headshotSFXVolume',
            name = 'headshotSFXVolume_name',
            description = "headshotSFXVolume_desc",
            renderer = 'number',
            default = 1,
            min = 0,
        },
        {
            key = 'showMultMessage',
            name = 'showMultMessage_name',
            renderer = 'checkbox',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBullseye_ammoRetrieval',
    page = 'Bullseye',
    l10n = 'Bullseye',
    name = 'ammoRetrieval_groupName',
    description = "ammoRetrieval_groupDesc",
    permanentStorage = true,
    order = 4,
    settings = {
        {
            key  = 'ammoRetrievalChance',
            name = 'ammoRetrievalChance_name',
            renderer = 'number',
            default = .25,
            min = 0,
            max = 1,
        },
        {
            key  = 'thrownRetrievalChance',
            name = 'thrownRetrievalChance_name',
            renderer = 'number',
            default = .75,
            min = 0,
            max = 1,
        },
        {
            key = 'retrieveEnchantedProjectiles',
            name = 'retrieveEnchantedProjectiles_name',
            description = "retrieveEnchantedProjectiles_desc",
            renderer = 'checkbox',
            default = false,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsBullseye_nearHit',
    page = 'Bullseye',
    l10n = 'Bullseye',
    name = 'nearHit_groupName',
    description = "nearHit_groupDesc",
    permanentStorage = true,
    order = 5,
    settings = {
        {
            key = 'nearHitAggroEnabled',
            name = 'nearHitAggroEnabled_name',
            description = "nearHitAggroEnabled_desc",
            renderer = 'checkbox',
            default = true,
        },
        {
            key  = 'aggroDistance',
            name = 'aggroDistance_name',
            description = "aggroDistance_desc",
            renderer = 'number',
            default = 500,
            min = 0,
        },
    }
}
