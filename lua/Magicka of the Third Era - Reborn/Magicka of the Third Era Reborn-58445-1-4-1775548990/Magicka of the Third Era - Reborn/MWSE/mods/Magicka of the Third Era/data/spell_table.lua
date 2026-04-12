-- All the calculation logic for specific effects is stored here (except for very few niche cases). Commented values might be inaccurate, since I tweak balance a lot.
local spell_table = {}
-----------------
-- Alteration
-----------------
-- Water Breathing
-- 0 is 3434 because I want an iterable array, but don't know why I want it. Never mind, I'll keep both. Ugh.
spell_table[3434] = {coef = 0.75, mag_pow = 0.45, const_offset = 6.5}
spell_table[0] = spell_table[3434]
-- Swift Swim
spell_table[1] = {coef = 0.13, mag_pow = 0.7, dur_pow = -0.35}
-- Water Walking
spell_table[2] = {coef = 0.85, mag_pow = 0.7, dur_pow = -0.3, const_offset = 3}
-- Shield
spell_table[3] = {coef = 0.13, mag_pow = 0.74, dur_pow = -0.25, range1_coef_mod = 0.35, range2_coef_mod = 0.4}
-- Elemental Shields
spell_table[4] = {coef = 0.21, mag_pow = 0.8, dur_pow = -0.35, range1_coef_mod = 0.5, range2_coef_mod = 0.55}
spell_table[5] = {coef = 0.21, mag_pow = 0.8, dur_pow = -0.35, range1_coef_mod = 0.5, range2_coef_mod = 0.55}
spell_table[6] = {coef = 0.21, mag_pow = 0.8, dur_pow = -0.35, range1_coef_mod = 0.5, range2_coef_mod = 0.55}
-- Burden
spell_table[7] = {coef = 0.01, mag_pow = 0.7, dur_pow = 0.4, area_pow = 0.08, range2_coef_mod = 1.3}
-- Feather
spell_table[8] = {coef = 0.2, mag_pow = 0.7, dur_pow = -0.65, dur_min = 20, ignore_magmin = true}
-- Jump
spell_table[9] = {coef = 0.45, mag_pow = 0.75, dur_pow = -0.6, area_pow = 0.1}
-- Levitate
-- It's a special snowflake with offensive use case, which is done in formulas, but isn't referenced here.
spell_table[10] = {coef = 0.13, mag_pow = 0.68, dur_pow = -0.25, const_offset = 6, mag_offset = 10}
-- Slowfall
spell_table[11] = {coef = 0.4, mag_pow = 0.5, dur_pow = 0, area_pow = 0.1, const_offset = 7}
-- Lock
spell_table[12] = {coef = 0.09, mag_pow = 1, range2_coef_mod = 1.1, const_offset = 9, ignore_magmin = true}
-- Open
spell_table[13] = {coef = 0.065, mag_pow = 1.15, const_offset = 1, ignore_magmin = true}
-----------------
-- Destruction
-----------------
-- These are the cornerstones of balance... Overall they're weaker than in Vanilla, but more spammable.
-- S - best, A - good, B - okay, C - bad
------------------------------------------------------
-- Type      |  Price  |   AOE   |   DoT   | Resists |
------------------------------------------------------
-- Fire      |    A    |    S    |    A    |    B    |  
------------------------------------------------------
-- Frost     |    B    |    B    |    B    |    A    |
------------------------------------------------------
-- Shock     |    C    |    A    |    C    |    S    |
------------------------------------------------------
-- Poison    |    A    |    A    |    S    |    C    |
------------------------------------------------------
-- Health    |    C    |    C    |    B    |    S    |
------------------------------------------------------
-- Fire Damage --
-- Cheap, best for AOE
spell_table[14] = {coef = 0.56, mag_pow = 0.71, dur_pow = -0.2, area_pow = 0.08, range2_coef_mod = 1.4}
-- Shock Damage --
-- Expensive, ok for AOE and ranged
spell_table[15] = {coef = 0.645, mag_pow = 0.72, dur_pow = -0.13, area_pow = 0.11, range2_coef_mod = 1.4}
-- Frost Damage --
-- Cheap for touch spells, expensive for ranged
spell_table[16] = {coef = 0.54, mag_pow = 0.715, dur_pow = -0.17, area_pow = 0.145, range2_coef_mod = 1.55}
-- Poison Damage --
-- Cheap, best for DoTs
spell_table[27] = {coef = 0.575, mag_pow = 0.715, dur_pow = -0.225, area_pow = 0.125, range2_coef_mod = 1.4}
-- Damage Health --
-- Expensive, ok for DoTs and touch spells
spell_table[23] = {coef = 0.64, mag_pow = 0.725, dur_pow = -0.19, area_pow = 0.2, range2_coef_mod = 1.5}
-- Drain Attribute
spell_table[17] = {coef = 0.145, mag_pow = 0.9, dur_pow = -0.75, dur_offset = 10, area_pow = 0.17, range0_const_cost = 100, range1_coef_mod = 0.7}
-- Drain Health
-- 100, 1s = 23
-- 200, 1s = 38
-- 100, 30s = 26
-- 200, 30s = 43
spell_table[18] = {coef = 0.5, mag_pow = 0.725, dur_pow = -0.69, area_pow = 0.09, range0_const_cost = 100, range2_coef_mod = 1.35}
-- Drain Magicka
spell_table[19] = {coef = 0.13, mag_pow = 0.8, dur_pow = -0.72, area_pow = 0.1, range0_const_cost = 100, range2_coef_mod = 1.25}
-- Drain Fatigue
spell_table[20] = {coef = 0.15, mag_pow = 0.65, dur_pow = -0.58, area_pow = 0.12, range0_const_cost = 100, range2_coef_mod = 1.35}
-- Drain Skill
spell_table[21] = {coef = 0.18, mag_pow = 0.8, dur_pow = -0.67, area_pow = 0.12, range0_const_cost = 100, range2_coef_mod = 1.4}
-- Damage Attribute
spell_table[22] = {coef = 0.66, mag_pow = 0.85, dur_pow = -0.18, area_pow = 0.15, range2_coef_mod = 1.4}
-- Damage Magicka
spell_table[24] = {coef = 0.5, mag_pow = 0.8, dur_pow = -0.3, area_pow = 0.15, range2_coef_mod = 1.3}
-- Damage Fatigue
spell_table[25] = {coef = 0.3, mag_pow = 0.75, dur_pow = -0.3, area_pow = 0.15, range2_coef_mod = 1.4}
-- Damage Skill
spell_table[26] = {coef = 0.5, mag_pow = 0.8, dur_pow = -0.2, area_pow = 0.15, range2_coef_mod = 1.4}
-- Weakness to Fire
spell_table[28] = {coef = 0.12, mag_pow = 0.8, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
-- Weakness to Frost
spell_table[29] = {coef = 0.125, mag_pow = 0.8, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
-- Weakness to Shock
spell_table[30] = {coef = 0.13, mag_pow = 0.8, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
-- Weakness to Magic
spell_table[31] = {coef = 0.13, mag_pow = 0.825, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
-- Weakness to diseases
-- prettier filler
spell_table[32] = {coef = 0.02, mag_pow = 0.8, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
spell_table[33] = spell_table[32]
spell_table[34] = spell_table[32]
-- Weakness to Poison
spell_table[35] = {coef = 0.13, mag_pow = 0.8, dur_pow = -0.475, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
-- Weakness to Normal Weapons
spell_table[36] = {coef = 0.075, mag_pow = 0.77, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
-- Disintegrate Weapon
spell_table[37] = {coef = 0.073, mag_pow = 0.75, dur_pow = -0.2, area_pow = 0.1, range2_coef_mod = 1.4}
-- Disintegrate Armor
spell_table[38] = {coef = 0.04, mag_pow = 0.75, dur_pow = -0.2, area_pow = 0.1, range2_coef_mod = 1.4}
-----------------
-- Illusion
-----------------
-- Invisibility
-- 10 sec = 11 cost
-- 30 sec = 16 cost
spell_table[39] = {coef = 0.8, mag_pow = 0.65, dur_pow = 0, dur_offset = 10, const_offset = 2}
-- Chameleon
-- 20, 10s = 13
-- 20, 30s = 19
-- 50, 10s = 32
spell_table[40] = {coef = 0.053, mag_pow = 1.15, dur_pow = -0.7, dur_min = 10, const_offset = 3}
-- Light
spell_table[41] = {coef = 0.15, mag_pow = 0.8, dur_pow = -0.55, range1_coef_mod = 0.8, range2_coef_mod = 0.8, const_offset = 2}
-- Magelight
spell_table[344] = spell_table[41]
-- Sanctuary
-- 20, 10s = 9
-- 30, 20s = 17
-- 50, 30s = 29
spell_table[42] = {coef = 0.35, mag_pow = 0.73, dur_pow = -0.4}
-- Night's Eye
spell_table[43] = {coef = 0.5, mag_pow = 0.65, dur_pow = -0.4, dur_offset = 15}
-- Charm
-- 10, 20s = 7
-- 20, 20s = 12
-- 50, 20s = 24
spell_table[44] = {coef = 0.7, mag_pow = 0.73, dur_pow = -0.65, dur_min = 20, ignore_magmin = true}
-- Paralyze
spell_table[45] = {coef = 0.6, mag_pow = 1.05, dur_pow = 0, area_pow = 0.17, range2_coef_mod = 1.4}
-- Silence
-- 10s = 9
-- 30s = 23
spell_table[46] = {coef = 0.65, mag_pow = 0.78, area_pow = 0.08, range2_coef_mod = 1.3}
-- Blind
spell_table[47] = {coef = 0.28, mag_pow = 0.71, dur_pow = -0.4, area_pow = 0.075, range2_coef_mod = 1.25}
-- Sound
-- Increases spell costs by 5% per mag (does not affect spell chance). Might be weaker than Silence in most cases, but remember that AI is dumb and may waste all magicka for 1 spell.
-- 20, 10s = 10
-- 26, 10s = 12
-- 20, 30s = 15
-- 44, 30s = 27
spell_table[48] = {coef = 0.27, mag_pow = 0.7, dur_pow = -0.3, range2_coef_mod = 1.3}
-- Calm Humanoid
-- these spells are reworked! now mag = level
-- lvl 5 = 8
-- lvl 15 = 15
-- lvl 30 = 24
-- 10 is min duration (does not matter with most of these spells)
spell_table[49] = {coef = 0.4, mag_pow = 0.9, dur_pow = -0.8, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 4, range2_coef_mod = 1.1}
-- Calm Creature
-- lvl 5 = 6
-- lvl 15 = 11
-- lvl 30 = 20
spell_table[50] = {coef = 0.35, mag_pow = 0.9, dur_pow = -0.8, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 2, range2_coef_mod = 1.1}
-- Frenzy Humanoid
-- Very strong, so expensive
-- most humanoids are lower than 20
-- lvl 5 = 14
-- lvl 15 = 24
-- lvl 30 = 38
-- on target spells even harder, modifier is low to encourage using them this way
spell_table[51] = {coef = 0.6, mag_pow = 0.9, dur_pow = -0.8, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 9, range2_coef_mod = 1.1}
-- Frenzy Creature
-- useful now, but on target spells will be much better
-- lvl 5 on target = 11
-- lvl 15 on target = 19
-- lvl 30 on target = 31
spell_table[52] = {coef = 0.45, mag_pow = 0.9, dur_pow = -0.8, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 6, range2_coef_mod = 1.1}
-- Demoralize Humanoid
-- Bad version of Calm, useful for CC
-- lvl 5, 10s = 6
-- lvl 15, 10s = 11
-- lvl 30, 10s = 19
spell_table[53] = {coef = 0.2, mag_pow = 0.9, dur_pow = -0.6, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 3, range2_coef_mod = 1.1}
-- Demoralize Creature
-- Same as above. Most creatures are lvl 15 or lower, so same values.
spell_table[54] = {coef = 0.2, mag_pow = 0.9, dur_pow = -0.6, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 3, range2_coef_mod = 1.1}
-- Rally Humanoid
-- "Come back so you can die" the spell. Costs 70% of demoralize.
spell_table[55] = {coef = 0.14, mag_pow = 0.9, dur_pow = -0.6, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 3, range2_coef_mod = 1.1}
-- Rally Creature
-- Also same values.
spell_table[56] = {coef = 0.14, mag_pow = 0.9, dur_pow = -0.6, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 3, range2_coef_mod = 1.1}
-----------------
-- Mysticism
-----------------
-- Dispel
-- 100 is the lowest magnitude because fuck rng and btb does this too (I assume he knows something)
-- 10 pts on self, 14-16 pts on others.
-- Very low area pow for mass dispels
spell_table[57] = {coef = 0.25, mag_pow = 0.7, area_pow = 0.05, range1_coef_mod = 1.4, range2_coef_mod = 1.6, strength_min = 200}
-- Soultrap
-- Use scrolls if you're really bad at mysticism
-- 10s = 9
-- 60s = 15
spell_table[58] = {coef = 3.6, mag_pow = 0.65, dur_pow = -0.35, area_pow = 0.1, range2_coef_mod = 1.3, dur_min = 10}
-- Telekinesis
-- Offset to nerf cheap 1 second skills
-- You can make really high magnitude at high skill, which is useful at least sometimes (In TR there's a cave with Daedric Pauldron where only high Telekinesis will help)
-- 10, 10s = 10
-- 30, 10s = 15
-- 50, 30s = 22
spell_table[59] = {coef = 0.28, mag_pow = 0.7, dur_pow = -0.45, const_offset = 6}
-- Mark & Recall
spell_table[60] = {const_cost = 17}
spell_table[61] = {const_cost = 17}
-- Interventions
spell_table[62] = {const_cost = 13}
spell_table[63] = {const_cost = 13}
-- Detect Animal
-- 100 for 60 = 10
-- 300 for 360 = 29 (castable if you wish)
spell_table[64] = {coef = 0.1, mag_pow = 0.7, dur_pow = -0.5, dur_offset = 20}
-- Detect Enchantment
spell_table[65] = spell_table[64]
-- Detect Key
spell_table[66] = spell_table[64]
-- Spell Absorption
-- 40, 10s = 18
-- 100, 10s = 41
-- 10, 30s = 9
-- 25, 30s = 17
-- 50, 30s = 31
spell_table[67] = {coef = 0.1, mag_pow = 0.87, dur_pow = -0.4, dur_offset = 10}
-- Reflect
-- Probably gonna use same values for now
spell_table[68] = {coef = 0.1, mag_pow = 0.87, dur_pow = -0.4, dur_offset = 10}
-- Absorb Attribute
spell_table[85] = {coef = 0.3, mag_pow = 0.8, dur_pow = -0.5, dur_min = 10, area_pow = 0.1, range2_coef_mod = 1.3}
-- Absorb Health
-- Damage Health + Restore Health. Another one that will be a pain to balance
spell_table[86] = {coef = 0.85, mag_pow = 0.725, dur_pow = -0.225, area_pow = 0.21, range2_coef_mod = 1.45}
-- Absorb Magicka
-- Ignoring for now, although maybe with huge durational bias...
-- BTB has some premade spells for it - and those are instant? Why? Still would rather ignore.
spell_table[87] = {const_cost = 100}
-- Absorb Fatigue
-- Damage Fatigue + Restore Fatigue, obviously good, best suited for fighters.
-- 50 = 14
-- 100 = 24
-- 10, 10s = 12
-- 30, 10s = 27
spell_table[88] = {coef = 0.4, mag_pow = 0.73, dur_pow = -0.25, area_pow = 0.15, range2_coef_mod = 1.3}
-- Absorb Skill
-- Skipping for now, magic school issue is real.
spell_table[89] = {const_cost = 100}
-----------------
-- Restoration
-----------------
-- Cure Diseases / Corprus
spell_table[69] = {const_cost = 10, range0_const_cost = 12}
spell_table[70] = {const_cost = 15, range0_const_cost = 21}
spell_table[71] = {const_cost = 100}
-- Cure Poison
spell_table[72] = {const_cost = 9, range0_const_cost = 17}
-- Cure Paralyzation
spell_table[73] = {const_cost = 9}
-- Restore Attribute
spell_table[74] = {coef = 0.5, mag_pow = 0.5, dur_pow = -0.1, area_pow = 0.08, range1_coef_mod = 0.7, range2_coef_mod = 0.7, const_offset = 8}
-- Restore Health
spell_table[75] = {coef = 0.5, mag_pow = 0.71, dur_pow = -0.225, area_pow = 0.06, range1_coef_mod = 0.65, range1_dur = -0.4, range2_coef_mod = 0.7, range2_dur = -0.4}
-- Restore Magicka
spell_table[76] = {const_cost = 5} -- for better compatibility with mods that add spells with this effect
-- Restore Fatigue
spell_table[77] = {coef = 0.35, mag_pow = 0.7, dur_pow = -0.335, area_pow = 0.06, range1_coef_mod = 0.55, range1_dur = -0.45, range2_coef_mod = 0.6, range2_dur = -0.45}
-- Restore Skill
-- Same as with Attribute for now
spell_table[78] = {coef = 0.5, mag_pow = 0.5, dur_pow = -0.1, area_pow = 0.08, range1_coef_mod = 0.7, range2_coef_mod = 0.7, const_offset = 8}
-- Fortify Attribute
-- 20, 30s = 14
-- 25, 60s = 19
-- 50, 20s = 25
-- 50, 60s = 32
-- cheaper for targeted spells (buffs)
spell_table[79] = {coef = 0.42, mag_pow = 0.74, dur_pow = -0.5, dur_min = 20, range1_coef_mod = 0.7, range1_dur = -0.62, range2_coef_mod = 0.7, range2_dur = -0.62, ignore_magmin = true}
-- Fortify Health
-- 30, 20s = 10
-- 50, 30s = 16
-- 50, 60s = 19
-- 100, 60s = 31
-- also a bit cheaper for buffs (not that much)
spell_table[80] = {coef = 0.24, mag_pow = 0.71, dur_pow = -0.47, dur_min = 20, range1_coef_mod = 0.8, range1_dur = -0.55, range2_coef_mod = 0.8, range2_dur = -0.55, ignore_magmin = true}
-- Fortify Magicka
-- Strange effect to cast, will skip for now
spell_table[81] = {const_cost = 10, range0_const_cost = 100} -- unlikely buffs added by mods
-- Fortify Fatigue
-- 40, 20s = 9
-- 50, 60s = 15
-- 100, 60s = 25
-- also good for buffs
spell_table[82] = {coef = 0.18, mag_pow = 0.7, dur_pow = -0.47, dur_min = 20, range1_coef_mod = 0.7, range1_dur = -0.55, range2_coef_mod = 0.7, range2_dur = -0.55, ignore_magmin = true}
-- Fortify Skill
-- Fortifying magical schools sucks A LOT, so I've realized that I am gonna disable this skill for now.
-- Anyway, it's a bad design for most skills. With non-combat skills you essentially bypass your character limitations and give yourself absurd speechcraft or sth like that.
-- With combat skills, there are counterparts. For weapons, fortify attack. For acrobatics/athletics, jump/speed. For sneak, chameleon.
-- The only somewhat interesting are armor skills (because they scale off your armor, unlike shield) and block. And these can be restricted to premades imo. 
spell_table[83] = {const_cost = 10, range0_const_cost = 100} -- unlikely buffs added by mods
-- Fortify Maximum Magicka
-- Obvious skip
spell_table[84] = {const_cost = 100}
-- Resist Fire
-- Same values for all 3 elements for now
-- 25, 60s = 14
-- 50, 60s = 26
-- 75, 60s = 34
spell_table[90] = {coef = 0.225, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.55, range2_coef_mod = 0.6, ignore_magmin = true}
-- Resist Frost
spell_table[91] = spell_table[90]
-- Resist Shock
spell_table[92] = spell_table[90]
-- Resist Magicka
-- Similar but just a little bit more expensive (you don't need it that often, actually)
spell_table[93] = {coef = 0.26, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.55, range2_coef_mod = 0.6, ignore_magmin = true}
-- Resist Common Disease
-- You can cure yourself for 12
-- 70, 360s = 8
-- 100, 360s = 11
spell_table[94] = {coef = 0.07, mag_pow = 0.85, dur_pow = -0.75, ignore_magmin = true}
-- Resist Blight Disease
-- 70, 360s = 12
-- 100, 360s = 16
spell_table[95] = {coef = 0.1, mag_pow = 0.85, dur_pow = -0.75, ignore_magmin = true}
-- Resist Corprus
-- prettier filler
spell_table[96] = {coef = 0.2, mag_pow = 0.85, dur_pow = -0.75, ignore_magmin = true}
-- Resist Poison
-- The only point is to pre-cast it to save some magicka later if you get poisoned, or with low skill. Or against short-duration effects
spell_table[97] = {coef = 0.18, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.45, range2_coef_mod = 0.5, ignore_magmin = true}
-- Resist Normal Weapons
-- I don't know, it should not break anything, so... same as Fire & rest?
spell_table[98] = spell_table[90]
-- Resist Paralysis
-- Can be marginally useful
spell_table[99] = {coef = 0.19, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.45, range2_coef_mod = 0.5, ignore_magmin = true}
-- Remove Curse
spell_table[100] = {const_cost = 100}
-- Fortify Attack
spell_table[117] = {coef = 0.35, mag_pow = 0.71, dur_pow = -0.5, dur_min = 20, range1_coef_mod = 0.7, range1_dur = -0.6, range2_coef_mod = 0.7, range2_dur = -0.6, ignore_magmin = true}
-----------------
-- Conjuration
-----------------
-- Turn Undead
-- Like "demoralize creature", but for undead! I have no idea because I've never used this.
-- No strength min because btb uses 50 mag sometimes, let's trust him on this
spell_table[101] = {coef = 0.085, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.12, range2_coef_mod = 1.2}
-- Summon Scamp
-- Same formula for most summons, only different coef. E.G. 60 sec summon is 20% more expensive than 30 sec.
-- 10s = 8
-- 30s = 11
-- 60s = 14
spell_table[102] = {coef = 1.35, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Clannfear
-- 30s = 14
spell_table[103] = {coef = 1.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Daedroth
-- 30s = 26
spell_table[104] = {coef = 3.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Dremora
-- 30s = 22
spell_table[105] = {coef = 2.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Ancestral Ghost
-- Cheapest summon
-- 30s = 7
spell_table[106] = {coef = 0.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Skeletal Minion
-- 30s = 9
spell_table[107] = {coef = 1.1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Bonewalker
-- 30s = 12
spell_table[108] = {coef = 1.55, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Greater Bonewalker
-- 30s = 14
spell_table[109] = {coef = 1.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Bonelord
-- 30s = 17
spell_table[110] = {coef = 2.25, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Winged Twilight
-- 30s = 26
spell_table[111] = {coef = 3.35, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Hunger
-- 30s = 20
spell_table[112] = {coef = 2.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Golden Saint
-- Most expensive summon. Still summonable for 60s by master mage.
-- 30s = 33
spell_table[113] = {coef = 4.15, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Flame Atronach
-- 30s = 18
spell_table[114] = {coef = 2.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Frost Atronach
-- 30s = 22
spell_table[115] = {coef = 2.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Storm Atronach
-- 30s = 30
spell_table[116] = {coef = 3.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Centurion Sphere
-- 30s = 13
spell_table[134] = {coef = 1.65, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Command Creature
-- Shouldn't these 2 go to illusion? Weird if you ask me.
-- 5, 10s = 10
-- 10, 10s = 14
-- 20, 10s = 21
-- 20, 30s = 27
-- 40, 10s = 34
spell_table[118] = {coef = 0.35, mag_pow = 0.85, dur_pow = -0.55, dur_min = 10, const_offset = 5, range2_coef_mod = 1.1}
-- Command Humanoid
-- Same as above for now (humanoids usually have higher levels)
spell_table[119] = {coef = 0.35, mag_pow = 0.85, dur_pow = -0.55, dur_min = 10, const_offset = 5, range2_coef_mod = 1.1}
-- Bound Dagger
-- Bound has similar scaling to summons
-- 60s = 12
spell_table[120] = {coef = 1.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Longsword
-- 60s = 18
spell_table[121] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Mace
-- 60s = 17
spell_table[122] = {coef = 1.75, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Battleaxe
-- 60s = 22
spell_table[123] = {coef = 2.35, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Spear
-- 60s = 18
spell_table[124] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Longbow
-- 60s = 18
spell_table[125] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- eXTRASPELL (sic!)
spell_table[126] = {const_cost = 100}
-- Bound Cuirass
-- 60s = 18
spell_table[127] = {coef = 1.85, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Helm
-- 60s = 10
spell_table[128] = {coef = 1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Boots
-- 60s = 10
spell_table[129] = {coef = 1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Shield
-- 60s = 9
spell_table[130] = {coef = 0.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Gloves
-- 60s = 10
spell_table[131] = {coef = 1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- skipping some irrelevant ones
-- Rough estimate for these. Intended to use with rebalance mods! Or since these are special spells, enjoy them being OP.
-- Summon Fabricant
-- 30s = 27
spell_table[137] = {coef = 3.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Call Wolf
-- 30s = 14
spell_table[138] = {coef = 1.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Call Bear
-- 30s = 17
spell_table[139] = {coef = 2.2, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Bonewolf
-- 30s = 14
spell_table[140] = {coef = 1.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-----------------
-- Modded Spells
-----------------
-----------------
-- Magicka Expanded
-----------------
-- Banish Daedra
-- premade spell is WAY too strong
spell_table[220] = {coef = 0.9, mag_pow = 0.85, const_offset = 6, range2_coef_mod = 1.3}
-- Summons --
-- Mort's rebalance mods are recommended. Balanced around them.
-- Goblin Grunt
-- 30s = 10
spell_table[223] = {coef = 1.2, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Goblin Officer
-- 30s = 30
spell_table[224] = {coef = 3.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Hulking Fabricant
-- 30s = 36
spell_table[225] = {coef = 4.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Ascended Sleeper
-- 30s = 36
spell_table[226] = {coef = 4.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Draugr
-- Idk, needs further review
-- 30s = 18
spell_table[227] = {coef = 2.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Lich
-- 30s = 35
spell_table[228] = {coef = 4.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound --
-- Bound Claymore
-- 60s = 22
spell_table[229] = {coef = 2.35, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Club
-- 60s = 12
spell_table[230] = {coef = 1.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Daikatana
-- 60s = 24
spell_table[231] = {coef = 2.55, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Katana
-- 60s = 21
spell_table[232] = {coef = 2.25, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Shortsword
-- 60s = 18
spell_table[233] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Staff
-- 60s = 18
spell_table[234] = {coef = 1.85, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Tanto
-- 60s = 18
spell_table[235] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Wakizashi
-- 60s = 22
spell_table[236] = {coef = 2.35, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound War Axe
-- 60s = 18
spell_table[237] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Warhammer
-- 60s = 23
spell_table[238] = {coef = 2.45, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Greaves
-- 60s = 10
spell_table[239] = {coef = 1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Bound Left Pauldron
-- 60s = 7
spell_table[240] = {coef = 0.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Teleportation - Vanilla --
spell_table[241] = {const_cost = 22}
spell_table[242] = spell_table[241]
spell_table[243] = spell_table[241]
spell_table[244] = spell_table[241]
spell_table[245] = spell_table[241]
spell_table[246] = spell_table[241]
spell_table[247] = spell_table[241]
spell_table[248] = spell_table[241]
spell_table[249] = spell_table[241]
spell_table[250] = spell_table[241]
spell_table[251] = spell_table[241]
-- More summons --
-- Ogrim
-- 30s = 19
spell_table[252] = {coef = 2.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- War Durzog
-- 30s = 22
spell_table[253] = {coef = 2.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Spriggan
-- 30s = 23
spell_table[254] = {coef = 3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Steam Centurion
-- 30s = 22
spell_table[255] = {coef = 2.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Steam Archer
-- 30s = 19
spell_table[256] = {coef = 2.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Ash Ghoul
-- Storm Atronach level power-wise
-- 30s = 30
spell_table[257] = {coef = 3.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Ash Zombie
-- 30s = 18
spell_table[258] = {coef = 2.45, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Ash Slave
-- 30s = 19
spell_table[259] = {coef = 2.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Centurion Spider
-- 30s = 11
spell_table[260] = {coef = 1.35, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Imperfect
-- nope, it is broken and untouched by mort's mods
-- 30s = 44
spell_table[261] = {coef = 6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Goblin Warchief
-- lvl 35, has strong spells...
-- 30s = 36
spell_table[262] = {coef = 4.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Darkness. 
-- Slightly more expensive blind.
spell_table[263] = {coef = 0.32, mag_pow = 0.71, dur_pow = -0.4, area_pow = 0.075, range2_coef_mod = 1.25}
-- Bound Left Pauldron
-- 60s = 7
spell_table[264] = {coef = 0.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-----------------
-- Chrysopoeia
-----------------
-- "this spell has no magical cost" - fair enough
spell_table[266] = {const_cost = 0.01}
-----------------
-- Magicka Expanded (more)
-----------------
-- TR Summons - many might be too strong, and not intended to be summonable. Values are very approximate. Master mage can somewhat summon all of these, because who cares about balance at high level.
-- Armor Centurion
-- 30s = 14
spell_table[267] = {coef = 1.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Armor Centurion Champion
-- 30s = 21
spell_table[268] = {coef = 2.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Draugr Housecarl
-- 30s = 31
spell_table[269] = {coef = 4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Draugr Lord
-- 30s = 35
spell_table[270] = {coef = 4.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Dridea
-- 30s = 31
spell_table[271] = {coef = 4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Dridea Monarch
-- 750 hp??? Wth.
-- 30s = 39
spell_table[272] = {coef = 5.1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Frost Lich
-- 30s = 31
spell_table[273] = {coef = 4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Giant
-- 1000 hp.
-- 30s = 40
spell_table[274] = {coef = 5.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Goblin Shaman
-- 30s = 21
spell_table[275] = {coef = 2.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Greater Lich
-- Yeah...
-- 30s = 41
spell_table[276] = {coef = 5.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Lamia
-- Aren't they supposed to be aquatic? How does this even work?
-- 30s = 14
spell_table[277] = {coef = 1.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Mammoth
-- 1500 hp
-- 30s = 39
spell_table[278] = {coef = 5.2, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Minotaur
-- 1200 hp
-- 30s = 39
spell_table[279] = {coef = 5.2, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Mud Golem
-- 30s = 16
spell_table[280] = {coef = 2.1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Parastylus
-- 30s = 13
spell_table[281] = {coef = 1.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Plain Strider
-- 30s = 23
spell_table[282] = {coef = 3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Raki
-- 30s = 19
spell_table[283] = {coef = 2.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Sabre Cat
-- 30s = 23
spell_table[284] = {coef = 3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Silt Strider
-- why walk when you can ride... it hits like a truck and has 800 hp!
-- 30s = 39
spell_table[285] = {coef = 5.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Sload
-- 30s = 31
spell_table[286] = {coef = 4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Swamp Troll
-- 30s = 15
spell_table[287] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Welkynd Spirit
-- 30s = 18
spell_table[288] = {coef = 2.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Wereboar
-- 30s = 27
spell_table[289] = {coef = 3.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Velk
-- 30s = 8
spell_table[290] = {coef = 1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Vermai
-- 30s = 18
spell_table[291] = {coef = 2.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Thebataur
-- 1500 hp, hits like a truck...
-- 30s = 42
spell_table[292] = {coef = 5.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Teleportation - TR
spell_table[293] = spell_table[241]
spell_table[294] = spell_table[241]
spell_table[295] = spell_table[241]
spell_table[296] = spell_table[241]
spell_table[297] = spell_table[241]
spell_table[298] = spell_table[241]
spell_table[299] = spell_table[241]
spell_table[300] = spell_table[241]
spell_table[301] = spell_table[241]
spell_table[302] = spell_table[241]
spell_table[303] = spell_table[241]
spell_table[304] = spell_table[241]
spell_table[305] = spell_table[241]
spell_table[306] = spell_table[241]
spell_table[307] = spell_table[241]
spell_table[308] = spell_table[241]
spell_table[309] = spell_table[241]
spell_table[310] = spell_table[241]
-- Weather
-- High cost is for immersion (imagine being able to control weather)
spell_table[312] = {const_cost = 30}
spell_table[313] = {const_cost = 30}
spell_table[314] = {const_cost = 30}
-- Ash
spell_table[315] = {const_cost = 33}
-- Blight
spell_table[316] = {const_cost = 36}
spell_table[317] = {const_cost = 30}
spell_table[318] = {const_cost = 30}
spell_table[319] = {const_cost = 30}
spell_table[320] = {const_cost = 30}
spell_table[321] = {const_cost = 30}
-- Call Lightning
spell_table[331] = {coef = 0.7, mag_pow = 0.7, dur_pow = 0, dur_offset = 10, const_offset = 2}

-- Blink
-- seems like a pretty powerful spell!
spell_table[325] = {const_cost = 16}

-- Call Werewolf - filler value (it's bugged)
spell_table[326] = {const_cost = 20}

-- Clone
spell_table[328] = {coef = 0.45, mag_pow = 0.75, dur_pow = -0.5, area_pow = 0.1, dur_min = 10, ignore_magmin = true, const_offset = 5, range2_coef_mod = 1.1}
-- Clone effect (filler)
spell_table[329] = {const_cost = 1}
-- Mind Scan
spell_table[330] = {coef = 0.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20, const_offset = 10}
-- Mind Rip
spell_table[331] = {const_cost = 20}
-- Soul Scrye
spell_table[332] = {coef = 0.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20, const_offset = 7}
-- Coalesce
-- this is something I'll fully support in my modifier update
spell_table[333] = {const_cost = 7}
-- Ash Shell
spell_table[334] = {coef = 0.75, mag_pow = 0.65, dur_pow = 0, dur_offset = 10, const_offset = 2}
-- Permutation
-- almost impossible to balance, it'll be useless at low conju and too strong at high
spell_table[335] = {coef = 3.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-----------------
-- Enhanced Detection
-----------------
-- Using same values as in vanilla
spell_table[336] = {coef = 0.1, mag_pow = 0.7, dur_pow = -0.5, dur_offset = 20}
spell_table[337] = spell_table[336]
spell_table[338] = spell_table[336]
spell_table[339] = spell_table[336]
spell_table[340] = spell_table[336]
spell_table[341] = spell_table[336]
spell_table[342] = spell_table[336]
-----------------
-- 3E 427 A Space Odyssey
-----------------
-- Float
-- Seems like a very powerful effect, didn't try the mod tho, might change it
spell_table[424] = {coef = 0.4, mag_pow = 0.75, dur_pow = -0.25, const_offset = 6, area_pow = 0.12, range1_coef_mod = 1.5, range2_coef_mod = 1.7}
-----------------
-- OAAB Dark Temptations
-----------------
-- Summon Dark Seducer
-- Same as Golden Saint
spell_table[427] = {coef = 4.15, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Magicka Expanded Continues
-- Palm Lightning
-- no idea how good it is!
spell_table[432] = {coef = 0.59, mag_pow = 0.71, dur_pow = -0.13, area_pow = 0.11}

-----------------
-- Customizable MWSE Multi Mark and Harder Recall
-----------------
-- Same as Vanilla
spell_table[601] = {const_cost = 17}
spell_table[602] = {const_cost = 17}
-----------------
-- Necrocraft
-----------------
-- I haven't played the mod, values are very experimental!
-- Call Skeleton Cripple
spell_table[656] = {const_cost = 10}
-- Call Skeleton Warrior
spell_table[657] = {const_cost = 17}
-- Call Skeleton Champion
spell_table[658] = {const_cost = 24}
-- Call Bonespider
spell_table[659] = {const_cost = 10}
-- Call Bonelord
spell_table[660] = {const_cost = 17}
-- Call Boneoverlord
spell_table[661] = {const_cost = 24}
-- Call Bonewalker
spell_table[662] = {const_cost = 10}
-- Call Greater Bonewalker
spell_table[663] = {const_cost = 17}
-- Call Mummy
-- unused?
spell_table[664] = {const_cost = 24}
-- Commune Dead
spell_table[665] = {coef = 1.8, mag_pow = 0.7, dur_pow = -0.5, dur_offset = 20, const_offset = 6}
-- Raise Skeleton
-- Level 10 = 15
-- Level 20 = 24
-- Level 30 = 32
-- Level 40 = 40
spell_table[666] = {coef = 1.15, mag_pow = 0.79, const_offset = 3}
-- Raise Bone Construct
spell_table[667] = {coef = 1.15, mag_pow = 0.79, const_offset = 3}
-- Raise Corpse
spell_table[668] = {coef = 1.15, mag_pow = 0.79, const_offset = 3}
-- Death Pact
-- 30s = 15
spell_table[669] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Corrupt Soulgem
-- I don't understand what magnitude does, just a guess based on values
-- 20 = 16
-- 40 = 25
spell_table[670] = {coef = 0.7, mag_pow = 0.79, const_offset = 3}
-- Spread Disease
spell_table[671] = {const_cost = 10, range2_const_cost = 14}
-- Dark Ritual
-- Again, just a guess, tell me if it's wrong
spell_table[672] = {coef = 0.09, mag_pow = 0.73, dur_pow = -0.25}
-- Feint Death
-- Weaker Paralysis?
-- 10s = 12
-- 20s = 18
spell_table[673] = {coef = 0.3, mag_pow = 1, dur_pow = 0, dur_offset = 10, area_pow = 0.2, range2_coef_mod = 1.4}
-- Conceal Dead
-- 30s = 13
spell_table[674] = {coef = 1.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Spirit
-- No idea, so about half of raise spells
-- 20 = 12
-- 40 = 19
spell_table[675] = {coef = 0.575, mag_pow = 0.79, const_offset = 2}
-- Bone Binding
-- Unused?
spell_table[676] = {const_cost = 10}
-----------------
-- Extradimensional Pockets
-----------------
-- Pockets 50 = 10
-- Pockets 200 = 27
spell_table[701] = {coef = 0.4, mag_pow = 0.7}
-----------------
-- Bound Ammo
-----------------
-- Bolts and Arrows
spell_table[704] = {coef = 1.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
spell_table[705] = {coef = 1.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Crossbow
spell_table[706] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-----------------
-- Animate Weapon
-----------------
-- 60 seconds = 10
spell_table[711] = {coef = 0.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20, const_offset = 3}

-----------------
-- Leech Effects
-----------------
-- Leech Health
-- 10, 30s = 13
-- 20, 30s = 23
-- 30, 30s = 32
spell_table[900] = {coef = 0.18, mag_pow = 0.85, dur_pow = -0.35}
-- Leech Magicka
-- it's unusable in spellmaker, but just in case
spell_table[901] = {coef = 0.2, mag_pow = 0.85, dur_pow = -0.35}
-- Leech Fatigue
-- 10, 30s = 11
-- 20, 30s = 19
-- 30, 30s = 27
spell_table[902] = {coef = 0.15, mag_pow = 0.85, dur_pow = -0.35}
-----------------
-- Tamriel Rebuilt
-----------------
-- I haven't played with the new TR, values are just what it seems like from tes3view / their lua file
-- Summon Devourer
-- 30s = 30
spell_table[2090] = {coef = 3.75, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Dremora Archer
-- 30s = 23
spell_table[2091] = {coef = 3.05, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Dremora Spellcaster
-- 30s = 23
spell_table[2092] = {coef = 3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Guardian
-- 30s = 36
spell_table[2093] = {coef = 4.55, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Rock Chisel Clannfear
-- 30s = 13
spell_table[2094] = {coef = 1.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Ogrim
-- we already have Summon Ogrim at home
spell_table[2095] = spell_table[252]
-- Summon Seducer
-- 30s = 30
spell_table[2096] = {coef = 3.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Dark Seducer
-- 30s = 38
spell_table[2097] = {coef = 4.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Vermai
-- again, already made this for ME
spell_table[2098] = spell_table[291]
-- Summon Storm Monarch
-- 30s = 35
spell_table[2099] = {coef = 4.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Ice Wraith
-- 30s = 25
spell_table[2100] = {coef = 3.2, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Dwemer Spectre
-- 30s = 14
spell_table[2101] = {coef = 1.85, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Steam Centurion
-- again
spell_table[2102] = spell_table[255]
-- Summon Spider Centurion
-- again
spell_table[2103] = spell_table[260]
-- Summon Welkynd Spirit
-- again
spell_table[2104] = spell_table[288]
-- Summon Auroran
-- 30s = 29
spell_table[2105] = {coef = 3.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Herne
spell_table[2107] = {coef = 1.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Morphoid
spell_table[2108] = {coef = 1.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Draugr
spell_table[2109] = {coef = 2.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Spriggan
spell_table[2110] = {coef = 3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- these seem unused?
-- Bound Greaves
spell_table[2111] = spell_table[239]
-- Bound Waraxe
spell_table[2112] = spell_table[237]
-- Bound Warhammer
spell_table[2113] = spell_table[238]
-- Bound HammerResdayn
spell_table[2114] = spell_table[238]
-- Bound RazorResdayn
spell_table[2115] = spell_table[238]
-- Bound Pauldrons
spell_table[2116] = spell_table[239]
-- Summon BoneldGr
spell_table[2117] = {coef = 4.65, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Banish Daedra
spell_table[2119] = spell_table[220]
-- Kyne's Intervention
spell_table[2122] = {const_cost = 13}
-- Summon Ghost
spell_table[2126] = {coef = 1.1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Wraith
spell_table[2127] = {coef = 3.1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Barrowguard
spell_table[2128] = {coef = 1.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon MinoBarrowguard
spell_table[2129] = {coef = 3.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon SkeletonChampion
spell_table[2130] = {coef = 3.1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon AtroFrostMon
spell_table[2131] = {coef = 3.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- misc spells, need time which I don't have -> some placeholder values, thanks to Varlothen
-- Passwall
-- matched Blink
spell_table[2106] = {const_cost = 16}
-- Banish Daedra
-- again
spell_table[2119] = spell_table[220]
-- Reflect Damage
-- matched Reflect
spell_table[2120] = {coef = 0.1, mag_pow = 0.87, dur_pow = -0.4, dur_offset = 10}
-- Detect Human
-- again
spell_table[2121] = spell_table[336]
-- Rad Shield
-- matched Elemental Shields
spell_table[2123] = {coef = 0.21, mag_pow = 0.8, dur_pow = -0.35, range1_coef_mod = 0.5, range2_coef_mod = 0.55}
-- Wabbajack
spell_table[2124] = {const_cost = 20}
-- Insight
spell_table[2125] = {coef = 1, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20, const_offset = 10}
-- Armor Resartus
spell_table[2132] = {coef = 1.75, mag_pow = 0.71, dur_pow = -0.225}
-- Weapon Resartus
spell_table[2133] = {coef = 1.75, mag_pow = 0.71, dur_pow = -0.225}

-----------------
-- Magicka of the Third Era
-----------------
-- Blood Magic (modifier)
spell_table[3401] = {const_cost = 0.01}


-----------------
-- Atronach Expansion
-----------------
-- I haven't played the mod, so I've simply correlated the values to vanilla ones
-- Summon Ash Golem
-- 30s = 14
spell_table[7700] = {coef = 1.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Bone Golem
-- 30s = 13
spell_table[7701] = {coef = 1.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Crystal Golem
-- 30s = 29
spell_table[7702] = {coef = 3.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Flesh Atronach
-- 30s = 26
spell_table[7703] = {coef = 3.35, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Iron Golem
-- 30s = 19
spell_table[7704] = {coef = 2.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Swamp Myconid
-- 30s = 11
spell_table[7705] = {coef = 1.35, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Telvanni Myconid
-- 30s = 31
spell_table[7706] = {coef = 4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-----------------
-- OAAB Grazelands
-----------------
-- I use this mod myself so it is added just in case (summon defect Daedroth)
-- 30s = 23
spell_table[7800] = {coef = 3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-----------------
-- A Taste of Magic
-----------------
-- Fire Aura
-- premade will cost 18
spell_table[24002] = {coef = 0.6, mag_pow = 0.7, dur_pow = -0.25}
-- Drain Dodge
-- same as Blind
spell_table[24003] = spell_table[47]
-- Unbreakable Weapon
-- like mid tier summon
spell_table[24004] = {coef = 2.2, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Pierce
-- will add better support for modifiers in 2090
-- 10 for 100% pierce
spell_table[24005] = {coef = 0.05, mag_pow = 1, ignore_magmin = true}
-- Quicken
-- same as above
-- 5 for 100 (assuming twice as fast?)
spell_table[24006] = {coef = 0.025, mag_pow = 1, ignore_magmin = true}
-- Charge Weapon
-- guesswork
spell_table[24007] = {coef = 1.1, mag_pow = 0.72, dur_pow = -0.13}
-- Repair Weapon
-- like heal but cheaper
spell_table[24009] = {coef = 0.4, mag_pow = 0.7, dur_pow = -0.2}
-- Extend Weapon
-- guesswork
spell_table[24010] = {coef = 0.2, mag_pow = 0.71, dur_pow = -0.3}
-- Haste
-- proportional (baseline spell will cost 40 but that was intended ig)
spell_table[24011] = {coef = 0.7, mag_pow = 0.71, dur_pow = -0.3}
-- Charge Item
-- guesswork
spell_table[24012] = {coef = 1.1, mag_pow = 0.72, dur_pow = -0.13}
-- Frost Aura
-- premade will cost 19
spell_table[24013] = {coef = 0.62, mag_pow = 0.7, dur_pow = -0.25}
-- Shock Aura
-- premade will cost 20
spell_table[24014] = {coef = 0.62, mag_pow = 0.71, dur_pow = -0.25}
-- Weak to BCP - similar to elements (cheaper a bit)
spell_table[24015] = {coef = 0.1, mag_pow = 0.8, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
spell_table[24016] = spell_table[24015]
spell_table[24017] = spell_table[24015]
-- Resist BCP - similar to resist element (also cheaper)
spell_table[24018] = {coef = 0.2, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.55, range2_coef_mod = 0.6, ignore_magmin = true}
spell_table[24019] = spell_table[24018]
spell_table[24020] = spell_table[24018]


--SA Edit: Bound fishing pole
spell_table[3031] =  {coef = 1.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return spell_table
