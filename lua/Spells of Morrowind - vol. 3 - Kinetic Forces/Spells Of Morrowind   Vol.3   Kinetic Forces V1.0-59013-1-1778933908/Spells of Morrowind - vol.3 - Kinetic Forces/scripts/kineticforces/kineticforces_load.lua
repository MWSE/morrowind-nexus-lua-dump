-- ============================================================
-- Kinetic Bolt — LOAD Script
-- ============================================================
print("[KineticBolt] LOAD script starting...")

local content = require('openmw.content')

-- ============================================================
-- [0] SOUND RECORDS
-- Fields: fileName (VFS path), volume (0-255), minRange (0-255), maxRange (0-255)
-- These IDs are what castSound/boltSound/hitSound/areaSound expect.
-- ============================================================

content.sounds.records['kinetic_cast'] = {
    fileName = 'sound/kinetic/klaunch.mp3',
    volume   = 255,
    minRange = 0,
    maxRange = 200,
}

content.sounds.records['kinetic_bolt'] = {
    fileName = 'sound/kinetic/kbolt.mp3',
    volume   = 220,
    minRange = 0,
    maxRange = 200,
}

content.sounds.records['kinetic_hit'] = {
    fileName = 'sound/kinetic/khit.mp3',
    volume   = 255,
    minRange = 0,
    maxRange = 200,
}

content.sounds.records['kinetic_area'] = {
    fileName = 'sound/kinetic/khit.mp3',
    volume   = 255,
    minRange = 0,
    maxRange = 300,
}

-- ============================================================
-- [1] MAGIC EFFECT DEFINITIONS
-- ============================================================

-- Hover/Detection Effects (Phase 1)
content.magicEffects.records.kb_mgef = {
    template   = content.magicEffects.records['open'],
    name       = 'Kinetic Bolt',
    school     = 'alteration',
    icon       = 'icons\\s\\kinetic_bolt.tga',
    description = 'Condense kinetic force. Second cast launches.',
    castSound  = 'kinetic_cast',
    boltSound  = 'kinetic_bolt',
    hitSound   = 'kinetic_hit',
    hasDuration = false,
    hasArea     = false,
}

content.magicEffects.records.ke_mgef = {
    template   = content.magicEffects.records['open'],
    name       = 'Kinetic Explosion',
    school     = 'alteration',
    icon       = 'icons\\s\\kinetic_explosion.tga',
    description = 'Condense kinetic force. Second cast detonates.',
    castSound  = 'kinetic_cast',
    boltSound  = 'kinetic_bolt',
    hitSound   = 'kinetic_hit',
    areaSound  = 'kinetic_area',
    hasDuration = false,
    hasArea     = true,
}

-- Impact Effects (Phase 2 — what MagExp actually fires)
content.magicEffects.records.kb_launch = {
    template   = content.magicEffects.records['open'],
    name       = 'Kinetic Bolt Impact',
    school     = 'alteration',
    icon       = 'icons\\s\\kinetic_bolt.tga',
    description = 'Impact effect for kinetic bolt.',
    castSound  = 'kinetic_cast',
    boltSound  = 'kinetic_bolt',
    hitSound   = 'kinetic_hit',
    hasDuration = false,
    hasMagnitude = true,
    hasArea     = false,
    allowsSpellmaking = false,
    allowsEnchanting = false,
}

content.magicEffects.records.ke_launch = {
    template   = content.magicEffects.records['open'],
    name       = 'Kinetic Explosion Impact',
    school     = 'alteration',
    icon       = 'icons\\s\\kinetic_explosion.tga',
    description = 'Impact effect for kinetic explosion.',
    castSound  = 'kinetic_cast',
    boltSound  = 'kinetic_bolt',
    hitSound   = 'kinetic_hit',
    areaSound  = 'kinetic_area',
    hasDuration = false,
    hasArea     = true,
    allowsSpellmaking = false,
    allowsEnchanting = false,
}

-- ============================================================
-- [2] SPELL RECORDS
-- ============================================================

-- Selection Spells (Owned by Player/NPCs)
content.spells.records.kinetic_bolt = {
    name       = 'Kinetic Bolt',
    type       = content.spells.TYPE.Spell,
    cost       = 45,
    school     = 'alteration',
    isAutocalc = false,
    hasArea = false,
    hasDuration = false,
    effects    = {
        { id = 'kb_mgef', range = content.RANGE.Self, duration = 10, magnitudeMin = 0, magnitudeMax = 30 }
    }
}

content.spells.records.kinetic_expl = {
    name       = 'Kinetic Explosion',
    type       = content.spells.TYPE.Spell,
    cost       = 60,
    school     = 'alteration',
    isAutocalc = false,
    hasDuration = false,
    effects    = {
        { id = 'ke_mgef', range = content.RANGE.Self, duration = 10, magnitudeMin = 0, magnitudeMax = 40 }
    }
}

-- Launch Spells (Fired by MagExp — damage applied via speed-scaled health write)
content.spells.records.kb_launch = {
    name       = 'Kinetic Bolt',
    type       = content.spells.TYPE.Spell,
    cost       = 0,
    allowsSpellmaking = false,
    allowsEnchanting = false,
    isAutocalc = false,
    effects    = {
        { id = 'kb_launch', range = content.RANGE.Target, magnitudeMin = 0, magnitudeMax = 30 }
    }
}

content.spells.records.ke_launch = {
    name       = 'Kinetic Explosion',
    type       = content.spells.TYPE.Spell,
    allowsSpellmaking = false,
    allowsEnchanting = false,
    cost       = 0,
    isAutocalc = false,
    effects    = {
        { id = 'ke_launch', range = content.RANGE.Target, magnitudeMin = 0, magnitudeMax = 40, area = 15 }
    }
}

print("[KineticBolt] Magic records successfully registered.")