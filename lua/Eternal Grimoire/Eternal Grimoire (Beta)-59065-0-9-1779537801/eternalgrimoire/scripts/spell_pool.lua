local M = {}

local types = require('openmw.types')


-- ============================================================
-- Fixed Spell Slot Layout (15 spells per grimoire)
-- ============================================================


local SPELL_SLOTS = {
    1, 1, 1, 1, 1,
    2, 2, 2, 2,
    3, 3, 3,
    4, 4,
    5,
}   


-- Ordered to match Morrowind's 0-based attribute indices
local ATTRIBUTE_NAMES = {
    [0] = "strength",
    [1] = "intelligence",
    [2] = "willpower",
    [3] = "agility",
    [4] = "speed",
    [5] = "endurance",
    [6] = "personality",
    [7] = "luck",
}


-- Ordered to match Morrowind's 0-based skill indices
local SKILL_NAMES = {
    [0]  = "block",
    [1]  = "armorer",
    [2]  = "mediumarmor",
    [3]  = "heavyarmor",
    [4]  = "bluntweapon",
    [5]  = "longblade",
    [6]  = "axe",
    [7]  = "spear",
    [8]  = "athletics",
    [9]  = "enchant",
    [10] = "destruction",
    [11] = "alteration",
    [12] = "illusion",
    [13] = "conjuration",
    [14] = "mysticism",
    [15] = "restoration",
    [16] = "alchemy",
    [17] = "unarmored",
    [18] = "security",
    [19] = "sneak",
    [20] = "acrobatics",
    [21] = "lightarmor",
    [22] = "shortblade",
    [23] = "marksman",
    [24] = "mercantile",
    [25] = "speechcraft",
    [26] = "handtohand",
}


-- ============================================================
-- Special-case flags
-- ============================================================


-- Effects with NO magnitude and NO duration (instant actions)
-- These do NOT scale magnitude or duration
local noDurationNoMagnitude = {
    AlmsiviIntervention = true,
    DivineIntervention  = true,
    Mark                = true,
    Recall              = true,
}


-- Cure effects: instant application, magnitude = 1
local cureEffects = {
    CurePoison        = true,
    CureCommonDisease = true,
    CureBlightDisease = true,
}


-- ============================================================
-- Effect Configurations
-- Each entry defines:
--   id: effect identifier
--   school: magic school for name generation
--   ranges: allowed range types (0=Self, 1=Touch, 2=Target)
--   magMin/magMax: magnitude at skill 100. Scales proportionally above 100.
--   durMin/durMax: duration at skill 100. Scales proportionally above 100.
--   areaMin/areaMax: area at skill 100. Scales proportionally above 100.
--   onlyIn1Effect: true if only allowed in 1-effect spells
-- ============================================================


local effectConfigs = {
    -- ════════════════════════════════════════════════════════
    -- DESTRUCTION
    -- ════════════════════════════════════════════════════════
    { id = "FireDamage",              school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 20, durMin = 0,  durMax = 15,  areaMin = 5,  areaMax = 25 },
    { id = "FrostDamage",             school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 20, durMin = 0,  durMax = 15,  areaMin = 5,  areaMax = 25 },
    { id = "ShockDamage",             school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 20, durMin = 0,  durMax = 15,  areaMin = 5,  areaMax = 25 },
    { id = "DrainHealth",             school = "destruction", ranges = {0,1,2}, magMin = 10, magMax = 200, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 40 },
    { id = "DrainMagicka",            school = "destruction", ranges = {0,1,2}, magMin = 25, magMax = 200, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 40 },
    { id = "DrainFatigue",            school = "destruction", ranges = {0,1,2}, magMin = 50, magMax = 200, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 40 },
    { id = "DrainAttribute",          school = "destruction", ranges = {0,1,2}, magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 8,  areaMax = 35 },
    { id = "DrainSkill",              school = "destruction", ranges = {0,1,2}, magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 8,  areaMax = 35 },
    { id = "Burden",                  school = "destruction", ranges = {0,1,2}, magMin = 100, magMax = 300, durMin = 10, durMax = 60, areaMin = 10, areaMax = 40 },
    { id = "Blind",                   school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 10, durMax = 60, areaMin = 5,  areaMax = 25 },
    { id = "Silence",                 school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 1,   durMin = 3,  durMax = 60,  areaMin = 5,  areaMax = 20 },
    { id = "Paralyze",                school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 10,  durMin = 1,  durMax = 5,   areaMin = 3,  areaMax = 12 },
    { id = "Poison",                  school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 15,  durMin = 0,  durMax = 25,  areaMin = 5,  areaMax = 22 },
    { id = "DisintegrateArmor",       school = "destruction", ranges = {0,1,2}, magMin = 20, magMax = 100, durMin = 0,  durMax = 60,  areaMin = 5,  areaMax = 18 },
    { id = "DisintegrateWeapon",      school = "destruction", ranges = {0,1,2}, magMin = 20, magMax = 100, durMin = 0,  durMax = 60,  areaMin = 5,  areaMax = 18 },
    { id = "WeaknessToFire",          school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "WeaknessToFrost",         school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "WeaknessToShock",         school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "WeaknessToMagicka",       school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "WeaknessToPoison",        school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "WeaknessToCommonDisease", school = "destruction", ranges = {0},     magMin = 1,  magMax = 100, durMin = 60, durMax = 600, areaMin = 0,  areaMax = 0  },
    { id = "DamageAttribute",         school = "destruction", ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 0,  durMax = 30,  areaMin = 5,  areaMax = 20 },
    { id = "DamageSkill",             school = "destruction", ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 0,  durMax = 30,  areaMin = 5,  areaMax = 20 },
    { id = "DamageHealth",            school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 20,  durMin = 0,  durMax = 15,  areaMin = 5,  areaMax = 22 },
    { id = "DamageFatigue",           school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 25,  durMin = 0,  durMax = 30,  areaMin = 5,  areaMax = 25 },
    { id = "DamageMagicka",           school = "destruction", ranges = {0,1,2}, magMin = 1,  magMax = 20,  durMin = 0,  durMax = 15,  areaMin = 5,  areaMax = 20 },


    -- ════════════════════════════════════════════════════════
    -- RESTORATION
    -- ════════════════════════════════════════════════════════
    { id = "RestoreHealth",           school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 10, durMin = 0,  durMax = 20,  areaMin = 5,  areaMax = 18 },
    { id = "RestoreMagicka",          school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 5,  durMin = 0,  durMax = 10,  areaMin = 5,  areaMax = 15 },
    { id = "RestoreFatigue",          school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 20, durMin = 0,  durMax = 30,  areaMin = 5,  areaMax = 20 },
    { id = "FortifyHealth",           school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "FortifyMagicka",          school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "FortifyFatigue",          school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "FortifyAttribute",        school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "FortifySkill",            school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "FortifyAttack",           school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "CurePoison",              school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 1,   durMin = 0,  durMax = 30,  areaMin = 0,  areaMax = 0  },
    { id = "CureCommonDisease",       school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 1,   durMin = 0,  durMax = 0,   areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "CureBlightDisease",       school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 1,   durMin = 0,  durMax = 0,   areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "ResistFire",              school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "ResistFrost",             school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "ResistShock",             school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "ResistMagicka",           school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "ResistPoison",            school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "ResistCommonDisease",     school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "ResistNormalWeapons",     school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "ResistParalysis",         school = "restoration", ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },


    -- ════════════════════════════════════════════════════════
    -- ALTERATION
    -- ════════════════════════════════════════════════════════
    { id = "Shield",                  school = "alteration",  ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 1,  durMax = 60,  areaMin = 5,  areaMax = 25 },
    { id = "Feather",                 school = "alteration",  ranges = {0,1,2}, magMin = 1,  magMax = 300, durMin = 1,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SlowFall",                school = "alteration",  ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 1,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "WaterBreathing",          school = "alteration",  ranges = {0,1,2}, magMin = 1,  magMax = 1,   durMin = 1,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "WaterWalking",            school = "alteration",  ranges = {0,1,2}, magMin = 1,  magMax = 1,   durMin = 1,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "Levitate",                school = "alteration",  ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 1,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "Jump",                    school = "alteration",  ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 1,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "Dispel",                  school = "alteration",  ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 0,  durMax = 0,   areaMin = 8,  areaMax = 35 },
    { id = "Lock",                    school = "alteration",  ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 0,  durMax = 0,   areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "Open",                    school = "alteration",  ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 0,  durMax = 0,   areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "Telekinesis",             school = "alteration",  ranges = {0},     magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0, onlyIn1Effect = true },


    -- ════════════════════════════════════════════════════════
    -- ILLUSION
    -- ════════════════════════════════════════════════════════
    { id = "Invisibility",            school = "illusion",    ranges = {0,1,2}, magMin = 1,  magMax = 1,   durMin = 3,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "Chameleon",               school = "illusion",    ranges = {0,1,2}, magMin = 5,  magMax = 100, durMin = 3,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "Light",                   school = "illusion",    ranges = {0,1,2}, magMin = 5,  magMax = 100, durMin = 10, durMax = 300, areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "NightEye",                school = "illusion",    ranges = {0},     magMin = 5,  magMax = 100, durMin = 10, durMax = 300, areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "Charm",                   school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "CalmHumanoid",            school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "CalmCreature",            school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "FrenzyHumanoid",          school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "FrenzyCreature",          school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "RallyHumanoid",           school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "RallyCreature",           school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "DemoralizeHumanoid",      school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "DemoralizeCreature",      school = "illusion",    ranges = {1,2},   magMin = 5,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "TurnUndead",              school = "illusion",    ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 8,  areaMax = 45 },


    -- ════════════════════════════════════════════════════════
    -- MYSTICISM
    -- ════════════════════════════════════════════════════════
    { id = "DetectAnimal",            school = "mysticism",   ranges = {0},     magMin = 1,  magMax = 100, durMin = 10, durMax = 300, areaMin = 0,  areaMax = 0  },
    { id = "DetectEnchantment",       school = "mysticism",   ranges = {0},     magMin = 1,  magMax = 100, durMin = 10, durMax = 300, areaMin = 0,  areaMax = 0  },
    { id = "DetectKey",               school = "mysticism",   ranges = {0},     magMin = 1,  magMax = 100, durMin = 10, durMax = 300, areaMin = 0,  areaMax = 0  },
    { id = "AlmsiviIntervention",     school = "mysticism",   ranges = {0},     magMin = 1,  magMax = 1,   durMin = 0,  durMax = 0,   areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "DivineIntervention",      school = "mysticism",   ranges = {0},     magMin = 1,  magMax = 1,   durMin = 0,  durMax = 0,   areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "Mark",                    school = "mysticism",   ranges = {0},     magMin = 1,  magMax = 1,   durMin = 0,  durMax = 0,   areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "Recall",                  school = "mysticism",   ranges = {0},     magMin = 1,  magMax = 1,   durMin = 0,  durMax = 0,   areaMin = 0,  areaMax = 0, onlyIn1Effect = true },
    { id = "Soultrap",                school = "mysticism",   ranges = {1,2},   magMin = 1,  magMax = 1,   durMin = 5,  durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "Reflect",                 school = "mysticism",   ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 5,  areaMax = 20 },
    { id = "SpellAbsorption",         school = "mysticism",   ranges = {0,1,2}, magMin = 1,  magMax = 100, durMin = 5,  durMax = 60,  areaMin = 5,  areaMax = 20 },
    { id = "AbsorbHealth",            school = "mysticism",   ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 1,  durMax = 60,  areaMin = 5,  areaMax = 22 },
    { id = "AbsorbMagicka",           school = "mysticism",   ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 1,  durMax = 60,  areaMin = 5,  areaMax = 22 },
    { id = "AbsorbFatigue",           school = "mysticism",   ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 1,  durMax = 60,  areaMin = 5,  areaMax = 22 },
    { id = "AbsorbAttribute",         school = "mysticism",   ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 5,  areaMax = 25 },
    { id = "AbsorbSkill",             school = "mysticism",   ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 5,  areaMax = 25 },


    -- ════════════════════════════════════════════════════════
    -- CONJURATION — All summons/bound items are SELF only
    -- ════════════════════════════════════════════════════════
    { id = "CommandHumanoid",         school = "illusion",    ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "CommandCreature",         school = "illusion",    ranges = {1,2},   magMin = 1,  magMax = 100, durMin = 10, durMax = 60,  areaMin = 10, areaMax = 50 },
    { id = "SummonAncestralGhost",    school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonBonelord",          school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonBonewalker",        school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonCenturionSphere",   school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonClannfear",         school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonDaedroth",          school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonDremora",           school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonFlameAtronach",     school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonFrostAtronach",     school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonGoldenSaint",       school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonGreaterBonewalker", school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonHunger",            school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonScamp",             school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonSkeletalMinion",    school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonStormAtronach",     school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "SummonWingedTwilight",    school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundBattleAxe",          school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundBoots",              school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundCuirass",            school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundDagger",             school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundGloves",             school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundHelm",               school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundLongbow",            school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundLongsword",          school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundMace",               school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundShield",             school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
    { id = "BoundSpear",              school = "conjuration", ranges = {0},     magMin = 1,  magMax = 1,   durMin = 10, durMax = 60,  areaMin = 0,  areaMax = 0  },
}


-- ============================================================
-- Skill/attribute parameter requirements
-- ============================================================


local needsAttribute = {
    DamageAttribute  = true,
    DrainAttribute   = true,
    FortifyAttribute = true,
    AbsorbAttribute  = true,
}


local needsSkill = {
    DamageSkill  = true,
    DrainSkill   = true,
    FortifySkill = true,
    AbsorbSkill  = true,
}


local ATTRIBUTE_COUNT = 8
local SKILL_COUNT = 27


-- ============================================================
-- Build lookup maps from effectConfigs
-- ============================================================


local effectConfigMap = {}
for _, cfg in ipairs(effectConfigs) do
    effectConfigMap[cfg.id] = cfg
end


-- ============================================================
-- Name Words / Range Labels
-- ============================================================


local rangeNames = { [0] = "Self", [1] = "Touch", [2] = "Bolt" }


local nameWords = {
    destruction = { "Blight",    "Hex",     "Ruin",    "Smite",   "Wrath",   "Decay",   "Plague"  },
    restoration = { "Mending",   "Renewal",  "Solace",  "Vigil",   "Warding", "Bastion", "Sanctum" },
    alteration  = { "Aegis",     "Grasp",    "Mantle",  "Shaping", "Veil",    "Flux",    "Prism"   },
    illusion    = { "Mirage",    "Phantom",  "Shadow",  "Shroud",  "Whisper", "Echo",    "Glamour" },
    mysticism   = { "Binding",   "Fracture", "Seeking", "Tether",  "Unravel", "Portal",  "Cipher"  },
    conjuration = { "Calling",   "Summoning","Gateway", "Pact",    "Binding", "Rift",    "Vessel"  },
    mixed       = { "Arcanum",   "Grimoire", "Nexus",   "Rift",    "Surge",   "Tempest", "Enigma"  },
}


-- ============================================================
-- Skill-based Magnitude Helpers
-- ============================================================
local function getSkillForSchool(school, player)
    if not player then
        return 100
    end

    local ok, result = pcall(function()
        local skillStat = types.NPC.stats.skills[school](player)
        if not skillStat then
            return nil
        end
        return skillStat.modified
    end)

    if not ok or not result then
        return 100
    end

    return result
end


-- Get player's current level
local function getPlayerLevel(player)
    if not player then return 1 end
    local ok, result = pcall(function()
        return types.NPC.stats.level(player).current
    end)
    if ok and result then return result end
    return 1
end


-- ============================================================
-- LCG Seeded Random Helpers
-- ============================================================


local function lcg(seed)
    return (1664525 * seed + 1013904223) % (2 ^ 32)
end


-- ============================================================
-- Runtime-validated pool
-- ============================================================


local validatedConfigs = nil


local function getValidatedConfigs(core)
    if validatedConfigs then return validatedConfigs end

    validatedConfigs = {}
    local rejected = {}

    for _, cfg in ipairs(effectConfigs) do
        local ok = pcall(function()
            local rec = core.magic.effects.record(cfg.id)
            if not rec then error("nil record") end
        end)
        if ok then
            validatedConfigs[#validatedConfigs + 1] = cfg
        else
            rejected[#rejected + 1] = cfg.id
        end
    end

    return validatedConfigs
end


-- ============================================================
-- Unified Effect Value Rolling (magnitude + duration + area)
-- ============================================================


local function rollEffectValues(cfg, state, skillValue, player)
    local magMin, magMax, duration

    -- ==========================================
    -- CASE 1: No magnitude and no duration
    -- (instant actions, no scaling)
    -- ==========================================
    if noDurationNoMagnitude[cfg.id] then
        return 1, 1, 0, 0, 0
    end

    -- ==========================================
    -- CASE 2: Cure effects (instant)
    -- ==========================================
    if cureEffects[cfg.id] then
        return 1, 1, 0, 0, 0
    end

    local isFixedMagnitude = (cfg.magMin == 1 and cfg.magMax == 1)
    local playerLevel = getPlayerLevel(player)

    -- ==========================================
    -- FIXED MAGNITUDE EFFECTS (1–1)
    -- These stay at magnitude = 1. Duration (if any) scales proportionally.
    -- ==========================================
    if isFixedMagnitude then
        magMin = 1
        magMax = 1

        if cfg.durMax > 0 then
            local finalDurMax = math.ceil(cfg.durMax * skillValue / 100.0)
            local durFloor = math.min(cfg.durMin, finalDurMax)
            
            local durState = lcg(state + 13579)
            duration = 1 + (durState % playerLevel)
            duration = math.min(duration, finalDurMax)
            duration = math.max(duration, durFloor)
        else
            duration = 0
        end

        return magMin, magMax, duration, 0, 0
    end

    -- ==========================================
    -- VARIABLE MAGNITUDE & DURATION
    -- All three (magMax, durMax, areaMax) now use the same rule:
    --   value_at_100 * (skill / 100), rounded up with math.ceil()
    --   This allows values to exceed config maximum when skill > 100.
    -- ==========================================

    -- Magnitude
    local finalMagMax = math.ceil(cfg.magMax * skillValue / 100.0)
    local magFloor = math.min(cfg.magMin, finalMagMax)
    
    local magMinState = lcg(state + 11111)
    magMin = 1 + (magMinState % playerLevel)
    magMin = math.min(magMin, finalMagMax)
    magMin = math.max(magMin, magFloor)
    magMax = finalMagMax

    -- Duration
    if cfg.durMax > 0 then
        local finalDurMax = math.ceil(cfg.durMax * skillValue / 100.0)
        local durFloor = math.min(cfg.durMin, finalDurMax)
        
        local durState = lcg(state + 24680)
        duration = 1 + (durState % playerLevel)
        duration = math.min(duration, finalDurMax)
        duration = math.max(duration, durFloor)
    else
        duration = 0
    end

    -- ==========================================
    -- AREA OF EFFECT ROLLING
    -- Uses identical proportional scaling as magnitude/duration.
    -- areaMax in config = value at skill 100.
    -- areaMin rolls 0..playerLevel then clamped.
    -- ==========================================
    local areaMinVal = 0
    local areaMaxVal = 0

    if (cfg.areaMax or 0) > 0 and cfg.school ~= "conjuration" and duration > 0 then
        local finalAreaMax = math.ceil(cfg.areaMax * skillValue / 100.0)
        
        local areaFloor = cfg.areaMin or 0
        local areaState = lcg(state + 77777)
        
        local rolledMin = 0
        if playerLevel > 0 then
            rolledMin = areaState % (playerLevel + 1)  -- 0 to playerLevel
        end
        
        areaMinVal = math.max(areaFloor, math.min(rolledMin, finalAreaMax))
        areaMaxVal = finalAreaMax
    end

    return magMin, magMax, duration, areaMinVal, areaMaxVal
end


-- ============================================================
-- Effect Selection with Conjuration Ordering Fix
-- ============================================================


local function selectEffects(effectCount, seed, configs, player)
    local selected = {}
    local chosen   = {}
    local poolSize = #configs
    local conjurationEffect = nil

    for i = 1, effectCount do
        local state    = lcg(seed + i * 997)
        local attempts = 0

        while attempts < 200 do
            local idx = (state % poolSize) + 1
            local cfg = configs[idx]

            if not chosen[cfg.id] then
                local eligible = true

                if cfg.onlyIn1Effect and effectCount > 1 then
                    eligible = false
                elseif cfg.onlyIn1to4Effects and effectCount > 5 then
                    eligible = false
                end

                if eligible then
                    chosen[cfg.id] = true

                    local rangeIdx = (lcg(state + 13) % #cfg.ranges) + 1
                    local range    = cfg.ranges[rangeIdx]

                    local skillValue = getSkillForSchool(cfg.school, player)

                    local magMin, magMax, duration, areaMinVal, areaMaxVal =
                        rollEffectValues(cfg, state, skillValue, player)

                    local affectedSkill     = nil
                    local affectedAttribute = nil

                    if needsAttribute[cfg.id] then
                        affectedAttribute = ATTRIBUTE_NAMES[lcg(state + 101) % ATTRIBUTE_COUNT]
                    elseif needsSkill[cfg.id] then
                        affectedSkill = SKILL_NAMES[lcg(state + 103) % SKILL_COUNT]
                    end

                    local effectData = {
                        id                = cfg.id,
                        affectedSkill     = affectedSkill,
                        affectedAttribute = affectedAttribute,
                        range             = range,
                        areaMin           = areaMinVal,
                        areaMax           = areaMaxVal,
                        duration          = duration,
                        magnitudeMin      = magMin,
                        magnitudeMax      = magMax,
                    }

                    -- If this is a conjuration effect, save it to put at the end
                    if cfg.school == "conjuration" then
                        conjurationEffect = effectData
                    else
                        selected[#selected + 1] = effectData
                    end

                    break
                end
            end

            state    = lcg(state)
            attempts = attempts + 1
        end
    end

    -- Put conjuration effect last (to prevent damage effects hitting your own summon)
    if conjurationEffect then
        selected[#selected + 1] = conjurationEffect
    end

    -- ============================================================
    -- Fallback if slot is empty
    -- ============================================================

    if #selected == 0 then
        local state = lcg(seed + 42)

        local safeConfigs = {}
        for _, cfg in ipairs(configs) do
            if not cfg.onlyIn1Effect and not cfg.onlyIn1to4Effects then
                safeConfigs[#safeConfigs + 1] = cfg
            end
        end

        if #safeConfigs == 0 then return selected end

        local cfg = safeConfigs[(state % #safeConfigs) + 1]
        local rangeIdx = (lcg(state + 13) % #cfg.ranges) + 1
        local range    = cfg.ranges[rangeIdx]

        local skillValue = getSkillForSchool(cfg.school, player)

        local magMin, magMax, duration, areaMinVal, areaMaxVal =
            rollEffectValues(cfg, state, skillValue, player)

        selected[1] = {
            id                = cfg.id,
            affectedSkill     = -1,
            affectedAttribute = -1,
            range             = range,
            areaMin           = areaMinVal,
            areaMax           = areaMaxVal,
            duration          = duration,
            magnitudeMin      = magMin,
            magnitudeMax      = magMax,
        }
    end

    return selected
end


-- ============================================================
-- Name Generation
-- ============================================================


local function generateSpellName(effects, seed)
    local school = "mixed"
    if effects[1] and effectConfigMap[effects[1].id] then
        school = effectConfigMap[effects[1].id].school
    end
    if #effects > 2 and lcg(seed) % 3 == 0 then school = "mixed" end

    local words     = nameWords[school]
    local wIdx      = (lcg(seed + 3) % #words) + 1
    local word      = words[wIdx]
    local rangeName = rangeNames[effects[1] and effects[1].range or 1] or "Touch"

    return string.format("EG %s of %s", rangeName, word)
end


-- ============================================================
-- Public API
-- ============================================================


function M.generateSpellsForTime(gameTime, core, player)
    if gameTime <= 0 then gameTime = 1 end

    local configs = core and getValidatedConfigs(core) or effectConfigs
    local spells  = {}

    for slotIndex, effectCount in ipairs(SPELL_SLOTS) do
        local seed      = gameTime + slotIndex * 9973
        local effects   = selectEffects(effectCount, seed, configs, player)
        local spellId   = string.format("eg_grimoire_t%d_s%d", gameTime % 999999, slotIndex)
        local spellName = generateSpellName(effects, seed)

        spells[#spells + 1] = {
            id      = spellId,
            name    = spellName,
            effects = effects,
            cost    = effectCount * 7,
        }
    end

    return spells
end

return M
