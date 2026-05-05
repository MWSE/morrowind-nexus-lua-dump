-- ============================================================
-- DisarmTrap - LOAD Script (v2.1 - Clean Record Order)
-- ============================================================

local content = require('openmw.content')

-- = [1] CUSTOM EFFECTS DEFINITIONS = --

-- Disarm (Alteration)
content.magicEffects.records.disarmtrap = {
    template     = content.magicEffects.records['open'],
    name         = 'Disarm Trap',
    school       = 'alteration',
    icon         = 'icons\\s\\disarmtrap.tga',
    description  = 'Disarms trapped objects with alteration forces.',
    hasMagnitude = true,
    hasArea      = false,
    hasDuration  = false,
    harmful      = false,
    hitStatic    = "VFX_AlterationHit",
    allowsEnchanting = true,
    allowsSpellmaking = true,
}

-- Absorb Purge (Mysticism)
content.magicEffects.records.absorbtrap = {
    template     = content.magicEffects.records['soultrap'],
    name         = 'Absorb Trap',
    school       = 'mysticism',
    icon         = 'icons\\s\\absorbtrap.tga',
    description  = 'Purges trapped objects. If successful, restores magicka based on the trap magnitude. If failed, it will trigger the trap.',
    hasMagnitude = true,
    hasArea      = false,
    hasDuration  = false,
    harmful      = false,
    hitStatic    = "VFX_AlterationHit",
    allowsEnchanting = true,
    allowsSpellmaking = true,
}

-- Detect Trap (Mysticism)
content.magicEffects.records.detecttrap = {
    template     = content.magicEffects.records['detectanimal'],
    name         = 'Trap Reveal',
    school       = 'mysticism',
    icon         = 'icons\\s\\detecttrapmyst.tga', -- Placeholder icon
    description  = 'Detects a trapped object and reveals its difficulty.',
    hasMagnitude = false,
    hasArea      = false,
    hasDuration  = false,
    harmful      = false,
    allowsEnchanting = true,
    allowsSpellmaking = false,
}

-- Detect Trap (Alteration)
content.magicEffects.records.detecttrap_alt = {
    template     = content.magicEffects.records['detectanimal'],
    name         = 'Trap Examine',
    school       = 'alteration',
    icon         = 'icons\\s\\detecttrapalt.tga', -- Placeholder icon
    description  = 'Detects a trapped object and reveals its difficulty level as a number.',
    hasMagnitude = false,
    hasArea      = false,
    hasDuration  = false,
    harmful      = false,
    allowsEnchanting = true,
    allowsSpellmaking = false,
}

-- Custom Restoration Effects (Mysticism Visuals)
content.magicEffects.records.trap_abs_mg = {
    template     = content.magicEffects.records['restoremagicka'],
    name         = 'Absorb Magicka',
    school       = 'mysticism',
    icon         = 'icons\\s\\Tx_S_Ab_Magic.tga',
    particle     = 'vfx_myst_flare01.tga',
    description  = 'Absorbs trap magicka to restore Magicka over 5 seconds.',
    hasMagnitude = true,
    hasDuration  = true,
    harmful      = false,
    hitStatic    = "VFX_MysticismHit",
    hitSound     = "mysticism hit",
}

-- = [2] SPELL RECORDS = --

-- Basic Disarm
content.spells.records.disarmtrap_spell = {
    name       = 'Trap Disarm',
    type       = content.spells.TYPE.Spell,
    cost       = 9,
    isAutocalc = false,
    effects    = {
        {
            id           = 'disarmtrap',
            range        = content.RANGE.Touch,
            magnitudeMin = 20,
            magnitudeMax = 20,
        }
    }
}

-- Advanced Absorb
content.spells.records.absorbtrap_spell = {
    name       = 'Trap Absorb',
    type       = content.spells.TYPE.Spell,
    cost       = 18,
    isAutocalc = false,
    effects    = {
        {
            id           = 'absorbtrap',
            range        = content.RANGE.Touch,
            magnitudeMin = 20,
            magnitudeMax = 20,
        },
    }
}

-- Detect Trap
content.spells.records.detecttrap_spell = {
    name       = 'Trap Reveal',
    type       = content.spells.TYPE.Spell,
    cost       = 6,
    isAutocalc = false,
    effects    = {
        {
            id           = 'detecttrap',
            range        = content.RANGE.Touch,
            magnitudeMin = 1,
            magnitudeMax = 1    ,
        },
    }
}

-- Detect Trap (Alteration)
content.spells.records.detecttrap_alt_spell = {
    name       = 'Trap Examine',
    type       = content.spells.TYPE.Spell,
    cost       = 3,
    isAutocalc = false,
    effects    = {
        {
            id           = 'detecttrap_alt',
            range        = content.RANGE.Touch,
            magnitudeMin = 1,
            magnitudeMax = 1    ,
        },
    }
}

-- Internal Restoration Mechanics (Not for player inventory, but for Global use)

content.spells.records.disarmtrap_abs_magicka = {
    name       = 'Absorb Magicka (Trap)',
    type       = content.spells.TYPE.Spell,
    cost       = 0,
    isAutocalc = false,
    effects    = {
        {
            id           = 'trap_abs_mg',
            range        = content.RANGE.Self,
            magnitudeMin = 5,
            magnitudeMax = 5,
            duration     = 5,
        }
    }
}

-- print("[DisarmTrap] Content records (v2.1) registered successfully.")
