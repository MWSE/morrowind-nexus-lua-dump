--[[
0 - Red Blood:
	Anything else
1 - Bone Dust:
	Skeletal Creatures, Ash Creatures, Vampire NPCs
2 - Sparks:
	Dwemer Constructs, Imperfect, Fabricants
3 - Ichor:
	Organic Daedra
4 - Ectoplasm:
	Ghosts, Ghost NPCs
5 - Blue Blood:
	Mudcrab, Dreugh, Netch, Riekling, Karstaag, Grahl
6 - Orange Blood:
	Shalk, Kwama, Nix-Hound
7 - Elemental Energy:
	Atronachs, Spriggan, Hircine, The Swimmer, Dagoth Ur, Ash Vampires

!!!CAUTION: Array indices MUST be all lowercase! E.g.:
Wrong:
["#bmcr\\IceMWarMinion.nif"] = 5,
Correct:
["#bmcr\\icemwarminion.nif"] = 5,
	
]]--

local this = {}

-- These values aren't set with the full relative path.
-- You can test the expected values using the lua console `currentRef.object.mesh`

this.arcticBlood = {
	["r\\frostgiant.nif"] = 5,
	["r\\ice troll.nif"] = 5,
	["r\\iceminion.nif"] = 5,
	["r\\icemraider.nif"] = 5,
	["r\\udyrfrykte.nif"] = 5,
	-- Bloodmoon Creatures
	["#bmcr\\icemwarminion.nif"] = 5,
	["#bmcr\\iceminionbad.nif"] = 5,
	["#bmcr\\iceminionbearfur.nif"] = 5,
	["#bmcr\\iceminionbearfurw.nif"] = 5,
	["#bmcr\\iceminionfurarm.nif"] = 5,
	["#bmcr\\iceminionnordarm.nif"] = 5,
	["#bmcr\\iceminionpeltast.nif"] = 5,
	["#bmcr\\iceminionpeltast2.nif"] = 5,
	["#bmcr\\iceminionpeltast3.nif"] = 5,
	["#bmcr\\iceminionshaman.nif"] = 5,
	["#bmcr\\iceminionwolffur.nif"] = 5,
	["#bmcr\\iceminionwolffurw.nif"] = 5,
	-- Morrowind Rebirth
	["r\\frostgiant1.nif"] = 5,
	["r\\frostgiant2.nif"] = 5,
	["r\\riekling_berserker.nif"] = 5,
	["r\\riekling_nightstalker.nif"] = 5,
	["r\\riekling_raider_01.nif"] = 5,
	["r\\riekling_shaman.nif"] = 5,
	["r\\riekling_warrior_01.nif"] = 5,
	["r\\riekling_warrior_02.nif"] = 5,
}
this.ashBlood = {
	["r\\ascendedsleeper.nif"] = 1,
	["r\\ashghoul.nif"] = 1,
	["r\\ashslave.nif"] = 1,
	["r\\ashzombie.nif"] = 1,
	-- Salt Gems of Bensamsi
	["md_ashgem\\ashzombie_gem.nif"] = 1,
	["md_ashgem\\ashzombie_gem_d1.nif"] = 1,
	["md_ashgem\\ashzombie_gem_d2.nif"] = 1,
	-- Quorn Resource Integration
	["r\\ashghoul_hood.nif"] = 1,
	-- Morrowind Rebirth
	["r\\ashghoulalt.nif"] = 1,
	["r\\dagothgeres.nif"] = 1,
	-- Creatures XI
	["plx_crt\\mca_ash_priest.nif"] = 1,
	["plx_crt\\mca_ash_slave_a.nif"] = 1,
	["plx_crt\\mca_ash_slave_w.nif"] = 1,
	["plx_crt\\mca_ash_warrior.nif"] = 1,
	["plx_crt\\ashpoet.nif"] = 1,
}
this.crustaceanBlood = {
	["r\\cavemudcrab.nif"] = 5,
	["r\\dreugh.nif"] = 5,
	-- TR
	["tr\\cr\\tr_cephalopod_vo.nif"] = 5,
	["tr\\cr\\tr_dreugh01.nif"] = 5,
	["tr\\cr\\tr_dreugh02.nif"] = 5,
	["tr\\cr\\tr_dreugh03.nif"] = 5,
	["tr\\cr\\tr_eyestar_vo.nif"] = 5,
	["tr\\cr\\tr_molecrab_vo.nif"] = 5,
	["tr\\cr\\tr_muckleech_vo.nif"] = 5,
	["tr\\cr\\tr_seacrab.nif"] = 5,
	["pc\\cr\\pc_sload_01.nif"] = 5,
	["pc\\cr\\pc_str_mudcrab.nif"] = 5,
	-- R-Zero's Creatorium: Waters and Shores
	["r0\\r\\h2o\\dreugh_land.nif"] = 5,
	["r0\\r\\h2o\\dreugh_manowar.nif"] = 5,
	["r0\\r\\h2o\\mudcrab_king.nif"] = 5,
	["r0\\r\\h2o\\mudcrab_titan.nif"] = 5,
	-- Antares' Creatures Integration
	["ancr\\cecaelia.nif"] = 5,
	-- Morrowind Rebirth
	["r\\dreugh_warlord.nif"] = 5,
	["r\\mudcrab_merchant.nif"] = 5,
	["r\\rock_crab.nif"] = 5,
	-- Creatures XI
	["plx_crt\\acd_clinker.nif"] = 5,
	["plx_crt\\seacrab.nif"] = 5,
	["plx_crt\\tr_sea_crab_vo.nif"] = 5,
	-- RandomPal
	["r\\cephalopod.nif"] = 5,
	["rp\\s_dreugh\\sdreugh.nif"] = 5,
	-- Diseased and Blighted Creatures Frank
	["cab\\rd\\mudcrabd.nif"] = 5,
}
this.corprusBlood = {
	["r\\byagram.nif"] = 0,
	["r\\corprus_stalker.nif"] = 0,
	["r\\lame_corprus.nif"] = 0,
	-- RandomPal
	["war\\f\\war_crpsstlkr_fa.nif"] = 0,
	["war\\f\\war_crpsstlkr_fb.nif"] = 0,
	["war\\f\\war_crpsstlkr_fc.nif"] = 0,
	["war\\f\\war_crpsstlkr_fd.nif"] = 0,
	["war\\f\\war_crpsstlkr_fe.nif"] = 0,
	["war\\f\\war_crpsstlkr_ff.nif"] = 0,
	["war\\f\\war_crpsstlkr_fg.nif"] = 0,
	["war\\f\\war_crpsstlkr_fh.nif"] = 0,
	["war\\f\\war_crpsstlkr_fi.nif"] = 0,
	["war\\m\\war_crpsstlkr_ma.nif"] = 0,
	["war\\m\\war_crpsstlkr_mb.nif"] = 0,
	["war\\m\\war_crpsstlkr_mc.nif"] = 0,
	["war\\m\\war_crpsstlkr_md.nif"] = 0,
	["war\\m\\war_crpsstlkr_me.nif"] = 0,
	["war\\m\\war_crpsstlkr_mf.nif"] = 0,
	["war\\m\\war_crpsstlkr_mg.nif"] = 0,
	["war\\m\\war_crpsstlkr_mgx.nif"] = 0,
	["war\\m\\war_crpsstlkr_mh.nif"] = 0,
	["war\\m\\war_crpsstlkr_mi.nif"] = 0,
}
this.dwemerBlood = {
	["r\\g_centurionspider.nif"] = 2,
	["r\\sphere_centurions.nif"] = 2,
	["r\\spherearcher.nif"] = 2,
	["r\\steam_centurions.nif"] = 2,
	-- TR
	["tr\\cr\\tr_dwemer.nif"] = 2,
	["tr\\cr\\tr_dwrv_explodo_01.nif"] = 2,
	["tr\\cr\\tr_dwrv_explodo_02.nif"] = 2,
	-- Unique Creatures
	["mca\\mca_centurionadvanced.nif"] = 2,
	["mca\\mca_centurionshock.nif"] = 2,
	-- Morrowind Rebirth
	["r\\centurion_blade.nif"] = 2,
	["r\\centurion_flying.nif"] = 2,
	["r\\centurion_giant.nif"] = 2,
	["r\\centurion_shock.nif"] = 2,
	["r\\centurion_spider_miner.nif"] = 2,
	["r\\centurion_spider_tower.nif"] = 2,
	-- Creatures XI
	["plx_crt\\centurion_battle.nif"] = 2,
	["plx_crt\\centurion_blade.nif"] = 2,
	["plx_crt\\centurion_bomb.nif"] = 2,
	["plx_crt\\centurion_flying.nif"] = 2,
	["plx_crt\\centurion_mace.nif"] = 2,
	["plx_crt\\centurion_repair.nif"] = 2,
	-- RandomPal
	["0s\\centurion_bomber.nif"] = 2,
	["a_cb\\acl_cen_bom.nif"] = 2,
	["a_css\\acl_cen_s_spider.nif"] = 2,
	["mca\\mca_centurionadvanced.nif"] = 2,
	["rp\\crt\\centurion_giant.nif"] = 2,
	-- OAAB
	["oaab\\r\\centurion_siege.nif"] = 2,
	["oaab\\r\\centurion_siege.nif"] = 2,
}
this.daedraBlood = {
	["r\\clannfear.nif"] = 3,
	["r\\clannfear_daddy.nif"] = 3,
	["r\\daedroth.nif"] = 3,
	["r\\dremora.nif"] = 3,
	["r\\golden saint.nif"] = 3,
	["r\\hunger.nif"] = 3,
	["r\\scamp_fetch.nif"] = 3,
	["r\\wingedtwilight.nif"] = 3,
	-- TR
	["tr\\cr\\tr_clannfear_lesser.nif"] = 3,
	["tr\\cr\\tr_dae_bat_vo.nif"] = 3,
	["tr\\cr\\tr_dremora.nif"] = 3,
	["tr\\cr\\tr_dremora_archer.nif"] = 3,
	["tr\\cr\\tr_dremora_caster.nif"] = 3,
	["tr\\cr\\tr_dridrea_vo.nif"] = 3,
	["tr\\cr\\tr_vermai.nif"] = 3,
	["tr\\cr\\tr_vile_dae_c.nif"] = 3,
	-- The Sanguine Rose
	["mdsr\\r\\herne.nif"] = 3,
	["mdsr\\r\\mazken.nif"] = 3,
	["mdsr\\r\\xivilai.nif"] = 3,
	-- Antares' Creatures Integration
	["ancr\\ancr_beholder.nif"] = 3,
	-- Unique Creatures
	["mca\\mca_dremora.nif"] = 3,
	["mca\\mca_dremora_anhaedra.nif"] = 3,
	["mca\\mca_dremora_champion.nif"] = 3,
	["mca\\mca_dremora_dregas.nif"] = 3,
	["mca\\mca_dremora_khash.nif"] = 3,
	["mca\\mca_dremora_kraazt.nif"] = 3,
	["mca\\mca_dremora_warrior01.nif"] = 3,
	["mca\\mca_dremora_warrior02.nif"] = 3,
	["mca\\mca_winged_twilight.nif"] = 3,
	-- Quorn Resource Integration
	["r\\dremora\\lordgod.nif"] = 3,
	["r\\dremora\\lordinspiration.nif"] = 3,
	["r\\dremora\\lordterror.nif"] = 3,
	-- Morrowind Rebirth
	["r\\lordgod.nif"] = 3,
	["r\\lordinspiration.nif"] = 3,
	["r\\lordterror.nif"] = 3,
	["r\\clannfear_fire.nif"] = 3,
	["r\\creeper.nif"] = 3,
	["r\\molaggrunda.nif"] = 3,
	["r\\scamp_fetch.nif"] = 3,
	["r\\staada.nif"] = 3,
	-- Creatures XI
	["plx_crt\\dremora_champion.nif"] = 3,
	["plx_crt\\dremora_champion2.nif"] = 3,
	["plx_crt\\dremora_champion3.nif"] = 3,
	["plx_crt\\dremora_mage.nif"] = 3,
	["plx_crt\\dremora_mage_1.nif"] = 3,
	["plx_crt\\dremora_mage_3_chrl.nif"] = 3,
	["plx_crt\\dremora_mage_6_chrl.nif"] = 3,
	["plx_crt\\firescamp.nif"] = 3,
	["plx_crt\\fleshdremora.nif"] = 3,
	["plx_crt\\tr_dae_bat_vo.nif"] = 3,
	["plx_crt\\tr_dae_bat_vo2.nif"] = 3,
	["plx_crt\\new_dremora.nif"] = 3,
	["plx_crt\\new_dremora_m.nif"] = 3,
	["plx_crt\\boe_morphoid.nif"] = 3,
	["plx_crt\\copy of tr_dae_bat_vo.nif"] = 3,
	["plx_crt\\darksaint.nif"] = 3,
	["plx_crt\\um_daedrorker.nif"] = 3,
	["plx_crt\\um_sed1.nif"] = 3,
	["plx_crt\\vermai.nif"] = 3,
	["plx_crt\\dbeasthound_blue.nif"] = 3,
	["plx_crt\\horror.nif"] = 3,
	["plx_crt\\lurker.nif"] = 3,
	["plx_crt\\plx_crt_dremora_ol.nif"] = 3,
	["plx_crt\\silversaint.nif"] = 3,
	-- RandomPal
	["@3.0\\da\\clf\\v1\\clf.nif"] = 3,
	["@3.0\\da\\dth\\v1\\dth.nif"] = 3,
	["nx9\\nx9_xivilai.nif"] = 3,
	["r\\golden saint2.nif"] = 3,
	["r\\golden saint3.nif"] = 3,
	["r\\golden saint4.nif"] = 3,
	["r\\golden saint5.nif"] = 3,
	["r\\scamp_creeper.nif"] = 3,
	["r\\war_wt_grunda.nif"] = 3,
	["rp\\crt\\old_scamp.nif"] = 3,
	["rp\\drem\\s_dremora.nif"] = 3,
	-- TelShadow: The Shrine Defenders
	["r\\silver saint.nif"] = 3,
	-- OAAB
	["oaab\\r\\daedrat.nif"] = 3,
	["oaab\\r\\herne.nif"] = 3,
	["oaab\\r\\mazken.nif"] = 3,
	-- Pimp My Shrine
	["ss20\\r\\vernmini.nif"] = 3,
	["ss20\\r\\ss20_mazken.nif"] = 3,
}
this.elementalBlood = {
	["r\\atronach_fire.nif"] = 7,
	["r\\atronach_frost.nif"] = 7,
	["r\\atronach_storm.nif"] = 7,
	["r\\spriggan.nif"] = 7,
	-- TR
	["tr\\cr\\tr_golem_mud_vo.nif"] = 7,
	-- PT
	["pc\\cr\\pc_ayl_guard_01.nif"] = 7,
	["pc\\cr\\pc_spriggan.nif"] = 7,
	["sky\\r\\sky_ice wraith_01.nif"] = 7,
	-- Spriggans and Twiggans
	["md_iggan\\md_twiggan.nif"] = 7,
	-- Atronach Expansion
	["mdae\\atronach_flesh.nif"] = 7,
	["mdae\\atronach_iron.nif"] = 7,
	["mdae\\wi_bone_golem.nif"] = 7,
	["mdae\\md_ashlands_golem.nif"] = 7,
	["mdae\\md_atronach_fungus.nif"] = 7,
	["mdae\\md_atronach_telvanni.nif"] = 7,
	["mdae\\md_crystal_atronach.nif"] = 7,
	-- Antares' Creatures Integration
	["ancr\\ga\\gargoyle.nif"] = 7,
	["ancr\\fm\\frostmonarch.nif"] = 7,
	-- Unique Creatures
	["mca\\mca_flameatronach.nif"] = 7,
	-- Morrowind Rebirth
	["r\\frostmonarch.nif"] = 7,
	["r\\earth_atronach.nif"] = 7,
	-- Creatures XI
	["plx_crt\\ent_ai.nif"] = 7,
	["plx_crt\\ent_bc.nif"] = 7,
	["plx_crt\\ent_wg.nif"] = 7,
	["plx_crt\\frostmonarch.nif"] = 7,
	["plx_crt\\atronach_flesh.nif"] = 7,
	["plx_crt\\woodsprite.nif"] = 7,
	-- RandomPal
	["r\\atronach_monarch.nif"] = 7,
	["rp\\crt\\storm_monarch.nif"] = 7,
	-- Pimp My Shrine
	["ss20\\r\\golem_shrine.nif"] = 7,
	["ss20\\r\\lavaguardian.nif"] = 7,
}
this.fabricantBlood = {
	["r\\fabricant.nif"] = 2,
	["r\\fabricant_hulking.nif"] = 2,
	["r\\fabricant_imperfect.nif"] = 2,
}
this.fishBlood = {
	["r\\babelfish.nif"] = 0,
	["r\\slaughterfish.nif"] = 0,
	-- TR
	["tr\\cr\\tr_barfish_1a.nif"] = 0,
	["tr\\cr\\tr_barfish_1b.nif"] = 0,
	["tr\\cr\\tr_barfish_1c.nif"] = 0,
	["tr\\cr\\tr_barfish_2a.nif"] = 0,
	["tr\\cr\\tr_barfish_2b.nif"] = 0,
	["tr\\cr\\tr_barfish_2c.nif"] = 0,
	["tr\\cr\\tr_barfish_3a.nif"] = 0,
	["tr\\cr\\tr_barfish_3b.nif"] = 0,
	["tr\\cr\\tr_barfish_3c.nif"] = 0,
	["tr\\cr\\tr_tully_calf_vo.nif"] = 0,
	["tr\\cr\\tr_tully_vo.nif"] = 0,
	-- PT
	["pc\\cr\\pc_fish_chrysoph.nif"] = 0,
	["pc\\cr\\pc_fish_jewel.nif"] = 0,
	["pc\\cr\\pc_fish_leaper.nif"] = 0,
	["pc\\cr\\pc_fish_longfin.nif"] = 0,
	["pc\\cr\\pc_fish_soldier.nif"] = 0,
	["pc\\cr\\pc_slaughterfish.nif"] = 0,
	["pc\\cr\\pc_slaughterfish_01.nif"] = 0,
	-- SHOTN
	["sky\\r\\sky_browntrout_01.nif"] = 0,
	["sky\\r\\sky_fishcod_01.nif"] = 0,
	["sky\\r\\sky_northernpike_01.nif"] = 0,
	["sky\\r\\sky_pikeperch_01.nif"] = 0,
	["sky\\r\\sky_pinksalmon_01.nif"] = 0,
	-- R-Zero's Creatorium: Waters and Shores
	["r0\\r\\h2o\\s-fish_blind.nif"] = 0,
	["r0\\r\\h2o\\s-fish_elec.nif"] = 0,
	-- Morrowind Rebirth
	["r\\blindfish.nif"] = 0,
	["r\\electricfish.nif"] = 0,
	["r\\oldbluefin.nif"] = 0,
	["r\\slaughter_shark.nif"] = 0,
	-- Creatures XI
	["plx_crt\\ayu.nif"] = 0,
	["plx_crt\\barramundi.nif"] = 0,
	["plx_crt\\bocaccio.nif"] = 0,
	["plx_crt\\oldbluefin.nif"] = 0,
	["plx_crt\\slaughtershark.nif"] = 0,
	["plx_crt\\demekin.nif"] = 0,
	["plx_crt\\seahorse.nif"] = 0,
	-- RandomPal
	["r\\fish.nif"] = 0,
	["r\\fish2.nif"] = 0,
	["r\\fish3.nif"] = 0,
	-- OAAB
	["oaab\\r\\r0_s-fish_blind.nif"] = 0,
}
this.ghostBlood = {
	["r\\ancestorghost.nif"] = 4,
	["r\\dwarvenspecter.nif"] = 4,
	-- TR
	["tr\\cr\\tr_ancestorghostwpn.nif"] = 4,
	-- PT
	["pc\\cr\\pc_ghost_01.nif"] = 4,
	["pc\\cr\\pc_ghost_02.nif"] = 4,
	["pc\\cr\\pc_wraith_01.nif"] = 4,
	["pc\\cr\\pc_wraith_02.nif"] = 4,
	-- Better Dwarven Spectres - Mer and Maidens Edition
	["md_dwsp\\dwspecter_f.nif"] = 4,
	-- Vvardenfell Ancestor Ghosts Weaponized
	["a3\\ancestorghostwpn.nif"] = 4,
	-- Unique Creatures
	["r\\ghast.nif"] = 4,
	["r\\ravenous_spectre.nif"] = 4,
	["r\\revenant.nif"] = 4,
	["r\\shade.nif"] = 4,
	["r\\spectre.nif"] = 4,
	-- Morrowind Rebirth
	["r\\greenslime.nif"] = 4,
	["r\\dahrk_mezalf.nif"] = 4,
	["r\\radac_stungnthumz.nif"] = 4,
	-- RandomPal
	["mca\\mca_banshee01.nif"] = 4,
	["mca\\mca_banshee02.nif"] = 4,
	["mca\\mca_banshee03.nif"] = 4,
	["un\\ancestorghost.nif"] = 4,
	["un\\un_banshee.nif"] = 4,
	["un\\un_ghost_greater.nif"] = 4,
	["un\\un_ghost_sul_senipul.nif"] = 4,
	["un\\un_ghost_vabdas.nif"] = 4,
	["un\\un_ghost_variner.nif"] = 4,
	["un\\un_kanit.nif"] = 4,
	-- Pimp My Shrine
	["ss20\\r\\spirit.nif"] = 4,
	["ss20\\r\\spiritmad.nif"] = 4,
}
this.goblinBlood = {
	["r\\goblin01.nif"] = 0,
	["r\\goblin02.nif"] = 0,
	["r\\goblin03.nif"] = 0,
	["tr\\cr\\tr_goblinshaman.nif"] = 0,
	-- PT
	["sky\\r\\sky_goblinthr_01.nif"] = 0,
	-- Quorn Resource Integration
	["r\\goblinslave01.nif"] = 0,
	["r\\goblinslave02.nif"] = 0,
	-- Morrowind Rebirth
	["r\\goblin_shaman.nif"] = 0,
}
this.insectBlood = {
	["r\\nixhound.nif"] = 6,
	["r\\shalk.nif"] = 6,
	-- TR
	["tr\\cr\\tr_beetle_g01_vo.nif"] = 6,
	["tr\\cr\\tr_beetle_g02_vo.nif"] = 6,
	["tr\\cr\\tr_beetle_g03_vo.nif"] = 6,
	["tr\\cr\\tr_beetle_g04_vo.nif"] = 6,
	["tr\\cr\\tr_dres_bug_mtd_vo.nif"] = 6,
	["tr\\cr\\tr_dres_bug_small_vo.nif"] = 6,
	["tr\\cr\\tr_dres_bug_vo.nif"] = 6,
	["tr\\cr\\tr_juvriverstrider.nif"] = 6,
	["tr\\cr\\tr_le_g_but_micro.nif"] = 6,
	["tr\\cr\\tr_le_g_but_small.nif"] = 6,
	["tr\\cr\\tr_le_g_but_tiny.nif"] = 6,
	["tr\\cr\\tr_le_p_but_micro.nif"] = 6,
	["tr\\cr\\tr_le_p_but_small.nif"] = 6,
	["tr\\cr\\tr_le_p_but_tiny.nif"] = 6,
	["tr\\cr\\tr_le_r_but_micro.nif"] = 6,
	["tr\\cr\\tr_le_r_but_small.nif"] = 6,
	["tr\\cr\\tr_le_r_but_tiny.nif"] = 6,
	["tr\\cr\\tr_nixmount.nif"] = 6,
	["tr\\cr\\tr_ornada_clutch_vo.nif"] = 6,
	["tr\\cr\\tr_ornada_vo.nif"] = 6,
	["tr\\cr\\tr_parastylus_vo.nif"] = 6,
	["tr\\cr\\tr_plainstrider_vo.nif"] = 6,
	["tr\\cr\\tr_riverstrider_nr.nif"] = 6,
	["tr\\cr\\tr_siltstrider_vo.nif"] = 6,
	["tr\\cr\\tr_skyrender.nif"] = 6,
	["tr\\cr\\tr_skyrenderm.nif"] = 6,
	["tr\\cr\\tr_swampfly_vo.nif"] = 6,
	["tr\\cr\\tr_swampspider_vo.nif"] = 6,
	["tr\\cr\\tr_venusplant_aa.nif"] = 6,
	["tr\\cr\\tr_yethbug.nif"] = 6,
	-- SHOTN
	["sky\\r\\sky_bees_01.nif"] = 6,
	["sky\\r\\sky_bees_02.nif"] = 6,
	["sky\\r\\sky_spider_01.nif"] = 6,
	["sky\\r\\sky_spikeworm_01.nif"] = 6,
	-- Morrowind Rebirth
	["r\\nixhoundb.nif"] = 6,
	["r\\shalkb.nif"] = 6,
	["r\\ash_scorpion.nif"] = 6,
	["r\\shalk_blueback.nif"] = 6,
	["r\\shalk_greenback.nif"] = 6,
	-- Blighted Animals Retextured
	["nixhoundb.nif"] = 6,
	["shalkb.nif"] = 6,
	-- Creatures XI
	["plx_crt\\nixh_b.nif"] = 6,
	["plx_crt\\nixh_d.nif"] = 6,
	["plx_crt\\nixpup.nif"] = 6,
	["plx_crt\\tr_beetle_g01_vo.nif"] = 6,
	["plx_crt\\tr_beetle_g02_vo.nif"] = 6,
	["plx_crt\\tr_beetle_g03_vo.nif"] = 6,
	["plx_crt\\tr_beetle_g04_vo.nif"] = 6,
	["plx_crt\\butterfly.nif"] = 6,
	["plx_crt\\butterfly2.nif"] = 6,
	["plx_crt\\pf_was1.nif"] = 6,
	["plx_crt\\pf_wasp.nif"] = 6,
	["plx_crt\\photodragons.nif"] = 6,
	-- RandomPal
	["r\\wyrm_spider.nif"] = 6,
	-- Diseased and Blighted Creatures Frank
	["cab\\rc\\nixhoundb.nif"] = 6,
	["cab\\rc\\shalkb.nif"] = 6,
	["cab\\rd\\shalkd.nif"] = 6,
	-- OAAB
	["oaab\\r\\lidicus_cspider.nif"] = 6,
	["oaab\\r\\tr_siltstrider_vo.nif"] = 6,
}
this.kwamaBlood = {
	["r\\kwama forager.nif"] = 6,
	["r\\kwama queen.nif"] = 6,
	["r\\kwama warior.nif"] = 6,
	["r\\kwama worker.nif"] = 6,
	["r\\minescrib.nif"] = 6,
	-- Morrowind Rebirth
	["r\\kwama foragerb.nif"] = 6,
	["r\\scribb.nif"] = 6,
	["r\\ashscrib.nif"] = 6,
	-- Blighted Animals Retextured
	["kwama foragerb.nif"] = 6,
	["scribb.nif"] = 6,
	-- Creatures XI
	["plx_crt\\kwama forager_b.nif"] = 6,
	["plx_crt\\kwama forager_d.nif"] = 6,
	["plx_crt\\kwama warior_b.nif"] = 6,
	["plx_crt\\kwama warior_d.nif"] = 6,
	["plx_crt\\kwama worker_b.nif"] = 6,
	["plx_crt\\kwama worker_d.nif"] = 6,
	["plx_crt\\minescrib_b.nif"] = 6,
	["plx_crt\\um_hornedscrib.nif"] = 6,
	["plx_crt\\tr_parastylus_vo.nif"] = 6,
	["plx_crt\\scarab.nif"] = 6,
	["plx_crt\\scorpion1.nif"] = 6,
	["plx_crt\\scorpion2.nif"] = 6,
	["plx_crt\\spider.nif"] = 6,
	-- Diseased and Blighted Creatures Frank
	["cab\\rc\\kwama foragerb.nif"] = 6,
	["cab\\rc\\kwama warriorb.nif"] = 6,
	["cab\\rc\\kwama workerb.nif"] = 6,
	["cab\\rc\\scribb.nif"] = 6,
	["cab\\rd\\kwama workerd.nif"] = 6,
	["cab\\rd\\scribd.nif"] = 6,
	-- OAAB
	["oaab\\r\\kwama grubber.nif"] = 6,
}
this.mammalBlood = {
	["r\\bear_black_larger.nif"] = 0,
	["r\\bear_blond_larger.nif"] = 0,
	["r\\bear_brown_larger.nif"] = 0,
	["r\\horker.nif"] = 0,
	["r\\horker_larger.nif"] = 0,
	["r\\mount.nif"] = 0,
	["r\\packrat.nif"] = 0,
	["r\\raven.nif"] = 0,
	["r\\rust rat.nif"] = 0,
	["r\\wolf_black.nif"] = 0,
	["r\\wolf_red.nif"] = 0,
	["r\\wolf_white.nif"] = 0,
	["wolf\\skinnpc.nif"] = 0,
	-- TR
	["tr\\cr\\tr_hoom.nif"] = 0,
	["tr\\cr\\tr_mouse00_ya.nif"] = 0,
	["tr\\cr\\tr_mouse01_ya.nif"] = 0,
	["tr\\cr\\tr_mouse02_ya.nif"] = 0,
	["tr\\cr\\tr_seatroll_vo.nif"] = 0,
	["tr\\cr\\tr_swamp_troll.nif"] = 0,
	["tr\\cr\\tr_troll_cave01.nif"] = 0,
	["tr\\cr\\tr_troll_cave02.nif"] = 0,
	["tr\\cr\\tr_troll_cave03.nif"] = 0,
	["tr\\cr\\tr_troll_cave04.nif"] = 0,
	["tr\\cr\\tr_troll_frost01.nif"] = 0,
	["tr\\cr\\tr_troll_frost02.nif"] = 0,
	["tr\\cr\\tr_troll_frost03.nif"] = 0,
	["tr\\cr\\tr_troll_frost04.nif"] = 0,
	["tr\\cr\\tr_velk.nif"] = 0,
	["tr\\cr\\troll_armored.nif"] = 0,
	-- PT
	["pc\\cr\\pc_bat_01.nif"] = 0,
	["pc\\cr\\pc_bear.nif"] = 0,
	["pc\\cr\\pc_bull.nif"] = 0,
	["pc\\cr\\pc_bull_r.nif"] = 0,
	["pc\\cr\\pc_bullfrog.nif"] = 0,
	["pc\\cr\\pc_cow.nif"] = 0,
	["pc\\cr\\pc_crow_01.nif"] = 0,
	["pc\\cr\\pc_eagle_01.nif"] = 0,
	["pc\\cr\\pc_goat_01.nif"] = 0,
	["pc\\cr\\pc_horse_01.nif"] = 0,
	["pc\\cr\\pc_horse_02.nif"] = 0,
	["pc\\cr\\pc_horse_03.nif"] = 0,
	["pc\\cr\\pc_horsesdl_01.nif"] = 0,
	["pc\\cr\\pc_horsesdl_02.nif"] = 0,
	["pc\\cr\\pc_horsesdl_03.nif"] = 0,
	["pc\\cr\\pc_minotaur_01.nif"] = 0,
	["pc\\cr\\pc_minotaur_02.nif"] = 0,
	["pc\\cr\\pc_mule.nif"] = 0,
	["pc\\cr\\pc_packmule_01.nif"] = 0,
	["pc\\cr\\pc_packmule_02.nif"] = 0,
	["pc\\cr\\pc_seagull_01.nif"] = 0,
	["pc\\cr\\pc_whitewolf.nif"] = 0,
	["pc\\cr\\pc_wolf.nif"] = 0,
	-- SHOTN
	["sky\\r\\sky_bear_grey_01.nif"] = 0,
	["sky\\r\\sky_boar_01.nif"] = 0,
	["sky\\r\\sky_chickadee_01.nif"] = 0,
	["sky\\r\\sky_cow_01.nif"] = 0,
	["sky\\r\\sky_cow_02.nif"] = 0,
	["sky\\r\\sky_cow_03.nif"] = 0,
	["sky\\r\\sky_devourer_black_01.nif"] = 0,
	["sky\\r\\sky_dn_bear_black_01.nif"] = 0,
	["sky\\r\\sky_elk_01.nif"] = 0,
	["sky\\r\\sky_elk_02.nif"] = 0,
	["sky\\r\\sky_elk_03.nif"] = 0,
	["sky\\r\\sky_farm_chicken_01.nif"] = 0,
	["sky\\r\\sky_farm_chicken_02.nif"] = 0,
	["sky\\r\\sky_farm_chicken_03.nif"] = 0,
	["sky\\r\\sky_farm_chicken_04.nif"] = 0,
	["sky\\r\\sky_farm_chicken_05.nif"] = 0,
	["sky\\r\\sky_farm_chickenc_01.nif"] = 0,
	["sky\\r\\sky_farm_chickenc_02.nif"] = 0,
	["sky\\r\\sky_farm_chickenc_03.nif"] = 0,
	["sky\\r\\sky_farm_rooster_01.nif"] = 0,
	["sky\\r\\sky_farm_rooster_02.nif"] = 0,
	["sky\\r\\sky_giant.nif"] = 0,
	["sky\\r\\sky_goat_01.nif"] = 0,
	["sky\\r\\sky_goat_02.nif"] = 0,
	["sky\\r\\sky_goat_03.nif"] = 0,
	["sky\\r\\sky_goldfinch_01.nif"] = 0,
	["sky\\r\\sky_goldfinch_02.nif"] = 0,
	["sky\\r\\sky_hagraven_01.nif"] = 0,
	["sky\\r\\sky_horse_01.nif"] = 0,
	["sky\\r\\sky_horse_02.nif"] = 0,
	["sky\\r\\sky_horse_03.nif"] = 0,
	["sky\\r\\sky_horse_04.nif"] = 0,
	["sky\\r\\sky_horse_05.nif"] = 0,
	["sky\\r\\sky_horse_06.nif"] = 0,
	["sky\\r\\sky_horse_07.nif"] = 0,
	["sky\\r\\sky_horse_08.nif"] = 0,
	["sky\\r\\sky_mammoth_01.nif"] = 0,
	["sky\\r\\sky_minotaur_01.nif"] = 0,
	["sky\\r\\sky_raki_01.nif"] = 0,
	["sky\\r\\sky_robin_01.nif"] = 0,
	["sky\\r\\sky_sabre_cat_01.nif"] = 0,
	["sky\\r\\sky_sabre_cat_02.nif"] = 0,
	["sky\\r\\sky_sparrow_01.nif"] = 0,
	["sky\\r\\sky_sparrow_02.nif"] = 0,
	["sky\\r\\sky_squirrel_01.nif"] = 0,
	["sky\\r\\sky_squirrel_02.nif"] = 0,
	["sky\\r\\sky_wereboar_01.1st.nif"] = 0,
	["sky\\r\\sky_wereboar_01.nif"] = 0,
	["sky\\r\\sky_wereboar_olct.nif"] = 0,
	["sky\\r\\sky_werewolf_01.nif"] = 0,
	["sky\\r\\sky_wolf_grey.nif"] = 0,
	-- Bloodmoon Creatures
	["#bmcr\\icemraider2.nif"] = 0,
	["#bmcr\\icemwarmount.nif"] = 0,
	["#bmcr\\icemwarraider.nif"] = 0,
	-- Antares' Creatures Integration
	["ancr\\ancr_troll.nif"] = 0,
	["ancr\\hg\\hillgiant.nif"] = 0,
	-- Morrowind Rebirth
	["r\\hillgiant.nif"] = 0,
	["r\\ratb.nif"] = 0,
	["r\\swamp_troll.nif"] = 0,
	["plx_crt\\bunny1.nif"] = 0,
	-- Creatures XI
	["plx_crt\\meow.nif"] = 0,
	["plx_crt\\moosebullpw1.nif"] = 0,
	["plx_crt\\db_deer.nif"] = 0,
	["plx_crt\\squirrel1.nif"] = 0,
	["plx_crt\\dgargoyle.nif"] = 0,
	["plx_crt\\dimp.nif"] = 0,
	["plx_crt\\um_bugbear.nif"] = 0,
	["plx_crt\\um_cavetroll.nif"] = 0,
	-- RandomPal
	["r0\\r\\bm\\troll_cave.nif"] = 0,
	-- Diseased and Blighted Creatures Frank
	["cab\\rc\\ratb.nif"] = 0,
	["cab\\rd\\ratd.nif"] = 0,
	-- OAAB
	["oaab\\r\\bat.nif"] = 0,
}
this.netchBlood = {
	["r\\netch_betty.nif"] = 5,
	["r\\netch_bull.nif"] = 5,
	-- morrowind rebirth
	["r\\netch_betty_ash.nif"] = 5,
	["r\\netch_betty_swamp.nif"] = 5,
	["r\\netch_bull_ash.nif"] = 5,
	["r\\netch_bull_swamp.nif"] = 5,
	-- creatures xi
	["plx_crt\\vnetch_betty.nif"] = 1,
	["plx_crt\\vnetch_bull.nif"] = 1,
}
this.reptileBlood = {
	["r\\cliffracer.nif"] = 0,
	["r\\durzog.nif"] = 0,
	["r\\durzog_collar.nif"] = 0,
	["r\\duskyalit.nif"] = 0,
	["r\\guar.nif"] = 0,
	["r\\guar_white.nif"] = 0,
	["r\\guar_withpack.nif"] = 0,
	["r\\leastkagouti.nif"] = 0,
	-- TR
	["tr\\cr\\guar_withharness.nif"] = 0,
	["tr\\cr\\tr_direkagouti.nif"] = 0,
	-- PT
	["pc\\cr\\pc_lamia.nif"] = 0,
	["pc\\cr\\pc_rivernewt_01.nif"] = 0,
	["pc\\cr\\pc_rivernewt_02.nif"] = 0,
	-- SHOTN
	["sky\\r\\sky_wormmouth_01.nif"] = 0,
	-- Antares' Creatures Integration
	["ancr\\med\\medusa.nif"] = 0,
	["ancr\\med\\medusa_nerodia.nif"] = 0,
	-- Morrowind Rebirth
	["r\\alitb.nif"] = 0,
	["r\\cliffracerb.nif"] = 0,
	["r\\guar_withharness.nif"] = 0,
	["r\\kagoutib.nif"] = 0,
	["r\\guar_withpack.nif"] = 0,
	["r\\wormmouth.nif"] = 0,
	-- Creatures XI
	["plx_crt\\acd_kriin_01.nif"] = 0,
	["plx_crt\\alit_b.nif"] = 0,
	["plx_crt\\alit_d.nif"] = 0,
	["plx_crt\\um_raptor.nif"] = 0,
	["plx_crt\\um_raptor2.nif"] = 0,
	["plx_crt\\um_r'hkolrym.nif"] = 0,
	["plx_crt\\snake_1.nif"] = 0,
	["plx_crt\\snake_2.nif"] = 0,
	["plx_crt\\kagouti_b.nif"] = 0,
	["plx_crt\\kagouti_d.nif"] = 0,
	["plx_crt\\cliffracer_b.nif"] = 0,
	["plx_crt\\cliffracer_d.nif"] = 0,
	["plx_crt\\um_fabricant.nif"] = 0,
	["plx_crt\\bloodwing.nif"] = 0,
	["plx_crt\\iceworm.nif"] = 0,
	["plx_crt\\ultimarotworm.nif"] = 0,
	-- Diseased and Blighted Creatures Frank
	["cab\\rc\\alitb.nif"] = 0,
	["cab\\rc\\cliffracerb.nif"] = 0,
	["cab\\rc\\kagoutib.nif"] = 0,
	["cab\\rd\\alitd.nif"] = 0,
	["cab\\rd\\cliffracerd.nif"] = 0,
	["cab\\rd\\durzogd.nif"] = 0,
	["cab\\rd\\kagoutid.nif"] = 0,
	-- Pimp My Shrine
	["ss20\\r\\surfracer.nif"] = 0,
}
this.skeletalBlood = {
	["r\\bonelord.nif"] = 1,
	["r\\liche.nif"] = 1,
	["r\\liche_king.nif"] = 1,
	["r\\skeleton.nif"] = 1,
	-- TR
	["tr\\cr\\tr_liche_greater.nif"] = 1,
	["tr\\cr\\tr_skeleton_arise01.nif"] = 1,
	["tr\\cr\\tr_skeleton_arise02.nif"] = 1,
	["tr\\cr\\tr_skeleton_arise03.nif"] = 1,
	["tr\\cr\\tr_skeleton_arise04.nif"] = 1,
	["tr\\cr\\tr_skeleton_khajiit.nif"] = 1,
	["tr\\cr\\tr_skeleton_orc.nif"] = 1,
	-- PT
	["pc\\cr\\pc_skeleton_imp01.nif"] = 1,
	["pc\\cr\\pc_skeleton_imp02.nif"] = 1,
	-- SHOTN
	["sky\\r\\sky_lich_frost_01.nif"] = 1,
	["sky\\r\\sky_lich_frost_02.nif"] = 1,
	["sky\\r\\sky_lich_frost_03.nif"] = 1,
	["sky\\r\\sky_lich_frost_04.nif"] = 1,
	["sky\\r\\sky_skeleton_crip_01.nif"] = 1,
	-- Unique Creatures
	["mca\\mca_lich_ancient.nif"] = 1,
	["mca\\mca_skeleton_archer.nif"] = 1,
	["mca\\mca_skeleton_berserk01.nif"] = 1,
	["mca\\mca_skeleton_berserk02.nif"] = 1,
	["mca\\mca_skeleton_crippled.nif"] = 1,
	["mca\\mca_skeleton_indoril.nif"] = 1,
	["mca\\mca_skeleton_nordmail.nif"] = 1,
	["mca\\mca_skeleton_orcish.nif"] = 1,
	["mca\\mca_skeleton_warrior.nif"] = 1,
	["mca\\mca_skeleton_warwizard.nif"] = 1,
	["mca\\mca_wight01.nif"] = 1, 
	["mca\\mca_wormlord.nif"] = 1,
	-- Morrowind Rebirth
	["r\\lich_queen.nif"] = 1,
	["r\\skeleton_beldoh.nif"] = 1,
	["r\\skeleton_berserk_01.nif"] = 1,
	["r\\skeleton_berserk_02.nif"] = 1,
	["r\\skeleton_champion.nif"] = 1,
	["r\\skeleton_dunmer.nif"] = 1,
	["r\\skeleton_fur.nif"] = 1,
	["r\\skeleton_imp_archer.nif"] = 1,
	["r\\skeleton_imp_warrior.nif"] = 1,
	["r\\skeleton_indoril.nif"] = 1,
	["r\\skeleton_khelam.nif"] = 1,
	["r\\skeleton_kragh.nif"] = 1,
	["r\\skeleton_nordmail.nif"] = 1,
	["r\\skeleton_orcish.nif"] = 1,
	["r\\skeleton_uraezhar.nif"] = 1,
	["r\\skeleton_warrior_01.nif"] = 1,
	["r\\skeleton_warrior_02.nif"] = 1,
	["r\\skeleton_warrior_03.nif"] = 1,
	["r\\skeleton_warrior_04.nif"] = 1,
	["r\\skeleton_warrior_05.nif"] = 1,
	["r\\skeleton_warrior_06.nif"] = 1,
	["r\\skeleton_warrior_07.nif"] = 1,
	["r\\skeleton_wormlord.nif"] = 1,
	["r\\phnem.nif"] = 1,
	["r\\prac_dummy.nif"] = 1,
	["r\\prac_target.nif"] = 1,
	-- Creatures XI
	["plx_crt\\skeleton_archer.nif"] = 1,
	["plx_crt\\skeleton_berserk1.nif"] = 1,
	["plx_crt\\skeleton_berserk2.nif"] = 1,
	["plx_crt\\skeleton_champion.nif"] = 1,
	["plx_crt\\skeleton_crippled.nif"] = 1,
	["plx_crt\\skeleton_nordmail.nif"] = 1,
	["plx_crt\\skeleton_wight.nif"] = 1,
	["plx_crt\\db_flamingskull.nif"] = 1,
	["plx_crt\\lich_ancient.nif"] = 1,
	["plx_crt\\nordskelly3.nif"] = 1,
	["plx_crt\\warwizard.nif"] = 1,
	-- RandomPal
	["mca\\mca_skeleton_warrior.nif"] = 1,
	["mca\\mca_skeleton_warwizard.nif"] = 1,
	["undeadglassknight.nif"] = 1,
	["un\\un_lich.nif"] = 1,
	["un\\un_pirate.nif"] = 1,
	["un\\un_piratecap.nif"] = 1,
	["un\\un_skeleton_arise.nif"] = 1,
	["un\\un_skeleton_dead.nif"] = 1,
	["un\\un_skeleton_decayed.nif"] = 1,
	["un\\un_skeleton01.nif"] = 1,
	["un\\un_skeletonarise2.nif"] = 1,
	-- OAAB
	["oaab\\r\\undeadglassknight.nif"] = 1,
}
this.specialBlood = {
	["r\\almelexia.nif"] = 7,
	["r\\almelexia_warrior.nif"] = 7,
	["r\\ashvampire.nif"] = 7,
	["r\\dagothr.nif"] = 7,
	["r\\heart_akulakhan.nif"] = 7,
	["r\\hircine.nif"] = 7,
	["r\\hircine_bear_larger.nif"] = 7,
	["r\\hircinewolf.nif"] = 7,
	["r\\lordvivec.nif"] = 7,
	["r\\swimmer.nif"] = 7,
	-- Dagoth Creatures Replacer
	["r\\dagothgares.nif"] = 7,
	["r\\dagoth_ascendedsleeper01.nif"] = 7,
	["r\\dagoth_ascendedsleeper02.nif"] = 7,
	["r\\dagoth_ashghoul01.nif"] = 7,
	["r\\dagoth_ashghoul02.nif"] = 7,
	-- Divine Dagoths
	["dn\\dn_ashvampire01.nif"] = 7,
	["dn\\dn_ashvampire02.nif"] = 7,
	["dn\\dn_ashvampire03.nif"] = 7,
	["dn\\dn_ashvampire04.nif"] = 7,
	["dn\\dn_ashvampire05.nif"] = 7,
	["dn\\dn_ashvampire06.nif"] = 7,
	["dn\\dn_ashvampire07.nif"] = 7,
}
this.undeadBlood = {
	["r\\bonewalker.nif"] = 1,
	["r\\cr_draugr.nif"] = 1,
	["r\\draugrlord.nif"] = 1,
	["r\\greatbonewalker.nif"] = 1,
	["r\\undeadwolf_2.nif"] = 1,
	-- TR
	["tr\\cr\\tr_mummy_02.nif"] = 1,
	["tr\\cr\\tr_mummy_vo.nif"] = 1,
	-- PT
	["pc\\cr\\pc_mummy.nif"] = 1,
	-- SHOTN
	["sky\\r\\sky_draugr_axeman.nif"] = 1,
	["sky\\r\\sky_draugrlord.nif"] = 1,
	-- Bloodmoon Creatures
	["#bmcr\\blackbonewolf.nif"] = 1,
	["#bmcr\\blackskinnedwolf.nif"] = 1,
	["#bmcr\\draugrnordarm.nif"] = 1,
	-- Morrowind Rebirth
	["r\\draugr_berserker.nif"] = 1,
	["r\\draugr_deathlord.nif"] = 1,
	-- Creatures XI
	["plx_crt\\mummy.nif"] = 1,
	["plx_crt\\mummy_summon.nif"] = 1,
	["plx_crt\\dzombie.nif"] = 1,
	-- RandomPal
	["mca\\mca_ghoul.nif"] = 1,
	["un\\un_draugr.nif"] = 1,
	["un\\un_draugrlord.nif"] = 1,
	["un\\m\\mummy.nif"] = 1,
	-- OAAB
	["oaab\\r\\vamp_stalker.nif"] = 1,
}

return this