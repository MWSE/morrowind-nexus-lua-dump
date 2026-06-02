-- scripts/arcane_illumination/data/protected_items.lua
-- Returns a lowercase-keyed set: id -> true

local raw = [[
keening
sunder
wraithguard
lugrub's axe
dwarven war axe_redas
ebony staff caper
ebony wizard's staff
rusty_dagger_unique
devil_tanto_tgamg
daedric wakizashi_hhst
glass_dagger_enamor
dart_uniq_judgement
dwemer_boots of flying
bonemold_gah-julan_hhda
bonemold_founders_helm
bonemold_tshield_hrlb
amulet of ashamanu
amuletfleshmadewhole_uniq
amulet_agustas_unique
expensive_amulet_delyna
expensive_amulet_aeta
sarandas_amulet
exquisite_amulet_hlervu1
julielle_aumines_amulet
linus_iulus_maran amulet
amulet_skink_unique
linus_iulus_stendarran_belt
sarandas_belt
common_glove_l_balmolagmer
common_glove_r_balmolagmer
extravagant_rt_art_wild
expensive_glove_left_ilmeni
extravagant_glove_left_maur
extravagant_glove_right_maur
common_pants_02_hentus
sarandas_pants_2
adusamsi's_ring
extravagant_ring_aund_uni
ring_blackjinx_uniq
exquisite_ring_brallion
common_ring_danar
sarandas_ring_2
ring_keley
expensive_ring_01_bill
expensive_ring_aeta
sarandas_ring_1
expensive_ring_01_hrdt
exquisite_ring_processus
ring_dahrkmezalf_uniq
extravagant_robe_01_red
robe of st roris
exquisite_robe_drake's pride
sarandas_shirt_2
exquisite_shirt_01_rasha
sarandas_shoes_2
therana's skirt
misc_beluelle_silver_bowl
misc_lw_bowl_chapel
misc_dwrv_artifact_ils
misc_dwarfbone_unique
misc_dwrv_ark_cube00
misc_fakesoulgem
ingred_guar_hide_girith
misc_uniq_egg_of_gold
misc_goblet_dagoth
ingred_guar_hide_marsus
misc_6th_ash_hrmm
misc_de_goblet_01_redas
misc_skull_llevule
misc_6th_ash_hrcs
misc_wraithguard_no_equip
bk_a1_1_caiuspackage
bk_a1_1_packagedecoded
tr_m3_q_theriftcandle
tr_m3_q_theriftcandleoff
tr_m3_a9_q_ritualcandle
tr_m3_raathimtorch01
tr_m3_raathimtorch02
tr_m3_raathimtorch03
tr_m3_oe_mg_ritualcandle
tr_m3_oe_mg_ritualcandle_lit
tr_m1_fw_tg2_candlestick
tr_m3-794_lantern
tr_m3_lgt_lantern1
tr_m3_lgt_candle
tr_m2_kaishi_lantern
tr_m3_q_a7_nethrillantern
tr_m3_tt_rip_ritualcandle
tr_m3_i3_316_com_candle_14_off
tr_m3_oe_mg_silvercandle
tr_m2_q_14_candle02
tr_m2_q_14_candle01
tr_m3_et14_lantern
tr_m3_votive_i3-399-ind
tr_m2_q_14_commonsoulgem
tr_m1_soulgem_curse_i62
tr_m3_oe_q_missagem
tr_m3_oe_q_missagem2
tr_m3_oe_q_missagempre
tr_m1_q_hernessoul
tr_m3_oe_fiendgem
tr_m3_zymelkaazsoulgem
tr_m2_plans_i2-307
tr_m2_kmlz_chefb_coherer
tr_m3_dwemeroreprobe
tr_m2_dwrv_artifact70_01
tr_m1_q_attackpiece4
tr_m3_q_fakedwemercoin
tr_m1_q_attackpiece3
tr_m1_eec_harecoherer
tr_m1_q_attackpiece2
tr_m2_q_22_lw_platter
tr_m2_q_22_lw_platter2
tr_m2_q_9_flinbottle
tr_m3_essempty_i3-128-ind
tr_m3_oe_tg_goblet
tr_m2_q_9_pot_uni
tr_m1_yamanakal_spoon
tr_m3_voicebottle21
tr_m3_oe_fg_lenwskel
tr_m3_oe_fg_q_constskelet
tr_m3_kha_anguish_crux
tr_m2_necrom_enduur_uni
tr_m3_tt_rip_fedura_ash
tr_m3_voicebottle7
tr_m4_aa_uvaynjewelrybag_01
tr_m3_essrose_i3-128-ind
tr_m3_q_bloodstone
tr_m3_q_bloodstone_actv
tr_m3_oe_mggemreward
tr_m3_blood_i1-453-aun
tr_m3_q_oe_tokenbrass
tr_m2_q_6_badshovel
tr_m3_q_oe_urien_sword_01
tr_m3_voicebottle17
tr_m3_oe_svarrcloth
tr_m3_voicebottle14
tr_m1_q_diamondsample
tr_i2_445_sealingskull
tr_m3_kha_sy_hand
tr_m3_voicebottle10
tr_m2_q_a9_6_skull
tr_m3_oe_mg_enchbroom
tr_m3_q_hideseekskull
tr_m1_faruna_roll_pin
tr_m1_q_57_featherspear
tr_m3_et22_forceps
tr_m4_armun_ganahiru_hide
tr_m3_esskanet_i3-128-ind
tr_m3_q_ienasajug
tr_m2_q_10_treatment
tr_m1_q50_cloth_1
tr_m1_q50_cloth_2
tr_m3_voicebottle22
tr_m3_voicebottle24
tr_m3_voicebottle8
tr_m7_ns_tt_chavana1_potion
tr_m3_q_theriftdeskitem6
tr_m4_kassadpackage
tr_m3_rd_hiseyes_intelligence
tr_m1_bo_muskfly_oil
tr_m3_q_oe_ulka_dice
tr_m3_voicebottle16
tr_m7_othm_q_madranadrum
tr_m3_oe_fg_sycobroom
tr_m2_q_6_goodshovel
tr_m3_essnight_i3-128-ind
tr_m3_essnirth_i3-128-ind
tr_m2_q_a8_2_nobura_tayo
tr_m3_voicebottle19
tr_m3_oe_ashstatue
tr_m3_oe_cirtielashstatue
tr_m1_fw_ic2_package
tr_m3_dirt_i3-390-ind
tr_m3_relic1_i3-559-ind
tr_m3-725_misc_rot_khj_02
tr_m3-725_misc_rot_orc_02
tr_m3_elysanadiamond
tr_m3_trueelysanadiamond
tr_m3_q_theriftdeskitem7
tr_m3_voicebottle23
tr_m7_q_scryingglass
tr_m3_tt_flood_sarnatash
tr_m3_seedbag_i3-390-ind
tr_m7_q_hh_alvynu_glassshard
tr_m7_q_hh_alvynu_glassshard_x
tr_m7_q_hh_seventhfam_seydaneen
tr_m2_q_a9_5_aryn_skull
tr_m3_voicebottle20
tr_m3_voicebottle13
tr_m1_q50_go2_finethread
tr_m3_essstone_i3-128-ind
tr_m3_sa_supplypackage
tr_m7_talmsbelethlute
tr_m3_esstimsa_i3-128-ind
tr_m3_voicebottle18
tr_m3_voicebottle15
tr_m3_q_oe_tokenwood
tr_m1_eec_zarenpack
tr_m3_voicebottle9
pc_m1_mg_cha3_potion2
pc_m1_cha_cassynder_goblet
pc_m1_mg_cha3_potion1
pc_m1_ip_lki4_blood
pc_m1_anv_blkview_asoulgemmsc1
pc_m1_anv_blkview_asoulgemmsc2
pc_m1_anv_blkview_asoulgemmsc3
pc_m1_dm_adunadosu
pc_m1_tg_anv3_painting
pc_m1_mg_anv7_crystalball
pc_m1_anv_crabbuck_bucket
pc_m1_anv_workorc_pole
pc_m1_cha_pelleg_vial
pc_m1_ip_lki2_painting
pc_m1_cha_selkies_skin
pc_m1_k1_mc2_shipment
pc_m1_fg_anv5_painting
pc_m1_anv_decatorremains
pc_m1_mg_cha2_basket
]]

local set = {}
for line in raw:gmatch("[^\r\n]+") do
    local id = line:match("^%s*(.-)%s*$")
    if id ~= "" and id:sub(1, 1) ~= "#" then
        set[id:lower()] = true
    end
end

return set