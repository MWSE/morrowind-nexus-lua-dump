local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local Settings = {}
Settings._SETTINGS_DB = {}

Settings.KEYS = {
    COMBAT_MIN_ENEMY_LEVEL = 'COMBAT_MIN_ENEMY_LEVEL',
    COMBAT_MIN_LEVEL_DIFFERENCE = 'COMBAT_MIN_LEVEL_DIFFERENCE',
    COMBAT_PLAY_COMBAT_MUSIC = 'COMBAT_PLAY_COMBAT_MUSIC',
    COMBAT_ENEMIES_IGNORE = 'COMBAT_ENEMIES_IGNORE',
    COMBAT_ENEMIES_IGNORE_RESPECT_LEVEL_DIFFERENCE = 'COMBAT_ENEMIES_IGNORE_RESPECT_LEVEL_DIFFERENCE',
    COMBAT_ENEMIES_ALWAYS = 'COMBAT_ENEMIES_ALWAYS',
    COMBAT_ENEMIES_INCLUDE = 'COMBAT_ENEMIES_INCLUDE',
    GENERAL_PLAY_EXPLORATION_MUSIC = 'GENERAL_PLAY_EXPLORATION_MUSIC',
    GENERAL_USE_DEFAULT_SOUNDBANK = 'GENERAL_USE_DEFAULT_SOUNDBANK'
}

Settings.PAGE = {
    key = 'Page_openmw_dynamic_music',
    l10n = 'Dynamic_Music',
    name = 'Dynamic Music',
    description = 'Dynamic Music Framework',
}

Settings.GROUPS = {
    GENERAL = {
        key = 'Settings_openmw_dynamic_music_1000_general',
        page = Settings.PAGE.key,
        l10n = 'Dynamic_Music',
        name = '1: General Settings',
        description = 'General Settings',
        permanentStorage = true
    },
    COMBAT = {
        key = 'Settings_openmw_dynamic_music_2000_combat',
        page = Settings.PAGE.key,
        l10n = 'Dynamic_Music',
        name = '2: Combat Settings',
        description = 'Combat related settings.',
        permanentStorage = true
    }
}

Settings.SETTINGS = {
    {
        key = Settings.KEYS.COMBAT_PLAY_COMBAT_MUSIC,
        group = Settings.GROUPS.COMBAT,
        renderer = 'checkbox',
        name = '1. Play Combat Music',
        description = 'Turns combat music on/off.',
        default = false,
    },
    {
        key = Settings.KEYS.COMBAT_MIN_ENEMY_LEVEL,
        group = Settings.GROUPS.COMBAT,
        renderer = 'number',
        name = '2. Min. Enemy Level',
        description =
        'Don\'t play combat music for enemies below this level.  Set to 0 to deactivate this setting. Needs activated DEFAULT soundbank to work in situations where no soundbank matches',
        default = 5,
    },
    {
        key = Settings.KEYS.COMBAT_MIN_LEVEL_DIFFERENCE,
        group = Settings.GROUPS.COMBAT,
        renderer = 'number',
        name = '3. Min. Level Difference',
        description =
        'Player must be at least x levels above the enemy. Otherwise combat music is still being played.',
        default = 1,
    },
    {
        key = Settings.KEYS.COMBAT_ENEMIES_IGNORE,
        group = Settings.GROUPS.COMBAT,
        renderer = 'textLine',
        name = '4. Ignore Enemies',
        description = 'Ignore these enemies and don\'t play combat music (comma separated actor Ids)',
        default = ''
    },
    {
        key = Settings.KEYS.COMBAT_ENEMIES_IGNORE_RESPECT_LEVEL_DIFFERENCE,
        group = Settings.GROUPS.COMBAT,
        renderer = 'checkbox',
        name = '4.1 Ignore Enemies - Respect Min. Level Difference',
        description = 'Only ignore the enemies if min. level difference is met',
        default = true,
    },
    {
        key = Settings.KEYS.COMBAT_ENEMIES_INCLUDE,
        group = Settings.GROUPS.COMBAT,
        renderer = 'textLine',
        name = '5. Include Enemies',
        description = 'Enemies that should always play combat music (comma separated actor Ids).',
        default = ''
    },
    {
        key = Settings.KEYS.GENERAL_USE_DEFAULT_SOUNDBANK,
        group = Settings.GROUPS.GENERAL,
        renderer = 'checkbox',
        name = 'Use DEFAULT Soundbank',
        description =
        'Uses the DEFAULT soundbank if no other soundbank matches. If you have custom tracks in your vanilla playlist they will be ignored and need to be added to the DEFAULT soundbank manually.',
        default = false,
    }
}

I.Settings.registerPage {
    key = Settings.PAGE.key,
    l10n = Settings.PAGE.l10n,
    name = Settings.PAGE.name,
    description = Settings.PAGE.description
}

for _, group in pairs(Settings.GROUPS) do
    local settings = {}
    for _, s in pairs(Settings.SETTINGS) do
        if s.group == group then
            local setting = {
                key = s.key,
                renderer = s.renderer,
                name = s.name,
                description = s.description,
                default = s.default
            }

            table.insert(settings, setting)
        end
    end

    I.Settings.registerGroup {
        key = group.key,
        page = Settings.PAGE.key,
        l10n = group.l10n,
        name = group.name,
        description = group.description,
        permanentStorage = true,
        settings = settings
    }

    local playerSection = storage.playerSection(group.key)
    for _, setting in pairs(settings) do
        Settings._SETTINGS_DB[setting.key] = setting
        setting._playerSection = playerSection
    end
end

function Settings.getValue(key)
    return Settings._SETTINGS_DB[key]._playerSection:get(key)
end

return Settings
