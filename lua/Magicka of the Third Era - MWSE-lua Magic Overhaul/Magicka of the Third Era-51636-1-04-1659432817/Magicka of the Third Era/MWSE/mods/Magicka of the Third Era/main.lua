-- Config info --
-- Determinism mode affects spell chances.
-- 0 = Vanilla (cringe dice rolls). 1 = Semi-deterministic (no dice rolls for effects where it is abusable like Open). 2 = Full determinism (based and CHIMpilled).
-- Threshold for this is 60% chance.
-- Mod is balanced around 2, which is objectively the best option.
-- You can give a flat chance bonus to non-determinist spells, irrelevant if you use full determinism mode.
-- Mod may make NPCs struggle with casting, so npc_assist is designed to bandaid that. Morrowind NPCs are not intended to fail spells.
-- There are different options on overriding "always to succeed spells".
-- Fatigue penalty defines how much of a cost penalty fatigue gives.
-- Chance formula should not be switched from 3 atm, save for experiments.
-- Armor penalty is similar to fatigue penalty, but for wearing full set of armor with 0 skill.
-- Armor penalty cap is to determine at which skill level penalty goes away.
-- Leveling variables are pretty obvious.
-- Overflowing magicka is experimental and applies diminising returns to magicka pools > 100. Set to 0 to disable, or to high value to make magicka pools much less relevant. 25 is very mild.

local default_config = {
  determinism_mode = 2,
  flat_chance_bonus = 0,
  npc_assist = true,
  override_costs_alwaystosucceed = true,
  override_chances_alwaystosucceed = false,
  fatigue_penalty_mult = 50,
  log_level = "INFO",
  chance_formula = 3,
  experience_gain = true,
  armor_penalty_perc_max = 100,
  armor_penalty_cap_light = 50,
  armor_penalty_cap_medium = 60,
  armor_penalty_cap_heavy = 70,
  leveling_rate_global = 100,
  leveling_rate_destruction = 90,
  leveling_rate_alteration = 100,
  leveling_rate_illusion = 140,
  leveling_rate_conjuration = 150,
  leveling_rate_mysticism = 130,
  leveling_rate_restoration = 85,
  overflowing_magicka_rate = 50
}

local config_name = "Magicka of the Third Era"
local config = mwse.loadConfig(config_name, default_config)
local EasyMCM = require("easyMCM.EasyMCM")

local logger = require("logging.logger")
local log = logger.new{
    name = "Magicka of the Third Era",
    logLevel = config.log_level,
}

local version = "1.04"

local spellmaker_cost = 0
-- flat multiplier to spellmaking cost
local cost_gold_mult = 40

-- Abusable effect IDs that will be determinist under the semi-deterministic mode.
local determinist_effect_table = {8, 10, 13, 39, 43, 44, 60, 61, 62, 63, 64, 65, 66, 69, 70, 71, 72, 73, 74, 78, 79, 83, 90, 91, 92, 93, 97, 99, 118, 119,
241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 601, 602}

-- We store spells here, to reduce the amount of needless calculations
local spell_storage = {}

-- Premade spell list. Can be used as a blacklist later on.
-- don't set cost to 0, mod will freak out
-- skill tables are for spells with negative effects. we don't want these spells to be treated as half-destruction spells
local premade_spells = {
  -- vanilla special spells
  skillmephala_sp = {fixed_cost = 7},
  HealingTouch_SP_uniq = {fixed_cost = 13},
  -- Ahead of the Classes mod, cheaper unique class spells
  aa_cl_antipal_spell = {flat_mult = 0.65},
  aa_cl_astro_spell01 = {flat_mult = 0.75}, -- astro spells are not tested
  aa_cl_astro_spell02 = {flat_mult = 0.75},
  aa_cl_battle_spell = {flat_mult = 0.75}, -- this is a very weak spell atm
  aa_cl_crusad_spell = {flat_mult = 0.75}, -- same as above
  aa_cl_dervish_spell01 = {flat_mult = 0.75},
  aa_cl_dervish_spell02 = {flat_mult = 0.75},
  aa_cl_dire_spell = {flat_mult = 0.6},
  aa_cl_duel_spell = {flat_mult = 0.7},
  aa_cl_gambl_spell = {flat_mult = 0.5}, -- open 10-100 is a bad spell, but you're playing as a gambler, so whatever
  aa_cl_garden_spell = {fixed_cost = 2}, -- it restores magicka on target
  aa_cl_mabrig_spell = {flat_mult = 0.75},
  aa_cl_necro_spell = {flat_mult = 0.75},
  aa_cl_necro_spell02 = {flat_mult = 0.75},
  aa_cl_necro_spell03 = {flat_mult = 0.75},
  aa_cl_pally_spell = {flat_mult = 0.75},
  aa_cl_ranger_spell = {flat_mult = 0.7},
  aa_cl_sailor_spell = {flat_mult = 0.65},
  aa_cl_seraph_spell = {fixed_cost = 14, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}}, -- cure all diseases with fire damage on self
  aa_cl_shaman_spell = {flat_mult = 0.75},
  aa_cl_sharp_spell = {flat_mult = 0.75},
  aa_cl_skald_spell = {flat_mult = 0.65},
  aa_cl_spear_spell = {flat_mult = 0.6},
  aa_cl_veteran_spell = {flat_mult = 0.75},
  -- Magicka of the Third Era's unique spells
  a_ve_uniqsp_01_lifetap = {fixed_cost = 0.05}, -- restore magicka for a price
  a_ve_uniqsp_02_dragonbite = {flat_mult = 0.85},
  a_ve_uniqsp_03_drakeguard = {fixed_cost = 23},
  a_ve_uniqsp_04_sumrit = {fixed_cost = 25, skill_table = {[0] = 0, [1] = 0.5, [2] = 0, [3] = 0, [4] = 0, [5] = 0.5}}, -- fortifies conjuration for a price -> stronger summons are possible -- semi resto semi conj
  a_ve_uniqsp_05_fireball = {flat_mult = 0.9}, -- showcase of a basic synergy that's even cheaper
  a_ve_uniqsp_06_burden = {fixed_cost = 27}, -- strongest burden spell
  a_ve_uniqsp_07_panacea = {fixed_cost = 22},
  a_ve_uniqsp_08_manaleech = {fixed_cost = 23}, -- drain 120 magicka over 30 secs for 23
  a_ve_uniqsp_09_waterstrider = {fixed_cost = 11},
  a_ve_uniqsp_10_absarmor = {fixed_cost = 15},
  a_ve_uniqsp_11_foolsleap = {fixed_cost = 25}, -- icarus flight as a spell, like jump but for resto (less useful for resto unless you also can slowfall)
  a_ve_uniqsp_12_pray_la = {fixed_cost = 13}, -- fortify armor skills
  a_ve_uniqsp_13_pray_ma = {fixed_cost = 13},
  a_ve_uniqsp_14_pray_ha = {fixed_cost = 13},
  a_ve_uniqsp_15_lifetapgr = {fixed_cost = 0.05}, -- bigger lifetap
  a_ve_uniqsp_16_discountmark = {fixed_cost = 12, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 1, [5] = 0}}, -- cheap mark and recall with negatives, forced to be mysticism and not destruction
  a_ve_uniqsp_17_discountrecall = {fixed_cost = 12, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 1, [5] = 0}}, -- just in case, they're at the same trader
  a_ve_uniqsp_18_fortifyall = {fixed_cost = 34},
  a_ve_uniqsp_19_aquaform = {flat_mult = 0.8}, -- another even cheaper synergy
  a_ve_uniqsp_20_vampiricform = {fixed_cost = 25}, -- hard to measure strength of this
  a_ve_uniqsp_21_mehrunesprot = {fixed_cost = 27},
  a_ve_uniqsp_22_giftofmana = {fixed_cost = 10}, -- restore 100 magicka on touch
  a_ve_uniqsp_23_manawell = {fixed_cost = 24}, -- restore 60 magicka over 30 secs
  a_ve_uniqsp_24_chaoticspark = {flat_mult = 0.75},
  a_ve_uniqsp_25_blackstorm = {flat_mult = 0.55}, -- huge aoe damage health that's usually not practical
  a_ve_uniqsp_26_curseoftheproud = {flat_mult = 0.8}, -- weakness to normal weapons debuff
  a_ve_uniqsp_27_annihilatearmor = {fixed_cost = 29}, -- strongest disintegrate armor spell, way stronger than you can make
  a_ve_uniqsp_28_gravecurse = {flat_mult = 0.7}, -- cheap because it's Telvanni exclusive
  a_ve_uniqsp_29_pray_bl = {fixed_cost = 13}, -- fortify block
  a_ve_uniqsp_30_chaoticshockst = {flat_mult = 0.67},
  a_ve_uniqsp_31_desperateprayer = {flat_mult = 0.65}, -- strongest instant self heal, requires Temple rank
  a_ve_uniqsp_32_blackspite = {fixed_cost = 17}, -- self damage damage skill, keep an eye on this in case of balance tweaks
  a_ve_uniqsp_33_vespite = {fixed_cost = 28}, -- same as above but stronger
  a_ve_uniqsp_34_hardenbone = {fixed_cost = 19, skill_table = {[0] = 0, [1] = 0.25, [2] = 0.25, [3] = 0, [4] = 0, [5] = 0.5}}, -- designed to buff undead summons, but can be used as bad damage spell, hence the split
  a_ve_uniqsp_35_livingbomb = {fixed_cost = 17, skill_table = {[0] = 0.5, [1] = 0.25, [2] = 0.25, [3] = 0, [4] = 0, [5] = 0}}, -- alteration buff / bad damage spell
  a_ve_uniqsp_36_holyfire = {flat_mult = 0.93, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}}, -- this and 2 below are destruction spells, but for resto. This one needs high rank in imperial cult.
  a_ve_uniqsp_37_smite = {flat_mult = 0.95, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}},
  a_ve_uniqsp_38_handofjustice = {flat_mult = 0.95, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}},
  a_ve_uniqsp_39_berserk = {fixed_cost = 14, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}}, -- buff with negatives
  a_ve_uniqsp_40_burstofspeed = {fixed_cost = 23},
  a_ve_uniqsp_41_coupdegrace = {fixed_cost = 30}, -- high rank morag tong only
  a_ve_uniqsp_42_fightingprowess = {flat_mult = 0.85},
  a_ve_uniqsp_43_warriorblessing = {flat_mult = 0.9},
  a_ve_uniqsp_44_akamiblessing = {fixed_cost = 12},
  a_ve_uniqsp_45_incompetence = {fixed_cost = 13},
  a_ve_uniqsp_46_counterspell = {fixed_cost = 20},
  a_ve_uniqsp_47_bargainopen = {fixed_cost = 10, skill_table = {[0] = 1, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}}, -- cheaper open 50 with negatives, keep an eye in case formula changes
  a_ve_uniqsp_48_paralyzer = {fixed_cost = 32}, -- strongest paralyze spell
  a_ve_uniqsp_49_c1_frost = {fixed_cost = 14}, -- 3 strong early game destro spells, best used in rotation, located at the same trader.
  a_ve_uniqsp_50_c2_shock = {fixed_cost = 14},
  a_ve_uniqsp_51_c3_fire = {fixed_cost = 14},
  a_ve_uniqsp_52_exhaustfrost = {flat_mult = 0.9} -- another cheaper synergy
}

-- Tables for offensive values for effects, so that you can finally make Crassius Curio ugly for cheap.
-- There are no such tables for buffs because I don't want to differentiate attribute values, and skill buffs are just disabled outside of unique spells (I could leave, like, 4 out of 27, but that'd look ugly)
local att_table_offense = {[0] = 1, [1] = 0.45, [2] = 0.75, [3] = 0.65, [4] = 0.75, [5] = 1, [6] = 0.4, [7] = 0.4}
local skill_table_offense = {[0] = 1, [1] = 0.4, [2] = 0.7, [3] = 0.7, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 0.8, [9] = 0.4, [10] = 1, [11] = 0.6, [12] = 0.6, [13] = 0.6, [14] = 1, [15] = 1, [16] = 0.4,
[17] = 0.7, [18] = 0.4, [19] = 0.5, [20] = 0.4, [21] = 0.7, [22] = 1, [23] = 1, [24] = 0.4, [25] = 0.4, [26] = 1}

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
spell_table[3] = {coef = 0.12, mag_pow = 0.74, dur_pow = -0.2, range1_coef_mod = 0.35, range2_coef_mod = 0.4}
-- Elemental Shields
spell_table[4] = {coef = 0.2, mag_pow = 0.8, dur_pow = -0.35, range1_coef_mod = 0.5, range2_coef_mod = 0.55}
spell_table[5] = {coef = 0.2, mag_pow = 0.8, dur_pow = -0.35, range1_coef_mod = 0.5, range2_coef_mod = 0.55}
spell_table[6] = {coef = 0.2, mag_pow = 0.8, dur_pow = -0.35, range1_coef_mod = 0.5, range2_coef_mod = 0.55}
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
spell_table[15] = {coef = 0.66, mag_pow = 0.72, dur_pow = -0.13, area_pow = 0.125, range2_coef_mod = 1.4}
-- Frost Damage --
-- Cheap for touch spells, expensive for ranged
spell_table[16] = {coef = 0.54, mag_pow = 0.715, dur_pow = -0.17, area_pow = 0.155, range2_coef_mod = 1.55}
-- Poison Damage --
-- Cheap, best for DoTs
spell_table[27] = {coef = 0.58, mag_pow = 0.715, dur_pow = -0.24, area_pow = 0.125, range2_coef_mod = 1.4}
-- Damage Health --
-- Expensive, ok for DoTs and touch spells
spell_table[23] = {coef = 0.64, mag_pow = 0.725, dur_pow = -0.19, area_pow = 0.21, range2_coef_mod = 1.5}
-- Drain Attribute
spell_table[17] = {coef = 0.135, mag_pow = 0.9, dur_pow = -0.65, dur_offset = 10, area_pow = 0.17, range0_const_cost = 100, range1_coef_mod = 0.7}
-- Drain Health
spell_table[18] = {coef = 0.46, mag_pow = 0.68, dur_pow = -0.58, area_pow = 0.1, range0_const_cost = 100, range2_coef_mod = 1.35}
-- Drain Magicka
spell_table[19] = {coef = 0.13, mag_pow = 0.8, dur_pow = -0.56, area_pow = 0.1, range0_const_cost = 100, range2_coef_mod = 1.25}
-- Drain Fatigue
spell_table[20] = {coef = 0.16, mag_pow = 0.65, dur_pow = -0.5, area_pow = 0.12, range0_const_cost = 100, range2_coef_mod = 1.35}
-- Drain Skill
spell_table[21] = {coef = 0.18, mag_pow = 0.8, dur_pow = -0.6, area_pow = 0.12, range0_const_cost = 100, range2_coef_mod = 1.4}
-- Damage Attribute
spell_table[22] = {coef = 0.6, mag_pow = 0.85, dur_pow = -0.2, area_pow = 0.15, range2_coef_mod = 1.4}
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
spell_table[31] = {coef = 0.13, mag_pow = 0.83, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.3}
-- Weakness to diseases
spell_table[32] = {const_cost = 5}
spell_table[33] = spell_table[32]
spell_table[34] = spell_table[32]
-- Weakness to Poison
spell_table[35] = {coef = 0.13, mag_pow = 0.8, dur_pow = -0.48, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.4}
-- Weakness to Normal Weapons
spell_table[36] = {coef = 0.08, mag_pow = 0.77, dur_pow = -0.47, dur_offset = 10, area_pow = 0.09, range2_coef_mod = 1.4}
-- Disintegrate Weapon
spell_table[37] = {coef = 0.07, mag_pow = 0.75, dur_pow = -0.2, area_pow = 0.1, range2_coef_mod = 1.4}
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
-- 10, 40s = 8
-- 50, 60s = 23
spell_table[41] = {coef = 0.1, mag_pow = 0.8, dur_pow = -0.55, range1_coef_mod = 0.8, range2_coef_mod = 0.8, const_offset = 2}
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
spell_table[46] = {coef = 0.7, mag_pow = 0.78, area_pow = 0.08, range2_coef_mod = 1.3}
-- Blind
spell_table[47] = {coef = 0.23, mag_pow = 0.69, dur_pow = -0.4, area_pow = 0.08, range2_coef_mod = 1.25}
-- Sound
-- Increases spell costs by 5% per mag (does not affect spell chance). Might be weaker than Silence in most cases, but remember that AI is dumb and may waste all magicka for 1 spell.
-- 20, 10s = 10
-- 26, 10s = 12
-- 20, 30s = 15
-- 44, 30s = 27
spell_table[48] = {coef = 0.35, mag_pow = 0.7, dur_pow = -0.3, range2_coef_mod = 1.3}
-- Calm Humanoid
-- 100 mag is min because I don't trust this spell (and similar ones)
-- 100 10s = 16
-- 10 is min duration
spell_table[49] = {coef = 0.16, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.12, dur_min = 10, strength_min = 200}
-- Calm Creature
-- Same, but much cheaper since it's less useful
-- 100 10s = 10
spell_table[50] = {coef = 0.1, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.12, dur_min = 10, strength_min = 200}
-- Frenzy Humanoid
-- Very strong, so expensive
-- 100 for 10s = 24
spell_table[51] = {coef = 0.24, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.12, dur_min = 10, strength_min = 200}
-- Frenzy Creature
-- Kinda useless except for some niche quest cases maybe
spell_table[52] = {coef = 0.12, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.12, dur_min = 10, strength_min = 200}
-- Demoralize Humanoid
-- Bad version of Calm, useful for CC
-- This is actually a Mysticism spell in Vanilla, so need to tweak it.
-- 10s = 10
-- 30s = 16
-- 10s 20 ft = 19
spell_table[53] = {coef = 0.1, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.15, strength_min = 200}
-- Demoralize Creature
-- Same as above, but cheaper. These need LOTS of testing.
spell_table[54] = {coef = 0.08, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.12, strength_min = 200}
-- Rally Humanoid
-- "Come back so you can die" the spell. Costs 70% of demoralize, so 10s = 7.
spell_table[55] = {coef = 0.07, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.1, strength_min = 200}
-- Rally Creature
-- Even more useless!
spell_table[56] = {coef = 0.06, mag_pow = 0.7, dur_pow = -0.3, area_pow = 0.1, strength_min = 200}
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
spell_table[79] = {coef = 0.45, mag_pow = 0.72, dur_pow = -0.5, dur_min = 20, range1_coef_mod = 0.7, range1_dur = -0.6, range2_coef_mod = 0.7, range2_dur = -0.6, ignore_magmin = true}
-- Fortify Health
-- 30, 20s = 10
-- 50, 30s = 16
-- 50, 60s = 19
-- 100, 60s = 31
-- also a bit cheaper for buffs (not that much)
spell_table[80] = {coef = 0.27, mag_pow = 0.71, dur_pow = -0.47, dur_min = 20, range1_coef_mod = 0.8, range1_dur = -0.55, range2_coef_mod = 0.8, range2_dur = -0.55, ignore_magmin = true}
-- Fortify Magicka
-- Strange effect to cast, will skip for now
spell_table[81] = {const_cost = 100}
-- Fortify Fatigue
-- 40, 20s = 9
-- 50, 60s = 15
-- 100, 60s = 25
-- also good for buffs
spell_table[82] = {coef = 0.22, mag_pow = 0.7, dur_pow = -0.47, dur_min = 20, range1_coef_mod = 0.7, range1_dur = -0.55, range2_coef_mod = 0.7, range2_dur = -0.55, ignore_magmin = true}
-- Fortify Skill
-- Fortifying magical schools sucks A LOT, so I've realized that I am gonna disable this skill for now.
-- Anyway, it's a bad design for most skills. With non-combat skills you essentially bypass your character limitations and give yourself absurd speechcraft or sth like that.
-- With combat skills, there are counterparts. For weapons, fortify attack. For acrobatics/athletics, jump/speed. For sneak, chameleon.
-- The only somewhat interesting are armor skills (because they scale off your armor, unlike shield) and block. And these can be restricted to premades imo. 
spell_table[83] = {const_cost = 100}
-- Fortify Maximum Magicka
-- Obvious skip
spell_table[84] = {const_cost = 100}
-- Resist Fire
-- Same values for all 3 elements for now
-- 25, 60s = 14
-- 50, 60s = 26
-- 75, 60s = 34
spell_table[90] = {coef = 0.24, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.55, range2_coef_mod = 0.6, ignore_magmin = true}
-- Resist Frost
spell_table[91] = spell_table[90]
-- Resist Shock
spell_table[92] = spell_table[90]
-- Resist Magicka
-- Similar but just a little bit more expensive (you don't need it that often, actually)
spell_table[93] = {coef = 0.285, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.55, range2_coef_mod = 0.6, ignore_magmin = true}
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
spell_table[96] = {const_cost = 100}
-- Resist Poison
-- The only point is to pre-cast it to save some magicka later if you get poisoned, or with low skill. Or against short-duration effects
spell_table[97] = {coef = 0.17, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.45, range2_coef_mod = 0.5, ignore_magmin = true}
-- Resist Normal Weapons
-- I don't know, it should not break anything, so... same as Fire & rest?
spell_table[98] = spell_table[90]
-- Resist Paralysis
-- Can be marginally useful
spell_table[99] = {coef = 0.19, mag_pow = 0.85, dur_pow = -0.7, dur_min = 20, range1_coef_mod = 0.45, range2_coef_mod = 0.5, ignore_magmin = true}
-- Remove Curse
spell_table[100] = {const_cost = 100}
-- Fortify Attack
spell_table[117] = {coef = 0.37, mag_pow = 0.71, dur_pow = -0.5, dur_min = 20, range1_coef_mod = 0.7, range1_dur = -0.6, range2_coef_mod = 0.7, range2_dur = -0.6, ignore_magmin = true}
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
-- 30s = 23
spell_table[105] = {coef = 3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
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
spell_table[110] = {coef = 2.2, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Winged Twilight
-- 30s = 26
spell_table[111] = {coef = 3.4, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Hunger
-- 30s = 20
spell_table[112] = {coef = 2.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Golden Saint
-- Most expensive summon. Still summonable for 60s by master mage.
-- 30s = 33
spell_table[113] = {coef = 4.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Flame Atronach
-- 30s = 18
spell_table[114] = {coef = 2.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Frost Atronach
-- 30s = 22
spell_table[115] = {coef = 2.8, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Summon Storm Atronach
-- 30s = 30
spell_table[116] = {coef = 3.9, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
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
spell_table[225] = {coef = 4.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Ascended Sleeper
-- 30s = 36
spell_table[226] = {coef = 4.6, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Draugr
-- Idk, needs further review
-- 30s = 18
spell_table[227] = {coef = 2.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Lich
-- 30s = 35
spell_table[228] = {coef = 4.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
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
spell_table[252] = {coef = 2.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
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
spell_table[262] = {coef = 4.7, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-- Darkness, which is in Cortex pack, which I am doing last. Filler for now.
spell_table[263] = {const_cost = 7}
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
-- 30s = 19
spell_table[280] = {coef = 2.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
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
-- 30s = 19
spell_table[291] = {coef = 2.5, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
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
-- OAAB Dark Temptations
-----------------
-- Summon Dark Seducer
-- Same as Golden Saint
spell_table[427] = {coef = 4.3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}
-----------------
-- Customizable MWSE Multi Mark and Harder Recall
-----------------
-- Same as Vanilla
spell_table[601] = {const_cost = 17}
spell_table[602] = {const_cost = 17}
-----------------
-- OAAB Grazelands
-----------------
-- I use this mod myself so it is added just in case (summon defect Daedroth)
-- 30s = 23
spell_table[7800] = {coef = 3, mag_pow = 0.7, dur_pow = -0.3, dur_offset = 20}

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                                                             Synergies
-- Synergies are generalized and stored in this fairly readable, json-like format. You can have as many as you wish! Although having too many might cause lag for the first calculation. Not sure how efficient lua is.
-- "effects_required" is not really needed right now, but I might want to optimize this and so use them to filter stuff early, not sure if it needed. Probably not.
-- "rules" is an array of arrays. Each of these arrays is a rule. Which is a set of requirements. All of these requirements have to work for a single effect.
-- basically, for each array in rule there must be an effect that fits all of the conditions.
-- condition format: {field = ..., value = ..., sign = ...}
-- "field" values : everything that's collected when we pass the spell array to multi-effect formula.
-- "value" is self explanatory
-- "sign" values : "equal", "not equal", "greater", "greater or equal", "less", "less or equal"
-- "benefit" values: so far only "cost_discount", which reduces cost by a percentage
-- "cost_discount" value is multiplied by (cheapest relevant / total cost), so result discount can't be greater than cost_discount / N, where N is amount of required effects.
-- Discount is applied to actual cost, which is the lowest of "sum of effects" and "weighed" cost. But of course, "sum of effects" cost is unsynergetic by itself.
-- These can stack if you hit many synergies with one spell, but they will get less impactful by themselves.
-- If there are several effects that apply the condition (e.g. fire damage for 5 secs and fire damage for 10 secs in example below), lowest one takes priority.
-- It's very unlikely to happen and not profitable to player to build spells this way, but just so you know.
-- Effects that get skipped in advanced formula (const_cost, targeted levitation and such) won't work for synergies

local synergy_table = {}

-- For example, this is a synergy that requires 2 components. Both are Fire Damage, both are Ranged, both have Radius of 5 or greater. One must have duration of 1, other must have it >= 5.
synergy_table[1] = {
  name = "Fireball",
  effects_required = {14},
  rules = {
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"},
      {field = "radius", value = 5, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "duration", value = 1, sign = "equal"},
      {field = "radius", value = 5, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

synergy_table[2] = {
  name = "Chromatic Blast",
  effects_required = {14, 15, 16},
  rules = {
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "min", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "min", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "min", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.45
  }
}

synergy_table[3] = {
  name = "Armor Melter",
  effects_required = {14, 38},
  rules = {
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 38, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[4] = {
  name = "Traveller's Respite",
  effects_required = {8, 77},
  rules = {
    {
      {field = "id", value = 77, sign = "equal"},
      {field = "duration", value = 60, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 8, sign = "equal"},
      {field = "duration", value = 60, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

synergy_table[5] = {
  name = "Calling of Fire",
  effects_required = {4, 114},
  rules = {
    {
      {field = "id", value = 4, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 114, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[6] = {
  name = "Calling of Ice",
  effects_required = {6, 115},
  rules = {
    {
      {field = "id", value = 6, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 115, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[7] = {
  name = "Calling of Storm",
  effects_required = {5, 116},
  rules = {
    {
      {field = "id", value = 5, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 116, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[8] = {
  name = "Bound Suit",
  effects_required = {127, 128, 129, 131},
  rules = {
    {
      {field = "id", value = 127, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 128, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 129, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 131, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.0
  }
}

synergy_table[9] = {
  name = "Daedric Duelist",
  effects_required = {121, 130},
  rules = {
    {
      {field = "id", value = 121, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 130, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[10] = {
  name = "Daedric Berserk",
  effects_required = {117, 123},
  rules = {
    {
      {field = "id", value = 117, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 123, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[11] = {
  name = "Ultimate Detection",
  effects_required = {64, 65, 66},
  rules = {
    {
      {field = "id", value = 64, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 65, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 66, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.8
  }
}

synergy_table[12] = {
  name = "Cruel Wound",
  effects_required = {22, 23},
  rules = {
    {
      {field = "id", value = 22, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"}
    },
    {
      {field = "id", value = 23, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.3
  }
}

synergy_table[13] = {
  name = "Chromatic Shield",
  effects_required = {4, 5, 6},
  rules = {
    {
      {field = "id", value = 4, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 5, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 6, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.45
  }
}

synergy_table[14] = {
  name = "Wintry Chill",
  effects_required = {16, 17},
  rules = {
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"}
    },
    {
      {field = "id", value = 17, sign = "equal"},
      {field = "attribute", value = 4, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.7
  }
}

synergy_table[15] = {
  name = "Muscle Damage",
  effects_required = {15, 17},
  rules = {
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"}
    },
    {
      {field = "id", value = 17, sign = "equal"},
      {field = "attribute", value = 3, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[16] = {
  name = "Ghost Form",
  effects_required = {42, 98},
  rules = {
    {
      {field = "id", value = 42, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 98, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.8
  }
}

synergy_table[17] = {
  name = "Energy Drain",
  effects_required = {86, 88},
  rules = {
    {
      {field = "id", value = 86, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "duration", value = 7, sign = "greater or equal"}
    },
    {
      {field = "id", value = 88, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "duration", value = 7, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.3
  }
}

synergy_table[18] = {
  name = "Evaporate Weapon",
  effects_required = {15, 37},
  rules = {
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "min", value = 40, sign = "greater or equal"}
    },
    {
      {field = "id", value = 37, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.85
  }
}

synergy_table[19] = {
  name = "Weakening Poison Field",
  effects_required = {17, 27},
  rules = {
    {
      {field = "id", value = 17, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"},
      {field = "attribute", value = 0, sign = "equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 27, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.85
  }
}

-- based on scroll. these effects will be uneven if you use the same duration, so discount will be big (no point in having longer invisibility than levitation)
synergy_table[20] = {
  name = "Windform",
  effects_required = {10, 39},
  rules = {
    {
      {field = "id", value = 10, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"},
      {field = "min", value = 120, sign = "greater or equal"},
      {field = "duration", value = 20, sign = "greater or equal"}
    },
    {
      {field = "id", value = 39, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.85
  }
}

-- based on scroll. Has many weird effects, so high discount.
synergy_table[21] = {
  name = "Soulrot",
  effects_required = {22, 27, 45},
  rules = {
    {
      {field = "id", value = 22, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "attribute", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 22, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "attribute", value = 5, sign = "equal"}
    },
    {
      {field = "id", value = 27, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "min", value = 15, sign = "greater or equal"}
    },
    {
      {field = "id", value = 45, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "duration", value = 3, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.32
  }
}

-- based on scroll. Suboptimal with almost useless effect, large discount
synergy_table[22] = {
  name = "Black Storm",
  effects_required = {15, 24},
  rules = {
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 2, sign = "less or equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 24, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.5
  }
}

-- based on scroll. Huge synergies due to awkward effects. Not really expecting player to use this unless it's uber cheap.
synergy_table[23] = {
  name = "Baleful Suffering",
  effects_required = {7, 37, 38, 47},
  rules = {
    {
      {field = "id", value = 7, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 37, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 38, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 47, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.6
  }
}

-- based on scroll. Reasonable. Restore part can be used as a regen. Can be used as a big targeted buff.
synergy_table[24] = {
  name = "Warrior's Blessing",
  effects_required = {75, 77, 117},
  rules = {
    {
      {field = "id", value = 75, sign = "equal"},
      {field = "duration", value = 2, sign = "greater or equal"}
    },
    {
      {field = "id", value = 77, sign = "equal"},
      {field = "duration", value = 2, sign = "greater or equal"}
    },
    {
      {field = "id", value = 117, sign = "equal"},
      {field = "min", value = 15, sign = "greater or equal"}
    },
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

-- based on scroll
synergy_table[25] = {
  name = "Hoptoad",
  effects_required = {9, 11},
  rules = {
    {
      {field = "id", value = 9, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 11, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.4
  }
}

-- based on scroll. Also uneven effects here
synergy_table[26] = {
  name = "Psychic Prison",
  effects_required = {45, 58},
  rules = {
    {
      {field = "id", value = 45, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 58, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.65
  }
}

-- based on scroll. Bad scaling and AOE might be not practical.
synergy_table[27] = {
  name = "Illnea's Breath",
  effects_required = {16, 45},
  rules = {
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 45, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.75
  }
}

synergy_table[28] = {
  name = "Amphibious Form",
  effects_required = {0, 1},
  rules = {
    {
      {field = "id", value = 0, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"}
    },
    {
      {field = "id", value = 1, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.45
  }
}

-- probably not very good if you can cast stronger separate buffs, but for low magicka pool might be fine
synergy_table[29] = {
  name = "Fighting Form",
  effects_required = {79},
  rules = {
    {
      {field = "id", value = 79, sign = "equal"},
      {field = "attribute", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 79, sign = "equal"},
      {field = "attribute", value = 3, sign = "equal"}
    },
    {
      {field = "id", value = 79, sign = "equal"},
      {field = "attribute", value = 4, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1
  }
}

synergy_table[30] = {
  name = "Shadow Crawler",
  effects_required = {39, 43},
  rules = {
    {
      {field = "id", value = 39, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 43, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

synergy_table[31] = {
  name = "Tiring Frost (Melee)",
  effects_required = {16, 25},
  rules = {
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"}
    },
    {
      {field = "id", value = 25, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.3
  }
}

synergy_table[32] = {
  name = "Tiring Frost (Ranged)",
  effects_required = {16, 25},
  rules = {
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 25, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.24
  }
}

synergy_table[33] = {
  name = "Warming Fire",
  effects_required = {14, 91},
  rules = {
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 91, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.8
  }
}

synergy_table[34] = {
  name = "Cooling Frost",
  effects_required = {15, 90},
  rules = {
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 90, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.8
  }
}

synergy_table[35] = {
  name = "Exposing Poison",
  effects_required = {27, 31},
  rules = {
    {
      {field = "id", value = 27, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 31, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

synergy_table[36] = {
  name = "Fatal Wound",
  effects_required = {23, 27},
  rules = {
    {
      {field = "id", value = 23, sign = "equal"},
      {field = "duration", value = 1, sign = "equal"},
      {field = "min", value = 40, sign = "greater or equal"}
    },
    {
      {field = "id", value = 27, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.4
  }
}

-----------------------------------------------------------------------------------------------------------------------------------------------

function detect_synergies (effect_db, effect_costs, synergy_array)
  -- preparation
  local synergy_bonuses = {synergy_ids = {}, cost_discount = 0}
  local total_effect_cost = 0
  for i = 1, #effect_costs do
    total_effect_cost = total_effect_cost + effect_costs[i]
  end
  
  -- go through every synergy to see if it fits. It's not optimized atm, so not sure if it will behave well with 50 synergies. I plan to add a lot, after all.
  for i, synergy in ipairs(synergy_array) do

    local required_effect_amount = #synergy.effects_required

    --local effect_check_array = {}
    --for j=1, required_effect_amount do
    --  effect_check_array[effects_required[j]] = -1
    --end

    local synergy_rules = synergy.rules
    local synergy_fulfilment_array = {}
    for a = 1, #synergy_rules do
      synergy_fulfilment_array[a] = -1
    end

    -- iterate through each rule (pick each for one synergy)
    for j, rule in ipairs(synergy_rules) do
      -- iterate through each effect
      for v, effect in ipairs(effect_db) do
        --print(string.format("Effect ID: %d. Mag: %d-%d. ", effect.id, effect.min, effect.max))
        local is_legit_effect = true
        local rule_fulfilment_array = {}
        for b = 1, #rule do
          rule_fulfilment_array[b] = -1
        end
        -- iterate through each part of rule, for each effect
        for k, item in ipairs(rule) do
          --print(string.format("Rule part requirement: %s is %s %d", item.field, item.sign, item.value))
          local field_value = effect[item.field]
          -- convert the sign into condition
          if item.sign == "equal" then
            if field_value == item.value then
              --print("Rule part satisfied!")
            else
              --print("Rule part not satisfied!")
              is_legit_effect = false
            end
          elseif item.sign == "greater" then
            if field_value > item.value then
              --print("Rule part satisfied!")
            else
              --print("Rule part not satisfied!")
              is_legit_effect = false
            end
          elseif item.sign == "greater or equal" then
            if field_value >= item.value then
              --print("Rule part satisfied!")
            else
              --print("Rule part not satisfied!")
              is_legit_effect = false
            end
          elseif item.sign == "less" then
            if field_value < item.value then
              --print("Rule part satisfied!")
            else
              --print("Rule part not satisfied!")
              is_legit_effect = false
            end
          elseif item.sign == "less or equal" then
            if field_value <= item.value then
              --print("Rule part satisfied!")
            else
              --print("Rule part not satisfied!")
              is_legit_effect = false
            end
          elseif item.sign == "not equal" then
            if field_value ~= item.value then
              --print("Rule part satisfied!")
            else
              --print("Rule part not satisfied!")
              is_legit_effect = false
            end  
          end
          -- if satisfies this part, for this part's id, set it's value in array to effect number
          if is_legit_effect then
            --print(string.format("Effect number %d satisfies rule %d of the synergy rule array for rule no. %d", v, j, i))
            rule_fulfilment_array[k] = v
          end  
        end
          -- now that our effect passed through every part of rule, check the fulfilment array. if at least one is wrong, the effect is not legit for the rule.
        for c = 1, #rule_fulfilment_array do
          if rule_fulfilment_array[c] == -1 then  
            is_legit_effect = false
          end
        end
        -- if effect satisfies all conditions described in this rule, we write it down
        if is_legit_effect then
          synergy_fulfilment_array[j] = v
        end
      end
    end

    -- check the synergy array whether all the rules are satisfied
    local synergy_works = true
    for d = 1, #synergy_fulfilment_array do
      if synergy_fulfilment_array[d] == -1 then
        synergy_works = false
      end
      --print(string.format("Rule number %d. Satisfied by effect number: %d.", d, synergy_fulfilment_array[d]))
    end

    if synergy_works then
      log:trace(string.format("Synergy %s works for this spell!", synergy.name, synergy.benefit.type))
      table.insert(synergy_bonuses.synergy_ids, i)
      local effect_weight = 0
      -- weight is equal to the lowest relevant / total cost
      for d = 1, #synergy_fulfilment_array do
        if effect_weight == 0 then
          effect_weight = effect_costs[synergy_fulfilment_array[d]]
        else
          effect_weight = math.min(effect_weight, effect_costs[synergy_fulfilment_array[d]])
        end
      end
      effect_weight = effect_weight / total_effect_cost
      log:trace(string.format("Weight for this synergy: %.2f", effect_weight))
      -- for now only cost discount is supported
      if synergy.benefit.type == "cost_discount" then
        synergy_bonuses.cost_discount = synergy_bonuses.cost_discount + effect_weight * synergy.benefit.value
      end
    end

  end

  return synergy_bonuses
end

-- Thanks to nimble armor mod for this, using it's values for now
armorParts = {
	[0] = 0.1,	-- helmet
	[1] = 0.25,	-- cuirass
	[2] = 0.05, -- left pauldron
	[3] = 0.05, -- right pauldron
	[4] = 0.15, -- greaves
	[5] = 0.15, -- boots
	[6] = 0.05, -- left gauntlet
	[7] = 0.05, -- right gauntlet
	[8] = 0.15	-- shield
--	[9] = 0.05, -- left bracer uses the same value as left gauntlet
--	[10] = 0.05 -- right bracer uses the same value as right gauntlet
}

local function get_armor_coefs(armored_actor)
  local armor = {light = 0, medium = 0, heavy = 0}
	if armored_actor == nil then -- check for disabled actors
		return armor
	end
	for i, value in pairs(armorParts) do
		local stack = tes3.getEquippedItem{actor = armored_actor, objectType = tes3.objectType.armor, slot = i}
		if i == tes3.armorSlot.leftGauntlet or i == tes3.armorSlot.rightGauntlet then	-- if no gloves - check for bracers
			if not stack then stack = tes3.getEquippedItem{actor = armored_actor, objectType = tes3.objectType.armor, slot = i+3} end
		end
		if stack then
			local item = stack.object
			if item.weightClass == 0 then
				armor.light = armor.light + value
			elseif item.weightClass == 1 then
				armor.medium = armor.medium + value
			elseif item.weightClass == 2 then
				armor.heavy = armor.heavy + value
			end
		end
	end
  return armor
end

local function spellmaker_update(e)
  -- This function updates the spell cost/chance in spellmaker. Also shows the synergies and recalculates the price based on cost.
  log:trace("Spellmaking menu is being updated!")
  local menu = tes3ui.findMenu("MenuSpellmaking")
  if menu then
    -- Find effects in the UI
    local ms_sel = menu:findChild("MenuSpellmaking_SpellEffectsLayout")
    local psp_p = ms_sel:findChild("PartScrollPane_pane")
    local effect_database = psp_p.children
    -- Effect variables
    local effect_id = 0
    local effect_school = 0
    local duration = 1
    local mag_min = 0
    local mag_max = 0
    local radius = 0
    local range = 0
    local e_attribute = 0
    local e_skill = 0
    -- Calculation variables
    local effect_cost = 0
    local total_effect_cost = 0
    local spell_cost = 0
    local spell_chance = 0
    local player_skill = 0
    local relevant_skill = 0
    local skills_weighed = 0
    local skill_for_spell = 0
    local effect_db = {}
    local cost_db = {}
    local magic_skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}
    local discount = 0
    -- Calculations for effects
    for i=1, #effect_database do
      effect_id = effect_database[i]:getPropertyObject("MenuSpellmaking_Effect").id
      effect_school = effect_database[i]:getPropertyObject("MenuSpellmaking_Effect").school
      duration = effect_database[i]:getPropertyInt("MenuSpellmaking_Duration")
      -- Some stupid bug when default duration is 0, ruins the calculations and is factually incorrect (you can never have a duration of 0 in a spell, without MCP at least)
      if duration == 0 then
        duration = 1
      end
      mag_min = effect_database[i]:getPropertyInt("MenuSpellmaking_MagLow")
      mag_max = effect_database[i]:getPropertyInt("MenuSpellmaking_MagHigh")
      radius = effect_database[i]:getPropertyInt("MenuSpellmaking_Area")
      range = effect_database[i].text

      e_attribute = effect_database[i]:getPropertyInt("MenuSpellmaking_Attribute")
      e_skill = effect_database[i]:getPropertyInt("MenuSpellmaking_Skill")
      
      -- Why can't you just be normal
      if range == "Target" then
        range = 2
      elseif range == "Touch" then
        range = 1
      else
        range = 0
      end
      
      local effect_data = {id = effect_id, min = mag_min, max = mag_max, duration = duration, radius = radius, rangeType = range, attribute = e_attribute, skill = e_skill}
      effect_cost = effect_cost_advanced(effect_data)
      effect_db[i] = effect_data
      cost_db[i] = effect_cost
      
      total_effect_cost = total_effect_cost + effect_cost

      if effect_school >= 0 and effect_school <= 5 then
        magic_skill_table[effect_school] = magic_skill_table[effect_school] + effect_cost
      else
        -- case of custom schools or crap like this
        magic_skill_table[0] = magic_skill_table[0] + effect_cost
      end
    end

    -- If spell is legit, re-calculate the cost
    if total_effect_cost > 0 then
      if #effect_db == 1 then
        log:trace("One-effect spell in the spellmaker found! Using basic formula.")
        spell_cost = total_effect_cost
      else
        log:trace("Multi-effect spell in the spellmaker found! Trying advanced formula.")
        local adv_calc = spell_cost_advanced(effect_db, cost_db)
        spell_cost = adv_calc.cost
        discount = adv_calc.synergies.cost_discount
        if spell_cost == 0 then
          log:debug("Non-legit spell for advanced formula in spellmaking menu! Going for plan B.")
          spell_cost = total_effect_cost
        end
      end

      -- weighing magic skills
      for k=0, 5 do
        magic_skill_table[k] = magic_skill_table[k] / total_effect_cost
        log:trace(string.format("Coeficient for skill %d: %.2f", k, magic_skill_table[k]))
      end

      skill_for_spell = magic_skill_table[0] * tes3.mobilePlayer.alteration.current + magic_skill_table[1] * tes3.mobilePlayer.conjuration.current + magic_skill_table[2] * tes3.mobilePlayer.destruction.current +
      magic_skill_table[3] * tes3.mobilePlayer.illusion.current + magic_skill_table[4] * tes3.mobilePlayer.mysticism.current + magic_skill_table[5] * tes3.mobilePlayer.restoration.current

      spell_chance = calculate_cast_chance(spell_cost, tes3.mobilePlayer.willpower.current, tes3.mobilePlayer.luck.current, skill_for_spell)
      log:trace(string.format("Spell info updated. Skill for spell: %d, Cost: %.2f, Chance: %.2f", skill_for_spell, spell_cost, spell_chance))

      -- display discount
      local cost_text = tostring (math.floor(spell_cost * 100) / 100)
      if discount > 0 then
        cost_text = cost_text .. " (-" .. tostring(math.floor(discount*100)) .. "%)"
      end

      -- forward data for mods that use this value
      e.spellPointCost = spell_cost

      --Needs a small delay since vanilla gets calculated right after this event, and we need to overwrite vanilla
      timer.start{type = timer.real, duration = 0.07, callback = function()
        menu:findChild("MenuSpellmaking_SpellPointCost").text = cost_text
        menu:findChild("MenuSpellmaking_SpellChance").text = tostring (math.floor(spell_chance * 100) / 100)
        menu:findChild("MenuSpellmaking_PriceValueLabel").text = tostring (math.floor(spell_cost * cost_gold_mult)) 
        end}
      
      -- save for cost checker
      spellmaker_cost = spell_cost

    end
  end
end

-- attempt to fit with spellmaker mod
local self_spellmaking = false

-- block spellmaking if you don't have enough gold, thanks to SpellMaker mod for this
local function spellmaking_block(eventData)
  local menu = tes3ui.findMenu("MenuSpellmaking")
  if menu then
    local buyButton = menu:findChild("MenuSpellmaking_Buybutton")
    local gold_amount = tes3.getPlayerGold()
    self_spellmaking = (tes3ui.getServiceActor(e) == nil)
    if self_spellmaking then 
      return
    end
    buyButton:registerBefore(tes3.uiEvent.mouseClick,
				function(mouseClickEventData)
					if gold_amount < math.floor(spellmaker_cost * cost_gold_mult) then
						tes3.messageBox("You don't have enough gold to create this spell")
						return false -- this will prevent the regular mouseclick event from being run
					end
				end
			)
  end
end

local function spellmaking_payment(e)
  if not (self_spellmaking) then
    tes3.removeItem({reference = tes3.player, item = "gold_001", count = math.floor(spellmaker_cost * cost_gold_mult)})
  end
end

-- Update the spell selection UI. Spell costs in UI will be calculated once per spell. They'll be also used whenever player casts these spells.
local function magic_menu_update(e)
    if not e.newlyCreated then return end

    e.element:registerAfter("preUpdate", function()
        local names = e.element:findChild("MagicMenu_spell_names").children
        local costs = e.element:findChild("MagicMenu_spell_costs").children
        local chances = e.element:findChild("MagicMenu_spell_percents").children
        for i=1, #names do
            local spell = names[i]:getPropertyObject("MagicMenu_Spell")
            local spell_id = spell.id
			      --debug.log(spell)
            local effect_cost = 0
            local total_effect_cost = 0
            local spell_cost = 0
            local spell_chance = 0
            local player_skill = 0
            local relevant_skill = 0
            local skill_for_spell = 0
            local skills_weighed = 0
            local fatigue_normalized = 0
            local sound_factor = 0
            local determinist_spell = false
            local effect_db = {}
            local cost_db = {}
            local unique_spell_data = {}
            local magic_skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}
            
            -- Check for uniques.
            if premade_spells[spell_id] then
              log:trace(string.format("Found a unique spell: %s", spell_id))
              unique_spell_data = premade_spells[spell_id]
            end

            -- Check for the semi determinism mode
            if (config.override_costs_alwaystosucceed or not (spell.alwaysSucceeds)) and config.determinism_mode == 1 then
              for j, effect in ipairs(spell.effects) do
                if effect.object then
                  for k, effect_id in ipairs(determinist_effect_table) do
                    if effect.id == effect_id then
                      determinist_spell = true
                      log:trace(string.format("Found a determinist effect: %s", effect.id))
                    end
                  end
                end
              end
            end
            -- Check if spell's already in the storage
            if tes3.player.data.motte_spell_storage[spell_id] then
              local spell_data = tes3.player.data.motte_spell_storage[spell_id]
              magic_skill_table = spell_data.skill_table
              spell_cost = spell_data.cost
              log:trace(string.format("Spell %s found in storage. Cost: %.2f.", spell, spell_cost))
              -- we are using 6 here because of a lua bug
              skill_for_spell = magic_skill_table[6] * tes3.mobilePlayer.alteration.current + magic_skill_table[1] * tes3.mobilePlayer.conjuration.current + magic_skill_table[2] * tes3.mobilePlayer.destruction.current +
              magic_skill_table[3] * tes3.mobilePlayer.illusion.current + magic_skill_table[4] * tes3.mobilePlayer.mysticism.current + magic_skill_table[5] * tes3.mobilePlayer.restoration.current
            else  
              local old_cost = spell.magickaCost
              
              if config.override_costs_alwaystosucceed or not (spell.alwaysSucceeds) then
                for j, effect in ipairs(spell.effects) do
                  if effect.object then                  

                    effect_cost = effect_cost_advanced(effect)
                    cost_db[j] = effect_cost
                    effect_db[j] = effect
                    total_effect_cost = total_effect_cost + effect_cost
                    
                    if effect.object.school >= 0 and effect.object.school <= 5 then
                      magic_skill_table[effect.object.school] = magic_skill_table[effect.object.school] + effect_cost
                    else
                      -- case of custom schools or crap like this
                      magic_skill_table[0] = magic_skill_table[0] + effect_cost
                    end

                  end
                end
                -- Process the non-autosucceed, legit spells
                if total_effect_cost > 0 then
                  -- skill for multi effect spells is a weighed arithmetic average of the effect skills
                  for k=0, 5 do
                    magic_skill_table[k] = magic_skill_table[k] / total_effect_cost
                    log:trace(string.format("Coeficient for skill %d: %.2f", k, magic_skill_table[k]))
                  end
                  skill_for_spell = magic_skill_table[0] * tes3.mobilePlayer.alteration.current + magic_skill_table[1] * tes3.mobilePlayer.conjuration.current + magic_skill_table[2] * tes3.mobilePlayer.destruction.current +
                  magic_skill_table[3] * tes3.mobilePlayer.illusion.current + magic_skill_table[4] * tes3.mobilePlayer.mysticism.current + magic_skill_table[5] * tes3.mobilePlayer.restoration.current
                  
                  -- calculate cost of spell
                  if #effect_db == 1 then
                    log:trace("One-effect spell in the spell menu found! Using basic formula.")
                    spell_cost = total_effect_cost
                  else
                    log:trace("Multi-effect spell in the spell menu found! Trying advanced formula.")
                    local adv_calc = spell_cost_advanced(effect_db, cost_db)
                    spell_cost = adv_calc.cost
                    if spell_cost == 0 then
                      log:trace("Non-legit spell for advanced formula in spell menu! Going for plan B.")
                      spell_cost = total_effect_cost
                    end
                  end
                  -- unique checks
                  if unique_spell_data.use_premade_cost then
                    spell_cost = old_cost
                    log:trace("Found unique spell rule. Spell will use old costs.")
                  end
                  if unique_spell_data.fixed_cost then
                    spell_cost = unique_spell_data.fixed_cost
                    log:trace("Found unique spell rule. Spell will use pre-written costs.")
                  end
                  if unique_spell_data.flat_mult then
                    spell_cost = spell_cost * unique_spell_data.flat_mult
                    log:trace("Found unique spell rule. Spell will have it's cost multiplied by a value.")
                  end
                  if unique_spell_data.skill_table then
                    magic_skill_table = unique_spell_data.skill_table
                    log:trace("Found unique spell rule. Spell will use custom skill table.")
                  end
                  -- write it down to the storage so that we don't calculate it again
                  -- this is a workaround because index 0 in table causes issues when loaded in save game
                  local magic_skill_table2 = {}
                  magic_skill_table2[1] = magic_skill_table[1]
                  magic_skill_table2[2] = magic_skill_table[2]
                  magic_skill_table2[3] = magic_skill_table[3]
                  magic_skill_table2[4] = magic_skill_table[4]
                  magic_skill_table2[5] = magic_skill_table[5]
                  magic_skill_table2[6] = magic_skill_table[0]
                  tes3.player.data.motte_spell_storage[spell_id] = {cost = spell_cost, skill_table = magic_skill_table2}
                end
              else
                spell_cost = spell.magickaCost
                local do_not_save_this = False
                -- Find the weakest school skill
                local weakest_school = spell:getLeastProficientSchool(tes3.mobilePlayer)
                if weakest_school == 0 then
                  relevant_skill = tes3.mobilePlayer.alteration.current
                elseif weakest_school == 1 then
                  relevant_skill = tes3.mobilePlayer.conjuration.current
                elseif weakest_school == 2 then
                  relevant_skill = tes3.mobilePlayer.destruction.current
                elseif weakest_school == 3 then
                  relevant_skill = tes3.mobilePlayer.illusion.current
                elseif weakest_school == 4 then
                  relevant_skill = tes3.mobilePlayer.mysticism.current
                elseif weakest_school == 5 then
                  relevant_skill = tes3.mobilePlayer.restoration.current
                else
                  relevant_skill = 100
                  -- we don't want to save such spells into db
                  do_not_save_this = True
                  log:debug("Either no school or custom school - setting skill to 100. Not saving this skill in the DB.")
                end
                log:trace(string.format("Found a pre-made spell %s, that's intended to always succeed, so it's cost will stay. Relevant skill: %d", spell.id, relevant_skill))
                skill_for_spell = relevant_skill
                -- save legit spells
                if not(do_not_save_this) then
                  magic_skill_table[weakest_school] = 1
                  tes3.player.data.motte_spell_storage[spell_id] = {cost = spell_cost, skill_table = magic_skill_table}
                end
              end
            end
            
            -- If the spell has been at least partially processed, edit it's UI entry
            if spell_cost > 0 then
              log:trace(string.format("Spell processed. ID: %s. Your skill for this spell: %d", spell.id, skill_for_spell))
              spell_chance = calculate_cast_chance(spell_cost, tes3.mobilePlayer.willpower.current, tes3.mobilePlayer.luck.current, skill_for_spell)
              -- Fatigue increases costs up to 50% more, these costs do not affect the cast chance
              fatigue_normalized = math.min(1, tes3.mobilePlayer.fatigue.normalized)
              if tes3.mobilePlayer.sound < 0 then
                sound_factor = tes3.mobilePlayer.sound * -0.05
                log:trace(string.format("Player affected by sound. Increasing spell costs by a factor of %.2f...", sound_factor))
              end
              local armor_table = get_armor_coefs(tes3.mobilePlayer)
              local armor_factor = 0
              if config.armor_penalty_perc_max > 0 then
                armor_factor = armor_table.light * math.max(config.armor_penalty_cap_light - tes3.mobilePlayer.lightArmor.current, 0) / config.armor_penalty_cap_light +
                armor_table.medium * math.max(config.armor_penalty_cap_medium - tes3.mobilePlayer.mediumArmor.current, 0) / config.armor_penalty_cap_medium + 
                armor_table.heavy * math.max(config.armor_penalty_cap_heavy - tes3.mobilePlayer.heavyArmor.current, 0) / config.armor_penalty_cap_heavy
                armor_factor = armor_factor * (config.armor_penalty_perc_max / 100)
                if armor_factor > 0 then
                  log:trace(string.format("Player's costs are increased by armor. Factor: %.2f.", armor_factor))
                end
              end
              spell_cost = spell_cost * (1 + (config.fatigue_penalty_mult / 100) * (1 - fatigue_normalized) + sound_factor + armor_factor)
              if tes3.mobilePlayer.magicka.current > 100 then
                spell_cost = spell_cost * (1 + (tes3.mobilePlayer.magicka.current - 100) * config.overflowing_magicka_rate / 10000)
              end
              costs[i].text = tostring (math.floor(spell_cost))
              if spell.alwaysSucceeds and not (config.override_chances_alwaystosucceed) then
                spell_chance = 100
                log:trace(string.format("Spell %s has 100 percent success rate.", spell.id))
              end
              if config.determinism_mode == 2 or determinist_spell then
                if spell_chance > 60 then
                  chances[i].text = "/" .. tostring (math.floor(spell_chance)) .. "(100)"
                else
                  chances[i].text = "/" .. tostring (math.floor(spell_chance)) .. "(0)"
                end
              else
                if spell_chance > 0 then
                  spell_chance = math.min(spell_chance + config.flat_chance_bonus, 100)
                end
                chances[i].text = "/" .. tostring (math.floor(spell_chance))
              end
            end
        end
    end)
end

local function spell_chance_manipulation(e)
  local caster = e.caster.object.mobile
  local spell_cost = 0
  local spell_chance = 0
  local effect_cost = 0
  local total_effect_cost = 0
  local effect_chance = 0

  local spell_id = e.source.id
  local relevant_skill = 0
  local skills_weighed = 0
  local skill_for_spell = 0

  local effect_db = {}
  local cost_db = {}
  local magic_skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}

  local determinist_spell = False
  -- disable for non-spells
  if e.source.castType ~= tes3.spellType.spell then
    return
  end
  -- Calculate costs EXCEPT FOR:
  -- "Always succeed" spells, and ONLY IF "override costs" var is false (default = true)
  -- Costs here are ONLY relevant to chance calculations, cost itself is calculated at the different function
  -- Do we need this check, then?

  -- check if the spell is in storage. If unique spell is NOT in storage, it will get ignored (treated as non-unique). But it always should be in storage, as it gets calculated and added at the cost stage.
  if tes3.player.data.motte_spell_storage[spell_id] then
    local spell_data = tes3.player.data.motte_spell_storage[spell_id]
    magic_skill_table = spell_data.skill_table
    spell_cost = spell_data.cost
    log:trace(string.format("Spell %s found in storage. Preparing for cast chance calculations", spell_id))
    -- we are using 6 here because of a lua bug
    if caster.alteration and caster.conjuration and caster.destruction and caster.illusion and caster.mysticism and caster.restoration then
      skill_for_spell = magic_skill_table[6] * caster.alteration.current + magic_skill_table[1] * caster.conjuration.current + magic_skill_table[2] * caster.destruction.current +
      magic_skill_table[3] * caster.illusion.current + magic_skill_table[4] * caster.mysticism.current + magic_skill_table[5] * caster.restoration.current
    else
      skill_for_spell = 9999 -- creature casters
    end
    spell_chance = calculate_cast_chance(spell_cost, caster.willpower.current, caster.luck.current, skill_for_spell)
    log:trace(string.format("Resulting cost (for chances): %.2f. Skill for spell: %d. Therefore, chance to cast: %d. Chance calculations stage is finished.", spell_cost, skill_for_spell, spell_chance))
    e.castChance = spell_chance
  else
    if ((not (e.source.alwaysSucceeds) or config.override_costs_alwaystosucceed)) then
      for i, effect in ipairs(e.source.effects) do
        if effect.id ~= -1 then
          
          if config.determinism_mode == 1 then
            for j, effect_id in ipairs(determinist_effect_table) do
              if effect.id == effect_id then
                determinist_spell = True
                log:trace(string.format("Found a determinist effect: %s", effect.id))
              end
            end
          end
          
          effect_cost = effect_cost_advanced(effect)
          log:trace(string.format("[Cost for chances]\nEffect %d:\nName = %s\nDuration = %d\nMagnitude = %d-%d\nRadius = %d\nSkill = %d\nCost = %d", i, effect.object.name, effect.duration, effect.min, effect.max, effect.radius, effect.object.school, effect_cost))
          total_effect_cost = total_effect_cost + effect_cost
          cost_db[i] = effect_cost
          effect_db[i] = effect

          -- Determine the caster's skill for this effect

          if effect.object.school >= 0 and effect.object.school <= 5 then
            magic_skill_table[effect.object.school] = magic_skill_table[effect.object.school] + effect_cost
          else
            -- case of custom schools or crap like this
            magic_skill_table[0] = magic_skill_table[0] + effect_cost
          end
          
        end
      end
    else
    -- deal with cases where we don't want to recalculate costs
      spell_cost = e.source.magickaCost
      -- add check if skill exists
      if e.weakestSchool == 0 then
        if caster.alteration then
          relevant_skill = caster.alteration.current
        else
          relevant_skill = 100
        end
      elseif e.weakestSchool == 1 then
        if caster.conjuration then
          relevant_skill = caster.conjuration.current
        else
          relevant_skill = 100
        end
      elseif e.weakestSchool == 2 then
        if caster.destruction then
          relevant_skill = caster.destruction.current
        else
          relevant_skill = 100
        end
      elseif e.weakestSchool == 3 then
        if caster.illusion then
          relevant_skill = caster.illusion.current
        else
          relevant_skill = 100
        end
      elseif e.weakestSchool == 4 then
        if caster.mysticism then
          relevant_skill = caster.mysticism.current
        else
          relevant_skill = 100
        end
      elseif e.weakestSchool == 5 then
        if caster.restoration then
          relevant_skill = caster.restoration.current
        else
          relevant_skill = 100
        end
      else
        relevant_skill = 100
        log:warn(string.format("Either no school or custom school - setting skill to 100. Spell ID that caused this: %s", e.source.id))
      end
      skill_for_spell = relevant_skill
      spell_chance = calculate_cast_chance(spell_cost, caster.willpower.current, caster.luck.current, skill_for_spell)
      log:trace(string.format("This is a pre-made spell %s, so it got it's chance calculated immediately. Skill = %d. Chance: %d.", e.source.id, relevant_skill, spell_chance))
      e.castChance = spell_chance
    end
  end
  
  -- this happens only for legit spells that are not in the storage, can move this later.
  if total_effect_cost > 0  then
    --skill_for_spell = skills_weighed / total_effect_cost
    
    if caster.alteration and caster.conjuration and caster.destruction and caster.illusion and caster.mysticism and caster.restoration then
      for k=0, 5 do
        magic_skill_table[k] = magic_skill_table[k] / total_effect_cost
        log:trace(string.format("Coeficient for skill %d: %.2f", k, magic_skill_table[k]))
      end
      skill_for_spell = magic_skill_table[0] * caster.alteration.current + magic_skill_table[1] * caster.conjuration.current + magic_skill_table[2] * caster.destruction.current +
      magic_skill_table[3] * caster.illusion.current + magic_skill_table[4] * caster.mysticism.current + magic_skill_table[5] * caster.restoration.current
    else
      log:trace("Spell cast by an entity that has no skills. Using skill of 100.")
      skill_for_spell = 100
    end

    print(string.format("Skill for this spell: %d", skill_for_spell))
    if #effect_db == 1 then
      log:trace("One-effect spell is being cast (stage: chance calculations)! Using basic formula.")
      spell_cost = total_effect_cost
    else
      log:trace("Multi-effect spell is being cast (stage: chance calculations)! Trying advanced formula.")
      local adv_calc = spell_cost_advanced(effect_db, cost_db)
      spell_cost = adv_calc.cost
      if spell_cost == 0 then
        log:trace("Non-legit spell for advanced formula for casting (stage: chance calculations)! Going for plan B.")
        spell_cost = total_effect_cost
      end
    end
    spell_chance = calculate_cast_chance(spell_cost, caster.willpower.current, caster.luck.current, skill_for_spell)
    log:trace(string.format("Resulting cost (for chances): %.2f. Skill for spell: %d. Therefore, chance to cast: %d. Chance calculations stage is finished.", spell_cost, skill_for_spell, spell_chance))
    e.castChance = spell_chance
  end

  -- Respect "Always to succeed spells" if setting to overwrite chances is set to false (default: false)
  if e.source.alwaysSucceeds and (not(config.override_chances_alwaystosucceed)) then
    log:trace("Skipping this spell due to premade spell rules. Setting chance to 100 percent.")
    e.castChance = 100
  end

  -- Bandaid/diagnostic tool: if there are some absurdly strong spells that don't have "always succeeds", NPCs will suck at casting them.
  if e.castChance <= 60 and e.caster.object.mobile ~= tes3.mobilePlayer then
    log:debug(string.format("Low chance for spell for NPC: %s, spell: %s", e.caster.id, e.source.id))
    if config.npc_assist then
      e.castChance = 61
      log:trace("Increased spell chance to 61!")
    end
  end

  -- Friendship ended with dice rolls, determinism is my best friend now.
  if config.determinism_mode == 2 or determinist_spell then
    if e.castChance > 60 then
      e.castChance = 100
      log:trace("Determinism: overriding spell chances - spell is guaranteed to succeed.")
    else
      e.castChance = 0
      log:trace("Determinism: overriding spell chances - spell is guaranteed to fail.")
    end
  else
    -- apply flat bonus (tweakable, default is 0) when in non-determinist mode
    if e.castChance > 0 then
      e.castChance = math.min(e.castChance + config.flat_chance_bonus, 100)
    end
  end
end

local function spell_cost_manipulation(e)
  local spell_cost = 0
  local effect_cost = 0
  local total_effect_cost = 0
  local fatigue_normalized = 0
  local sound_factor = 0

  local spell_id = e.spell.id
  local effect_db = {}
  local cost_db = {}
  -- this is only to store spells
  local magic_skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}
  -- unique spells
  local unique_spell_data = {}
  local old_cost = e.spell.magickaCost
  if premade_spells[spell_id] then
    log:trace(string.format("Found a unique spell: %s", spell_id))
    unique_spell_data = premade_spells[spell_id]
  end

  -- disable for non-spells
  if e.spell.castType ~= tes3.spellType.spell then
    return
  end
  -- If we use different calculations for player and npcs, this will backfire. Will need to add a check for such case. For now, it's the same.
  -- Respects the unique spells.
  -- Adds new spells to the storage - needs testing.
  if tes3.player.data.motte_spell_storage[spell_id] then
    spell_cost = tes3.player.data.motte_spell_storage[spell_id].cost
    log:trace(string.format("Spell %s found in db, so we're not calculating it's cost again. Base cost = %.2f", e.spell.id, spell_cost))
  else
    -- Calculate costs EXCEPT FOR: "Always succeed" spells, and ONLY IF "override costs" var is false (default = true)
    if ((not (e.spell.alwaysSucceeds) or config.override_costs_alwaystosucceed)) then
      log:trace(string.format("Spell %s is being cast. Recalculating. We are at the cost stage.", e.spell.id))
      for i,effect in ipairs(e.spell.effects) do
        if effect.id ~= -1 then
          
          effect_cost = effect_cost_advanced(effect)
          log:trace(string.format("Effect %d:\nName = %s\nDuration = %d\nMagnitude = %d-%d\nRadius = %d", i, effect.object.name, effect.duration, effect.min, effect.max, effect.radius))
          cost_db[i] = effect_cost
          effect_db[i] = effect
          total_effect_cost = total_effect_cost + effect_cost

          if effect.object.school >= 0 and effect.object.school <= 5 then
            magic_skill_table[effect.object.school] = magic_skill_table[effect.object.school] + effect_cost
          else
            -- case of custom schools or crap like this
            magic_skill_table[0] = magic_skill_table[0] + effect_cost
          end

        end
      end
      if total_effect_cost > 0 then
        for k=0, 5 do
          magic_skill_table[k] = magic_skill_table[k] / total_effect_cost
          log:trace(string.format("Coeficient for skill %d: %.2f", k, magic_skill_table[k]))
        end
        if #effect_db == 1 then
          log:trace("One-effect spell is being cast (stage: cost calculations)! Using basic formula.")
          spell_cost = total_effect_cost
        else
          log:trace("Multi-effect spell is being cast (stage: cost calculations)! Trying advanced formula.")
          local adv_calc = spell_cost_advanced(effect_db, cost_db)
          spell_cost = adv_calc.cost
          if spell_cost == 0 then
            log:info("Non-legit spell for advanced formula for casting (stage: cost calculations)! Going for plan B.")
            spell_cost = total_effect_cost
          end
        end
        -- unique checks
        if unique_spell_data.use_premade_cost then
          spell_cost = old_cost
          log:trace("Found unique spell rule. Spell will use old costs.")
        end
        if unique_spell_data.fixed_cost then
          log:trace("Found unique spell rule. Spell will use pre-written costs.")
        end
        if unique_spell_data.flat_mult then
          spell_cost = spell_cost * unique_spell_data.flat_mult
          log:trace("Found unique spell rule. Spell will have it's cost multiplied by a value.")
        end
        if unique_spell_data.skill_table then
          magic_skill_table = unique_spell_data.skill_table
          log:trace("Found unique spell rule. Spell will use custom skill table.")
        end
        -- write it down to the storage  (useful for npc spells)
        -- index 0 in table causes issues when loaded, lua moment
        local magic_skill_table2 = {}
        magic_skill_table2[1] = magic_skill_table[1]
        magic_skill_table2[2] = magic_skill_table[2]
        magic_skill_table2[3] = magic_skill_table[3]
        magic_skill_table2[4] = magic_skill_table[4]
        magic_skill_table2[5] = magic_skill_table[5]
        magic_skill_table2[6] = magic_skill_table[0]
        tes3.player.data.motte_spell_storage[spell_id] = {cost = spell_cost, skill_table = magic_skill_table2}
      end
    else
      spell_cost = e.spell.magickaCost
      log:trace(string.format("Pre-made spell %s is being cast, it's cost will stay. We are at the cost stage.", e.spell.id))
    end
  end
  
  -- Fatigue increases costs up to 50% more (by default, configurable), these costs do not affect the cast chance.
  fatigue_normalized = math.min(1, e.caster.object.mobile.fatigue.normalized)
  -- Sound increases costs by 5% per magnitude. Also does not affect cast chance.
  if e.caster.object.mobile.sound < 0 then
    sound_factor = e.caster.object.mobile.sound * -0.05
    log:trace(string.format("Caster affected by sound, magnitude of %d. Increasing spell costs...", e.caster.mobile.sound))
  end
  -- Armor increases costs up to 100% more (by default, configurable). Also does not affect cast chance. Skip creature casters.
  local armor_factor = 0
  if e.caster.object.objectType == tes3.objectType.npc then
    local armor_table = get_armor_coefs(e.caster.object.mobile)  
    if config.armor_penalty_perc_max > 0 then
      armor_factor = armor_table.light * math.max(config.armor_penalty_cap_light - e.caster.object.mobile.lightArmor.current, 0) / config.armor_penalty_cap_light +
      armor_table.medium * math.max(config.armor_penalty_cap_medium - e.caster.object.mobile.mediumArmor.current, 0) / config.armor_penalty_cap_medium + 
      armor_table.heavy * math.max(config.armor_penalty_cap_heavy - e.caster.object.mobile.heavyArmor.current, 0) / config.armor_penalty_cap_heavy
      armor_factor = armor_factor * (config.armor_penalty_perc_max / 100)
      if armor_factor > 0 then
        log:trace(string.format("Spell costs are increased by armor. Factor: %.2f.", armor_factor))
      end
    end
  end
  spell_cost = spell_cost * (1 + (config.fatigue_penalty_mult / 100) * (1 - fatigue_normalized) + sound_factor + armor_factor)
  if e.caster.object.mobile == tes3.mobilePlayer and e.caster.object.mobile.magicka.current > 100 then
    spell_cost = spell_cost * (1 + (e.caster.object.mobile.magicka.current - 100) * config.overflowing_magicka_rate / 10000)
  end
  -- We need to help dumb NPC AI to handle new costs. I think they fail to cast at low magicka: they cast the spell thinking it costs the old cost (cheaper). They repeat this process, constantly failing at this stage.
  -- The alternative is to rewrite the entire AI so deal with it
  if e.caster.object.mobile ~= tes3.mobilePlayer and e.caster.object.mobile.magicka.current < spell_cost then
    log:info(string.format("NPC casting this spell has magicka of %.2f. However, spell costs %.2f. Spell discounted to magicka - 0.5 to help the AI handle this.", e.caster.object.mobile.magicka.current, spell_cost))
    spell_cost = math.max(e.caster.object.mobile.magicka.current - 0.5, 0)
    -- This should allow this spell to be cast one last time before NPC will have almost no magicka and switch to something else. Seems to work after testing
  end
  e.cost = spell_cost
  log:trace(string.format("Resulting cost for spell: %.2f. Cost calculation stage is finished.", e.cost))
end

function weighed_average (var_array, weight_array, method)
  local avg = 0
  local sum = 0
  if method == "arithmetic" then
    for i, x in ipairs(var_array) do
      avg = avg + x * weight_array[i]
    end
    for i, x in ipairs(weight_array) do
      sum = sum + x
    end
    avg = avg / sum
  elseif method == "geometric" then
    for i, x in ipairs(var_array) do
      avg = avg + math.log(x) * weight_array[i]
    end
    for i, x in ipairs(weight_array) do
      sum = sum + x
    end
    avg = math.exp(avg / sum)
  end
  return avg
end

-- Effect cost calculation, grabs all the info from the spell table and uses a generalized alg in most cases.
function effect_cost_advanced(effect)
  local table = {}
  local effect_cost = 0
  local effect_mag = 0
  local effect_strength = 0
  local effect_id = effect.id
  -- parameters to grab, default values if not in the db
  local mag_pow = 1
  local coef = 1
  local duration_pow = 0
  local duration_min = 1
  local area_pow = 0.1
  local constant_offset = 0
  local mag_offset = 0
  local duration_offset = 0
  local effect_strength_min = 0
  -- lua is stupid and starts arrays from 1, we have to remap the id=0 to something else if we want an iterable table
  -- Why do we want an iterable table, again?
  if effect_id == 0 then
    effect_id = 3434
  end
  if spell_table[effect_id] then
    table = spell_table[effect_id]
    -- get everything from the table, if possible
    if table.mag_pow then
      mag_pow = table.mag_pow
    end
    if table.coef then
      coef = table.coef
    end
    if table.dur_pow then
      duration_pow = table.dur_pow
    end
    if table.dur_min then
      duration_min = table.dur_min
    end
    if table.area_pow then
      area_pow = table.area_pow
    end
    -- offsets
    if table.const_offset then
      constant_offset = table.const_offset
    end
    if table.mag_offset then
      mag_offset = table.mag_offset
    end
    if table.dur_offset then
      duration_offset = table.dur_offset
    end
    -- range mods
    if effect.rangeType == 1 then
      if table.range1_coef_mod then
        coef = coef * table.range1_coef_mod 
      end
      if table.range1_dur then
        duration_pow = table.range1_dur
      end
    elseif effect.rangeType == 2 then
      if table.range2_coef_mod then
        coef = coef * table.range2_coef_mod 
      end
      if table.range2_dur then
        duration_pow = table.range2_dur
      end
    end
    -- modify coef for attribute/skill
    if effect_id == 17 or effect_id == 22 then
      coef = coef * att_table_offense[effect.attribute]
    end
    if effect_id == 21 or effect_id == 26 then
      coef = coef * skill_table_offense[effect.skill]
    end

    -- minimal strength
    if table.strength_min then
      effect_strength_min = table.strength_min
    end
    -- Calculate effect strength
    if table.ignore_magmin then
      effect_mag = math.max(2 * (math.max(effect.max, 1) + mag_offset), effect_strength_min)
    else
      effect_mag = math.max((math.max(effect.min, 1) + math.max(effect.max, 1) + 2 * mag_offset), effect_strength_min)
    end
    effect_strength = effect_mag * math.max((effect.duration + duration_offset), duration_min)
    -- Check for overrides
    if table.range0_const_cost and effect.rangeType == 0 then
      effect_cost = table.range0_const_cost
    else
      if table.const_cost then
        effect_cost = table.const_cost
      else
        effect_cost = math.pow(effect_strength, mag_pow) * coef * math.pow(math.max((effect.duration + duration_offset), duration_min), duration_pow) * math.pow((effect.radius + 1), area_pow) + constant_offset
      end
    end
    -- Special snowflake - targeted levitation with low magnitude
    -- Boring linear formula for now (10s = 10, 20s = 17)
    if effect_id == 10 and effect.rangeType ~= 0 and effect.min < 30 then
      log:trace(string.format("Found targeted levitation with effect min of %d", effect.min))
      if effect.rangeType == 1 then
        effect_cost = 0.72 * effect.duration * math.pow((effect.radius + 1), 0.1) + 2
      else
        effect_cost = 0.8 * effect.duration * math.pow((effect.radius + 1), 0.1) + 2
      end
    end
    log:trace(string.format("Effect ID %d calculated successfully. Costs: %.2f.", effect_id, effect_cost))
  else
    log:warn(string.format("Effect ID %d is not in the spell table. Effect cost will not be calculated.", effect.id))
  end
  return effect_cost
end

-- High effort formula for multi effect spells to make them cost correctly with non-linear scaling
-- Spell with 2 effects "frost damage 30" and "frost damage 20" will cost exactly the same as the spell with 1 effect "frost damage 50", although these effects, when added up, cost more.
function spell_cost_advanced (effect_array, cost_array)
  
  local spell_cost = 0
  local strength_array = {}
  local mag_pow_array = {}
  local coef_array = {}
  local duration_array = {}
  local duration_pow_array = {}
  local radius_array = {}
  local area_pow_array = {}
  local const_offset_array = {}
  
  local has_const_offset = false
  local weighed_mag_pow = 1
  local weighed_coef = 1
  local weighed_duration = 1
  local weighed_duration_pow = 1
  local weighed_radius = 1
  local weighed_area_pow = 1
  local weighed_const_offset = 0
  local total_strength = 0
  local sum_of_costs = 0

  -- Synergies!
  local synergy_bonuses = detect_synergies(effect_array, cost_array, synergy_table)

  for i=1, #effect_array do
    local table = {}
    -- parameters for the effects
    local mag_pow = 1
    local coef = 1
    local duration_pow = 0
    local duration_min = 1
    local area_pow = 0.2
    local constant_offset = 0
    local mag_offset = 0
    local duration_offset = 0
    local effect_strength_min = 0

    local effect_mag = 0
    -- we might fail to find water breathing, so I've added both 0 and 3434 as indices.
    if spell_table[effect_array[i].id] then
      table = spell_table[effect_array[i].id]
      -- basic
      if table.mag_pow then
        mag_pow = table.mag_pow
      end
      if table.coef then
        coef = table.coef
      end
      if table.dur_pow then
        duration_pow = table.dur_pow
      end
      if table.dur_min then
        duration_min = table.dur_min
      end
      if table.area_pow then
        area_pow = table.area_pow
      end
      -- offsets
      if table.const_offset then
        constant_offset = table.const_offset
      end
      if table.mag_offset then
        mag_offset = table.mag_offset
      end
      if table.dur_offset then
        duration_offset = table.dur_offset
      end
      -- range mods
      if effect_array[i].rangeType == 1 then
        if table.range1_coef_mod then
          coef = coef * table.range1_coef_mod 
        end
        if table.range1_dur then
          duration_pow = table.range1_dur
        end
      elseif effect_array[i].rangeType == 2 then
        if table.range2_coef_mod then
          coef = coef * table.range2_coef_mod 
        end
        if table.range2_dur then
          duration_pow = table.range2_dur
        end
      end
      -- modify coef for attribute/skill
      if effect_array[i].id == 17 or effect_array[i].id == 22 then
        coef = coef * att_table_offense[effect_array[i].attribute]
      end
      if effect_array[i].id == 21 or effect_array[i].id == 26 then
        coef = coef * skill_table_offense[effect_array[i].skill]
      end
      -- minimal strength
      if table.strength_min then
        effect_strength_min = table.strength_min
      end
      -- Skip if it has overrides (abusable / non-mergeable skill). Returns 0 and therefore we use sum of effect costs for the price instead.
      if (table.range0_const_cost and effect_array[i].rangeType == 0) or table.const_cost or (effect_array[i].id == 10 and effect_array[i].rangeType ~= 0) then
        log:trace("This spell is not valid for the advanced formula (constant cost, targeted levitation, and such). Aborting calculations, using sum of effects instead.")
        return {cost = 0, synergies = synergy_bonuses}
      end
      -- Calculate strength and put it in array.
      if table.ignore_magmin then
        effect_mag = math.max(2 * (math.max(effect_array[i].max, 1) + mag_offset), effect_strength_min)
        --strength_array[i] = math.max((2 * (math.max(effect_array[i].max, 1) + mag_offset)) * math.max((effect_array[i].duration + duration_offset), duration_min), effect_strength_min)
      else
        effect_mag = math.max(math.max(effect_array[i].min, 1) + math.max(effect_array[i].max, 1) + 2 * mag_offset, effect_strength_min)
        --strength_array[i] = math.max((math.max(effect_array[i].min, 1) + math.max(effect_array[i].max, 1) + 2 * mag_offset) * math.max((effect_array[i].duration + duration_offset), duration_min), effect_strength_min)
      end
      strength_array[i] = effect_mag * math.max((effect_array[i].duration + duration_offset), duration_min)
      -- Add stuff to separate arrays to use them for more readable weighed average calculation.
      if constant_offset > 0 then
        has_const_offset = true
      end
      mag_pow_array[i] = mag_pow
      coef_array[i] = coef
      duration_array[i] = math.max((effect_array[i].duration + duration_offset), duration_min)
      duration_pow_array[i] = duration_pow
      radius_array[i] = effect_array[i].radius + 1
      area_pow_array[i] = area_pow
      const_offset_array[i] = constant_offset
    else
      return {cost = 0, synergies = synergy_bonuses}
    end
  end
  
  --weighing everything
  weighed_mag_pow = weighed_average (mag_pow_array, cost_array, "geometric")
  weighed_coef = weighed_average (coef_array, cost_array, "geometric")
  weighed_duration = weighed_average (duration_array, cost_array, "geometric")
  weighed_duration_pow = weighed_average (duration_pow_array, cost_array, "arithmetic")
  weighed_radius = weighed_average (radius_array, cost_array, "geometric")
  weighed_area_pow = weighed_average (area_pow_array, cost_array, "arithmetic")
  -- This might be still non-ideal, need to think.
  -- Const offsets, effectively, do not stack additively, which is generally good (otherwise it would make spells with several const offsets unusable), but might lead to some weird cases.
  if has_const_offset then
    weighed_const_offset = weighed_average (const_offset_array, cost_array, "arithmetic")
  end

  for i, str in ipairs(strength_array) do
    total_strength = total_strength + str
  end

  for i, cost in ipairs(cost_array) do
    sum_of_costs = sum_of_costs + cost
  end

  -- Here it comes
  spell_cost = math.pow(total_strength, weighed_mag_pow) * weighed_coef * math.pow(weighed_duration, weighed_duration_pow) * math.pow(weighed_radius, weighed_area_pow) + weighed_const_offset

  if config.log_level == "TRACE" then    
    for i=1, #effect_array do
      log:trace(string.format("Effect no %d. Strength: %d, Mag pow: %.2f, Coef: %.2f, Duration: %d, Duration pow: %.2f, Radius: %d, Area pow: %.2f, Const offset: %d", i,
      strength_array[i], mag_pow_array[i], coef_array[i], duration_array[i], duration_pow_array[i], radius_array[i], area_pow_array[i], const_offset_array[i]))
    end
    log:trace(string.format("Weighed mag_pow: %.3f\nweighed coef: %.3f\nweighed duration: %.3f\nweighed duration pow: %.3f\nweighed radius: %.3f\nweighed area pow: %.3f\nweighed const offset: %.3f",
    weighed_mag_pow, weighed_coef, weighed_duration, weighed_duration_pow, weighed_radius, weighed_area_pow, weighed_const_offset))
    log:trace(string.format("Old cost (sum of effect costs): %.2f\nNew cost: %.2f.\nLowest one will be used.", sum_of_costs, spell_cost))
  end

  if sum_of_costs < spell_cost then
    log:trace("Found unsynergetic effects in the spell (sum of effect costs is lower than calculated cost). Sum of effects cost will be used instead. Above are the spell details.")
  end

  -- In some cases it might be worse than sum of effect costs. For these cases, we use sum of costs instead. If this function returns 0, same logic will apply (but synergies won't be applied so it's bad).
  spell_cost = math.min(spell_cost, sum_of_costs)

  -- Apply synergies. Treats the 'better' cost. Still won't apply synergies to spells with abusable effects.
  if synergy_bonuses.cost_discount > 0 then
    spell_cost = spell_cost * (1 - synergy_bonuses.cost_discount)
    log:trace(string.format("Synergies found! Discount is %.2f * spell cost!", synergy_bonuses.cost_discount))
  end

  return {cost = spell_cost, synergies = synergy_bonuses}
end

function calculate_cast_chance (spell_cost, willpower, luck, magic_skill)
  -- Fatigue affects spell costs instead (after chance is calculated, so it does not affect chance)
  -- Formulas: Exponential v1.2, "almost flat" v1.0, "complex".
  -- Exp v1.2 is pretty reasonable overall, but the difference between 30 and 50 is too big.
  -- "Almost flat" v1.0 makes low skilled mages suck a bit too much.
  -- Third formula - "complex" - is essentially exp v1.2 with some heavy handed tackling of 30-50 difference.
  -- Low willpower can cause too much issues at low skill, high willpower can make low level spells trivial. Maybe willpower should affect high skill spells more, instead of all being the same.
  -- Luck is basically bound to level with most leveling mods.
  
  local cast_chance = 0
  local willpower_coeficient = 0.4
  local luck_coeficient = 0.25
  local spell_cost_coeficient_flat = 1
  local spell_cost_coeficient_exp = 1.4
  local magic_skill_coeficient = 1.65
  local flat_increase = 22
  if config.chance_formula == 2 then
    willpower_coeficient = 0.2
    luck_coeficient = 0.12
    spell_cost_coeficient_flat = 1
    spell_cost_coeficient_exp = 1.21
    magic_skill_coeficient = 0.83
    flat_increase = 40
  end
  -- experimental formula, I don't like it, but it's better for balancing early/mid game, 45 skill at lvl 1 can make mages too powerful at start
  -- I think it's kinda bad that Morrowind major skills start at 30 min, it should be 20-30, or something like that /ramble
  if config.chance_formula == 3 then
    -- smooth the mid-levels 30-50 for early game balance
    -- 30 behaves as 30, but 50 behaves as 40
    if magic_skill >= 30 and magic_skill <= 50 then
      magic_skill = (magic_skill + 30) / 2
    elseif magic_skill > 50 and magic_skill <= 65 then
      -- then we get faster growth in 50-65 range, so while 50 behaves as 40, 65 behaves as 65 again
      magic_skill = (magic_skill - 50) * 5/3 + 40
    end
  end
  cast_chance = flat_increase + willpower_coeficient * willpower + luck_coeficient * luck - math.pow(spell_cost, spell_cost_coeficient_exp) +
      magic_skill_coeficient * magic_skill
  -- Clamping might actually be not the best approach if you want to visualise just how terrible your chances of casting are (-186 chance aka you'll never cast that)
  cast_chance = math.clamp(cast_chance, 0, 100)
  return cast_chance
end

-- Spell storage.
local function load_storage(e)
  if not tes3.player.data.motte_spell_storage then
    tes3.player.data.motte_spell_storage = {}
  else
    log:trace("Game loaded. Found spell storage.")
  end
end

local function exp_gain(e)

  local caster = e.caster.mobile

  if not(config.experience_gain) or e.source.castType ~= tes3.spellType.spell or caster ~= tes3.mobilePlayer then
    return
  end
  
  local spell_id = e.source.id
  local school = tes3.magicSchoolSkill[e.expGainSchool]
  local magic_skill_table = {}
  local spell_cost = 0
  -- Base divider for costs
  local base_const = 6
  -- Disable vanilla exp gain
  e.expGainSchool = tes3.magicSchool.none
  if tes3.player.data.motte_spell_storage[spell_id] then
    -- if spell is in the DB, where it should be.
    local spell_data = tes3.player.data.motte_spell_storage[spell_id]
    magic_skill_table = spell_data.skill_table
    spell_cost = spell_data.cost
    caster:exerciseSkill(10, spell_cost * magic_skill_table[2] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_destruction / 100)
    caster:exerciseSkill(11, spell_cost * magic_skill_table[6] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_alteration / 100)
    caster:exerciseSkill(12, spell_cost * magic_skill_table[3] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_illusion / 100)
    caster:exerciseSkill(13, spell_cost * magic_skill_table[1] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_conjuration / 100)
    caster:exerciseSkill(14, spell_cost * magic_skill_table[4] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_mysticism / 100)
    caster:exerciseSkill(15, spell_cost * magic_skill_table[5] / base_const * config.leveling_rate_global / 100 * config.leveling_rate_restoration / 100)
  else
    -- If spell is not in the DB for some reason. 
    spell_cost = e.source.magickaCost
    log:warn(string.format("Spell %s not found in database! Using simplified approach.", spell_id))
    caster:exerciseSkill(school, spell_cost / base_const * config.leveling_rate_global / 100)
  end  
end

local function initialized()
  event.register("uiActivated", magic_menu_update, {filter = "MenuMagic"})
  event.register("uiActivated", spellmaking_block, {filter = "MenuSpellmaking"})
  event.register("spellCreated", spellmaking_payment)
  event.register("spellMagickaUse", spell_cost_manipulation)
  event.register("spellCast", spell_chance_manipulation)
  event.register("spellCasted", exp_gain)
  event.register(tes3.event.calcSpellmakingSpellPointCost, spellmaker_update)
  event.register(tes3.event.loaded, load_storage)
  -- Disable vanilla spellmaking calc mechanic, if mods enable it again via script, it won't be pretty.
  tes3.findGMST("fSpellMakingValueMult").value = 0
  print("[Vengyre] Magicka of the Third Era initialized")
end

event.register("initialized", initialized)

-- MCM -- 

local resetConfig = false

local function modConfigReady()

	local template = mwse.mcm.createTemplate("Magicka of the Third Era")

	template.onClose = function()
		if resetConfig then
			resetConfig = false
			config = default_config
		end
		mwse.saveConfig(config_name, config, {indent = false})
	end

	local page = template:createSideBarPage({
    label = "Settings",
    description = [[
    Magicka of the Third Era settings menu. Default setting are the recommended ones, but you can tweak them if you want to further tailor game's balance.
    Use the "Reset Spell Storage" button while in-game to clear all the calculated spells from the save game, which should be done if you update the mod in the middle of the game.
    ]]
  })

  local main_settings = page:createCategory("Main Settings")

  main_settings:createDropdown{
    label = "Logging Level",
    description = [[
      How much mod will spam your MWSE log.
      ERROR level is enough for most users (will report only potential issues).
      INFO level is for balancing and is set as default. Feel free to set it lower if you feel like it spams too much.
      Anything higher is for debugging.
      ]],
    options = {
      { label = "TRACE", value = "TRACE"},
      { label = "DEBUG", value = "DEBUG"},
      { label = "INFO", value = "INFO"},
      { label = "ERROR", value = "ERROR"},
      { label = "NONE", value = "NONE"},
    },
    variable = mwse.mcm.createTableVariable{ id = "log_level", table = config },
    callback = function(self)
      log:setLogLevel(self.variable.value)
    end
  }

  main_settings:createDropdown{
		label = "Spell Chances Handling",
		options = {
			{ label = "0. Vanilla", value = 0 },
			{ label = "1. Partial Determinism", value = 1 },
			{ label = "2. Full Determinism", value = 2 },
		},
		variable = mwse.mcm.createTableVariable{ id = "determinism_mode", table = config },
		description = [[
    How spell chances behave in game.
    0 = Vanilla behavior (dice rolls for all spells).
    1 = Semi-deterministic (no dice rolls for effects where it is abusable like Open).
    2 = Full determinism (anything above threshold will succeed, anything below will fail).
    Current threshold for this is 60% chance.
    Mod is balanced around 2, which is objectively the best option. If you prefer having cast chances, I suggest trying 1 (might be actually the most difficult setting).
    ]]
	}

  main_settings:createSlider{
		label = "Flat Chance Increase (for non-determinist spells)",
		description = "This setting is relevant only if you are not using Full Determism (default) calculation mode. Allows you to increase chance for non-determinist spells (when using 0 and 1 spell chance handling modes). Mod is balanced around 61% being castable, so you might want the higher chance.",
		variable = mwse.mcm.createTableVariable{ id = "flat_chance_bonus", table = config },
		min = 0, max = 40, step = 1, jump = 5
	}

  main_settings:createOnOffButton{
    label = "Override Always-to-Succeed Costs",
    description = "By default mod re-calculates costs for all spells with valid effects, including always-to-succeed ones. Disable if you have a mod that adds expensive spells that have this tag.",
    variable = mwse.mcm.createTableVariable{ id = "override_costs_alwaystosucceed", table = config }
  }

  main_settings:createOnOffButton{
    label = "Override Always-to-Succeed Chances",
    description = "By default mod respects 'always succeeds' tag for spells and does not change their chances.",
    variable = mwse.mcm.createTableVariable{ id = "override_chances_alwaystosucceed", table = config }
  }

  main_settings:createOnOffButton{
    label = "Enable NPC Assist",
    description = "Enable assistance for spells cast by NPCs. By default, NPCs will have their minimal cast chance set to 61%, which is a guarantee under determinist mode. Also, gives a small assist to NPCs to bandaid the crappy AI (AI treats spells as if they have the old costs, which can freak them out). Leave this on unless you are 100% sure what are you doing. NPCs can't react to their failures properly and will be significantly weaker without it enabled.",
    variable = mwse.mcm.createTableVariable{ id = "npc_assist", table = config }
  }

  main_settings:createSlider{
		label = "Fatigue Cost Penalty",
		description = "By default mod increases costs depending on missing fatigue, up to 50% more. These costs do not affect the cast chance. Set to 0 to disable.",
		variable = mwse.mcm.createTableVariable{ id = "fatigue_penalty_mult", table = config },
		min = 0, max = 150, step = 1, jump = 5
	}

  main_settings:createSlider{
		label = "Armor Cost Penalty",
		description = "By default mod increases costs if you're wearing armor while having low skill, up to 100% more. These costs do not affect the cast chance. Set to 0 to disable.",
		variable = mwse.mcm.createTableVariable{ id = "armor_penalty_perc_max", table = config },
		min = 0, max = 300, step = 1, jump = 10
	}

  main_settings:createSlider{
		label = "Armor Cost Penalty - Light",
		description = "Required Light Armor skill value to suffer no cost penalties with Armor Cost Penalty. If your skill is below this value, you'll get increasingly higher spell costs, up to Armor Cost Penalty value. Default value is 50.",
		variable = mwse.mcm.createTableVariable{ id = "armor_penalty_cap_light", table = config },
		min = 5, max = 100, step = 1, jump = 5
	}

  main_settings:createSlider{
		label = "Armor Cost Penalty - Medium",
		description = "Required Medium Armor skill value to suffer no cost penalties with Armor Cost Penalty. If your skill is below this value, you'll get increasingly higher spell costs, up to Armor Cost Penalty value. Default value is 60.",
		variable = mwse.mcm.createTableVariable{ id = "armor_penalty_cap_medium", table = config },
		min = 5, max = 100, step = 1, jump = 5
	}

  main_settings:createSlider{
		label = "Armor Cost Penalty - Heavy",
		description = "Required Heavy Armor skill value to suffer no cost penalties with Armor Cost Penalty. If your skill is below this value, you'll get increasingly higher spell costs, up to Armor Cost Penalty value. Default value is 70.",
		variable = mwse.mcm.createTableVariable{ id = "armor_penalty_cap_heavy", table = config },
		min = 5, max = 100, step = 1, jump = 5
	}

  main_settings:createSlider{
		label = "Overflowing Magicka",
		description = [[
      Spells will cost more while you have more than 100 CURRENT magicka. By default, for every 100 points of magicka over the 100, spells cost 50% more. Spells will gradually become cheaper as you spend magicka, dropping to their initial cost once you have 100 magicka or less. 
      The goal is to nerf huge magicka pools without either touching normal magicka pools or penalizing players for increasing their magicka. Set to 0 to disable.
      
      For example, if set to 100%:
      
      A spell costs 20.

      With 100 Magicka, you can cast it 5 times.
      With 200 Magicka, you can cast it 3 times before dropping to ~100 (200 -> 160 -> 128 -> ~100), and then you can cast it 5 more times. 8 total.
      With 300 Magicka, you can cast it 2 times before dropping to ~200 (300 -> 240 -> ~200), and then 8 more times, so 10 total.

      So, in this case, 200 Magicka behaves like 160 (20 cost spell x 8 times) and 300 Magicka behaves like 200 (10 times).
      ]],
		variable = mwse.mcm.createTableVariable{ id = "overflowing_magicka_rate", table = config },
		min = 0, max = 200, step = 1, jump = 5
	}

  main_settings:createDropdown{
		label = "Chance Calculation Formula",
		options = {
			{ label = "1. Default", value = 1 },
			{ label = "2. Alternative", value = 2 },
			{ label = "3. Complex", value = 3 }
		},
		variable = mwse.mcm.createTableVariable{ id = "chance_formula", table = config },
		description = [[
    Formula used to calculate chances. Default and recommended is 3. Change it if you dare, but the balance might fall into Oblivion.
    1. Default formula. Exponential difficulty: slightly easier to cast cheap spells, harder to cast expensive spells.
    2. Alternative formula. Smoother curve. Harder at low skill, easier at high skill.
    3. Complex. Similar to 1, but more balanced for the midgame. Recommended for now.
    ]]
	}

  main_settings:createOnOffButton{
    label = "Reworked Experience Gain",
    description = "By default mod alters the experience gain from casting spells. Experience is based on spell cost. Experience is gained not for one but all schools involved proportional to effect costs.",
    variable = mwse.mcm.createTableVariable{ id = "experience_gain", table = config }
  }

  main_settings:createSlider{
		label = "Global Magic Leveling Rate",
		description = "Affects the exp gain from casting spells. Default: 100",
		variable = mwse.mcm.createTableVariable{ id = "leveling_rate_global", table = config },
		min = 0, max = 300, step = 1, jump = 10
	}

  main_settings:createSlider{
		label = "Alteration Leveling Rate",
		description = "Affects the exp gains to Alteration spell school. Default: 100",
		variable = mwse.mcm.createTableVariable{ id = "leveling_rate_alteration", table = config },
		min = 0, max = 300, step = 1, jump = 10
	}

  main_settings:createSlider{
		label = "Conjuration Leveling Rate",
		description = "Affects the exp gains to Conjuration spell school. Default: 150",
		variable = mwse.mcm.createTableVariable{ id = "leveling_rate_conjuration", table = config },
		min = 0, max = 300, step = 1, jump = 10
	}

  main_settings:createSlider{
		label = "Destruction Leveling Rate",
		description = "Affects the exp gains to Destruction spell school. Default: 100",
		variable = mwse.mcm.createTableVariable{ id = "leveling_rate_destruction", table = config },
		min = 0, max = 300, step = 1, jump = 10
	}

  main_settings:createSlider{
		label = "Illusion Leveling Rate",
		description = "Affects the exp gains to Illusion spell school. Default: 130",
		variable = mwse.mcm.createTableVariable{ id = "leveling_rate_illusion", table = config },
		min = 0, max = 300, step = 1, jump = 10
	}

  main_settings:createSlider{
		label = "Mysticism Leveling Rate",
		description = "Affects the exp gains to Mysticism spell school. Default: 130",
		variable = mwse.mcm.createTableVariable{ id = "leveling_rate_mysticism", table = config },
		min = 0, max = 300, step = 1, jump = 10
	}

  main_settings:createSlider{
		label = "Restoration Leveling Rate",
		description = "Affects the exp gains to Restoration spell school. Default: 90",
		variable = mwse.mcm.createTableVariable{ id = "leveling_rate_restoration", table = config },
		min = 0, max = 300, step = 1, jump = 10
	}

  main_settings:createButton{
		buttonText = "Reset Spell Storage",
		callback = function()
			if (tes3.player ~= nil) then
				tes3.player.data.motte_spell_storage = {}
				tes3.messageBox("[Magicka of the Third Era] Spell storage has been reset.")
			end
		end,
		inGameOnly = true,
	}

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)