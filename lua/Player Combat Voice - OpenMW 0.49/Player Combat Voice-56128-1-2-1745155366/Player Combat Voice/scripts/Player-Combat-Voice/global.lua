-- global.lua (Modified for Enable/Disable and Trigger Chances, Marksman Settings)

local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsPlayerCombatVoice',
    page = 'PlayerCombatVoice',
    l10n = 'PlayerCombatVoice',
    name = 'Settings',
    permanentStorage = true, -- Ensures settings persist
    settings = {
        {
            key = 'EnableHitSounds',
            renderer = 'checkbox',
            name = 'Enable Hit Voice',
            default = true,
        },
        {
            key = 'HitChance',
            renderer = 'number',
            integer = true,
            name = 'Hit Sound Chance (%)',
            description = 'Chance (0-100) for a hit sound to play (default is 50)',
            min = 0,
            max = 100,
            default = 50,
        },
        {
            key = 'EnableAttackSounds',
            renderer = 'checkbox',
            name = 'Enable Attack Voice',
            default = true,
        },
        {
            key = 'AttackChance',
            renderer = 'number',
            integer = true,
            name = 'Attack Sound Chance (%)',
            description = 'Chance (0-100) for an attack sound to play (default is 100)',
            min = 0,
            max = 100,
            default = 100,
        },
        {
            key = 'EnableSpellCastSounds',
            renderer = 'checkbox',
            name = 'Enable Spellcast Voice',
            default = true,
        },
        {
            key = 'SpellCastChance',
            renderer = 'number',
            integer = true,
            name = 'Spellcast Sound Chance (%)',
            description = 'Chance (0-100) for a spell cast sound to play (default is 30)',
            min = 0,
            max = 100,
            default = 30,
        },
        {
            key = 'EnableMarksmanSounds',
            renderer = 'checkbox',
            name = 'Enable Voice for Ranged Attack',
            default = true,
        },
        {
            key = 'MarksmanChance',
            renderer = 'number',
            integer = true,
            name = 'Ranged Attack Sound Chance (%)',
            description = 'Chance (0-100) for a ranged attack sound to play (default is 30)',
            min = 0,
            max = 100,
            default = 30,
        },
        -- Consider adding other configurable values here later
        -- e.g., AttackCooldown, SpellCooldown, HitSoundChance etc.
    },
}