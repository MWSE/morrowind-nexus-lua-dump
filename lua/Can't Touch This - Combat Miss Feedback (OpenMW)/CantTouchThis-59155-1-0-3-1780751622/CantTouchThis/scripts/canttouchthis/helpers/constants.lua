---@omw-context local
local anim      = require('openmw.animation')
local Constants = {}


---@enum TRUE_ATTACK_TYPE
Constants.TRUE_ATTACK_TYPE   = {
    Chop = 0,
    Slash = 1,
    Thrust = 2,
}

Constants.readableAttackType = {
    [0] = "chop",
    [1] = "slash",
    [2] = "thrust"
}

Constants.attackTypeByIndex  = {
    [0] = Constants.TRUE_ATTACK_TYPE.Chop,
    [1] = Constants.TRUE_ATTACK_TYPE.Slash,
    [2] = Constants.TRUE_ATTACK_TYPE.Thrust,
}



Constants.h2hdodgeAnimations = {
    "missdr",
    "missdl",
    "missdfwd",
    "missdfwdr",
    "missdfwdl",
    "missdbk",
    "missdbkr",
    "missdbkl",
    "dodgeturnleft",
    "dodgeturnright",
    "dodgeleanback",
}

Constants.armedDodgeAnimations = {
    "dodgeturnleft",
    "dodgeturnright",
    "dodgeleanback",
}

Constants.dodgeBlendMask = anim.BLEND_MASK.Torso + anim.BLEND_MASK.LowerBody
Constants.dodgePriority = anim.PRIORITY.Scripted

Constants.staggerAnimations = {
    "hit1",
    "hit2",
    "hit3",
    "hit4",
    "hit5",
    "swimhit1",
    "swimhit2",
    "swimhit3",
    "knockdown",
    "knockout",
    "swimknockout",
    "swimknockdown",
}

Constants.creatureWhiteList = {
    "vivec_god",
    "bm_hircine_huntaspect"
}

Constants.creatureBlackList = {
    "bm_riekling",
    "bm_riekling_be_unique1",
    "bm_riekling_be_unique2",
    "bm_riekling_be_unique3",
    "bm_riekling_be_unique4",
    "bm_riekling_be_unique5",
    "bm_riekling_dulk_unique",
    "bm_riekling_krish_uniqu",
    "bm_riekling_be_unique",
    "bm_riekling_boarmaster",
    "bm_riekling_st_unique",
    "bm_riekling_mounted",
    "ab_und_dwrvspectrewep",
    "ab_und_dwrvspectrewepf",
    "t_cyr_und_wrth_01",
    "t_cyr_und_wrthfad_01",
    "t_dae_cre_seducdark_01",
    "t_dwe_cre_centarc_01",
    "centurion_projectile",
    "centurion_projectile_c",
    "t_dwe_cre_centarcml_01",
    "t_dwe_cre_centarcsh_01",
    "t_glb_cre_dreumow_01",
    "t_mw_cre_dreumow_01",
    "t_mw_und_ancestorwep_01",
    "t_tsa_cre_tsaesci_01",
    "t_tsa_cre_tsaesci_02",
    "t_tsa_cre_tsaesci _01", -- td has some bad creature ids. keeping both variants in case they fix them in the future
    "t_tsa_cre_tsaesci _02",
    "almalexia",
    "pc_m1_cha_goldnets_gob1",
    "pc_m1_cha_goldnets_gob2",
    "pc_m1_cha_goldnets_gob3",
    "pc_m1_mg_cha4_goblin1",
    "pc_m1_mg_cha4_goblin5",
    "goblin_officeruni",
    "t_cyr_cre_gob_01",
    "t_cyr_cre_gobchf_01",
    "pc_m1_sc_goattrbls_gob1",
    "pc_m1_sc_goattrbls_gob2",
    "t_mw_cre_gobbrs_01",
    "t_mw_cre_gobbru_01",
    "t_sky_cre_gobbrs_01",
    "t_sky_cre_gobbru_01",
    "tr_m7_cre_gobmag_uni",
    "tr_m7_cre_gobmaggot_01",
    "tr_m7_cre_gobmaggot_02",
    "sky_qre_dse4_goba",
    "t_cyr_cre_gobchf_01",
    "t_mw_cre_gobchf_01",
    "t_sky_cre_gobchf_01",
    "tr_m7_cre_gobmag_chief",
    "tr_m7_cre_gobmaggot_03",
    "tr_m7_ns_arena_gobboss",
    "pc_m1_mg_cha4_goblin4",
    "t_sky_cre_gobthr_01",
    "t_mw_cre_gobthr_01",
    "tr_m7_cre_gobmaggot_06",
    "t_mw_cre_gobblind_01",
    "t_sky_cre_gobshm_01",
    "t_mw_cre_gobshm_01",
    "tr_m7_cre_gobmaggot_04",
    "t_mw_cre_gobblind_02",
    "tr_m7_kalk_goblinfollow",
    "t_mw_cre_gobblind_03",
    "t_mw_cre_gobblind_04",
    -- "almalexia_warrior",
    -- "goblin_grunt",
    -- "goblin_footsoldier",
    -- "t_mw_cre_gobskr_01",
    -- "t_cyr_cre_gobskm_01",
    -- "tr_m7_cre_gobmaggot_05",
    -- "tr_m7_ns_arena_gobreg",
    -- "tr_m7_ns_arena_gobr1eg",
    --BENEATH THE PERMAFROST
    "sch_FVFC1_sc_e1CrMum",
    "sch_FVFC1_sc_e1CrSkel",
    "sch_FVFC2_cr_BSpec2a",
    "sch_FVFC2_cr_BSpec2b",
    "sch_FVFC2_cr_BSpec4",
}


return Constants
