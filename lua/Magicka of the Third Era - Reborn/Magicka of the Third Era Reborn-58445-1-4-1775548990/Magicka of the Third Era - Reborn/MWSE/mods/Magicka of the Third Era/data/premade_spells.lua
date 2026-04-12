-- premade_spells.lua
-- Per-spell cost overrides and school assignments.
-- Supported fields per entry:
--   use_premade_cost  boolean  use the spell's original magickaCost unchanged
--   fixed_cost        number   override the calculated cost with this value
--   flat_mult         number   multiply the calculated cost by this factor
--   skill_table       table    override the school weighting (indices 0-5)
-- don't set fixed_cost to 0, mod will freak out.
-- skill_table is used for spells with negative or off-school effects
-- so they aren't treated as belonging to the wrong school.

-- High Rank Exclusives:
-- House Telvanni: weird buff for summons / bad damage spell with a downside ; greater lifetap (now this is *really* good)
-- Mages Guild: very big burden ; lolrandom huge aoe shock spell
-- Morag Tong: strongest oneshot spell with a downside ; debuff for str/spd (cheap and actually really good)
-- Imperial Cult: strong damaging resto spell ('holy')
-- Legion: strong offensive buff
-- Tribunal Temple: huge insta heal

-- Unique Elemental Top-tier spells:
-- Fire: Leles Birian has strong fireball in the middle of nowhere, with a synergy built-in + extra discount
-- Frost: Andrar (my NPC, in the Fort Frostmoth) has strong touch frost spell, no strings attached, just simple and powerful + extra discount
-- Shock: Uleni Heleran has huge AOE instant spark, unreasonable, but fun ig? big discount
-- Poison: Salama Andrethi has Melancholy Medicine, strong and wacky poison spell that also poisons you (easy to fix, but something to keep in mind)
-- Damage Health: Mertisi Andavel has Vehement Spite, which is really powerful and magicka-efficient, but hurts caster. Very strong in practice


return {
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
  aa_cl_seraph_spell = {fixed_cost = 13, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}}, -- cure all diseases with fire damage on self
  aa_cl_shaman_spell = {flat_mult = 0.75},
  aa_cl_sharp_spell = {flat_mult = 0.75},
  aa_cl_skald_spell = {flat_mult = 0.65},
  aa_cl_spear_spell = {flat_mult = 0.6},
  aa_cl_veteran_spell = {flat_mult = 0.75},
  -- OAAB
  ABtv_sp_MilarHeal = {flat_mult = 0.9}, -- quest reward
  -- TR
  T_Com_Con_PeryitonSpellSouth = {flat_mult = 0.85},
  T_Com_Con_PeryitonSpellFringes = {flat_mult = 0.85},
  T_Com_Con_PeryitonSpellWest = {flat_mult = 0.85},
  T_Com_Con_PeryitonSpellNorth = {flat_mult = 0.85}, -- this is still useless (and the spell is useless by itself)
  T_Com_Con_PeryitonSpellEast = {flat_mult = 0.85},
  -- Necrocraft
  T_Bk_MysteriesOfTheWormTR = {fixed_cost = 40}, -- it costs 250 (!) in the mod?
  NC_ME_MassReanimation = {fixed_cost = 30}, -- 50 in the mod
  NC_ME_MassSkeletal = {fixed_cost = 22}, -- 30 in the mod
  -- Magicka of the Third Era's unique spells
  a_ve_uniqsp_01_lifetap = {fixed_cost = 0.05}, -- restore magicka for a price
  a_ve_uniqsp_02_dragonbite = {flat_mult = 0.85},
  a_ve_uniqsp_03_drakeguard = {fixed_cost = 23},
  a_ve_uniqsp_04_sumrit = {fixed_cost = 25, skill_table = {[0] = 0, [1] = 0.5, [2] = 0, [3] = 0, [4] = 0, [5] = 0.5}}, -- fortifies conjuration for a price -> stronger summons are possible -- semi resto semi conj
  a_ve_uniqsp_05_fireball = {flat_mult = 0.9}, -- showcase of a basic synergy that's even cheaper
  a_ve_uniqsp_06_burden = {fixed_cost = 27}, -- strongest burden spell, MG high rank exclusive
  a_ve_uniqsp_07_panacea = {fixed_cost = 22},
  a_ve_uniqsp_08_manaleech = {fixed_cost = 24}, -- drain 120 magicka over 30 secs for 24
  a_ve_uniqsp_09_waterstrider = {fixed_cost = 11},
  a_ve_uniqsp_10_absarmor = {fixed_cost = 15},
  a_ve_uniqsp_11_foolsleap = {fixed_cost = 25}, -- icarus flight as a spell, like jump but for resto (less useful for resto unless you also can slowfall)
  a_ve_uniqsp_12_pray_la = {fixed_cost = 13}, -- fortify armor skills
  a_ve_uniqsp_13_pray_ma = {fixed_cost = 13},
  a_ve_uniqsp_14_pray_ha = {fixed_cost = 13},
  a_ve_uniqsp_15_lifetapgr = {fixed_cost = 0.05}, -- bigger lifetap, this is a really really good spell btw
  a_ve_uniqsp_16_discountmark = {fixed_cost = 12, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 1, [5] = 0}}, -- cheap mark and recall with negatives, forced to be mysticism and not destruction
  a_ve_uniqsp_17_discountrecall = {fixed_cost = 12, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 1, [5] = 0}}, -- just in case, they're at the same trader
  a_ve_uniqsp_18_fortifyall = {fixed_cost = 38},
  a_ve_uniqsp_19_aquaform = {flat_mult = 0.75}, -- another even cheaper synergy
  a_ve_uniqsp_20_vampiricform = {fixed_cost = 25}, -- hard to measure strength of this
  a_ve_uniqsp_21_mehrunesprot = {fixed_cost = 27},
  a_ve_uniqsp_22_giftofmana = {fixed_cost = 10}, -- restore 100 magicka on touch
  a_ve_uniqsp_23_manawell = {fixed_cost = 24}, -- restore 60 magicka over 30 secs
  a_ve_uniqsp_24_chaoticspark = {flat_mult = 0.75},
  a_ve_uniqsp_25_blackstorm = {flat_mult = 0.55}, -- huge aoe damage health that's usually not practical
  a_ve_uniqsp_26_curseoftheproud = {flat_mult = 0.8}, -- weakness to normal weapons debuff
  a_ve_uniqsp_27_annihilatearmor = {fixed_cost = 29}, -- strongest disintegrate armor spell, way stronger than you can make
  a_ve_uniqsp_28_gravecurse = {flat_mult = 0.7}, -- morag tong exclusive, drain str/spd
  a_ve_uniqsp_29_pray_bl = {fixed_cost = 13}, -- fortify block
  a_ve_uniqsp_30_chaoticshockst = {flat_mult = 0.67},
  a_ve_uniqsp_31_desperateprayer = {flat_mult = 0.65}, -- strongest instant self heal, requires Temple rank
  a_ve_uniqsp_32_blackspite = {fixed_cost = 17}, -- self damage damage skill, keep an eye on this in case of balance tweaks
  a_ve_uniqsp_33_vespite = {fixed_cost = 29}, -- same as above but stronger
  a_ve_uniqsp_34_hardenbone = {fixed_cost = 17, skill_table = {[0] = 0, [1] = 0.25, [2] = 0.25, [3] = 0, [4] = 0, [5] = 0.5}}, -- designed to buff undead summons, but can be used as bad damage spell, hence the split
  a_ve_uniqsp_35_livingbomb = {fixed_cost = 15, skill_table = {[0] = 0.5, [1] = 0.25, [2] = 0.25, [3] = 0, [4] = 0, [5] = 0}}, -- alteration buff / bad damage spell
  a_ve_uniqsp_36_holyfire = {flat_mult = 0.87, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}}, -- this and 2 below are destruction spells, but for resto. This one needs high rank in imperial cult.
  a_ve_uniqsp_37_smite = {flat_mult = 0.95, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}},
  a_ve_uniqsp_38_handofjustice = {flat_mult = 0.95, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}},
  a_ve_uniqsp_39_berserk = {fixed_cost = 14, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}}, -- buff with negatives
  a_ve_uniqsp_40_burstofspeed = {fixed_cost = 23},
  a_ve_uniqsp_41_coupdegrace = {fixed_cost = 35}, -- high rank morag tong only
  a_ve_uniqsp_42_fightingprowess = {flat_mult = 0.85},
  a_ve_uniqsp_43_warriorblessing = {flat_mult = 0.9},
  a_ve_uniqsp_44_akamiblessing = {fixed_cost = 12},
  a_ve_uniqsp_45_incompetence = {fixed_cost = 13},
  a_ve_uniqsp_46_counterspell = {fixed_cost = 20},
  a_ve_uniqsp_47_bargainopen = {fixed_cost = 10, skill_table = {[0] = 1, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}}, -- cheaper open 50 with negatives, keep an eye in case formula changes
  a_ve_uniqsp_48_paralyzer = {fixed_cost = 32}, -- strongest paralyze spell
  a_ve_uniqsp_49_c1_frost = {fixed_cost = 15}, -- 3 strong early game destro spells, best used in rotation, located at the same trader.
  a_ve_uniqsp_50_c2_shock = {fixed_cost = 15},
  a_ve_uniqsp_51_c3_fire = {fixed_cost = 15},
  a_ve_uniqsp_52_exhaustfrost = {flat_mult = 0.9}, -- another cheaper synergy
  a_ve_uniqsp_53_murderous_i = {fixed_cost = 25, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 1, [4] = 0, [5] = 0}}, -- buff the NPC you enrage!
  a_ve_uniqsp_54_aoefrenzy = {flat_mult = 0.8}, -- huge AOE frenzy
  a_ve_uniqsp_55_crabbless = {fixed_cost = 17, skill_table = {[0] = 1, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}}, -- become weightless, of course it has some negatives
  a_ve_uniqsp_56_retrishield = {flat_mult = 0.9, skill_table = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 1}}, -- "holy" elemental shield
  a_ve_uniqsp_57_frostfist = {flat_mult = 0.9},
  a_ve_uniqsp_58_wizprank = {flat_mult = 0.9},
  a_ve_uniqsp_59_blindrage = {fixed_cost = 15},
  a_ve_uniqsp_60_noillness = {fixed_cost = 15},
  a_ve_uniqsp_61_legichrg = {fixed_cost = 24}, -- powerful and relatively cheap offensive buff, but Imperial Legion high rank exclusive
  a_ve_uniqsp_62_flamehf = {flat_mult = 0.9},  -- very big fireball
  a_ve_uniqsp_63_melamed = {fixed_cost = 34},
  a_ve_uniqsp_64_sparkmaster = {flat_mult = 0.68}, -- very unreasonable shock AOE
  a_ve_uniqsp_65_manaspark = {fixed_cost = 16, skill_table = {[0] = 0, [1] = 0, [2] = 0.75, [3] = 0, [4] = 0.25, [5] = 0}} -- small damage spell that absorbs some magicka
}
