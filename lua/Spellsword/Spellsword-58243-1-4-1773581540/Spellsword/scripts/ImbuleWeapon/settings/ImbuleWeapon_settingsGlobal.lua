local storage = require('openmw.storage')
local I = require('openmw.interfaces')

I.Settings.registerGroup ({
    key = 'SettingsImbuleWeapon',
    page = 'ImbuleWeapon',
    l10n = 'ImbuleWeapon',
    name = 'Main settings',
    description = 'Select casting method.\nFor both methods you need a chosen effect (spell absorption by default) on self to count as imbule spell.',
    permanentStorage = false,
    settings = {
        
        {
            key = 'Trigger',
            renderer = 'textLine',
            name = 'Trigger',
            description = 'Trigger effect that needs to be in the spell to turn it into imbue spell. The effect has to be on self. It should not have any spaces (for example: absorbattribute).',
            
            default = "spellabsorption",
        },
        
        {
            key = 'CastMethod',
            renderer = 'select',
            argument = {l10n="CastMethod",items = {"Charges","Active"}},
            name = 'Casting method',
            description = 'Charges - casting imbule spell will enchant a blade with varying amount of charges based on spell absorbtion min/max magnitude.\n\nActive - casting a spell enchants the weapon, draining magicka with each hit. Casting costs mana but first hit is free.',
            
            default = "Charges",
        },
        
        {
            key = 'SpellStacking',
            renderer = 'checkbox',
            name = 'Spell stacking',
            description = 'For Charge cast method only. Casting the same spell multiple times will increase the charges. When turned off each imbule spell will override current one.',
            
            default = false,
        },
        
        {
            key = 'IgnoreChance',
            renderer = 'checkbox',
            name = 'Ignore spell casting chance',
            description = 'For Active cast method only. If turned on then spells imbuled on weapon will always succeed.\nIf off, casting chance is included, just like in normal spell casting.',
            
            default = false,
        },
        
        {
            key = 'IgnoreChanceSkillGain',
            renderer = 'checkbox',
            name = 'Skill gain while ignoring spell casting chance',
            description = 'When false caster does not gain skill progress while Ignore spell casting chance is on.',
            
            default = false,
        },
        
        {
            key = 'ElementalBuff',
            renderer = 'checkbox',
            name = 'Elemental attack synergies',
            description = 'Buffs damage slightly when using elemental damage with different attack types.\nFire - Slash\nShock - Chop\nIce - Thrust',
            
            default = true,
        },
        
        {
            key = 'ElementalBuffAmount',
            renderer = 'number',
            name = 'Elemental buff amount',
            description = 'Damage modifier for elemental synergies. Raises damage by set amount.',
            
            default = 0.15,
        },
        
        {
            key = 'AmbientSound',
            renderer = 'checkbox',
            name = 'Imbued weapon ambient sound',
            description = 'Adds a hum when wielding imbued weapon.',
            
            default = true,
        },
        
        {
            key = 'AmbientSoundVolume',
            renderer = 'number',
            name = 'Imbued weapon ambient sound volume',
            description = 'Determines how loud is the imbued weapon ambient sound.',
            
            default = 0.3,
        },
    }
})