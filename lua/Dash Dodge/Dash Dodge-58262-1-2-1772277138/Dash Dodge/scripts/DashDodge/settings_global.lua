local interfaces = require('openmw.interfaces')

-- Default setting values
local isEnabled = true

-- Player settings
local buffSpeedMultiplierPlayer = 1.0
local buffDurationMultiplierPlayer = 1.0
local fatigueCostMultiplierPlayer = 1.0
local cooldownDurationMultiplierPlayer = 1.0
local enableEvasionEffectPlayer = true
local sfxVolumeMultiplierPlayer = 1.0

-- NPC settings
local enableDashNPC = true
local buffSpeedMultiplierNPC = 1.0
local buffDurationMultiplierNPC = 1.0
local fatigueCostMultiplierNPC = 1.0
local cooldownDurationMultiplierNPC = 1.0
local enableEvasionEffectNPC = true
local sfxVolumeMultiplierNPC = 1.0

-- Helper functions
local function getBoolSetting(settingKey, settingDefault)
    return {
        key = settingKey,
        renderer = 'checkbox',
        name = settingKey .. '_name',
        description = settingKey .. '_desc',
        default = settingDefault,
    }
end

local function getNumberSetting(settingKey, settingDefault, isSettingInt, settingMin, settingMax)
    return {
        key = settingKey,
        renderer = 'number',
        name = settingKey .. '_name',
        description = settingKey .. '_desc',
        default = settingDefault,
        argument = {
            integer = isSettingInt,
            min = settingMin,
            max = settingMax,
        },
    }
end

interfaces.Settings.registerGroup({
    key = 'Settings_DashDodge_General',
    page = 'DashDodge',
    l10n = 'DashDodge',
    name = 'General',
    permanentStorage = true,
    settings = {
        getBoolSetting('isEnabled', isEnabled),
    },
})

-- Player settings page
interfaces.Settings.registerGroup({
    key = 'Settings_DashDodge_Player',
    page = 'DashDodge',
    l10n = 'DashDodge',
    name = 'Player',
    permanentStorage = true,
    settings = {
        getNumberSetting('buffSpeedMultiplier_player', buffSpeedMultiplierPlayer, false, 0.1, 2.0),
        getNumberSetting('buffDurationMultiplier_player', buffDurationMultiplierPlayer, false, 0.1, 2.0),
        getNumberSetting('fatigueCostMultiplier_player', fatigueCostMultiplierPlayer, false, 0.0, 2.0),
        getNumberSetting('cooldownDurationMultiplier_player', cooldownDurationMultiplierPlayer, false, 0.5, 1.5),
        getBoolSetting('enableEvasionEffect_player', enableEvasionEffectPlayer),
        getNumberSetting('sfxVolumeMultiplier_player', sfxVolumeMultiplierPlayer, false, 0.0, 2.0),
    },
})

-- NPC settings page
interfaces.Settings.registerGroup({
    key = 'Settings_DashDodge_NPC',
    page = 'DashDodge',
    l10n = 'DashDodge',
    name = 'NPC',
    permanentStorage = true,
    settings = {
        getBoolSetting('enableDash_npc', enableDashNPC),
        getNumberSetting('buffSpeedMultiplier_npc', buffSpeedMultiplierNPC, false, 0.1, 2.0),
        getNumberSetting('buffDurationMultiplier_npc', buffDurationMultiplierNPC, false, 0.1, 2.0),
        getNumberSetting('fatigueCostMultiplier_npc', fatigueCostMultiplierNPC, false, 0.0, 2.0),
        getNumberSetting('cooldownDurationMultiplier_npc', cooldownDurationMultiplierNPC, false, 0.5, 1.5),
        getBoolSetting('enableEvasionEffect_npc', enableEvasionEffectNPC),
        getNumberSetting('sfxVolumeMultiplier_npc', sfxVolumeMultiplierNPC, false, 0.0, 2.0),
    },
})