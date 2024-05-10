local computeBoundingBoxes = false -- DO NOT USE THIS SETTING ON YOUR SAVEGAME -- set to true here and in HPBars_g.lua, use tcl to go out of bounds (below the world) and press "f". when it's done, press "h" and copy the console output into computedBoxes {}


local types = require('openmw.types')
local NPC = require('openmw.types').NPC
local core = require('openmw.core')
local storage = require('openmw.storage')
local playerSettings = storage.playerSection('SettingsPlayerHPBars')
local I = require("openmw.interfaces")
local self = require("openmw.self")
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local vfs = require('openmw.vfs')
local modData = storage.globalSection('HPBars')
local KEY = require('openmw.input').KEY
local input = require('openmw.input')
local v2 = util.vector2
local v3 = util.vector3
local boxCache = {}
local makeBorder = require("scripts.makeborder")

-- all vanilla and tamriel rebuilt, bounding boxes for MR too
customHeights = {
["meshes\\r\\Guar.NIF"] 	=	123	,
["meshes\\r\\Bonewalker.NIF"] 	=	118	,
["meshes\\r\\Guar_withpack.NIF"] 	=	143	,
["meshes\\r\\Clannfear.NIF"] 	=	108	,
["meshes\\r\\DuskyAlit.NIF"] 	=	108	,
["meshes\\r\\LeastKagouti.NIF"] 	=	108	,
["meshes\\r\\Dreugh.NIF"] 	=	43	,
["meshes\\r\\Skeleton.NIF"] 	=	122	,
["meshes\\r\\Kwama Worker.NIF"] 	=	73	,
["meshes\\r\\AshGhoul.NIF"] 	=	133	,
["meshes\\r\\AncestorGhost.NIF"] 	=	138	,
["meshes\\r\\Kwama Warior.NIF"] 	=	100	,
["meshes\\r\\AshSlave.NIF"] 	=	124	,
["meshes\\r\\AshZombie.NIF"] 	=	118	,
["meshes\\r\\Netch_Bull.NIF"] 	=	538	,
["meshes\\r\\Netch_Betty.NIF"] 	=	233	,
["meshes\\r\\BoneLord.NIF"] 	=	146	,
["meshes\\r\\Sphere_Centurions.NIF"] 	=	138	,
["meshes\\r\\G_CenturionSpider.NIF"] 	=	55	,
["meshes\\r\\CliffRacer.NIF"] 	=	265	,
["meshes\\r\\Daedroth.NIF"] 	=	113	,
["meshes\\r\\Dremora.NIF"] 	=	124	,
["meshes\\r\\DwarvenSpecter.NIF"] 	=	117	,
["meshes\\r\\Atronach_Fire.NIF"] 	=	146	,
["meshes\\r\\Atronach_Frost.NIF"] 	=	150	,
["meshes\\r\\Kwama Forager.NIF"] 	=	27	,
["meshes\\r\\Lame_Corprus.NIF"] 	=	120	,
["meshes\\r\\Clannfear_Daddy.NIF"] 	=	193, --166	,
["meshes\\r\\Steam_Centurions.NIF"] 	=	125	,
["meshes\\r\\Atronach_Storm.NIF"] 	=	143	,
["meshes\\r\\Rust rat.NIF"] 	=	40	,
["meshes\\r\\Hunger.NIF"] 	=	97	,
["meshes\\r\\AscendedSleeper.NIF"] 	=	132	,
["meshes\\r\\AshVampire.NIF"] 	=	146	,
["meshes\\r\\BYagram.NIF"] 	=	113	,
["meshes\\r\\Golden Saint.NIF"] 	=	129	,
["meshes\\r\\heart_Akulakhan.NIF"] 	=	151	,
["meshes\\r\\Dagothr.NIF"] 	=	159	,
["meshes\\r\\WingedTwilight.NIF"] 	=	128	,
["meshes\\r\\Guar_white.NIF"] 	=	144	,
["meshes\\r\\GreatBonewalker.NIF"] 	=	139	,
["meshes\\r\\LordVivec.NIF"] 	=	126	,
["meshes\\r\\Goblin02.NIF"] 	=	103	,
["meshes\\r\\PackRat.NIF"] 	=	54	,
["meshes\\r\\Goblin03.NIF"] 	=	148	,
["meshes\\r\\Fabricant_Hulking.NIF"] 	=	115	,
["meshes\\r\\Fabricant.NIF"] 	=	108	,
["meshes\\r\\SphereArcher.NIF"] 	=	137	,
["meshes\\r\\Almelexia.NIF"] 	=	141	,
["meshes\\r\\Almelexia_warrior.NIF"] 	=	138	,
["meshes\\r\\BabelFish.NIF"] 	=	18	,
["meshes\\r\\Goblin01.NIF"] 	=	81	,
["meshes\\r\\Liche_King.NIF"] 	=	128	,
["meshes\\r\\Liche.NIF"] 	=	126	,
["meshes\\r\\Durzog_collar.NIF"] 	=	114	,
["meshes\\r\\Durzog.NIF"] 	=	117	,
["meshes\\r\\Fabricant_Imperfect.NIF"] 	=	330	,
["meshes\\r\\cr_draugr.NIF"] 	=	120	,
["meshes\\r\\bear_black_larger.NIF"] 	=	116	,
["meshes\\r\\bear_brown_larger.NIF"] 	=	116	,
["meshes\\r\\IceMinion.NIF"] 	=	72	,
["meshes\\r\\IceMRaider.NIF"] 	=	98	,
["meshes\\r\\Mount.NIF"] 	=	68	,
["meshes\\r\\Horker.NIF"] 	=	42	,
["meshes\\r\\Wolf_Black.NIF"] 	=	62	,
["meshes\\r\\Wolf_red.NIF"] 	=	62	,
["meshes\\r\\FrostGiant.NIF"] 	=	297	,
["meshes\\r\\hircine.NIF"] 	=	240	,
["meshes\\r\\Spriggan.NIF"] 	=	125	,
["meshes\\r\\Horker_larger.NIF"] 	=	63	,
["meshes\\r\\swimmer.NIF"] 	=	75	,
["meshes\\r\\draugrLord.NIF"] 	=	129	,
["meshes\\r\\bear_blond_larger.NIF"] 	=	78	,
["meshes\\r\\UnDeadWolf_2.nif"] 	=	64	,
["meshes\\wolf\\skinNPC.NIF"] 	=	106	,
["meshes\\r\\Wolf_white.NIF"] 	=	83	,
["meshes\\r\\udyrfrykte.NIF"] 	=	128	,
["meshes\\r\\raven.NIF"] 	=	68	,
["meshes\\r\\ice troll.NIF"] 	=	172	,
["meshes\\r\\Hircine_Bear_larger.NIF"] 	=	143	,
["meshes\\r\\HircineWolf.NIF"] 	=	96	,
["meshes\\pc\\cr\\pc_AyleidSorceror.nif"] 	=	198	,
["meshes\\pc\\cr\\pc_ayl_guard_01.nif"] 	=	159	,
["meshes\\pc\\cr\\PC_Minotaur_01.nif"] 	=	219	,
["meshes\\pc\\cr\\pc_minotaur_02.nif"] 	=	234	,
["meshes\\pc\\cr\\pc_spriggan.nif"] 	=	132	,
["meshes\\pc\\cr\\pc_Alphyn.nif"] 	=	111	,
["meshes\\pc\\cr\\pc_bear.nif"] 	=	114	,
["meshes\\pc\\cr\\pc_butterfly_01.nif"] 	=	109	,
["meshes\\pc\\cr\\pc_butterfly_02.nif"] 	=	109	,
["meshes\\pc\\cr\\pc_butterfly_03.nif"] 	=	109	,
["meshes\\pc\\cr\\pc_butterfly_04.nif"] 	=	109	,
["meshes\\pc\\cr\\pc_butterfly_05.nif"] 	=	109	,
["meshes\\pc\\cr\\pc_butterfly_06.nif"] 	=	109	,
["meshes\\pc\\cr\\pc_bull.nif"] 	=	116	,
["meshes\\pc\\cr\\pc_bull_r.nif"] 	=	116	,
["meshes\\pc\\cr\\pc_cow.nif"] 	=	102	,
["meshes\\pc\\cr\\pc_mule.nif"] 	=	129	,
["meshes\\pc\\cr\\pc_packmule_01.nif"] 	=	139	,
["meshes\\pc\\cr\\pc_packmule_02.nif"] 	=	138	,
["meshes\\pc\\cr\\PC_Fish_Chrysoph.nif"] 	=	12	,
["meshes\\pc\\cr\\PC_Fish_Leaper.nif"] 	=	12	,
["meshes\\pc\\cr\\PC_Fish_Longfin.nif"] 	=	12	,
["meshes\\pc\\cr\\pc_slaughterfish.nif"] 	=	48	,
["meshes\\pc\\cr\\PC_Slaughterfish_01.nif"] 	=	25	,
["meshes\\pc\\cr\\PC_Fish_Soldier.nif"] 	=	9	,
["meshes\\pc\\cr\\PC_Fish_Jewel.nif"] 	=	15	,
["meshes\\pc\\cr\\PC_Bullfrog.nif"] 	=	33	,
["meshes\\pc\\cr\\pc_goat_01.nif"] 	=	78	,
["meshes\\pc\\cr\\pc_horse_01.nif"] 	=	150	,
["meshes\\pc\\cr\\pc_horse_02.nif"] 	=	150	,
["meshes\\pc\\cr\\pc_horse_03.nif"] 	=	150	,
["meshes\\pc\\cr\\pc_horsesdl_01.nif"] 	=	156	,
["meshes\\pc\\cr\\pc_horsesdl_02.nif"] 	=	156	,
["meshes\\pc\\cr\\pc_horsesdl_03.nif"] 	=	156	,
["meshes\\pc\\cr\\pc_str_mudcrab.nif"] 	=	48	,
["meshes\\pc\\cr\\pc_moth_01.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_02.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_03.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_04.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_05.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_06.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_01.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_02.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_03.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_04.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_05.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_moth_0h.nif"] 	=	108	,
["meshes\\pc\\cr\\pc_muskrat.nif"] 	=	46	,
["meshes\\pc\\cr\\pc_muskrat_collar.nif"] 	=	46	,
["meshes\\pc\\cr\\pc_Pig_01.nif"] 	=	85	,
["meshes\\pc\\cr\\pc_Pig_02.nif"] 	=	85	,
["meshes\\pc\\cr\\pc_rivernewt_01.nif"] 	=	30	,
["meshes\\pc\\cr\\pc_rivernewt_02.nif"] 	=	30	,
["meshes\\pc\\cr\\pc_tantha.nif"] 	=	43	,
["meshes\\pc\\cr\\pc_wolf.nif"] 	=	66	,
["meshes\\pc\\cr\\pc_whitewolf.nif"] 	=	75	,
["meshes\\pc\\cr\\pc_ghost_01.nif"] 	=	146	,
["meshes\\pc\\cr\\pc_ghost_02.nif"] 	=	146	,
["meshes\\pc\\cr\\pc_MinotaurBarr01.nif"] 	=	177	,
["meshes\\pc\\cr\\PC_Mummy.nif"] 	=	105	,
["meshes\\pc\\cr\\PC_RemanSkel_03.nif"] 	=	133	,
["meshes\\pc\\cr\\PC_RemanSkel_04.nif"] 	=	134	,
["meshes\\pc\\cr\\PC_RemanSkel_01.nif"] 	=	133	,
["meshes\\pc\\cr\\PC_RemanSkel_02.nif"] 	=	133	,
["meshes\\pc\\cr\\pc_skeleton_imp01.nif"] 	=	136	,
["meshes\\pc\\cr\\pc_skeleton_imp02.nif"] 	=	135	,
["meshes\\pc\\cr\\pc_wraith_01.nif"] 	=	145	,
["meshes\\pc\\cr\\pc_wraith_02.nif"] 	=	145	,
["meshes\\pc\\cr\\pc_auroran.nif"] 	=	171	,
["meshes\\tr\\cr\\tr_cr_devourer_01.nif"] 	=	134	,
["meshes\\tr\\cr\\tr_dremora_archer.nif"] 	=	134	,
["meshes\\tr\\cr\\tr_dremora_caster.nif"] 	=	132	,
["meshes\\TR\\cr\\TR_dridrea_VO.NIF"] 	=	156	,
["meshes\\tr\\cr\\tr_vile_dae_c.nif"] 	=	165	,
["meshes\\tr\\cr\\tr_clannfear_lesser.nif"] 	=	111	,
["meshes\\tr\\cr\\tr_storm_tyrant.nif"] 	=	228	,
["meshes\\tr\\cr\\tr_cr_seducer_01.nif"] 	=	131	,
["meshes\\tr\\cr\\tr_cr_seducerdark_01.nif"] 	=	267	,
["meshes\\tr\\cr\\tr_cr_seducerdark_02.nif"] 	=	131	,
["meshes\\TR\\cr\\TR_vermai.nif"] 	=	135	,
["meshes\\tr\\cr\\tr_xivilai.nif"] 	=	132	,
["meshes\\TR\\cr\\TR_Dwemer.nif"] 	=	113	,
["meshes\\tr\\cr\\tr_dwe_colos_01.nif"] 	=	342	,
["meshes\\tr\\cr\\tr_dwe_specter_f.nif"] 	=	127	,
["meshes\\EPoS\\cr\\epos_r_alfiq_01.NIF"] 	=	33	,
["meshes\\tr\\cr\\tr_DreughQueen01.nif"] 	=	166	,
["meshes\\TR\\cr\\TR_golem_mud_VO.NIF"] 	=	134	,
["meshes\\tr\\cr\\tr_Gremlin_01.nif"] 	=	66	,
["meshes\\tr\\cr\\tr_Gremlin_02.nif"] 	=	66	,
["meshes\\tr\\cr\\tr_Gremlin_03.nif"] 	=	66	,
["meshes\\tr\\cr\\tr_Gremlin_04.nif"] 	=	66	,
["meshes\\tr\\cr\\tr_Kobold_01.nif"] 	=	126	,
["meshes\\pc\\cr\\pc_lamia.nif"] 	=	78	,
["meshes\\tr\\cr\\tr_LandDreugh.nif"] 	=	106	,
["meshes\\pc\\cr\\PC_Sload_01.nif"] 	=	192	,
["meshes\\tr\\cr\\tr_troll_armor_01.nif"] 	=	146	,
["meshes\\tr\\cr\\tr_troll_armor_02.nif"] 	=	146	,
["meshes\\tr\\cr\\tr_troll_armor_03.nif"] 	=	146	,
["meshes\\tr\\cr\\tr_troll_armor_04.nif"] 	=	147	,
["meshes\\tr\\cr\\TR_troll_cave01.nif"] 	=	136	,
["meshes\\tr\\cr\\TR_troll_cave02.nif"] 	=	136	,
["meshes\\tr\\cr\\TR_troll_cave03.nif"] 	=	136	,
["meshes\\tr\\cr\\TR_troll_cave04.nif"] 	=	136	,
["meshes\\tr\\cr\\TR_troll_frost01.nif"] 	=	136	,
["meshes\\tr\\cr\\TR_troll_frost02.nif"] 	=	136	,
["meshes\\tr\\cr\\TR_troll_frost03.nif"] 	=	136	,
["meshes\\tr\\cr\\TR_troll_frost04.nif"] 	=	136	,
["meshes\\Sky\\r\\Sky_Wereboar_01.nif"] 	=	123	,
["meshes\\Sky\\r\\Sky_Werewolf_01.nif"] 	=	105	,
["meshes\\pc\\cr\\pc_Bat_01.nif"] 	=	162	,
["meshes\\TR\\cr\\TR_LE_g_but_tiny.NIF"] 	=	76	,
["meshes\\TR\\cr\\TR_LE_g_but_small.NIF"] 	=	120	,
["meshes\\TR\\cr\\TR_LE_g_but_micro.NIF"] 	=	62	,
["meshes\\TR\\cr\\TR_LE_p_but_tiny.NIF"] 	=	76	,
["meshes\\TR\\cr\\TR_LE_p_but_small.NIF"] 	=	123	,
["meshes\\TR\\cr\\TR_LE_p_but_micro.NIF"] 	=	60	,
["meshes\\TR\\cr\\TR_LE_r_but_tiny.NIF"] 	=	72	,
["meshes\\TR\\cr\\TR_LE_r_but_small.NIF"] 	=	123	,
["meshes\\TR\\cr\\TR_LE_r_but_micro.NIF"] 	=	60	,
["meshes\\Sky\\r\\Sky_Farm_Chicken_01.NIF"] 	=	45	,
["meshes\\Sky\\r\\Sky_Farm_Chicken_02.NIF"] 	=	45	,
["meshes\\Sky\\r\\Sky_Farm_Chicken_03.NIF"] 	=	46	,
["meshes\\Sky\\r\\Sky_Farm_Chicken_04.NIF"] 	=	51	,
["meshes\\Sky\\r\\Sky_Farm_Chicken_05.NIF"] 	=	51	,
["meshes\\Sky\\r\\Sky_Farm_Rooster_01.NIF"] 	=	50	,
["meshes\\Sky\\r\\Sky_Farm_Rooster_02.NIF"] 	=	50	,
["meshes\\sky\\r\\sky_deer01.nif"] 	=	104	,
["meshes\\sky\\r\\sky_deer02.nif"] 	=	91	,
["meshes\\tr\\cr\\tr_sturgeon.nif"] 	=	22	,
["meshes\\tr\\cr\\tr_sturgeon_anc.nif"] 	=	41	,
["meshes\\tr\\cr\\tr_horker_brown_01.nif"] 	=	32	,
["meshes\\tr\\cr\\tr_horker_brown_02.nif"] 	=	60	,
["meshes\\tr\\cr\\tr_horker_brown_03.nif"] 	=	105	,
["meshes\\tr\\cr\\tr_horker_grey_01.nif"] 	=	32	,
["meshes\\tr\\cr\\tr_horker_grey_02.nif"] 	=	60	,
["meshes\\tr\\cr\\tr_horker_grey_03.nif"] 	=	96	,
["meshes\\tr\\cr\\tr_horker_white_01.nif"] 	=	34	,
["meshes\\tr\\cr\\tr_horker_white_02.nif"] 	=	96	,
["meshes\\sky\\r\\sky_spider_01.nif"] 	=	45	,
["meshes\\TR\\cr\\TR_mouse02_YA.nif"] 	=	47	,
["meshes\\tr\\cr\\tr_rat_col_01.nif"] 	=	53	,
["meshes\\tr\\cr\\tr_rat_col_02.nif"] 	=	53	,
["meshes\\TR\\cr\\TR_mouse00_YA.nif"] 	=	53	,
["meshes\\TR\\cr\\TR_mouse01_YA.nif"] 	=	44	,
["meshes\\TR\\cr\\tr_seacrab.nif"] 	=	33	,
["meshes\\sky\\r\\sky_squirrel_01.nif"] 	=	30	,
["meshes\\sky\\r\\sky_squirrel_02.nif"] 	=	30	,
["meshes\\TR\\cr\\TR_liche_greater.nif"] 	=	131	,
["meshes\\tr\\cr\\tr_skeleton_arg_01.nif"] 	=	126	,
["meshes\\tr\\cr\\tr_skeleton_arg_02.nif"] 	=	125	,
["meshes\\tr\\cr\\tr_skeleton_arg_03.nif"] 	=	125	,
["meshes\\tr\\cr\\tr_skeleton_arise01.nif"] 	=	131	,
["meshes\\tr\\cr\\tr_skeleton_arise02.nif"] 	=	131	,
["meshes\\tr\\cr\\tr_skeleton_arise03.nif"] 	=	129	,
["meshes\\tr\\cr\\tr_skeleton_arise04.nif"] 	=	134	,
["meshes\\tr\\cr\\tr_skeleton_khajiit.nif"] 	=	125	,
["meshes\\TR\\cr\\TR_Skeleton_Orc.nif"] 	=	138	,
["meshes\\Sky\\r\\Sky_Goat_01.nif"] 	=	76	,
["meshes\\Sky\\r\\Sky_Goat_02.nif"] 	=	76	,
["meshes\\Sky\\r\\Sky_Spikeworm_01.nif"] 	=	54	,
["meshes\\Sky\\r\\Sky_Wormmouth_01.nif"] 	=	140	,
["meshes\\TR\\cr\\TR_GoblinShaman.nif"] 	=	92	,
["meshes\\Sky\\r\\Sky_GoblinThr_01.nif"] 	=	82	,
["meshes\\tr\\cr\\tr_direkagouti.nif"] 	=	189	,
["meshes\\TR\\cr\\TR_beetle_G02_VO.NIF"] 	=	41	,
["meshes\\TR\\cr\\TR_beetle_G01_VO.NIF"] 	=	41	,
["meshes\\TR\\cr\\TR_beetle_G03_VO.NIF"] 	=	41	,
["meshes\\TR\\cr\\TR_beetle_G04_VO.NIF"] 	=	41	,
["meshes\\tr\\cr\\tr_blindfish_01.nif"] 	=	47	,
["meshes\\TR\\cr\\TR_cephalopod_VO.NIF"] 	=	-9	,
["meshes\\TR\\cr\\TR_eyestar_VO.NIF"] 	=	18	,
["meshes\\TR\\cr\\TR_barfish_1a.NIF"] 	=	3	,
["meshes\\TR\\cr\\TR_barfish_1b.NIF"] 	=	3	,
["meshes\\TR\\cr\\TR_barfish_1c.NIF"] 	=	3	,
["meshes\\TR\\cr\\TR_barfish_2a.NIF"] 	=	4	,
["meshes\\TR\\cr\\TR_barfish_2b.NIF"] 	=	4	,
["meshes\\TR\\cr\\TR_barfish_2c.NIF"] 	=	4	,
["meshes\\TR\\cr\\TR_barfish_3a.NIF"] 	=	4	,
["meshes\\TR\\cr\\TR_barfish_3b.NIF"] 	=	4	,
["meshes\\TR\\cr\\TR_barfish_3c.NIF"] 	=	4	,
["meshes\\TR\\cr\\Guar_withharness.nif"] 	=	143	,
["meshes\\TR\\cr\\TR_hoom.nif"] 	=	146	,
["meshes\\tr\\cr\\tr_juvriverstrider.nif"] 	=	81	,
["meshes\\TR\\cr\\TR_molecrab_VO.NIF"] 	=	44	,
["meshes\\tr\\cr\\tr_cr_moth_01.nif"] 	=	109	,
["meshes\\tr\\cr\\tr_cr_moth_02.nif"] 	=	109	,
["meshes\\tr\\cr\\tr_cr_moth_03.nif"] 	=	109	,
["meshes\\TR\\cr\\TR_muckleech_VO.NIF"] 	=	34	,
["meshes\\TR\\cr\\TR_swampfly_VO.NIF"] 	=	42	,
["meshes\\TR\\cr\\TR_nixmount.nif"] 	=	110	,
["meshes\\TR\\cr\\TR_ornada_VO.NIF"] 	=	30	,
["meshes\\TR\\cr\\TR_ornada_clutch_VO.NIF"] 	=	30	,
["meshes\\TR\\cr\\TR_parastylus_VO.NIF"] 	=	75	,
["meshes\\TR\\cr\\TR_Plainstrider_VO.NIF"] 	=	333	,
["meshes\\tr\\cr\\tr_cr_redoranhound_01.nif"] 	=	60	,
["meshes\\tr\\cr\\tr_cr_redoranhound_02.nif"] 	=	60	,
["meshes\\tr\\cr\\tr_cr_redoranhound_03.nif"] 	=	60	,
["meshes\\tr\\cr\\tr_cr_redoranhound_04.nif"] 	=	60	,
["meshes\\tr\\cr\\tr_cr_redoranhound_05.nif"] 	=	60	,
["meshes\\tr\\cr\\tr_cr_redoranhound_06.nif"] 	=	60	,
["meshes\\tr\\cr\\tr_SharaiHopper_01.nif"] 	=	101	,
["meshes\\tr\\cr\\tr_skyrender.NIF"] 	=	207	,
["meshes\\TR\\cr\\tr_skyrenderM.NIF"] 	=	222	,
["meshes\\tr\\cr\\tr_SkyLamp_01.nif"] 	=	585	,
["meshes\\tr\\cr\\tr_SkyLamp_02.nif"] 	=	585	,
["meshes\\tr\\cr\\tr_SkyLamp_03.nif"] 	=	585	,
["meshes\\TR\\cr\\TR_siltstrider_VO.NIF"] 	=	1338	,
["meshes\\tr\\cr\\tr_cr_tguar.nif"] 	=	192	,
["meshes\\TR\\cr\\tr_swamp_troll.nif"] 	=	165	,
["meshes\\TR\\cr\\TR_tully_VO.NIF"] 	=	39	,
["meshes\\TR\\cr\\TR_tully_calf_VO.NIF"] 	=	24	,
["meshes\\TR\\cr\\TR_Velk.nif"] 	=	145	,
["meshes\\tr\\cr\\tr_yethbug.nif"] 	=	113	,
["meshes\\TR\\cr\\TR_ancestorghostwpn.nif"] 	=	146	,
["meshes\\tr\\cr\\tr_cr_bonelord_grt_01.nif"] 	=	203	,
["meshes\\TR\\cr\\TR_mummy_VO.NIF"] 	=	123	,
["meshes\\tr\\cr\\tr_mummy_02.nif"] 	=	119	,
["meshes\\TR\\cr\\tr_mummy_02.nif"] 	=	119	,
["meshes\\tr\\cr\\tr_ProceBoneWalker_01.nif"] 	=	155	,
["meshes\\tr\\cr\\tr_RevBonewalker_01.nif"] 	=	166	,
["meshes\\tr\\cr\\tr_cr_ushudimmu_01.nif"] 	=	118	,
["meshes\\sky\\r\\Sky_Giant.nif"] 	=	330	,
["meshes\\Sky\\r\\Sky_Hagraven_01.nif"] 	=	126	,
["meshes\\Sky\\r\\Sky_Ice Wraith_01.nif"] 	=	139	,
["meshes\\Sky\\r\\Sky_Minotaur_01.nif"] 	=	213	,
["meshes\\Sky\\r\\Sky_DN_Bear_Black_01.nif"] 	=	78	,
["meshes\\Sky\\r\\Sky_Bear_Grey_01.nif"] 	=	116	,
["meshes\\sky\\r\\Sky_Boar_01.nif"] 	=	57	,
["meshes\\sky\\r\\sky_butterfly_01.nif"] 	=	111	,
["meshes\\sky\\r\\sky_butterfly_02.nif"] 	=	111	,
["meshes\\sky\\r\\sky_butterfly_03.nif"] 	=	111	,
["meshes\\sky\\r\\sky_butterfly_04.nif"] 	=	111	,
["meshes\\Sky\\r\\sky_bull_01.nif"] 	=	114	,
["meshes\\Sky\\r\\sky_bull_02.nif"] 	=	114	,
["meshes\\Sky\\r\\Sky_Cow_01.nif"] 	=	101	,
["meshes\\Sky\\r\\Sky_Cow_02.nif"] 	=	101	,
["meshes\\Sky\\r\\Sky_Cow_03.nif"] 	=	101	,
["meshes\\sky\\r\\sky_danswyrm.nif"] 	=	15	,
["meshes\\sky\\r\\sky_elk_01.nif"] 	=	132	,
["meshes\\sky\\r\\sky_elk_02.nif"] 	=	132	,
["meshes\\sky\\r\\sky_elk_04.nif"] 	=	132	,
["meshes\\sky\\r\\sky_elk_05.nif"] 	=	132	,
["meshes\\sky\\r\\sky_elk_03.nif"] 	=	132	,
["meshes\\Sky\\r\\Sky_Browntrout_01.NIF"] 	=	36	,
["meshes\\Sky\\r\\sky_FishCod_01.nif"] 	=	36	,
["meshes\\Sky\\r\\Sky_Northernpike_01.NIF"] 	=	36	,
["meshes\\Sky\\r\\Sky_Pikeperch_01.NIF"] 	=	36	,
["meshes\\Sky\\r\\Sky_Pinksalmon_01.NIF"] 	=	36	,
["meshes\\Sky\\r\\Sky_Goat_03.nif"] 	=	77	,
["meshes\\Sky\\r\\Sky_horse_01.nif"] 	=	144	,
["meshes\\Sky\\r\\Sky_horse_03.nif"] 	=	144	,
["meshes\\Sky\\r\\Sky_horse_05.nif"] 	=	144	,
["meshes\\Sky\\r\\Sky_horse_07.nif"] 	=	144	,
["meshes\\Sky\\r\\Sky_horse_02.nif"] 	=	148	,
["meshes\\Sky\\r\\Sky_horse_04.nif"] 	=	148	,
["meshes\\Sky\\r\\Sky_horse_06.nif"] 	=	148	,
["meshes\\Sky\\r\\Sky_horse_08.nif"] 	=	148	,
["meshes\\sky\\r\\sky_irontoad.nif"] 	=	56	,
["meshes\\Sky\\r\\Sky_Mammoth_01.nif"] 	=	372	,
["meshes\\sky\\r\\sky_moth_01.nif"] 	=	111	,
["meshes\\sky\\r\\sky_moth_02.nif"] 	=	111	,
["meshes\\sky\\r\\sky_moth_03.nif"] 	=	108	,
["meshes\\Sky\\r\\Sky_Raki_01.nif"] 	=	84	,
["meshes\\Sky\\r\\Sky_Sabre_Cat_01.nif"] 	=	107	,
["meshes\\Sky\\r\\Sky_Sabre_Cat_02.nif"] 	=	107	,
["meshes\\sky\\r\\sky_snowray_01.nif"] 	=	111	,
["meshes\\Sky\\r\\sky_wolf_grey.nif"] 	=	63	,
["meshes\\sky\\r\\sky_KoglingAdult.nif"] 	=	144	,
["meshes\\sky\\r\\sky_KoglingBud.nif"] 	=	32	,
["meshes\\sky\\r\\sky_KoglingElder.nif"] 	=	177	,
["meshes\\sky\\r\\Sky_Draugr_Axeman.nif"] 	=	144	,
["meshes\\sky\\r\\Sky_DraugrLord.nif"] 	=	151	,
["meshes\\Sky\\r\\Sky_Lich_Frost_01.nif"] 	=	148	,
["meshes\\Sky\\r\\Sky_Lich_Frost_02.nif"] 	=	147	,
["meshes\\Sky\\r\\Sky_Lich_Frost_03.nif"] 	=	149	,
["meshes\\Sky\\r\\Sky_Lich_Frost_04.nif"] 	=	150	,
["meshes\\Sky\\r\\Sky_Skeleton_Crip_01.nif"] 	=	131	,
["meshes\\pc\\cr\\pc_tsaesci_01.nif"] 	=	186	,
["meshes\\pc\\cr\\pc_tsaesci_02.nif"] 	=	183	,
["meshes\\r\\Dreugh.nif"] 	=	50	,
["meshes\\TR\\cr\\TR_dres_bug_mtd_VO.NIF"] 	=	378	,
["meshes\\r\\dreugh.nif"] 	=	50	,
["meshes\\tr\\cr\\tr_mouse02_ya.nif"] 	=	33	,
["meshes\\TR\\cr\\tr_velk.nif"] 	=	117	,
["meshes\\r\\duskyalit.nif"] 	=	138	,
["meshes\\r\\Fabricant_Hulking.nif"] 	=	201	,
["meshes\\r\\WingedTwilight.nif"] 	=	222	,
["meshes\\r\\CaveMudcrab.NIF"] 	=	69	,
["meshes\\r\\Scamp_Fetch.NIF"] 	=	87	,
["meshes\\r\\MineScrib.NIF"] 	=	33	,
["meshes\\r\\SlaughterFish.NIF"] 	=	38	,
["meshes\\r\\NixHound.NIF"] 	=	87	,
["meshes\\r\\Kwama Queen.NIF"] 	=	108	,
["meshes\\r\\Shalk.NIF"] 	=	46	,
["meshes\\r\\CliffRacer.NIF"] 	=	268	,
["meshes\\r\\Corprus_Stalker.NIF"] 	=	120	,


}


-- center + full sizes
computedBoxes = {
["meshes\\r\\Golden Saint.NIF"] = {v3(-0, -0, 63.1748046875), v3(55.6318359375, 54.1123046875, 126.349609375)},
["meshes\\r\\heart_Akulakhan.NIF"] = {v3(12.876953125, 4.2548828125, 63.126953125), v3(80.0126953125, 73.3916015625, 126.673828125)},
["meshes\\r\\Dagothr.NIF"] = {v3(-0, -0, 93.5888671875), v3(58.5595703125, 56.9599609375, 186.369140625)},
["meshes\\r\\WingedTwilight.NIF"] = {v3(-0.15478515625, 11.56884765625, 66.1513671875), v3(58.5595703125, 71.3603515625, 133)},
["meshes\\r\\Guar_white.NIF"] = {v3(-0, 40.50927734375, 79.755859375), v3(98.7158203125, 239.57421875, 159.859375)},
["meshes\\r\\GreatBonewalker.NIF"] = {v3(-1.27490234375, 6.03173828125, 71.9130859375), v3(107.662109375, 82.4716796875, 144.173828125)},
["meshes\\r\\LordVivec.NIF"] = {v3(-0, -0, 63.1748046875), v3(30.400390625, 30.400390625, 126.349609375)},
["meshes\\r\\Goblin02.NIF"] = {v3(-0, -0, 54.337890625), v3(87.34765625, 80.0927734375, 109.373046875)},
["meshes\\r\\PackRat.NIF"] = {v3(-0, -0, 29.6513671875), v3(44.232421875, 119.6025390625, 59.302734375)},
["meshes\\r\\Goblin03.NIF"] = {v3(-0, -0, 82.0302734375), v3(131.021484375, 120.1396484375, 164.060546875)},
["meshes\\r\\Fabricant_Hulking.NIF"] = {v3(-0, -0, 59.0859375), v3(148.8076171875, 177.9443359375, 118.171875)},
["meshes\\r\\Fabricant.NIF"] = {v3(-1.46044921875, 4.993896484375, 53.462890625), v3(46.9052734375, 118.33935546875, 106.92578125)},
["meshes\\r\\SphereArcher.NIF"] = {v3(-0.5576171875, 1.1396484375, 78.1064453125), v3(107.9833984375, 94.8115234375, 156.212890625)},
["meshes\\r\\Almelexia.NIF"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\Almelexia_warrior.NIF"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\BabelFish.NIF"] = {v3(-0.27587890625, -7.3740234375, 3.8525390625), v3(38.5830078125, 83.041015625, 42.677734375)},
["meshes\\r\\Goblin01.NIF"] = {v3(-0, -0, 42.12109375), v3(55.494140625, 61.2958984375, 84.2421875)},
["meshes\\r\\Liche_King.NIF"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\Liche.NIF"] = {v3(-0, -0, 63.1748046875), v3(55.6318359375, 54.1123046875, 126.349609375)},
["meshes\\r\\Durzog_collar.NIF"] = {v3(-0, -0, 56.109375), v3(84.26171875, 162.853515625, 112.0859375)},
["meshes\\r\\Durzog.NIF"] = {v3(-0, -0, 56.109375), v3(96.673828125, 174.599609375, 112.0859375)},
["meshes\\r\\Fabricant_Imperfect.NIF"] = {v3(0.3408203125, 0.3408203125, 135.0146484375), v3(199.0947265625, 200.4580078125, 270.029296875)},
["meshes\\r\\cr_draugr.NIF"] = {v3(-1.950927734375, 24.2421875, 76.7841796875), v3(86.65185546875, 117.5068359375, 153.568359375)},
["meshes\\r\\bear_black_larger.NIF"] = {v3(-0, -0, 102.8916015625), v3(170.2490234375, 262.9599609375, 205.783203125)},
["meshes\\r\\bear_brown_larger.NIF"] = {v3(-0, -0, 102.8916015625), v3(148.7587890625, 239.3974609375, 205.783203125)},
["meshes\\r\\IceMinion.NIF"] = {v3(-0, -0, 35.6962890625), v3(45, 45, 72.08984375)},
["meshes\\r\\IceMRaider.NIF"] = {v3(-0, -0, 38.111328125), v3(94.794921875, 135.2978515625, 76.22265625)},
["meshes\\r\\Mount.NIF"] = {v3(-0, -0, 38.111328125), v3(74.69921875, 131.5224609375, 76.22265625)},
["meshes\\r\\Horker.NIF"] = {v3(-0.05517578125, -12.25732421875, 23.427734375), v3(113.552734375, 142.7216796875, 47.552734375)},
["meshes\\r\\Wolf_Black.NIF"] = {v3(-0, -0, 37.689453125), v3(59.583984375, 140.283203125, 75.7265625)},
["meshes\\r\\Wolf_red.NIF"] = {v3(-0, -0, 42.0703125), v3(40.8310546875, 150.5126953125, 84.140625)},
["meshes\\r\\FrostGiant.NIF"] = {v3(-0, -2.9765625, 130.265625), v3(134.712890625, 257.2265625, 263.810546875)},
["meshes\\r\\hircine.NIF"] = {v3(-0, -3.720703125, 98.1337890625), v3(100.25, 228.458984375, 196.375)},
["meshes\\r\\Spriggan.NIF"] = {v3(-0, -0, 67.587890625), v3(61.115234375, 121.2392578125, 135.17578125)},
["meshes\\r\\Horker_larger.NIF"] = {v3(-0.1240234375, -27.5791015625, 53.49609375), v3(255.4931640625, 321.123046875, 106.9921875)},
["meshes\\r\\swimmer.NIF"] = {v3(-0.1376953125, -30.6435546875, 107.4375), v3(352.0126953125, 442.435546875, 215.22265625)},
["meshes\\r\\draugrLord.NIF"] = {v3(0.94091796875, 24.6494140625, 76.7841796875), v3(70.4150390625, 104.4716796875, 153.568359375)},
["meshes\\r\\bear_blond_larger.NIF"] = {v3(-0, -0, 68.5947265625), v3(99.1728515625, 159.5986328125, 137.189453125)},
["meshes\\r\\UnDeadWolf_2.nif"] = {v3(-0, -0, 42.0703125), v3(40.8310546875, 150.5126953125, 84.140625)},
["meshes\\wolf\\skinNPC.NIF"] = {v3(-0, 6.78515625, 65.9775390625), v3(58.5595703125, 70.5302734375, 133)},
["meshes\\r\\Wolf_white.NIF"] = {v3(-0, -0, 58.8974609375), v3(57.1630859375, 210.7177734375, 117.794921875)},
["meshes\\r\\udyrfrykte.NIF"] = {v3(-0, -8.68701171875, 62.005859375), v3(118.703125, 192.8740234375, 124.708984375)},
["meshes\\r\\Guar.NIF"] = {v3(-0, 31.74560546875, 63.76953125), v3(78.97265625, 191.66015625, 127.88671875)},
["meshes\\r\\Bonewalker.NIF"] = {v3(-0, 11.39501953125, 73.8017578125), v3(50.099609375, 39.0341796875, 147.603515625)},
["meshes\\r\\Guar_withpack.NIF"] = {v3(-0, 36.29443359375, 71.9365234375), v3(88.84375, 215.6171875, 143.873046875)},
["meshes\\r\\Clannfear.NIF"] = {v3(-0, -0, 59.5302734375), v3(76.171875, 144.0791015625, 119.060546875)},
["meshes\\r\\DuskyAlit.NIF"] = {v3(-0, -0, 49.880859375), v3(89.89453125, 135.478515625, 100.109375)},
["meshes\\r\\LeastKagouti.NIF"] = {v3(-0, -0, 55.9501953125), v3(90.421875, 165.578125, 111.900390625)},
["meshes\\pc\\cr\\PC_Minotaur_01.nif"] = {v3(-0.26123046875, 0.50390625, 105.615234375), v3(114.54296875, 87.1748046875, 211.23046875)},
["meshes\\pc\\cr\\pc_minotaur_02.nif"] = {v3(-0.3974609375, 0.566650390625, 116.1767578125), v3(143.30859375, 116.07568359375, 232.353515625)},
["meshes\\pc\\cr\\pc_spriggan.nif"] = {v3(-0, -0, 67.587890625), v3(37.255859375, 115.72265625, 135.17578125)},
["meshes\\pc\\cr\\pc_Alphyn.nif"] = {v3(-0, 9.709716796875, 77.05078125), v3(176.333984375, 258.74658203125, 154.845703125)},
["meshes\\pc\\cr\\pc_bear.nif"] = {v3(-0, -0, 102.8916015625), v3(148.7587890625, 239.3974609375, 205.783203125)},
["meshes\\pc\\cr\\pc_butterfly_01.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_butterfly_02.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_butterfly_03.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_butterfly_04.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_butterfly_05.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_butterfly_06.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_bull.nif"] = {v3(-0, 22.39990234375, 56), v3(67.2001953125, 190.400390625, 112)},
["meshes\\pc\\cr\\pc_bull_r.nif"] = {v3(-0, 22.39990234375, 55.826171875), v3(67.2001953125, 190.400390625, 112)},
["meshes\\pc\\cr\\pc_cow.nif"] = {v3(-0, 20, 50), v3(60, 170, 100)},
["meshes\\pc\\cr\\pc_mule.nif"] = {v3(-0, 10.48291015625, 59.900390625), v3(55, 176, 117)},
["meshes\\pc\\cr\\pc_packmule_01.nif"] = {v3(-0, 10.48291015625, 60.07421875), v3(55, 176, 117)},
["meshes\\pc\\cr\\pc_packmule_02.nif"] = {v3(-0, 10.48291015625, 59.900390625), v3(55, 176, 117)},
["meshes\\pc\\cr\\PC_Fish_Chrysoph.nif"] = {v3(-0, 3.35546875, -0.802734375), v3(4.716796875, 32.599609375, 10.330078125)},
["meshes\\pc\\cr\\PC_Fish_Leaper.nif"] = {v3(-0, 3.35546875, 0.65234375), v3(4.716796875, 32.599609375, 10.330078125)},
["meshes\\pc\\cr\\PC_Fish_Longfin.nif"] = {v3(-0, -1.27978515625, -0), v3(12.7998046875, 51.2001953125, 21.759765625)},
["meshes\\pc\\cr\\pc_slaughterfish.nif"] = {v3(-0, -7.96826171875, 22.220703125), v3(77.6611328125, 212.271484375, 44.412109375)},
["meshes\\pc\\cr\\PC_Slaughterfish_01.nif"] = {v3(-0.27587890625, 0.81396484375, -53.3916015625), v3(38.5830078125, 83.041015625, 42.677734375)},
["meshes\\pc\\cr\\PC_Fish_Soldier.nif"] = {v3(-0, 3.35546875, 0.65234375), v3(4.716796875, 32.599609375, 10.330078125)},
["meshes\\pc\\cr\\PC_Fish_Jewel.nif"] = {v3(-0, 3.35546875, 0.65234375), v3(4.716796875, 32.599609375, 10.330078125)},
["meshes\\pc\\cr\\PC_Bullfrog.nif"] = {v3(-0, 10, -18.2880859375), v3(75.6416015625, 80, 102.736328125)},
["meshes\\pc\\cr\\pc_goat_01.nif"] = {v3(0.00146484375, 0.39404296875, 42.0576171875), v3(44.73046875, 120.2294921875, 84.041015625)},
["meshes\\pc\\cr\\pc_horse_01.nif"] = {v3(-0, 23.76220703125, 90.2958984375), v3(64, 220.7177734375, 178.6875)},
["meshes\\pc\\cr\\pc_horse_02.nif"] = {v3(-0, 23.76220703125, 90.2958984375), v3(64, 220.7177734375, 178.6875)},
["meshes\\pc\\cr\\pc_horse_03.nif"] = {v3(-0, 23.76220703125, 90.2958984375), v3(64, 220.7177734375, 178.6875)},
["meshes\\pc\\cr\\pc_horsesdl_01.nif"] = {v3(-0, 23.76220703125, 90.2958984375), v3(64, 220.7177734375, 178.6875)},
["meshes\\pc\\cr\\pc_horsesdl_02.nif"] = {v3(-0, 23.76220703125, 90.2958984375), v3(64, 220.7177734375, 178.6875)},
["meshes\\pc\\cr\\pc_horsesdl_03.nif"] = {v3(-0, 23.76220703125, 90.1220703125), v3(64, 220.7177734375, 178.6875)},
["meshes\\pc\\cr\\pc_str_mudcrab.nif"] = {v3(-0, 17.94482421875, 21.8837890625), v3(63.7373046875, 64.30859375, 51.583984375)},
["meshes\\pc\\cr\\pc_moth_01.nif"] = {v3(-0.125, 0.41162109375, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_moth_02.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_moth_03.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\tr\\cr\\tr_cr_redoranhound_01.nif"] = {v3(-0, -0, 33.6259765625), v3(59.0830078125, 123.6298828125, 67.251953125)},
["meshes\\tr\\cr\\tr_cr_redoranhound_02.nif"] = {v3(-0, -0, 33.6259765625), v3(37.8076171875, 118.1806640625, 67.251953125)},
["meshes\\tr\\cr\\tr_cr_redoranhound_03.nif"] = {v3(-0, -0, 33.6259765625), v3(37.8076171875, 118.1806640625, 67.251953125)},
["meshes\\tr\\cr\\tr_cr_redoranhound_04.nif"] = {v3(-0, -0, 33.6259765625), v3(37.8076171875, 118.1806640625, 67.251953125)},
["meshes\\tr\\cr\\tr_cr_redoranhound_05.nif"] = {v3(-0, -0, 33.6259765625), v3(37.8076171875, 118.1806640625, 67.251953125)},
["meshes\\tr\\cr\\tr_cr_redoranhound_06.nif"] = {v3(-0, -0, 33.6259765625), v3(37.8076171875, 118.1806640625, 67.251953125)},
["meshes\\tr\\cr\\tr_SharaiHopper_01.nif"] = {v3(-0, 9.296875, 50.3583984375), v3(53.3720703125, 144.697265625, 101.8203125)},
["meshes\\tr\\cr\\tr_skyrender.NIF"] = {v3(-2.81884765625, -1.4091796875, 116.2880859375), v3(47.43359375, 212.1318359375, 67.9375)},
["meshes\\TR\\cr\\tr_skyrenderM.NIF"] = {v3(-2.81884765625, -1.4091796875, 116.2880859375), v3(47.43359375, 212.1318359375, 67.9375)},
["meshes\\tr\\cr\\tr_SkyLamp_01.nif"] = {v3(-0, -0, 322.998046875), v3(264.5166015625, 398.69921875, 575.91796875)},
["meshes\\tr\\cr\\tr_SkyLamp_02.nif"] = {v3(-0, -0, 322.998046875), v3(264.5166015625, 398.69921875, 575.91796875)},
["meshes\\tr\\cr\\tr_SkyLamp_03.nif"] = {v3(-0, -0, 322.998046875), v3(264.5166015625, 398.69921875, 575.91796875)},
["meshes\\TR\\cr\\TR_siltstrider_VO.NIF"] = {v3(-1.337890625, 2.876953125, 680.0625), v3(627.1806640625, 1381.4912109375, 1284.2890625)},
["meshes\\tr\\cr\\tr_cr_tguar.nif"] = {v3(-0.000244140625, 43.96337890625, 91.9189453125), v3(159.62353515625, 334.396484375, 183.837890625)},
["meshes\\TR\\cr\\tr_swamp_troll.nif"] = {v3(-0, 8.2802734375, 80.5908203125), v3(107.595703125, 163.857421875, 161.458984375)},
["meshes\\TR\\cr\\TR_tully_VO.NIF"] = {v3(-0.3955078125, -35.119140625, 1.1513671875), v3(41.412109375, 242.302734375, 52.865234375)},
["meshes\\TR\\cr\\TR_tully_calf_VO.NIF"] = {v3(0.2353515625, 6.0283203125, 1.1513671875), v3(40.1494140625, 103.111328125, 45.927734375)},
["meshes\\TR\\cr\\TR_Velk.nif"] = {v3(0.001953125, 24.1328125, 76.611328125), v3(73.701171875, 190.3505859375, 152.9140625)},
["meshes\\tr\\cr\\tr_yethbug.nif"] = {v3(-0, -0, 100), v3(32, 32, 64)},
["meshes\\TR\\cr\\TR_ancestorghostwpn.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_cr_bonelord_grt_01.nif"] = {v3(-0.0107421875, -0, 99.9150390625), v3(62.548828125, 47.9892578125, 200.177734375)},
["meshes\\TR\\cr\\TR_mummy_VO.NIF"] = {v3(1.98388671875, -7.35302734375, 63.49609375), v3(30.9169921875, 32.41796875, 126.046875)},
["meshes\\tr\\cr\\tr_mummy_02.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\TR\\cr\\tr_mummy_02.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_ProceBoneWalker_01.nif"] = {v3(-31.28759765625, -18.59228515625, -0.2265625), v3(0.001953125, 0.001953125, 0.001953125)},
["meshes\\tr\\cr\\tr_RevBonewalker_01.nif"] = {v3(-0, 6.48291015625, 93.23046875), v3(92.9072265625, 63.0625, 182.2890625)},
["meshes\\tr\\cr\\tr_cr_ushudimmu_01.nif"] = {v3(-0, 14.849609375, 49.4794921875), v3(53.5673828125, 50.337890625, 99.1640625)},
["meshes\\sky\\r\\Sky_Giant.nif"] = {v3(-0, -0, 160), v3(93.013671875, 93.013671875, 320.18359375)},
["meshes\\Sky\\r\\Sky_Hagraven_01.nif"] = {v3(-1.16064453125, 16.24658203125, 64.3251953125), v3(71.994140625, 72.02734375, 130.287109375)},
["meshes\\Sky\\r\\Sky_Ice Wraith_01.nif"] = {v3(-0, -52.50830078125, 70.806640625), v3(83.5244140625, 153.4228515625, 172.5859375)},
["meshes\\Sky\\r\\Sky_Minotaur_01.nif"] = {v3(-0.26123046875, 0.50390625, 105.2666015625), v3(114.54296875, 87.1748046875, 211.23046875)},
["meshes\\Sky\\r\\Sky_DN_Bear_Black_01.nif"] = {v3(-0, -0, 68.5947265625), v3(99.1728515625, 159.5986328125, 137.189453125)},
["meshes\\Sky\\r\\Sky_Bear_Grey_01.nif"] = {v3(-0, -0, 102.8916015625), v3(148.7587890625, 239.3974609375, 205.783203125)},
["meshes\\sky\\r\\Sky_Boar_01.nif"] = {v3(-0, -0, 32.39453125), v3(63.5888671875, 111.3857421875, 64.7890625)},
["meshes\\sky\\r\\sky_butterfly_01.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\sky\\r\\sky_butterfly_02.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\sky\\r\\sky_butterfly_03.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\sky\\r\\sky_butterfly_04.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\Sky\\r\\sky_bull_01.nif"] = {v3(-0, 22.39990234375, 56), v3(67.2001953125, 190.400390625, 112)},
["meshes\\Sky\\r\\sky_bull_02.nif"] = {v3(-0, 22.39990234375, 56), v3(67.2001953125, 190.400390625, 112)},
["meshes\\Sky\\r\\Sky_Cow_01.nif"] = {v3(-0, 20, 49.826171875), v3(60, 170, 100)},
["meshes\\Sky\\r\\Sky_Cow_02.nif"] = {v3(-0, 20, 50), v3(60, 170, 100)},
["meshes\\Sky\\r\\Sky_Cow_03.nif"] = {v3(-0, 20, 50), v3(60, 170, 100)},
["meshes\\sky\\r\\sky_danswyrm.nif"] = {v3(-0, 9.07666015625, 23), v3(60.3955078125, 138.3408203125, 46.98046875)},
["meshes\\sky\\r\\sky_elk_01.nif"] = {v3(-0, 39.4560546875, 76.740234375), v3(62.9189453125, 181.8017578125, 151.94921875)},
["meshes\\sky\\r\\sky_elk_02.nif"] = {v3(-0, 39.4560546875, 76.740234375), v3(62.9189453125, 181.8017578125, 151.94921875)},
["meshes\\sky\\r\\sky_elk_04.nif"] = {v3(-0, 39.4560546875, 76.740234375), v3(62.9189453125, 181.8017578125, 151.94921875)},
["meshes\\sky\\r\\sky_elk_05.nif"] = {v3(-0, 39.4560546875, 76.740234375), v3(62.9189453125, 181.8017578125, 151.94921875)},
["meshes\\sky\\r\\sky_elk_03.nif"] = {v3(-0, 39.4560546875, 76.740234375), v3(62.9189453125, 181.8017578125, 151.94921875)},
["meshes\\Sky\\r\\Sky_Browntrout_01.NIF"] = {v3(-0, 0.05615234375, 17.412109375), v3(15, 93.2236328125, 34.083984375)},
["meshes\\Sky\\r\\sky_FishCod_01.nif"] = {v3(-9.8330078125, -0.47509765625, 16.1103515625), v3(19.666015625, 86.5302734375, 32.16015625)},
["meshes\\Sky\\r\\Sky_Northernpike_01.NIF"] = {v3(-0, 0.01171875, 13.2978515625), v3(17.052734375, 100.228515625, 24.708984375)},
["meshes\\Sky\\r\\Sky_Pikeperch_01.NIF"] = {v3(-9.8330078125, -0.47509765625, 16.1103515625), v3(19.666015625, 86.5302734375, 32.16015625)},
["meshes\\Sky\\r\\Sky_Pinksalmon_01.NIF"] = {v3(-0, -0, 10.197265625), v3(10, 54.1103515625, 19.0390625)},
["meshes\\Sky\\r\\Sky_Goat_03.nif"] = {v3(0.00146484375, 0.39404296875, 46.0888671875), v3(44.73046875, 120.2294921875, 92.4453125)},
["meshes\\Sky\\r\\Sky_horse_01.nif"] = {v3(0.0205078125, 22.09814453125, 93.2548828125), v3(80.4296875, 238.408203125, 184.794921875)},
["meshes\\Sky\\r\\Sky_horse_03.nif"] = {v3(0.01025390625, 22.087890625, 93.2451171875), v3(80.4296875, 238.408203125, 184.794921875)},
["meshes\\Sky\\r\\Sky_horse_05.nif"] = {v3(0.01025390625, 22.087890625, 93.2451171875), v3(80.4296875, 238.408203125, 184.794921875)},
["meshes\\Sky\\r\\Sky_horse_07.nif"] = {v3(0.01025390625, 22.087890625, 93.2451171875), v3(80.4296875, 238.408203125, 184.794921875)},
["meshes\\Sky\\r\\Sky_horse_02.nif"] = {v3(0.01025390625, 22.087890625, 93.2451171875), v3(80.4296875, 238.408203125, 184.794921875)},
["meshes\\Sky\\r\\Sky_horse_04.nif"] = {v3(0.01025390625, 22.087890625, 93.2451171875), v3(80.4296875, 238.408203125, 184.794921875)},
["meshes\\Sky\\r\\Sky_horse_06.nif"] = {v3(0.01025390625, 22.087890625, 93.2451171875), v3(80.4296875, 238.408203125, 184.794921875)},
["meshes\\Sky\\r\\Sky_horse_08.nif"] = {v3(0.01025390625, 22.087890625, 93.2451171875), v3(80.4296875, 238.408203125, 184.794921875)},
["meshes\\sky\\r\\sky_irontoad.nif"] = {v3(-0, 2.998046875, 31.4130859375), v3(63.52734375, 133.576171875, 63.919921875)},
["meshes\\Sky\\r\\Sky_Mammoth_01.nif"] = {v3(0.000244140625, -21.32958984375, 188.724609375), v3(234.38818359375, 569.2744140625, 377.58984375)},
["meshes\\sky\\r\\sky_moth_01.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\sky\\r\\sky_moth_02.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\sky\\r\\sky_moth_03.nif"] = {v3(-0.0009765625, 0.01025390625, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\Sky\\r\\Sky_Raki_01.nif"] = {v3(-0.00390625, 2.2265625, 28.8291015625), v3(53.005859375, 119.470703125, 57.294921875)},
["meshes\\Sky\\r\\Sky_Sabre_Cat_01.nif"] = {v3(-0, 11.6142578125, 55.0146484375), v3(89.7705078125, 207.189453125, 110.029296875)},
["meshes\\Sky\\r\\Sky_Sabre_Cat_02.nif"] = {v3(-0, 12, 55.0146484375), v3(61.59375, 198.0654296875, 110.029296875)},
["meshes\\sky\\r\\sky_snowray_01.nif"] = {v3(-0, -0, 96.7568359375), v3(65.34375, 132.09375, 57.7578125)},
["meshes\\Sky\\r\\sky_wolf_grey.nif"] = {v3(-0, -0, 42.0703125), v3(40.8310546875, 150.5126953125, 84.140625)},
["meshes\\sky\\r\\sky_KoglingAdult.nif"] = {v3(-0, -0, 77.0361328125), v3(79.6376953125, 57.2919921875, 151.623046875)},
["meshes\\sky\\r\\sky_KoglingBud.nif"] = {v3(-0, -0.1884765625, 17.212890625), v3(45.501953125, 81.8369140625, 35.3046875)},
["meshes\\sky\\r\\sky_KoglingElder.nif"] = {v3(-0, -0, 93.9462890625), v3(108.306640625, 88.1025390625, 189.248046875)},
["meshes\\sky\\r\\Sky_Draugr_Axeman.nif"] = {v3(-0, 11, 73.150390625), v3(64.416015625, 62.65625, 146.30078125)},
["meshes\\sky\\r\\Sky_DraugrLord.nif"] = {v3(-1.204833984375, 11.3603515625, 76.30078125), v3(75.54052734375, 75.1728515625, 152.94921875)},
["meshes\\Sky\\r\\Sky_Lich_Frost_01.nif"] = {v3(-0, -0, 72.9765625), v3(64.416015625, 62.65625, 146.30078125)},
["meshes\\Sky\\r\\Sky_Lich_Frost_02.nif"] = {v3(-0, -0, 73.150390625), v3(64.416015625, 62.65625, 146.30078125)},
["meshes\\Sky\\r\\Sky_Lich_Frost_03.nif"] = {v3(-0, -0, 73.150390625), v3(64.416015625, 62.65625, 146.30078125)},
["meshes\\Sky\\r\\Sky_Lich_Frost_04.nif"] = {v3(-0, -0, 73.150390625), v3(64.416015625, 62.65625, 146.30078125)},
["meshes\\Sky\\r\\Sky_Skeleton_Crip_01.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_tsaesci_01.nif"] = {v3(-0, -72.11572265625, 102.455078125), v3(115.701171875, 215.5732421875, 204.21875)},
["meshes\\pc\\cr\\pc_tsaesci_02.nif"] = {v3(2.263671875, -70.27001953125, 102.8037109375), v3(136.13671875, 247.208984375, 204.21875)},
["meshes\\r\\Dreugh.nif"] = {v3(-0, 8.18505859375, 2.9677734375), v3(79.6259765625, 81.8603515625, 86.00390625)},
["meshes\\TR\\cr\\TR_dres_bug_mtd_VO.NIF"] = {v3(-4.6923828125, -111.07763671875, 343.6123046875), v3(109.19921875, 307.1220703125, 120.57421875)},
["meshes\\r\\dreugh.nif"] = {v3(-0, 10.2314453125, 3.7099609375), v3(99.5322265625, 102.326171875, 107.50390625)},
["meshes\\tr\\cr\\tr_mouse02_ya.nif"] = {v3(-0, -0, 22.23828125), v3(33.173828125, 89.7021484375, 44.4765625)},
["meshes\\TR\\cr\\tr_velk.nif"] = {v3(0.00146484375, 18.099609375, 57.5888671875), v3(55.275390625, 142.7626953125, 114.685546875)},
["meshes\\r\\duskyalit.nif"] = {v3(-0, -0, 56.3115234375), v3(101.130859375, 152.4140625, 112.623046875)},
["meshes\\r\\Fabricant_Hulking.nif"] = {v3(-0, -0, 118.1708984375), v3(282.6181640625, 340.8486328125, 236.341796875)},
["meshes\\r\\WingedTwilight.nif"] = {v3(-0.31005859375, 23.13818359375, 133), v3(117.1201171875, 142.7216796875, 266)},
["meshes\\r\\CaveMudcrab.NIF"] = {v3(-0, 20.55078125, 32.4072265625), v3(107.6201171875, 130.2470703125, 64.974609375)},
["meshes\\r\\Scamp_Fetch.NIF"] = {v3(-1.15185546875, -1.15185546875, 45.599609375), v3(36.2177734375, 53.7373046875, 90.494140625)},
["meshes\\r\\MineScrib.NIF"] = {v3(-0, 0.27734375, 19.421875), v3(54.404296875, 75.984375, 39.064453125)},
["meshes\\r\\SlaughterFish.NIF"] = {v3(-0, -5.79541015625, 16.16015625), v3(56.48046875, 154.37890625, 32.298828125)},
["meshes\\r\\NixHound.NIF"] = {v3(-0, -0, 46.181640625), v3(53.669921875, 177.044921875, 92.6328125)},
["meshes\\r\\Kwama Queen.NIF"] = {v3(-0.2880859375, -53.4013671875, 67.8173828125), v3(115.201171875, 376.9248046875, 137.474609375)},
["meshes\\r\\Shalk.NIF"] = {v3(-0.822265625, 6.1171875, 24.5234375), v3(108.66015625, 114.837890625, 49.39453125)},
["meshes\\r\\Corprus_Stalker.NIF"] = {v3(-1.78662109375, 4.4716796875, 65.4423828125), v3(46.9443359375, 39.7744140625, 130.884765625)},
["meshes\\r\\kwama_queen_blighted.nif"] = {v3(-0.35986328125, -66.75146484375, 84.771484375), v3(144.0009765625, 471.15625, 171.84375)},
["meshes\\r\\netch_betty_swamp.nif"] = {v3(1.34326171875, -0.2421875, 234.1005859375), v3(118.4716796875, 120.755859375, 179.083984375)},
["meshes\\r\\skeleton_warrior_07.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\frost_guardian.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\slaughter_shark.nif"] = {v3(-0, -10.1416015625, 28.28125), v3(98.841796875, 270.1630859375, 56.5234375)},
["meshes\\r\\centurion_spider_tower.nif"] = {v3(-0, -0, 20.130859375), v3(57.9853515625, 54.26953125, 40.609375)},
["meshes\\r\\prac_target.nif"] = {v3(-0, 15, 47), v3(68.01953125, 68.4599609375, 94)},
["meshes\\r\\shock_guardian.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\netch_betty_ash.nif"] = {v3(1.34326171875, -0.2421875, 234.1005859375), v3(118.4716796875, 120.755859375, 179.083984375)},
["meshes\\r\\skeleton_imp_archer.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\netch_bull_swamp.nif"] = {v3(-2.48779296875, 4.90625, 558.171875), v3(328.416015625, 503.5126953125, 420.517578125)},
["meshes\\r\\mazar.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\dwarven_wraith.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\dwarven_phantom.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\dwarven_ghast.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\silver_saint.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\swampscrib.nif"] = {v3(-0, 0.36962890625, 25.8955078125), v3(72.5390625, 101.3125, 52.0859375)},
["meshes\\r\\skeleton_warrior_06.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\skeleton_warrior_05.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\skeleton_warrior_04.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\skeleton_warrior_03.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\skeleton_warrior_02.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\ashscrib.nif"] = {v3(-0, 0.36962890625, 25.8955078125), v3(72.5390625, 101.3125, 52.0859375)},
["meshes\\r\\centurion_giant.nif"] = {v3(0.3408203125, 0.3408203125, 134.8408203125), v3(199.0947265625, 200.4580078125, 270.029296875)},
["meshes\\r\\shalk_blueback.nif"] = {v3(-0.61669921875, 4.587890625, 18.5234375), v3(81.4951171875, 86.1279296875, 37.046875)},
["meshes\\r\\blindfish.nif"] = {v3(-0, -7.244140625, 20.2001953125), v3(70.6005859375, 192.9736328125, 40.375)},
["meshes\\r\\Centurion_Flying.nif"] = {v3(-3.36181640625, 14.62646484375, 72.0234375), v3(94.98046875, 89.083984375, 144.046875)},
["meshes\\r\\Centurion_Blade.nif"] = {v3(-0.36865234375, 1.1220703125, 78.1064453125), v3(95.3271484375, 81.3671875, 156.212890625)},
["meshes\\Sky\\r\\Sky_Farm_Chicken_05.NIF"] = {v3(-0, 0.79296875, 28.896484375), v3(29.97265625, 41.1328125, 56.546875)},
["meshes\\TR\\cr\\TR_barfish_1a.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\r\\shalk_greenback.nif"] = {v3(-0.61669921875, 4.587890625, 18.349609375), v3(81.4951171875, 86.1279296875, 37.046875)},
["meshes\\r\\netch_bull_ash.nif"] = {v3(-2.48779296875, 4.90625, 558.171875), v3(328.416015625, 503.5126953125, 420.517578125)},
["meshes\\r\\skeleton_fur.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_moth_04.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_moth_05.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\pc\\cr\\pc_moth_06.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\r\\skeleton_imp_warrior.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_muskrat.nif"] = {v3(-0, -19.77734375, 29.6513671875), v3(44.232421875, 149.6533203125, 59.302734375)},
["meshes\\pc\\cr\\pc_muskrat_collar.nif"] = {v3(-0, -19.77734375, 29.6513671875), v3(44.232421875, 149.6533203125, 59.302734375)},
["meshes\\pc\\cr\\pc_Pig_01.nif"] = {v3(-0, -0, 43.513671875), v3(76.71875, 158.5, 87.02734375)},
["meshes\\pc\\cr\\pc_Pig_02.nif"] = {v3(-0, -0, 41.755859375), v3(76.71875, 153.3369140625, 83.859375)},
["meshes\\pc\\cr\\pc_rivernewt_01.nif"] = {v3(-0, -52.6171875, 26.48828125), v3(83.2001953125, 250.771484375, 57.271484375)},
["meshes\\pc\\cr\\pc_rivernewt_02.nif"] = {v3(-0, -12.53955078125, 26.48828125), v3(83.2001953125, 197.318359375, 57.271484375)},
["meshes\\pc\\cr\\pc_tantha.nif"] = {v3(-0, 0.54248046875, 52.5625), v3(77.369140625, 123.3359375, 107.140625)},
["meshes\\pc\\cr\\pc_wolf.nif"] = {v3(-0, -0, 42.0703125), v3(40.8310546875, 150.5126953125, 84.140625)},
["meshes\\pc\\cr\\pc_whitewolf.nif"] = {v3(-0, -0, 50.484375), v3(68.93359375, 186.9169921875, 100.96875)},
["meshes\\pc\\cr\\pc_ghost_01.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_ghost_02.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_MinotaurBarr01.nif"] = {v3(-0.26123046875, 0.50390625, 82.7255859375), v3(83.5068359375, 62.431640625, 168.546875)},
["meshes\\pc\\cr\\PC_Mummy.nif"] = {v3(-2.94970703125, 14.5537109375, 49.4794921875), v3(62.4990234375, 59.9755859375, 99.1640625)},
["meshes\\pc\\cr\\PC_RemanSkel_03.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\PC_RemanSkel_04.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\PC_RemanSkel_01.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\PC_RemanSkel_02.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_skeleton_imp01.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_skeleton_imp02.nif"] = {v3(-0, -0, 66.5), v3(68.8154296875, 67.5703125, 133)},
["meshes\\pc\\cr\\pc_wraith_01.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_wraith_02.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\pc\\cr\\pc_auroran.nif"] = {v3(-0, -0, 83.125), v3(73.2001953125, 71.2001953125, 166.25)},
["meshes\\tr\\cr\\tr_cr_devourer_01.nif"] = {v3(1.813232421875, -26.236328125, 70.162109375), v3(95.68212890625, 161.603515625, 136.828125)},
["meshes\\tr\\cr\\tr_dremora_archer.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_dremora_caster.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\TR\\cr\\TR_dridrea_VO.NIF"] = {v3(0.2705078125, 54.3046875, 89.0322265625), v3(74.728515625, 129.7177734375, 102.927734375)},
["meshes\\tr\\cr\\tr_vile_dae_c.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_clannfear_lesser.nif"] = {v3(-0, -0, 57.5), v3(74.0556640625, 140.0771484375, 115.75390625)},
["meshes\\tr\\cr\\tr_storm_tyrant.nif"] = {v3(7.07421875, -5.8994140625, 118.212890625), v3(134.17578125, 129.1181640625, 236.42578125)},
["meshes\\tr\\cr\\tr_cr_seducer_01.nif"] = {v3(-0, -0, 66.6083984375), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_cr_seducerdark_01.nif"] = {v3(-0, -0, 257.7548828125), v3(98.4482421875, 92.322265625, 179.390625)},
["meshes\\r\\fire_guardian.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\earth_atronach.nif"] = {v3(5.32568359375, -3.8525390625, 87.5654296875), v3(99.7548828125, 96.87890625, 175.130859375)},
["meshes\\r\\riekling_raider_01.nif"] = {v3(-0, -0, 37.5888671875), v3(72.1552734375, 130.830078125, 76.22265625)},
["meshes\\r\\electricfish.nif"] = {v3(-0, -8.693603515625, 24.2412109375), v3(84.78515625, 231.64306640625, 48.44921875)},
["meshes\\r\\rock_crab.NIF"] = {v3(-0, 32.89892578125, 40.12109375), v3(116.8515625, 117.8994140625, 94.5703125)},
["meshes\\r\\centurion_spider_miner.nif"] = {v3(-0, -0, 20.3046875), v3(70.4267578125, 67.845703125, 40.609375)},
["meshes\\r\\GreenSlime.nif"] = {v3(-0, -0, 45), v3(60, 60, 90)},
["meshes\\r\\skeleton_dunmer.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\skeleton_orcish.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\skeleton_indoril.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\LordTerror.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\riekling_berserker.nif"] = {v3(-0, -0, 44.0546875), v3(55, 55, 88.109375)},
["meshes\\r\\riekling_nightstalker.nif"] = {v3(-0, -0, 40.0498046875), v3(50, 50, 80.099609375)},
["meshes\\r\\riekling_warrior_02.nif"] = {v3(-0, -0, 40.0498046875), v3(50, 50, 80.099609375)},
["meshes\\r\\riekling_warrior_01.nif"] = {v3(-0, -0, 40.0498046875), v3(50, 50, 80.099609375)},
["meshes\\r\\riekling_shaman.nif"] = {v3(-0, -0, 40.0498046875), v3(50, 50, 80.099609375)},
["meshes\\r\\scamp_runt.nif"] = {v3(-1.15185546875, -1.15185546875, 45.599609375), v3(36.2177734375, 53.7373046875, 90.494140625)},
["meshes\\r\\Draugr_Berserker.nif"] = {v3(1.88232421875, 20.10205078125, 78.94140625), v3(70.4150390625, 104.4716796875, 153.568359375)},
["meshes\\r\\Draugr_Deathlord.nif"] = {v3(-0, 12, 79.7998046875), v3(70.2724609375, 68.3515625, 159.599609375)},
["meshes\\r\\clannfear_fire.nif"] = {v3(-0, -0, 66.14453125), v3(84.634765625, 160.087890625, 132.2890625)},
["meshes\\TR\\cr\\TR_LE_r_but_small.NIF"] = {v3(-0.21337890625, -0.748046875, 91.6142578125), v3(50.5732421875, 38.9609375, 68.779296875)},
["meshes\\TR\\cr\\tr_seacrab.nif"] = {v3(-0, -0, 38.5), v3(85.7998046875, 77, 77)},
["meshes\\TR\\cr\\TR_beetle_G03_VO.NIF"] = {v3(-0, -0, 44.3388671875), v3(64.9404296875, 117.689453125, 88.677734375)},
["meshes\\r\\centurion_overlord.nif"] = {v3(-1.06689453125, 16.6005859375, 79.2255859375), v3(91.5283203125, 81.98046875, 158.451171875)},
["meshes\\TR\\cr\\TR_barfish_3b.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\r\\wormmouth.nif"] = {v3(-0, 18.95703125, 90.822265625), v3(127.9970703125, 256.10546875, 179.62890625)},
["meshes\\r\\LordGod.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\LordInspiration.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\Guar_withharness.nif"] = {v3(-0, 40.3271484375, 79.9296875), v3(98.7158203125, 239.5751953125, 159.859375)},
["meshes\\r\\skeleton_khelam.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\skeleton_champion.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\phnem.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\r\\prac_dummy.NIF"] = {v3(-0.67138671875, 2.56982421875, 101.65625), v3(107.7080078125, 85.6494140625, 196.921875)},
["meshes\\r\\FrostGiant1.nif"] = {v3(-0, -0, 104.630859375), v3(123.53515625, 120.205078125, 208.74609375)},
["meshes\\TR\\cr\\TR_Plainstrider_VO.NIF"] = {v3(-1.49267578125, 45.85791015625, 161.9384765625), v3(212.6533203125, 702.837890625, 277.53125)},
["meshes\\TR\\cr\\TR_parastylus_VO.NIF"] = {v3(-0.03173828125, -9.4052734375, 43.28125), v3(66.041015625, 218.2724609375, 86.189453125)},
["meshes\\TR\\cr\\TR_ornada_clutch_VO.NIF"] = {v3(-0.48681640625, -2.59521484375, 31.171875), v3(22.9970703125, 65.2607421875, 44.75)},
["meshes\\TR\\cr\\TR_ornada_VO.NIF"] = {v3(-0.48681640625, -2.59521484375, 31.345703125), v3(22.9970703125, 65.2607421875, 44.75)},
["meshes\\TR\\cr\\TR_nixmount.nif"] = {v3(13.890625, 15.76611328125, 63.8193359375), v3(93.974609375, 239.0771484375, 106.607421875)},
["meshes\\TR\\cr\\TR_swampfly_VO.NIF"] = {v3(-0.34423828125, 0.15576171875, 30.3271484375), v3(17.1494140625, 40.337890625, 11.353515625)},
["meshes\\TR\\cr\\TR_muckleech_VO.NIF"] = {v3(-0.2060546875, -31.07373046875, 38.2109375), v3(52, 92.6630859375, 59.943359375)},
["meshes\\tr\\cr\\tr_cr_moth_03.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\tr\\cr\\tr_cr_moth_02.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\tr\\cr\\tr_cr_moth_01.nif"] = {v3(-0, -0, 101.6171875), v3(12.7998046875, 12.7998046875, 12.80078125)},
["meshes\\TR\\cr\\TR_molecrab_VO.NIF"] = {v3(-0.48681640625, -2.59521484375, 31.345703125), v3(22.9970703125, 65.2607421875, 44.75)},
["meshes\\tr\\cr\\tr_juvriverstrider.nif"] = {v3(2.0361328125, -38.1962890625, 49.8955078125), v3(78.25, 219.021484375, 97.962890625)},
["meshes\\TR\\cr\\TR_hoom.nif"] = {v3(-0, -0, 83.833984375), v3(106.70703125, 231.30078125, 167.66796875)},
["meshes\\TR\\cr\\Guar_withharness.nif"] = {v3(-0, 40.3271484375, 79.9296875), v3(98.7158203125, 239.5751953125, 159.859375)},
["meshes\\TR\\cr\\TR_barfish_3c.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\r\\FrostMonarch.nif"] = {v3(-0, 11, 96.25), v3(92.2294921875, 88, 192.642578125)},
["meshes\\TR\\cr\\TR_barfish_3a.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\TR\\cr\\TR_barfish_2c.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\TR\\cr\\TR_barfish_2b.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\TR\\cr\\TR_barfish_2a.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\TR\\cr\\TR_barfish_1c.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\TR\\cr\\TR_barfish_1b.NIF"] = {v3(-0.341796875, 3.77490234375, -12.484375), v3(2.8017578125, 29.98046875, 8.966796875)},
["meshes\\r\\dremora_archer.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\TR\\cr\\TR_eyestar_VO.NIF"] = {v3(-0, -0, 6.3486328125), v3(87.970703125, 91.3779296875, 12.697265625)},
["meshes\\TR\\cr\\TR_cephalopod_VO.NIF"] = {v3(-0, -0, 61.376953125), v3(318.603515625, 254.4130859375, 122.75390625)},
["meshes\\tr\\cr\\tr_blindfish_01.nif"] = {v3(-0, -7.96826171875, 22.220703125), v3(77.6611328125, 212.271484375, 44.412109375)},
["meshes\\TR\\cr\\TR_beetle_G04_VO.NIF"] = {v3(-0, -0, 44.3388671875), v3(64.9404296875, 137.689453125, 88.677734375)},
["meshes\\r\\FrostGiant2.nif"] = {v3(-0, -0, 104.630859375), v3(103.392578125, 98.89453125, 208.74609375)},
["meshes\\TR\\cr\\TR_beetle_G01_VO.NIF"] = {v3(-0, -0, 44.1650390625), v3(78.4765625, 127.2587890625, 88.677734375)},
["meshes\\TR\\cr\\TR_beetle_G02_VO.NIF"] = {v3(-0, -0, 44.3388671875), v3(64.9404296875, 117.689453125, 88.677734375)},
["meshes\\tr\\cr\\tr_direkagouti.nif"] = {v3(-0, -0, 89.5205078125), v3(129.77734375, 248.7763671875, 179.041015625)},
["meshes\\Sky\\r\\Sky_GoblinThr_01.nif"] = {v3(-0, -0, 44.4609375), v3(58.5771484375, 64.701171875, 88.921875)},
["meshes\\TR\\cr\\TR_GoblinShaman.nif"] = {v3(-0, -0, 46.4521484375), v3(77.1533203125, 81.716796875, 93.6015625)},
["meshes\\Sky\\r\\Sky_Wormmouth_01.nif"] = {v3(-0, 14.42236328125, 69.86328125), v3(90.6650390625, 188.12890625, 138.17578125)},
["meshes\\Sky\\r\\Sky_Spikeworm_01.nif"] = {v3(0.00390625, 39.67919921875, 21.5), v3(30.615234375, 95.84765625, 41.068359375)},
["meshes\\Sky\\r\\Sky_Goat_02.nif"] = {v3(0.00146484375, 0.39404296875, 41.8837890625), v3(44.73046875, 120.2294921875, 84.041015625)},
["meshes\\Sky\\r\\Sky_Goat_01.nif"] = {v3(0.00146484375, 0.39404296875, 42.0576171875), v3(44.73046875, 120.2294921875, 84.041015625)},
["meshes\\TR\\cr\\TR_Skeleton_Orc.nif"] = {v3(-0, -0, 67.83984375), v3(59.1904296875, 56.96484375, 135.6796875)},
["meshes\\tr\\cr\\tr_skeleton_khajiit.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_skeleton_arise04.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_skeleton_arise03.nif"] = {v3(-0, -0, 66.5), v3(58.9169921875, 57.31640625, 133)},
["meshes\\tr\\cr\\tr_skeleton_arise02.nif"] = {v3(-0, -0, 66.326171875), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_skeleton_arise01.nif"] = {v3(-0, -0, 65.91015625), v3(45.21484375, 42.369140625, 131.8203125)},
["meshes\\tr\\cr\\tr_skeleton_arg_03.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_skeleton_arg_02.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\tr\\cr\\tr_skeleton_arg_01.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\TR\\cr\\TR_liche_greater.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\sky\\r\\sky_squirrel_02.nif"] = {v3(-0, -9.60009765625, 24), v3(42.462890625, 112, 48)},
["meshes\\sky\\r\\sky_squirrel_01.nif"] = {v3(-0, -9.60009765625, 24), v3(42.462890625, 112, 48)},
["meshes\\r\\goblin_shaman.NIF"] = {v3(-0, -0, 46.4521484375), v3(61.66015625, 68.1064453125, 93.6015625)},
["meshes\\TR\\cr\\TR_mouse01_YA.nif"] = {v3(-0, -0, 29.6513671875), v3(44.232421875, 119.6025390625, 59.302734375)},
["meshes\\r\\raven.NIF"] = {v3(-0, -0, 36.4560546875), v3(42.6689453125, 129.54296875, 72.912109375)},
["meshes\\r\\ice troll.NIF"] = {v3(-4, 20, 84), v3(104, 104, 168)},
["meshes\\r\\Hircine_Bear_larger.NIF"] = {v3(-0, -0, 137.1884765625), v3(198.3447265625, 319.1962890625, 274.376953125)},
["meshes\\r\\HircineWolf.NIF"] = {v3(-0, -0, 71.3447265625), v3(69.412109375, 255.87109375, 143.037109375)},
["meshes\\pc\\cr\\pc_AyleidSorceror.nif"] = {v3(-0, -0, 105.1884765625), v3(111.4990234375, 101.8154296875, 210.3671875)},
["meshes\\pc\\cr\\pc_ayl_guard_01.nif"] = {v3(-0, -0, 103.82421875), v3(144.9462890625, 37.642578125, 73.890625)},
["meshes\\tr\\cr\\tr_horker_white_01.nif"] = {v3(-0.0400390625, -8.8525390625, 17.171875), v3(82.009765625, 103.076171875, 34.34375)},
["meshes\\tr\\cr\\tr_horker_grey_03.nif"] = {v3(-0.189453125, -42.109375, 79.080078125), v3(414.2294921875, 514.435546875, 158.5078125)},
["meshes\\tr\\cr\\tr_horker_grey_02.nif"] = {v3(-0.0703125, -15.662109375, 30.380859375), v3(145.0947265625, 182.3662109375, 60.76171875)},
["meshes\\tr\\cr\\tr_horker_grey_01.nif"] = {v3(-0.0400390625, -8.8525390625, 17.171875), v3(82.009765625, 103.076171875, 34.34375)},
["meshes\\tr\\cr\\tr_horker_brown_03.nif"] = {v3(-0.188232421875, -41.88330078125, 79.080078125), v3(407.83154296875, 507.5, 158.5078125)},
["meshes\\tr\\cr\\tr_horker_brown_02.nif"] = {v3(-0.0703125, -15.662109375, 30.20703125), v3(145.0947265625, 182.3662109375, 60.76171875)},
["meshes\\tr\\cr\\tr_horker_brown_01.nif"] = {v3(-0.0400390625, -8.8525390625, 17.171875), v3(82.009765625, 103.076171875, 34.34375)},
["meshes\\tr\\cr\\tr_sturgeon_anc.nif"] = {v3(-0, 0.0185546875, 21.275390625), v3(27.2841796875, 160.365234375, 39.53515625)},
["meshes\\tr\\cr\\tr_sturgeon.nif"] = {v3(-0, 0.00927734375, 10.6376953125), v3(13.642578125, 80.1826171875, 19.767578125)},
["meshes\\sky\\r\\sky_deer02.nif"] = {v3(-0, 11.7841796875, 63.517578125), v3(57.685546875, 155.0126953125, 129.125)},
["meshes\\sky\\r\\sky_deer01.nif"] = {v3(-0, 12.85546875, 88.693359375), v3(96.32421875, 169.1044921875, 181.791015625)},
["meshes\\Sky\\r\\Sky_Farm_Rooster_02.NIF"] = {v3(-0, -1.4501953125, 24.7314453125), v3(25, 40, 48)},
["meshes\\Sky\\r\\Sky_Farm_Rooster_01.NIF"] = {v3(-0, -1.4501953125, 24.9052734375), v3(25, 40, 48)},
["meshes\\r\\skeleton_kragh.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\Sky\\r\\Sky_Farm_Chicken_04.NIF"] = {v3(-0, 0.79296875, 28.896484375), v3(29.97265625, 41.1328125, 56.546875)},
["meshes\\Sky\\r\\Sky_Farm_Chicken_03.NIF"] = {v3(-0, -1.4501953125, 24.9052734375), v3(25, 40, 48)},
["meshes\\Sky\\r\\Sky_Farm_Chicken_02.NIF"] = {v3(-0, -1.4501953125, 24.7314453125), v3(25, 40, 48)},
["meshes\\Sky\\r\\Sky_Farm_Chicken_01.NIF"] = {v3(-0, -1.4501953125, 24.9052734375), v3(25, 40, 48)},
["meshes\\TR\\cr\\TR_LE_r_but_micro.NIF"] = {v3(-0.36865234375, 4.071044921875, 46.2978515625), v3(25.5146484375, 9.34130859375, 33.595703125)},
["meshes\\r\\clannfear_runt.nif"] = {v3(-0, -0, 52.916015625), v3(67.7080078125, 128.0703125, 105.83203125)},
["meshes\\TR\\cr\\TR_LE_r_but_tiny.NIF"] = {v3(0.2509765625, 6.1552734375, 55.9638671875), v3(45.92578125, 8.5966796875, 46.384765625)},
["meshes\\TR\\cr\\TR_LE_p_but_micro.NIF"] = {v3(-0.11181640625, 4.0849609375, 46.2978515625), v3(25.07421875, 7.779296875, 33.595703125)},
["meshes\\tr\\cr\\tr_cr_seducerdark_02.nif"] = {v3(-0, -0, 66.6083984375), v3(95.2568359375, 56.9599609375, 133)},
["meshes\\TR\\cr\\TR_vermai.nif"] = {v3(0.02880859375, 33.77587890625, 67.7294921875), v3(54.68359375, 82.185546875, 136.005859375)},
["meshes\\tr\\cr\\tr_xivilai.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\TR\\cr\\TR_Dwemer.nif"] = {v3(-0, -0, 53.2001953125), v3(46.84765625, 45.568359375, 106.400390625)},
["meshes\\tr\\cr\\tr_dwe_colos_01.nif"] = {v3(0.3408203125, 0.3408203125, 134.666015625), v3(199.0947265625, 200.4580078125, 270.029296875)},
["meshes\\tr\\cr\\tr_dwe_specter_f.nif"] = {v3(-0, -0, 66.5), v3(58.5595703125, 56.9599609375, 133)},
["meshes\\EPoS\\cr\\epos_r_alfiq_01.NIF"] = {v3(-0, -0, 16.9169921875), v3(11.0966796875, 67.3564453125, 33.833984375)},
["meshes\\tr\\cr\\tr_DreughQueen01.nif"] = {v3(-0, -0, 82.2568359375), v3(146.189453125, 114.1748046875, 204.46484375)},
["meshes\\TR\\cr\\TR_golem_mud_VO.NIF"] = {v3(-2.52099609375, 12.862060546875, 71.884765625), v3(79.83984375, 85.80615234375, 131.537109375)},
["meshes\\tr\\cr\\tr_Gremlin_01.nif"] = {v3(-0, -0, 32.7177734375), v3(32.81640625, 35.576171875, 65.55078125)},
["meshes\\tr\\cr\\tr_Gremlin_02.nif"] = {v3(-0, -0, 32.7177734375), v3(32.81640625, 35.576171875, 65.55078125)},
["meshes\\tr\\cr\\tr_Gremlin_03.nif"] = {v3(-0, -0, 32.7177734375), v3(32.81640625, 35.576171875, 65.55078125)},
["meshes\\tr\\cr\\tr_Gremlin_04.nif"] = {v3(-0, -0, 32.7177734375), v3(32.81640625, 35.576171875, 65.55078125)},
["meshes\\tr\\cr\\tr_Kobold_01.nif"] = {v3(-1.7744140625, 17.97412109375, 57.7626953125), v3(61.3046875, 85.810546875, 115.50390625)},
["meshes\\pc\\cr\\pc_lamia.nif"] = {v3(-0, 0.55615234375, 37.97265625), v3(52.8818359375, 86.7783203125, 75.9453125)},
["meshes\\tr\\cr\\tr_LandDreugh.nif"] = {v3(-0, 8.229248046875, 50), v3(84.365234375, 86.61181640625, 100)},
["meshes\\pc\\cr\\PC_Sload_01.nif"] = {v3(-0, -0, 89.826171875), v3(180, 180, 180)},
["meshes\\tr\\cr\\tr_troll_armor_01.nif"] = {v3(0.34619140625, -8.734375, 66.3701171875), v3(184.2734375, 237.3701171875, 133.4375)},
["meshes\\tr\\cr\\tr_troll_armor_02.nif"] = {v3(-0, -9.294921875, 66.3701171875), v3(127.01171875, 206.375, 133.4375)},
["meshes\\tr\\cr\\tr_troll_armor_03.nif"] = {v3(-0, -9.040283203125, 64.5), v3(124.0517578125, 201.23974609375, 129.697265625)},
["meshes\\tr\\cr\\tr_troll_armor_04.nif"] = {v3(-0, -9.5556640625, 68.58984375), v3(130.5732421875, 212.1611328125, 137.1796875)},
["meshes\\tr\\cr\\TR_troll_cave01.nif"] = {v3(-0.000244140625, -8.691162109375, 62.005859375), v3(119.18408203125, 193.39404296875, 124.708984375)},
["meshes\\tr\\cr\\TR_troll_cave02.nif"] = {v3(-0, -8.68701171875, 62.3544921875), v3(118.703125, 192.8740234375, 124.708984375)},
["meshes\\tr\\cr\\TR_troll_cave03.nif"] = {v3(-0, -8.68701171875, 62.3544921875), v3(118.703125, 192.8740234375, 124.708984375)},
["meshes\\tr\\cr\\TR_troll_cave04.nif"] = {v3(-0, -8.68701171875, 62.3544921875), v3(118.703125, 192.8740234375, 124.708984375)},
["meshes\\tr\\cr\\TR_troll_frost01.nif"] = {v3(0.144775390625, -8.37109375, 63.6015625), v3(173.35205078125, 225.5478515625, 127.203125)},
["meshes\\tr\\cr\\TR_troll_frost02.nif"] = {v3(-0, -8.8603515625, 63.6015625), v3(121.0771484375, 196.7314453125, 127.203125)},
["meshes\\tr\\cr\\TR_troll_frost03.nif"] = {v3(-0, -8.8603515625, 63.6015625), v3(121.0771484375, 196.7314453125, 127.203125)},
["meshes\\tr\\cr\\TR_troll_frost04.nif"] = {v3(-0, -8.8603515625, 63.6015625), v3(121.0771484375, 196.7314453125, 127.203125)},
["meshes\\Sky\\r\\Sky_Wereboar_01.nif"] = {v3(-0, -0, 53.353515625), v3(143.984375, 140.1357421875, 106.70703125)},
["meshes\\Sky\\r\\Sky_Werewolf_01.nif"] = {v3(-0, 6.78515625, 66.5), v3(58.5595703125, 70.5302734375, 133)},
["meshes\\pc\\cr\\pc_Bat_01.nif"] = {v3(-0.4111328125, -2.7900390625, 145.7919921875), v3(102.2236328125, 81.6015625, 147.228515625)},
["meshes\\TR\\cr\\TR_LE_g_but_tiny.NIF"] = {v3(-0.4482421875, 6.150146484375, 55.9638671875), v3(46.603515625, 13.73388671875, 46.384765625)},
["meshes\\TR\\cr\\TR_LE_g_but_small.NIF"] = {v3(-0.21337890625, -0.748046875, 91.6142578125), v3(50.5732421875, 38.9609375, 68.779296875)},
["meshes\\TR\\cr\\TR_LE_g_but_micro.NIF"] = {v3(-0.11181640625, 4.0849609375, 46.2978515625), v3(25.07421875, 7.779296875, 33.595703125)},
["meshes\\TR\\cr\\TR_LE_p_but_tiny.NIF"] = {v3(0.2509765625, 6.1552734375, 55.9638671875), v3(45.92578125, 8.5966796875, 46.384765625)},
["meshes\\TR\\cr\\TR_LE_p_but_small.NIF"] = {v3(-0.21337890625, -0.748046875, 91.6142578125), v3(50.5732421875, 38.9609375, 68.779296875)},
["meshes\\tr\\cr\\tr_horker_white_02.nif"] = {v3(-0.18359375, -40.8583984375, 79.25390625), v3(378.5087890625, 475.7373046875, 158.5078125)},
["meshes\\sky\\r\\sky_spider_01.nif"] = {v3(0.67578125, -36.287109375, 19.5419921875), v3(78.17578125, 127.990234375, 39.150390625)},
["meshes\\TR\\cr\\TR_mouse02_YA.nif"] = {v3(-0, -0, 29.6513671875), v3(44.232421875, 119.6025390625, 59.302734375)},
["meshes\\tr\\cr\\tr_rat_col_01.nif"] = {v3(-0, -0, 31.7265625), v3(47.328125, 127.974609375, 63.453125)},
["meshes\\tr\\cr\\tr_rat_col_02.nif"] = {v3(-0, -0, 32.6162109375), v3(48.6552734375, 131.5634765625, 65.232421875)},
["meshes\\TR\\cr\\TR_mouse00_YA.nif"] = {v3(-0, -0, 29.4775390625), v3(58.9462890625, 125.7216796875, 59.302734375)},
["meshes\\r\\Dreugh.NIF"] = {v3(-0, 7.36669921875, 2.6708984375), v3(71.6630859375, 73.6748046875, 77.40234375)},
["meshes\\r\\Skeleton.NIF"] = {v3(-0, -0, 63.1748046875), v3(55.6318359375, 54.1123046875, 126.349609375)},
["meshes\\r\\Kwama Worker.NIF"] = {v3(-0, -0, 38.4482421875), v3(70.0458984375, 134.41796875, 76.896484375)},
["meshes\\r\\AshGhoul.NIF"] = {v3(1.1201171875, -7.9921875, 71.92578125), v3(54.2236328125, 60.890625, 143.8515625)},
["meshes\\r\\AncestorGhost.NIF"] = {v3(-0, -0, 63.1748046875), v3(55.6318359375, 54.1123046875, 126.349609375)},
["meshes\\r\\Kwama Warior.NIF"] = {v3(-0.84521484375, 10.55126953125, 53.4482421875), v3(66.59765625, 96.4375, 107.244140625)},
["meshes\\r\\AshSlave.NIF"] = {v3(7.1103515625, -14.9921875, 68.861328125), v3(49.4150390625, 70.9287109375, 137.7734375)},
["meshes\\r\\AshZombie.NIF"] = {v3(3.9580078125, -17.99365234375, 65.4423828125), v3(46.9443359375, 63.732421875, 130.884765625)},
["meshes\\r\\Netch_Bull.NIF"] = {v3(-1.74755859375, 3.446044921875, 390.720703125), v3(233.458984375, 356.45166015625, 294.361328125)},
["meshes\\r\\Netch_Betty.NIF"] = {v3(0.9404296875, -0.16943359375, 163.8701171875), v3(82.9306640625, 84.529296875, 125.359375)},
["meshes\\r\\BoneLord.NIF"] = {v3(-0.0078125, -0.00146484375, 73.142578125), v3(50.541015625, 41.65625, 146.28515625)},
["meshes\\r\\Sphere_Centurions.NIF"] = {v3(-0.33154296875, 1.009765625, 69.947265625), v3(85.7939453125, 73.23046875, 140.591796875)},
["meshes\\r\\G_CenturionSpider.NIF"] = {v3(-0, -0, 36.548828125), v3(104.373046875, 97.685546875, 73.09765625)},
["meshes\\r\\CliffRacer.NIF"] = {v3(-0.65771484375, -4.46435546875, 233.2666015625), v3(163.5576171875, 130.5625, 235.56640625)},
["meshes\\r\\Daedroth.NIF"] = {v3(-0, -0, 63.0009765625), v3(55.6318359375, 112.23046875, 126.349609375)},
["meshes\\r\\Dremora.NIF"] = {v3(-0, -0, 63.0009765625), v3(55.6318359375, 54.1123046875, 126.349609375)},
["meshes\\r\\DwarvenSpecter.NIF"] = {v3(-0, -0, 59.67578125), v3(52.7041015625, 51.263671875, 119.69921875)},
["meshes\\r\\Atronach_Fire.NIF"] = {v3(-2.17333984375, 0.13720703125, 69.89453125), v3(76.416015625, 62.8037109375, 139.7890625)},
["meshes\\r\\Atronach_Frost.NIF"] = {v3(-3.87060546875, 5.912109375, 78.4599609375), v3(86.8017578125, 68.0322265625, 157.6171875)},
["meshes\\r\\Kwama Forager.NIF"] = {v3(-0, -0, 21.8046875), v3(24.0654296875, 55.828125, 43.634765625)},
["meshes\\r\\Lame_Corprus.NIF"] = {v3(0.5048828125, -2.751953125, 61.0810546875), v3(71.5234375, 68.0263671875, 122.509765625)},
["meshes\\r\\Clannfear_Daddy.NIF"] = {v3(-0, 13.3349609375, 97.69921875), v3(101.0341796875, 121.294921875, 197.857421875)},
["meshes\\r\\Steam_Centurions.NIF"] = {v3(-0.873046875, 13.58251953125, 64.47265625), v3(74.88671875, 67.0751953125, 129.642578125)},
["meshes\\r\\Atronach_Storm.NIF"] = {v3(3.886962890625, -4.462890625, 78.80859375), v3(75.84716796875, 72.3857421875, 157.6171875)},
["meshes\\r\\Rust rat.NIF"] = {v3(-0, -0, 29.6513671875), v3(44.232421875, 119.6025390625, 59.302734375)},
["meshes\\r\\Hunger.NIF"] = {v3(-0, -0, 50.9423828125), v3(55.76953125, 151.587890625, 101.884765625)},
["meshes\\r\\AscendedSleeper.NIF"] = {v3(1.442138671875, 5.060546875, 67.5361328125), v3(91.40185546875, 119.63671875, 135.419921875)},
["meshes\\r\\AshVampire.NIF"] = {v3(-0, -0, 80.4033203125), v3(58.5595703125, 56.9599609375, 160.345703125)},
["meshes\\r\\BYagram.NIF"] = {v3(-0, -0, 57.904296875), v3(136.689453125, 121.3251953125, 115.80859375)},


}





customScales = {
["meshes\\r\\Clannfear_Daddy.NIF"] = 0.2,
["meshes\\r\\AshVampire.NIF"] = 0.1,
["meshes\\r\\Dagothr.NIF"] = 0.1,
["meshes\\r\\CaveMudcrab.NIF"] = 0.1,
["meshes\\r\\CliffRacer.NIF"] = -0.1,
["meshes\\r\\BoneLord.NIF"] = 0.1,
["meshes\\r\\Dreugh.NIF"] = 0.1,
["meshes\\r\\Guar_withpack.NIF"] = 0.1,
["meshes\\r\\Bonewalker.NIF"] = 0.1,
["meshes\\r\\Guar.NIF"] = 0.1,


}

modelBlacklist = {
["meshes\\Sky\\r\\Sky_Chickadee_01.NIF"] = true,
["meshes\\Sky\\r\\Sky_Goldfinch_01.NIF"] = true,
["meshes\\Sky\\r\\Sky_Goldfinch_02.NIF"] = true,
["meshes\\Sky\\r\\Sky_Robin_01.NIF"] = true,
["meshes\\pc\\cr\\PC_Seagull_01.NIF"] = true,
["meshes\\Sky\\r\\Sky_Sparrow_01.NIF"] = true,
["meshes\\Sky\\r\\Sky_Sparrow_02.NIF"] = true,
["meshes\\tr\\cr\\tr_dummy_actor_01.nif"] = true,
["meshes\\td\\td_help_deprec_01.nif"] = true,
}
checkedModels = {
}
--for a,b in pairs(customHeights) do
--	checkedModels[a] = true
--end
for a,b in pairs(modelBlacklist) do
	checkedModels[a] = true
end

if computeBoundingBoxes then
	require("scripts.computeBoundingBoxes")
end

--local inProgress = {}
local barCache = {}
local AI_DB = {}
--raytracing
local raytracing = {}
local nextRay = nil
local raysPerTick = 1
-- Textures
local foreground = ui.texture { path = "textures/HPBARS_Bar.dds" }
local background = ui.texture { path = 'black' }
local numTex = {}
for i=0,9 do
	numTex[""..i] = ui.texture { path = "textures/num/"..i..".dds" }
end
numTex["/"] = ui.texture { path = "textures/num/slash.dds" }
local numWidth = {
	["0"] = 47,
	["1"] = 40,
	["2"] = 55,
	["3"] = 49,
	["4"] = 53,
	["5"] = 45,
	["6"] = 48,
	["7"] = 51,
	["8"] = 50,
	["9"] = 47,
	["/"] = 52,
}
local buffCache = {}
local iconCache = {}
local nextBuffUpdate = nil
local queueSettingsChange = {}
local activeBars = {}
local stylizedCache = {}
stylizedBars = {
	["stylized 1"] = {
		path = "1",
		start = 67,
		["end"] = 1690,
		width = 1757,
		height = 147,
		deco=false,
	},
	["stylized 2"] = {
		path = "4",
		start = 91,
		["end"] = 1720,
		width = 1812,
		height = 137,
		deco=true,
	},
	["stylized 3"] = {
		path = "8",
		start = 65,
		["end"] = 1691,
		width = 1830,
		height = 56,
		deco=false,
	},
	["stylized 4"] = {
		path = "9",
		start = 56,
		["end"] = 1752,
		width = 1808,
		height = 120,
		deco=false,
	},
}
I.Settings.registerGroup {
    key = "SettingsPlayerHPBars",
    page = "HPBars",
    l10n = "HPBars",
    name = "HPBars",
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "OWN_BAR",
			renderer = "checkbox",
			name = "Own bar",
			description = "Show your own healthbar (in 3rd person)",
			default = false,
		},
		{
			key = "ONLY_IN_COMBAT",
			name = "Only Render Bars For Actors In Combat",
			description = "Only shows bars for actors with with a weapon or spell readied (works for creatures too)",
			default = true, 
			renderer = "checkbox",
		},
		{
			key = "MAX_DISTANCE",
			name = "Max Distance",
			description = "Disables HP bars for actors that are further away than this",
			min = 100,
			default = 1500, 
			renderer = "number",
		},
		{
			key = "RAYTRACING",
			name = "Occlusion Detection",
			description = "Hide healthbars for actors that are occluded",
			default = true, 
			renderer = "checkbox",
		},
		{
			key = "LAGBAR",
			renderer = "checkbox",
			name = "Lag-Bar",
			description = "Visualizes recent damage taken",
			default = true,
		},
		{
			key = "HEALBAR",
			renderer = "checkbox",
			name = "Enemy healbar",
			description = "Visualizes incoming enemy healing",
			default = true,
		},
		{
			key = "HPTEXT",
			name = "HP Numbers",
			description = "choose what text should be displayed on the bar",
			default = "HP/MaxHP", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"none", "HP", "HP/MaxHP"},
			},
		},
		{
			key = "LEVEL",
			name = "Level number",
			description = "show the actor's level",
			default = "color-coded", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"hidden", "white", "gray", "bar-color", "color-coded"},
			},
		},
		{
			key = "LEVELTEXT_SIZE",
			name = "Level Number size",
			description = "percentage of bar height, 0-1",
			renderer = "number",
			max = 0.1,
			min = 1,
			default = 0.8,
		},
		
		{
			key = "BUFFS",
			name = "Buffs & Debuffs",
			description = "small performance hit",
			renderer = "checkbox",
			default = true,
		},
		{
			key = "BUFF_ICONSIZE",
			name = "Buff IconSize",
			description = "",
			renderer = "number",
			max = 0.1,
			min = 1,
			default = 1,
		},
		{
			key = "ANCHOR",
			name = "Bar anchor",
			description = "",
			default = "head", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"feet", "head"},
			},
		},
		{
			key = "OFFSET_X",
			name = "Offset X",
			description = "Moves the bars left or right",
			default = 0, 
			renderer = "number",
		},
		{
			key = "OFFSET_Y",
			name = "Offset Y",
			description = "Moves the bars up or down",
			default = -15, 
			renderer = "number",
		},
		{
			key = "LERPSPEED",
			name = "Animation Speed",
			description = "How fast the bars are animated, for example on physical damage taken",
			default = 128,
			min = 1,
			renderer = "number",
		},
		{
			key = "LAGDURATION",
			name = "Damage Taken Visualizer Duration",
			description = "For how long the red bar will indicate recently taken damage",
			default = 0.7, 
			min = 0.1,
			renderer = "number",
		},
		{
			key = "SCALE",
			name = "HP Bars Scale",
			description = "Multiplier on the final bar scale (after distance scaling)",
			default = 0.9,
			min = 0.1,
			renderer = "number",
		},
		{
			key = "BORDER_STYLE",
			name = "Border style",
			description = "max performance disables the transparency changing of the borders (which is in 0.1 steps), but then the bars will look less natural in the distance",
			default = "normal", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"none", "max performance", "normal"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "BORDER_COLOR",
			name = "Color Borders",
			description = "colors the borders based on ..",
			default = "default", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"default", "relative level", "reaction"}--,"stylized 1", "stylized 2", "stylized 3", "stylized 4"},
			},
		},
		{
			key = "COLOR_PRESET",
			name = "Color Preset",
			description = "the 'dynamic' preset only overwrites hp bar colors, you can still change damage and healing colors",
			default = "Y/T/B/R/G  ", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Y/T/B/R/G  ", "O/T/B/R/G  ", "R/T/B/W/G ", "O/Y2/B/W/G","O/Y/B/R/G  ","O/B/R/G    "},
			},
		},
		{
			key = "HOSTILE_COL",
			name = "Hostile HP Bar Color",
			description = "Health color for actors that are attacking you.",
			disabled = false,
			--default = util.color.hex("9a5e3a"), --tan (unused)
			--default =  util.color.hex("c5a15e"), --paper
			--default =  util.color.hex("b55500"), --orange
			default =  util.color.hex("a00004"),
			--default =  util.color.hex("a00004"), --red
			renderer = "color",
		},
		{
			key = "HOSTILE_DAMAGED_COL",
			name = "Hostile+Damaged HP Bar Color",
			description = "Health color at 0 HP for actors that are attacking you.",
			disabled = false,
			--default = util.color.hex("9a5e3a"), --tan (unused)
			--default =  util.color.hex("c5a15e"), --paper
			--default =  util.color.hex("b55500"), --orange
			default =  util.color.hex("300004"), --yellow
			--default =  util.color.hex("a00004"), --red
			renderer = "color",
		},
		{
			key = "NEUTRAL_COL",
			name = "Neutral HP Bar Color",
			description = "Health color for normal actors",
			disabled = false,
			--default = util.color.hex("9a5e3a"), --tan (unused)
			--default =  util.color.hex("c5a15e"), --paper
			--default =  util.color.hex("b55500"), --orange
			default =  util.color.hex("ccbb00"), --yellow
			--default =  util.color.hex("a00004"), --red
			renderer = "color",
		},
		{
			key = "NEUTRAL_DAMAGED_COL",
			name = "Neutral+Damaged HP Bar Color",
			description = "Health color at 0 HP for normal actors.",
			disabled = false,
			--default = util.color.hex("9a5e3a"), --tan (unused)
			--default =  util.color.hex("c5a15e"), --paper
			--default =  util.color.hex("b55500"), --orange
			default =  util.color.hex("a00004"), --yellow
			--default =  util.color.hex("a00004"), --red
			renderer = "color",
		},
		{
			key = "ALLY_COL",
			name = "Allied HP Bar Color",
			description = "Allied Health color",
			disabled = false,
			default =  util.color.hex("1263b0"), --blue
			--default =  util.color.hex("999999"), --gray-white
			--default =  util.color.hex("ccbb00"), --yellow
			renderer = "color",
		},
		{
			key = "ALLY_DAMAGED_COL",
			name = "Allied+Damaged HP Bar Color",
			description = "Health color at 0 HP for allied actors.",
			disabled = false,
			default =  util.color.hex("1263b0"), --blue
			--default =  util.color.hex("999999"), --gray-white
			--default =  util.color.hex("ccbb00"), --yellow
			renderer = "color",
		},
		{
			key = "DAMAGE_COL",
			name = "Damage Color",
			description = "'Lag-Bar' color",
			disabled = false,
			default =  util.color.hex("a00004"), --red
			--default =  util.color.hex("a00004"), --red
			--default =  util.color.hex("b7b7b7"), --white
			renderer = "color",
		},
		{
			key = "HEAL_COL",
			name = "Healing Color",
			description = "Color of incoming healing",
			disabled = false,
			default = util.color.hex("3ca01e"), --green
			renderer = "color",
		},

	}
}

I.Settings.registerPage {
    key = "HPBars",
    l10n = "HPBars",
    name = 'HPBars',
    description = 'Floating Healthbars'
}
local containerContent = {}
local container = {	
	type = ui.TYPE.Container,
	layer = 'HUD',
	content = ui.content(containerContent)
}
local hud = ui.create(container)

local function hdTexPath(str)
	--print(str)
	local newPath = str:gsub("icons\\s\\", "textures\\icons\\")
	if(vfs.fileExists(newPath)) then
		return newPath
	end
	return str
end

function vfx(pos)
	local effect = core.magic.effects.records[9]
	core.vfx.spawn(effect.castStatic, pos)
end

local function unpack(v3)
	return v3.x,v3.y,v3.z
end

local function ownlysLag(current, lerped, cached, paused, lag, timer, dt, drainSpeed, timerLength, treshold)
	local mult = drainSpeed/8
	if current > lerped then
		lerped = math.min(current,lerped*(1-dt*mult) + current*dt*mult)
	else
		lerped = math.max(current,lerped*(1-dt*mult) + current*dt*mult)
	end
	--lerped = math.max(current,lerped - dt * drainSpeed)
	if current > paused then
		paused = current
	end
	if current > lag then
		lag = lerped
	end
	if current < cached -treshold then 
		timer = 0
	else
		timer = timer + dt 
	end
	if timer > timerLength then
		paused = current
	end
	if lag > paused  then 
		lag = math.max(paused,lag - dt * drainSpeed)
	end
	return paused, lag, timer, lerped
end

function calculateHealing(actor)
	local timeBand = 3
	local incomingHealing = 0
	for a,b in pairs(types.Actor.activeSpells(actor)) do
		for c,d in pairs(b.effects) do
			if d.id == "restorehealth" then --and d.durationlLeft then -- should permanent effects count? let's say yes
				local duration = math.max(0,math.min(timeBand,d.durationLeft or timeBand))
				incomingHealing= incomingHealing +(d.maxMagnitude+d.minMagnitude)/2*duration
			end
		end
	end
	return incomingHealing
end

local function texText(currentHealth,maxHealth,size,color, widgetWidth, widgetHeight, align)
	widgetWidth = widgetWidth or 50
	widgetHeight = widgetHeight or 7
	
	local str = ""..math.floor(currentHealth)
	if playerSettings:get("HPTEXT") ~= "HP" and maxHealth then
		str = str.."/"..math.floor(maxHealth)
	end
	local ret = {}
	local totalWidth = 0
	local height = size or 0.85
	local middleOffset = 0
	for i=1, #str do
		local symbol = str:sub(i,i)
		if numTex[symbol] and numWidth[symbol] then
			local width = widgetHeight/80*numWidth[symbol]/widgetWidth*height
			if symbol =="/" then
				middleOffset = totalWidth+width/2
			end
			totalWidth = totalWidth+width*1.15
		end
	end
	if middleOffset > 0 then
		middleOffset = totalWidth/2-middleOffset
	end
	local currentPos = 0.5-totalWidth/2+middleOffset
	if align =="left" then
		currentPos = 0
	end
	for i=1, #str do
		local symbol = str:sub(i,i)
		if numTex[symbol] and numWidth[symbol] then
			local width = widgetHeight/80*numWidth[symbol]/widgetWidth*height
			table.insert(ret,{
				type = ui.TYPE.Image,
				props = {
					resource = numTex[symbol],
					relativePosition= v2(currentPos,(1-height)/2),
					relativeSize  = v2(width*1.2,height),
					color = color,
				}
			} )
			--print(symbol,width*5)
			currentPos = currentPos + width*1.15
		end
	end
	return ret
end

local function shortestBuff(actor)
	local shortest =9000
	for a,b in pairs(types.Actor.activeSpells(actor)) do
		--if ( b.caster ~=actor) then
			for c,d in pairs(b.effects) do
				if (d.duration) then
					shortest = math.min(shortest,d.duration)
				end
			end
		--end
	end
	--for a,b in pairs(types.Actor.activeSpells(actor)) do
	--	if (b.caster ==actor) then
	--		for c,d in pairs(b.effects) do
	--			if (d.duration) then
	--				shortest = math.min(shortest,d.durationLeft)
	--			end
	--		end
	--	end
	--end
	--print(shortest)
	return shortest~=9000 and shortest
end


local function updateBuffIcons(c)
	local actor = c.actor
	local isntPlayer = c.actor ~= self.object
	local content = {}
	local i = 0
	local iconSize = math.min(1.1,playerSettings:get("BUFF_ICONSIZE"))*0.5
	local width = iconSize*7/50
	--if not buffCache[actor.id] then
		--buffCache[actor.id] = {buffs={}, debuffs={}}
	local buffCount = 0
	local debuffCount = 0
	buffs = {}
	debuffs = {}
	for a,b in pairs(types.Actor.activeSpells(actor)) do
		for c,d in pairs(b.effects) do
			if (d.duration) then
				local icon = core.magic.effects.records[d.id].icon
				if not iconCache[icon] then
					iconCache[icon] =  ui.texture { path = hdTexPath(icon) }
				end
				if isntPlayer == ( b.caster ==actor) then
					table.insert(buffs,{icon,d.durationLeft/d.duration})
					buffCount=buffCount+1
				else
					table.insert(debuffs,{icon,d.durationLeft/d.duration})
					debuffCount=debuffCount+1
				end
			end
		end
	end
	local multSizes = 1
	if width*(buffCount+debuffCount) > 0.5 then
		multSizes = 0.5/(width*(buffCount+debuffCount))
	end
	if (buffCount+debuffCount) > 0 or #c.bar.layout.content[1].layout.content[4].layout.content > 0 then
		buffCount = 0
		debuffCount = 0
		for a,b in pairs(buffs) do
			buffCount=buffCount+1
			table.insert(content,{
				type = ui.TYPE.Image,
				props = {
					resource = iconCache[b[1]],
					relativePosition= v2(0.5-buffCount*width*multSizes,0.5-iconSize*multSizes),
					relativeSize  = v2(width*multSizes*1.007,iconSize*multSizes*1.007),
					alpha = b[2],
				}
			} )
		end
		for a,b in pairs(debuffs) do
			table.insert(content,{
				type = ui.TYPE.Image,
				props = {
					resource = iconCache[b[1]],
					relativePosition= v2(debuffCount*width*multSizes,0.5-iconSize*multSizes),
					relativeSize  = v2(width*multSizes*1.007,iconSize*multSizes*1.007),
					alpha = b[2],
				}
			} )
			debuffCount=debuffCount+1
		end
		
		c.bar.layout.content[1].layout.content[4].layout.content = ui.content (content)
		c.bar.layout.content[1].layout.content[4]:update()
	end
end

local function update(c,currentHealth,maxHealth,sizeMult)
	local now = core.getSimulationTime()
	local level = nil
	local levelColor = nil
	local borderColor = nil
	local healthPct = math.min(1,currentHealth/maxHealth)
	local t

	local HOSTILE_COL =  util.color.rgb(unpack(playerSettings:get("HOSTILE_COL"):asRgb()*healthPct+playerSettings:get("HOSTILE_DAMAGED_COL"):asRgb()*(1-healthPct)))
	local NEUTRAL_COL = util.color.rgb(unpack(playerSettings:get("NEUTRAL_COL"):asRgb()*healthPct+playerSettings:get("NEUTRAL_DAMAGED_COL"):asRgb()*(1-healthPct)))
	local ALLY_HPBAR_COL = util.color.rgb(unpack(playerSettings:get("ALLY_COL"):asRgb()*healthPct+playerSettings:get("ALLY_DAMAGED_COL"):asRgb()*(1-healthPct)))
	local DAMAGE_COL = playerSettings:get("DAMAGE_COL")
	local HEAL_COL = playerSettings:get("HEAL_COL")
	local actorAI = AI_DB[c.actor.id]
	local isAlly = (types.Player.objectIsInstance(c.actor) or 
					actorAI and ( 
						actorAI.Follow and not actorAI.Combat or 
						actorAI.Follow and actorAI.Combat and actorAI.Combat < actorAI.Follow -1 
					)) == true
	local aggro = (not types.Player.objectIsInstance(c.actor) and actorAI and actorAI.Combat and actorAI.Combat > now-0.6) == true
	local reaction = aggro and "hostile" or isAlly and "ally" or "neutral"
	--print(reaction)
	if aggro then
		HPBAR_COL = HOSTILE_COL
	elseif isAlly then
		HPBAR_COL = ALLY_HPBAR_COL
	else
		HPBAR_COL = NEUTRAL_COL
	end
	if c.reactionCache == nil then c.reactionCache = reaction end
	if (playerSettings:get("LEVEL") ~= "hidden" or playerSettings:get("BORDER_COLOR") == "relative level") and c.actor ~= self.object then
		level = types.Actor.stats.level(c.actor).current
		if playerSettings:get("LEVEL") == "color-coded" or playerSettings:get("BORDER_COLOR") == "relative level" then
			local playerLevel = types.Actor.stats.level(self).current
			local r = math.max(0,math.min(1,1-(playerLevel-level)/8))
			local g = math.max(0,math.min(1,1-(level-playerLevel)/8))
			levelColor = util.color.rgb(r,g,0)
			if playerSettings:get("BORDER_COLOR") == "relative level" then
				borderColor = util.color.rgb(r,g,0)
			end
		elseif playerSettings:get("LEVEL") == "gray" then
			levelColor = util.color.rgb(0.75,0.75,0.75)
		elseif playerSettings:get("LEVEL") == "bar-color" then
			levelColor = HPBAR_COL
		end
	end
	if playerSettings:get("BORDER_COLOR") == "reaction" then
		
		if AI_DB[c.actor.id] and AI_DB[c.actor.id].Combat and AI_DB[c.actor.id].Combat > now-0.5 then
			borderColor = util.color.rgb(0.8,0.1,0.1)
		end
	end
	
	local incomingHealing = calculateHealing(c.actor)
	local template = stylizedBars[playerSettings:get("BORDER_STYLE")]
	if not c.bar then
		local borderTemplate = I.MWUI.templates.borders
		if borderColor then
			borderTemplate = makeBorder('thin',borderColor).borders
		end
		c.bar = 
			ui.create({	--root
				type = ui.TYPE.Widget,
				layer = 'HUD',
				props = {
					position = v2(65,10),
					size = v2(100*sizeMult+2,14*sizeMult+2),
					anchor = v2(0.25,1),
				},
				content = ui.content {
					ui.create({ --r.1
						type = ui.TYPE.Widget,
						props = {relativeSize  = v2(1,1)},
						content = ui.content {
							ui.create({ --r.1.1
								type = ui.TYPE.Widget,
								props = {relativeSize  = v2(1,1)},
								content = ui.content ({
									{
										type = ui.TYPE.Image,
										props = {
											resource = background,
											tileH = false,
											tileV = false,
											relativePosition= v2(0,0.5),
											position=v2(1,1),
											size = v2(-2,-2),
											relativeSize  = v2(0.999/2,0.499),
											alpha = 0.6,
										},
									},
									playerSettings:get("BORDER_STYLE")~="none" and 
									{ -- Border
										template = borderTemplate,
										props = {
											relativeSize  = v2(1/2,0.5),
											size = v2(1,0),
											alpha = 0.5,
											relativePosition= v2(0,0.5),
										}
									} or {},
								})
							}),
							ui.create({-- r.1.2
								type = ui.TYPE.Widget,
								props = {relativeSize  = v2(1,1)},
								content = ui.content {
									playerSettings:get("LAGBAR") and { -- Damage Bar r.1.2/1
										type = ui.TYPE.Image,
										props = {
											resource = foreground,
											relativePosition= v2(0,0.5),
											tileH = true,
											tileV = false,
											color =  DAMAGE_COL,
											position = v2(1, 1),
											size = v2(-2,-3),
											relativeSize  = v2(c.healthLag/maxHealth/2,0.5)
										}
									} or {},
									{ -- HP Bar r.1.2/2
										type = ui.TYPE.Image,
										props = {
											resource = foreground,
											tileH = false,
											tileV = false,
											color = HPBAR_COL,
											position = v2(1, 1),
											size = v2(-2,-3),
											relativeSize  = v2(c.lerpHealth/maxHealth/2,0.5),
											relativePosition= v2(0,0.5),
										},
									},
									{ -- Healing r.1.2/3
										type = ui.TYPE.Image,
										props = {
											resource = foreground,
											tileH = true,
											tileV = false,
											color =  HEAL_COL,
											alpha = 0.45,
											position = v2(-1,1),
											size = v2(0,-2),
											relativePosition= v2(0,0.5),
										}
									},
								},
							}),
							playerSettings:get("HPTEXT") ~= "none" and ui.create({ -- HP Numbers r.1.3
								type = ui.TYPE.Widget,
								props = {
									relativeSize  = v2(0.5,0.5),
									relativePosition = v2(0,0.5),
									--visible = false,
								},
								content = ui.content (texText(currentHealth,maxHealth))
							}) or {},
							playerSettings:get("BUFFS") and ui.create({ -- MGEF r.1.4
								type = ui.TYPE.Widget,
								props = {
									relativeSize  = v2(1,1),
									--visible = false,
								},
								content = ui.content ({})
							}) or {},
							playerSettings:get("LEVEL") ~= "hidden" and c.actor ~= self.object and ui.create({ -- level
								type = ui.TYPE.Widget,
								props = {
									relativeSize  = v2(0.1,0.5),
									relativePosition = v2(0.52,0.5)
									--visible = false,
								},
								content = ui.content (texText(level,nil,playerSettings:get("LEVELTEXT_SIZE"),levelColor,10,7,"left"))
							}) or {},
						}
					})
				}
			})
	else
		--c.bar.layout.content[1].layout.content[4].layout.content = ui.content (buffIcons(c.actor))
		local updateLevel = false
		local updateBorders = false
		local targetBorderAlpha = math.max(0.1,math.min(0.71,sizeMult/3))
		if playerSettings:get("BORDER_STYLE")=="normal" and math.abs(targetBorderAlpha-c.cachedBorderAlpha) >= 0.1 then
			updateBorders = true
			--print("-----------")
		end
		
		if playerSettings:get("HPTEXT") ~= "none" and (sizeMult>1 and math.floor(c.cachedHealth)~=math.floor(currentHealth) or (sizeMult>1 ~=c.textVisible)) then
			c.bar.layout.content[1].layout.content[3].layout.content = ui.content (texText(currentHealth,maxHealth))
			c.textVisible = sizeMult>1
			c.bar.layout.content[1].layout.content[3].layout.props.visible = c.textVisible
			c.bar.layout.content[1].layout.content[3]:update()
			--print("-----")
		end
		
		local updateBars = false
		if math.abs(c.cachedLerpHealth - c.lerpHealth)/maxHealth >= 1/(50 *sizeMult) then
			updateBars = true
			updateLevel = true
		end
		if c.reactionCache ~=reaction then
			--print(reaction,c.reactionCache)
			updateBars = true
			if playerSettings:get("BORDER_COLOR") == "reaction" then
				updateBorders = true
			end
			updateLevel = true
		end
		if playerSettings:get("LAGBAR") and math.abs(c.cachedHealthLag -c.healthLag) / maxHealth >= 1/(50 *sizeMult) then
			updateBars = true
		end
		if (playerSettings:get("HEALBAR") or isAlly or not isAlly and c.cachedIncomingHealing > 0) and math.abs(c.cachedIncomingHealing - incomingHealing) / maxHealth >= 1/(50 *sizeMult) then
			updateBars = true
		end
		
		if updateLevel and playerSettings:get("LEVEL") == "bar-color" then
			c.bar.layout.content[1].layout.content[5].layout.content = ui.content (texText(level,nil,playerSettings:get("LEVELTEXT_SIZE"),levelColor,10,7,"left"))
			c.bar.layout.content[1].layout.content[5]:update()
		end
		
		if updateBorders then
			if playerSettings:get("BORDER_COLOR") == "reaction" then
				local borderColor = nil
				if aggro then
					borderColor = util.color.rgb(0.8,0.1,0.1)
				end
				local borderTemplate = makeBorder('thin',borderColor).borders
				c.bar.layout.content[1].layout.content[1].layout.content[2].template = borderTemplate
				c.reactionCache = reaction
			end
			if playerSettings:get("BORDER_STYLE")=="normal" then
				c.cachedBorderAlpha = math.floor(targetBorderAlpha*10)/10
				c.bar.layout.content[1].layout.content[1].layout.content[2].props.alpha = c.cachedBorderAlpha
			end
			c.bar.layout.content[1].layout.content[1]:update()
		end
		
		if updateBars then
			if math.abs(1-c.lerpHealth/maxHealth) <= 1/(50 *sizeMult) then
				c.bar.layout.content[1].layout.content[2].layout.content[2].props.relativeSize  = v2(1/2,0.5)
			else
				c.bar.layout.content[1].layout.content[2].layout.content[2].props.relativeSize  = v2(c.lerpHealth/maxHealth/2,0.5)
				--c.bar.layout.content[1].layout.content[2].layout.content[2].props.resource = ui.texture{ path = "textures\\hpbars\\"..template.path.."\\fill.dds", size = v2(c.lerpHealth/maxHealth*template.width,template.height)}
			end
			c.cachedLerpHealth = c.lerpHealth
			if playerSettings:get("COLOR_PRESET") == "dynamic1" then
				c.bar.layout.content[1].layout.content[2].layout.content[2].props.color = HPBAR_COL
			end
			
			c.bar.layout.content[1].layout.content[2].layout.content[2].props.color = HPBAR_COL
			c.reactionCache = reaction
			if playerSettings:get("LAGBAR") then
				if math.abs((c.healthLag-c.lerpHealth)/maxHealth) <= 1/(50 *sizeMult) then
					c.bar.layout.content[1].layout.content[2].layout.content[1].props.relativeSize  = v2(c.lerpHealth/maxHealth/2,0.5)
					c.cachedHealthLag = c.lerpHealth
				else
					c.bar.layout.content[1].layout.content[2].layout.content[1].props.relativeSize  = v2(c.healthLag/maxHealth/2,0.5)
					c.cachedHealthLag = c.healthLag
				end
			end
			
			if (playerSettings:get("HEALBAR") or isAlly or not isAlly and c.cachedIncomingHealing > 0) then
				if not playerSettings:get("HEALBAR") and not isAlly and c.cachedIncomingHealing > 0 then
					c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativeSize  = v2(0,0)
					c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativePosition = v2(0,0.5)
					c.cachedIncomingHealing = 0
				else
					if math.abs((incomingHealing+currentHealth-c.cachedLerpHealth)/maxHealth) <= 1/(50 *sizeMult) then
						c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativeSize  = v2(0,0.5)
						c.cachedIncomingHealing = incomingHealing
					else
						c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativeSize  = v2((incomingHealing+currentHealth-c.cachedLerpHealth)/maxHealth/2,0.5)
						c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativePosition = v2(c.cachedLerpHealth/maxHealth/2,0.5)
						c.cachedIncomingHealing = incomingHealing
					end
				end
			end
			--print("---")
			c.bar.layout.content[1].layout.content[2]:update()
		end
	end
end

-- UNUSED RN
local function updateStylized(c,currentHealth,maxHealth,sizeMult)
	local HPBAR_COL = playerSettings:get("HPBAR_COL")
	local ALLY_HPBAR_COL = playerSettings:get("ALLY_HPBAR_COL")
	local DAMAGE_COL = playerSettings:get("DAMAGE_COL")
	local HEAL_COL = playerSettings:get("HEAL_COL")
	if playerSettings:get("COLOR_PRESET") == "dynamic1" then
		HPBAR_COL = util.color.rgb(204/255,(42+145*currentHealth/maxHealth)/255,0/255)
		ALLY_HPBAR_COL = util.color.rgb((18+155*(1-currentHealth/maxHealth))/255,99/255,(100+76*currentHealth/maxHealth)/255)
		--DAMAGE_COL=util.color.hex("a00004")
		--HEAL_COL=util.color.hex("3ca01e")
	end
	local actorAI = AI_DB[c.actor.id]
	local isAlly = (types.Player.objectIsInstance(c.actor) or 
					actorAI and ( 
						actorAI.Follow and not actorAI.Combat or 
						actorAI.Follow and actorAI.Combat and actorAI.Combat < actorAI.Follow -1 
					)) == true
	
	if isAlly then
		HPBAR_COL = ALLY_HPBAR_COL
	end
	if c.allyCache == nil then c.allyCache = isAlly end
	local incomingHealing = calculateHealing(c.actor)
	local template = stylizedBars[playerSettings:get("BORDER_STYLE")]
	for i=1,100 do
		--test = ui.texture{path = "textures\\hpbars\\"..template.path.."\\fill.dds", size = v2(math.random(1000),math.random(1000))}
	end
	if not c.bar then
		--print("create")
		local bg = {}
		if template then
			--[[
			["stylized 1"] = {
				path = "1",
				start = 67,
				end = 1690,
				width = 1757,
				height = 147,
				deco=false,
			},]]
			foreground = ui.texture{path = "textures\\hpbars\\"..template.path.."\\fill.dds"}
			local texPath = "textures\\hpbars\\"..template.path.."\\bg.dds"
			if not stylizedCache[texPath] then
				stylizedCache[texPath] = ui.texture{path = texPath}
			end
			table.insert(bg, {
				type = ui.TYPE.Image,
				props = {
					resource = stylizedCache[texPath],
					tileH = false,
					tileV = false,
					relativePosition= v2(0,0.5),
					position=v2(1,1),
					size = v2(-2,-2),
					relativeSize  = v2(0.999/2,0.499*template.height/template.width*50/7*1.4),
					alpha = 0.6,
				}
			})
			if template.deco then
				local texPath = "textures\\hpbars\\"..template.path.."\\deco.dds"
				if not stylizedCache[texPath] then
					stylizedCache[texPath] = ui.texture{path = texPath}
				end
				table.insert(bg, {
					type = ui.TYPE.Image,
					props = {
						resource = stylizedCache[texPath],
						tileH = false,
						tileV = false,
						relativePosition= v2(0,0.5),
						position=v2(1,1),
						size = v2(-2,-2),
						relativeSize  = v2(0.999/2,0.499*template.height/template.width*50/7*1.5),
						alpha = 0.6,
					}
				})
			end
		else
			table.insert(bg, {
				type = ui.TYPE.Image,
				props = {
					resource = background,
					tileH = false,
					tileV = false,
					relativePosition= v2(0,0.5),
					position=v2(1,1),
					size = v2(-2,-2),
					relativeSize  = v2(0.999/2,0.499),
					alpha = 0.6,
				}
			})
			if playerSettings:get("BORDER_STYLE")~="none" then
				table.insert(bg, {
					template = I.MWUI.templates.borders,
					props = {
						relativeSize  = v2(1/2,0.5),
						size = v2(1,0),
						alpha = 0.5,
						relativePosition= v2(0,0.5),
					}
				})
			end
		end
		c.bar = 
			ui.create({	--root
				type = ui.TYPE.Widget,
				layer = 'HUD',
				props = {
					position = v2(65,10),
					size = v2(100*sizeMult+2,14*sizeMult+2)
				},
				content = ui.content {
					ui.create({ --r.1
						type = ui.TYPE.Widget,
						props = {relativeSize  = v2(1,1)},
						content = ui.content {
							ui.create({ --r.1.1
								type = ui.TYPE.Widget,
								props = {relativeSize  = v2(1,1)},
								content = ui.content (bg)
							}),
							ui.create({-- r.1.2
								type = ui.TYPE.Widget,
								props = {relativeSize  = v2(1,1)},
								content = ui.content {
									playerSettings:get("LAGBAR") and { -- Damage Bar r.1.2/1
										type = ui.TYPE.Image,
										props = {
											resource = foreground,
											relativePosition= v2(0,0.5),
											tileH = true,
											tileV = false,
											color =  DAMAGE_COL,
											position = v2(1, 1),
											size = v2(-2,-3),
											relativeSize  = v2(c.healthLag/maxHealth/2,0.5)
										}
									} or {},
									{ -- HP Bar r.1.2/2
										type = ui.TYPE.Image,
										props = {
											resource = foreground,
											tileH = false,
											tileV = false,
											color = HPBAR_COL,
											position = v2(1, 1),
											size = v2(-2,-3),
											relativeSize  = v2(0.999/2,0.499*template.height/template.width*50/7*1.4),
											relativePosition= v2(0,0.5),
										},
									},
									{ -- Healing r.1.2/3
										type = ui.TYPE.Image,
										props = {
											resource = foreground,
											tileH = true,
											tileV = false,
											color =  HEAL_COL,
											alpha = 0.45,
											position = v2(-1,1),
											size = v2(0,-2),
											relativePosition= v2(0,0.5),
										}
									},
								},
							}),
							playerSettings:get("HPTEXT") ~= "none" and ui.create({ -- HP Numbers r.1.3
								type = ui.TYPE.Widget,
								props = {
									relativeSize  = v2(1,1),
									--visible = false,
								},
								content = ui.content (texText(currentHealth,maxHealth))
							}) or {},
							playerSettings:get("BUFFS") and ui.create({ -- MGEF r.1.4
								type = ui.TYPE.Widget,
								props = {
									relativeSize  = v2(1,1),
									--visible = false,
								},
								content = ui.content ({})
							}) or {},
						}
					})
				}
			})
	else
		--c.bar.layout.content[1].layout.content[4].layout.content = ui.content (buffIcons(c.actor))
		
		local targetBorderAlpha = math.max(0.1,math.min(0.71,sizeMult/3))
		if playerSettings:get("BORDER_STYLE")=="normal" and math.abs(targetBorderAlpha-c.cachedBorderAlpha) >= 0.1 then
			c.cachedBorderAlpha = math.floor(targetBorderAlpha*10)/10
			c.bar.layout.content[1].layout.content[1].layout.content[2].props.alpha = c.cachedBorderAlpha
			c.bar.layout.content[1].layout.content[1]:update()
			--print("-----------")
		end
		
		if playerSettings:get("HPTEXT") ~= "none" and (sizeMult>1 and math.floor(c.cachedHealth)~=math.floor(currentHealth) or (sizeMult>1 ~=c.textVisible)) then
			c.bar.layout.content[1].layout.content[3].layout.content = ui.content (texText(currentHealth,maxHealth))
			c.textVisible = sizeMult>1
			c.bar.layout.content[1].layout.content[3].layout.props.visible = c.textVisible
			c.bar.layout.content[1].layout.content[3]:update()
			--print("-----")
		end
		
		local updateBars = false
		if math.abs(c.cachedLerpHealth - c.lerpHealth)/maxHealth >= 1/(50 *sizeMult) then
			updateBars = true
		end
		if c.allyCache ~=isAlly then
			updateBars = true
		end
		if playerSettings:get("LAGBAR") and math.abs(c.cachedHealthLag -c.healthLag) / maxHealth >= 1/(50 *sizeMult) then
			updateBars = true
		end
		if (playerSettings:get("HEALBAR") or isAlly or not isAlly and c.cachedIncomingHealing > 0) and math.abs(c.cachedIncomingHealing - incomingHealing) / maxHealth >= 1/(50 *sizeMult) then
			updateBars = true
		end
		
		if updateBars then
			if math.abs(1-c.lerpHealth/maxHealth) <= 1/(50 *sizeMult) then
				c.bar.layout.content[1].layout.content[2].layout.content[2].props.relativeSize  = v2(1/2,0.5)
			else
				c.bar.layout.content[1].layout.content[2].layout.content[2].props.relativeSize  = v2(c.lerpHealth/maxHealth/2,0.5)
				--c.bar.layout.content[1].layout.content[2].layout.content[2].props.resource = ui.texture{ path = "textures\\hpbars\\"..template.path.."\\fill.dds", size = v2(c.lerpHealth/maxHealth*template.width,template.height)}
			end
			c.cachedLerpHealth = c.lerpHealth
			if playerSettings:get("COLOR_PRESET") == "dynamic1" then
				c.bar.layout.content[1].layout.content[2].layout.content[2].props.color = HPBAR_COL
			end
			
			c.bar.layout.content[1].layout.content[2].layout.content[2].props.color = HPBAR_COL
			c.allyCache = isAlly
			if playerSettings:get("LAGBAR") then
				if math.abs((c.healthLag-c.lerpHealth)/maxHealth) <= 1/(50 *sizeMult) then
					c.bar.layout.content[1].layout.content[2].layout.content[1].props.relativeSize  = v2(c.lerpHealth/maxHealth/2,0.5)
					c.cachedHealthLag = c.lerpHealth
				else
					c.bar.layout.content[1].layout.content[2].layout.content[1].props.relativeSize  = v2(c.healthLag/maxHealth/2,0.5)
					c.cachedHealthLag = c.healthLag
				end
			end
			
			if (playerSettings:get("HEALBAR") or isAlly or not isAlly and c.cachedIncomingHealing > 0) then
				if not playerSettings:get("HEALBAR") and not isAlly and c.cachedIncomingHealing > 0 then
					c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativeSize  = v2(0,0)
					c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativePosition = v2(0,0.5)
					c.cachedIncomingHealing = 0
				else
					if math.abs((incomingHealing+currentHealth-c.cachedLerpHealth)/maxHealth) <= 1/(50 *sizeMult) then
						c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativeSize  = v2(0,0.5)
						c.cachedIncomingHealing = incomingHealing
					else
						c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativeSize  = v2((incomingHealing+currentHealth-c.cachedLerpHealth)/maxHealth/2,0.5)
						c.bar.layout.content[1].layout.content[2].layout.content[3].props.relativePosition = v2(c.cachedLerpHealth/maxHealth/2,0.5)
						c.cachedIncomingHealing = incomingHealing
					end
				end
			end
			--print("---")
			c.bar.layout.content[1].layout.content[2]:update()
		end
	end
end


local function onFrame(dt)
	if computeBoundingBoxes then
		computeBoundingBoxes_tick()
	end
	--local heightDB = modData:getCopy("heightDB")
	for a,b in pairs(queueSettingsChange) do
		playerSettings:set(b[1],b[2])
	end
	queueSettingsChange = {}
	local now = core.getRealTime()
	local drainSpeed = playerSettings:get("LERPSPEED")
	local timerLength = playerSettings:get("LAGDURATION")
	local layerId = ui.layers.indexOf("HUD")
	local width = ui.layers[layerId].size.x 
	local screenres = ui.screenSize()
	local uiScale = screenres.x / width
	screenres= screenres:ediv(v2(uiScale,uiScale))
	--local usedThisFrame = {}
	for _,actor in pairs(nearby.actors) do
		--print(actor.id)
		if actor~=self.object or playerSettings:get("OWN_BAR") and camera.getMode() ~= camera.MODE.FirstPerson then
			--print(actor.type)
			local height = false
			local actorRecordId = actor.recordId
			local actorScale = actor.scale
			if not boxCache[actorRecordId] then
				local npcRecord = types.NPC.record(actorRecordId)
				if npcRecord then-- and types.NPC.races.record(npcRecord.race).isBeast then -- somehow beasts have huge bounding boxes
					if npcRecord.isMale then
						boxCache[actorRecordId] = {v3(0,0,types.NPC.races.record(npcRecord.race).height.male*67.5/actorScale),v3(0,0,types.NPC.races.record(npcRecord.race).height.male*67.5/actorScale)}
					else
						boxCache[actorRecordId] = {v3(0,0,types.NPC.races.record(npcRecord.race).height.female*67.5/actorScale),v3(0,0,types.NPC.races.record(npcRecord.race).height.female*67.5/actorScale)}
					end
				else
					--print(actor:getBoundingBox().halfSize)
					local box = actor:getBoundingBox()
					boxCache[actorRecordId] = {box.center:ediv(v3(actorScale,actorScale,actorScale)), box.halfSize:ediv(v3(actorScale,actorScale,actorScale))}
					--print(box.center, box.halfSize)
					--print(boxCache[actorRecordId][1],boxCache[actorRecordId][2])
				end
				--print(actorRecordId, boxCache[actorRecordId])
			end
			--local hugeness = math.log10(boxCache[actorRecordId][2].x*boxCache[actorRecordId][2].y*boxCache[actorRecordId][2].z)
			local actorPos = actor.position
			local barPos = actorPos
			local barOffset=v3(0,0,0)
			--print(actorRecordId)
			local model = types.Creature.objectIsInstance(actor) and types.Creature.records[actor.recordId].model
			if model then
				--box center:
				barOffset = (computedBoxes[model] and computedBoxes[model][1]:emul(v3(0,0,1)) or boxCache[actorRecordId][1]:emul(v3(0,0,1)))*actorScale
				--print(computedBoxes[model] and computedBoxes[model][1]:emul(v3(1,1,1)))
				if playerSettings:get("ANCHOR") == "head" then
					--barOffset =  boxCache[actorRecordId][2]:emul(v3(0,0,actorScale))
					if customHeights[model] then
						barOffset = v3(barOffset.x, barOffset.y, customHeights[model]*actorScale)
					elseif computedBoxes[model] then
						barOffset = v3(0,0, barOffset.z + computedBoxes[model][2].z/2*actorScale)
					else
						barOffset = v3(0,0, barOffset.z + boxCache[actorRecordId][2].z*actorScale)
					end
				else
					if computedBoxes[model] then
						barOffset = v3(0,0, barOffset.z - computedBoxes[model][2].z/2*actorScale)
					else
						barOffset = v3(0,0, barOffset.z - boxCache[actorRecordId][2].z*actorScale)
					end
				end
			else
				if playerSettings:get("ANCHOR") == "head" then --npcs are too predictable to use the engine's buggy bounding boxes as fallback already
					barOffset = boxCache[actorRecordId][1]+boxCache[actorRecordId][2]
				else
					barOffset = v3(0,0,0)
				end
			end
			--print(barOffset)
			barPos =  barPos + barOffset
			local viewPos_XYZ = camera.worldToViewportVector(barPos)
			local viewpPos = v2(viewPos_XYZ.x/uiScale, viewPos_XYZ.y/uiScale)
			local v = camera.viewportToWorldVector(v2(0.5, 0.5))
			
			local u = (barPos - camera.getPosition()):normalize()
			local angleInRadians = math.acos(v:dot(u) / math.max(0.0001,v * u))
			local stanceFilter = true
			if playerSettings:get("ONLY_IN_COMBAT") and types.Actor.getStance(actor) == types.Actor.STANCE.Nothing then
				stanceFilter = false
			end
			local maxHealth = types.Actor.stats.dynamic.health(actor).base
			local currentHealth = types.Actor.stats.dynamic.health(actor).current
			if (not model or not modelBlacklist[model]) and (barCache[actor.id] or currentHealth > 0) and (stanceFilter or currentHealth ~= maxHealth) and viewPos_XYZ.z < playerSettings:get("MAX_DISTANCE") and angleInRadians < math.pi/2 and viewpPos.x >= screenres.x*-0.1 and viewpPos.x <= screenres.x*1.1 and viewpPos.y >= screenres.y*-0.1 and viewpPos.y <= screenres.y*1.1 then
				--print(hugeness)
				
				if not raytracing[actor.id] then
					raytracing[actor.id] = {}
					raytracing[actor.id].lastHit = 0
					raytracing[actor.id].actor = actor
					raytracing[actor.id].failedHits = 0
				end
				raytracing[actor.id].healthPct = currentHealth/maxHealth
				raytracing[actor.id].lastHealthUpdate = now
				raytracing[actor.id].barPos = barPos
				raytracing[actor.id].actorPos = actorPos
				raytracing[actor.id].distance = viewPos_XYZ.z
				local rayCheck = true
				local raytracingAlphaMult = 1
				if playerSettings:get("RAYTRACING") then
					if raytracing[actor.id].lastHit < now-1 then
						rayCheck = false
					elseif raytracing[actor.id].lastHit < now-0.05 then
						raytracingAlphaMult = 1-(now - raytracing[actor.id].lastHit)/1
					end
				end
				if rayCheck then
					--local hugeness1 = (boxCache[actorRecordId][2].x+boxCache[actorRecordId][2].y)
					--
					local hugeness2 = 0.85
					local hugeness3 = 0.85
					local hugeness = 0.85--model and customScales[model] and customScales[model]/100 or 1
					if model then
						local height = boxCache[actorRecordId][2].z*2
						if customHeights[model] then
							height = math.max(height,customHeights[model])
						end
						if computedBoxes[model] then
							height = math.max(height, computedBoxes[model][2].z)
						end
						height = height*actorScale
						if height < 110 then
							hugeness = 0.66 + height/323								
						else
							hugeness = 1 + 3*(1-0.7^((height-110)/215))
						end
					end
					if model then
						if computedBoxes[model] then
							hugeness2 = (computedBoxes[model][2].x*computedBoxes[model][2].y*computedBoxes[model][2].z)^0.333 / 90
							hugeness3 = (computedBoxes[model][2].x*computedBoxes[model][2].y)^0.333 / 90
						else
							hugeness2 = (boxCache[actorRecordId][2].x*boxCache[actorRecordId][2].y*boxCache[actorRecordId][2].z)^0.333 / 90
							hugeness3 = (boxCache[actorRecordId][2].x*boxCache[actorRecordId][2].y)^0.5 / 90
						end
					end
						
					hugeness = 0.3 + hugeness/4 + hugeness2/4 + hugeness3/4 + math.log10(maxHealth/10)/4
					if model then
						hugeness = hugeness + (customScales[model] or 0)
					end
					local offsetScale = 500/ viewPos_XYZ.z*playerSettings:get("SCALE")
					if offsetScale >1 then
						offsetScale = 1 + 10.7*(1-0.75^((offsetScale-1)/3))
					end
					local sizeMult = offsetScale*hugeness*0.85
					local c = barCache[actor.id]
					if not c or c.lastRender < now-1 then
						if c and c.bar then
							c.bar:destroy()
						end
						c = {
							actor = actor,
							lastRender = now,
							healthPaused = currentHealth,
							healthTimer = 0,
							lerpHealth = currentHealth,
							healthLag = currentHealth,
							cachedHealth = currentHealth,
							cachedLerpHealth = currentHealth,
							cachedIncomingHealing = 0,
							cachedHealthLag = currentHealth,
							cachedBorderAlpha = 0.5,
							textVisible = true,
							deathTimer = 0,
							lastBuffUpdate = now,
							hasBuffs = true,
						}
						barCache[actor.id] = c
					else
						if dt == 0 then
							c.lastRender = now
						end
						c.healthPaused, c.healthLag, c.healthTimer, c.lerpHealth = ownlysLag(currentHealth, c.lerpHealth, c.cachedHealth, c.healthPaused, c.healthLag, c.healthTimer, now-c.lastRender, drainSpeed, timerLength, 0)
						c.lastRender = now
					end
					
					if c.deathTimer <0.75 then
						if currentHealth == 0 then
							c.deathTimer = c.deathTimer+dt
						end
						if stylizedBars[playerSettings:get("BORDER_STYLE")] then
							updateStylized(c, currentHealth, maxHealth,sizeMult)
						else
							update(c, currentHealth, maxHealth,sizeMult)
						end
						c.bar.layout.props.position = v2(viewpPos.x+playerSettings:get("OFFSET_X")*offsetScale,viewpPos.y+playerSettings:get("OFFSET_Y")*offsetScale)
						c.bar.layout.props.alpha = math.max(0,math.min(1, 1.1-(1.219^(c.deathTimer*5)-1) ))*raytracingAlphaMult
						c.bar.layout.props.size = v2(100*sizeMult+2,14*sizeMult+2)
						c.bar:update()
						c.cachedHealth = currentHealth
					else
						if c.bar then
							c.bar:destroy()
						end
						barCache[actor.id] = nil
					end
				end
			end
		end
	end
	if playerSettings:get("RAYTRACING") then
		rayCounter = 0
		for i=1,15 do
			if not raytracing[nextRay] then
				nextRay = nil
			end
			nextRay = next(raytracing,nextRay)
			if not raytracing[nextRay] or raytracing[nextRay].lastHealthUpdate < now or raytracing[nextRay].distance > playerSettings:get("MAX_DISTANCE") then
				
			else
				rayCounter = rayCounter + 1
				--print("queuing "..raytracing[nextRay].actor.id)
				--print(camera.getPosition(), raytracing[nextRay].actorPos)
				--local rayTarget = (raytracing[nextRay].barPos-camera.getPosition()):normalize():emul(v3(playerSettings:get("MAX_DISTANCE")))
				local rayTarget = nil
				local forward = (raytracing[nextRay].barPos-camera.getPosition()):normalize()
				local up = v3(0,0,1)
				local right = forward:cross(up)
				--print("right",right)
				local actorId = nextRay
				if raytracing[actorId].failedHits %4 == 0 then
					rayTarget = raytracing[nextRay].barPos +right:emul(v3(20,20,20))
				elseif raytracing[actorId].failedHits %4 == 1 then
					rayTarget = raytracing[nextRay].barPos -right:emul(v3(20,20,20))
				elseif raytracing[actorId].failedHits %4 == 2 then
					rayTarget = (raytracing[nextRay].barPos + raytracing[nextRay].actorPos):ediv(v3(2,2,2))+right:emul(v3(20,20,20))
				elseif raytracing[actorId].failedHits %4 == 3 then
					rayTarget = (raytracing[nextRay].barPos + raytracing[nextRay].actorPos):ediv(v3(2,2,2))-right:emul(v3(20,20,20))
				end
				--vfx(rayTarget)
				local startPos = camera.getPosition()
				nearby.asyncCastRenderingRay(
					async:callback(function(res)
						if not res.hit or res.hitObject and res.hitObject == raytracing[actorId].actor then
							raytracing[actorId].lastHit = now
							raytracing[actorId].failedHits = 0
						elseif (res.hitPos - startPos):length() < raytracing[actorId].distance-100 then
							raytracing[actorId].failedHits = raytracing[actorId].failedHits + 1
						else
							raytracing[actorId].lastHit = now
							raytracing[actorId].failedHits = 0
						end
					end), 
					camera.getPosition(),rayTarget )
			end
			if rayCounter >= raysPerTick then
				break
			end
		end
			
		for a,b in pairs(raytracing) do
			if b.lastHealthUpdate < now or b.distance > playerSettings:get("MAX_DISTANCE") then
				raytracing[a] = nil
			end
		end
	
	end
	
	if playerSettings:get("BUFFS") then
		for i=1,10 do
			if not barCache[nextBuffUpdate] then
				nextBuffUpdate = nil
			end
			nextBuffUpdate = next(barCache,nextBuffUpdate)
			local c = barCache[nextBuffUpdate]
			if c and c.bar and c.lastBuffUpdate < now-0.125 then
				--local shortest= shortestBuff(c.actor)
				--if not shortest and c.hasBuffs or shortest and c.lastBuffUpdate < now-shortest/20 then
					updateBuffIcons(c)
					c.lastBuffUpdate = now
					break
				--end
			end
		end
	end
	for a,b in pairs(barCache) do
		if b.lastRender <= now-0.05 and b.bar then
			b.bar:destroy()
			b.bar = nil
		end
	end
end


local function updateSettings(_,setting)
	if #queueSettingsChange > 0 then
		return
	end
	--items = {"Y/T/B/R/G  ", "O/T/B/R/G  ", "R/T/B/W/G ", "O/Y2/B/W/G","O/Y/B/R/G  ","O/B/R/G    "},
	--"R/T/B/W/G", "O/Y2/B/W/G"
		if setting=="COLOR_PRESET" then
		if playerSettings:get("COLOR_PRESET") == "Y/T/B/R/G  " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.rgb(204/255,187/255,0)})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.rgb(204/255,42/255,0)})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("c5a15e")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("9a5e3a")})
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
		elseif playerSettings:get("COLOR_PRESET") == "O/T/B/R/G  " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.hex("b55500")})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("bb2100")})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("c5a15e")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("9a5e3a")})--
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
		elseif playerSettings:get("COLOR_PRESET") == "R/T/B/W/G " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("600004")})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("c5a15e")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("9a5e3a")})
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("AAAAAA")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
		elseif playerSettings:get("COLOR_PRESET") == "O/Y2/B/W/G" then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.hex("b55500")})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("ccbb00")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("ccbb00")})
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("FFFFFF")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
		elseif playerSettings:get("COLOR_PRESET") == "O/Y/B/R/G  " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.hex("b55500")})
			--table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("996542")})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.hex("9a5517")})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.hex("ccbb00")})
			--table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("c7ba73")})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.hex("ada11a")})
			
			table.insert(queueSettingsChange,{"ALLY_COL",util.color.hex("1263b0")})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.hex("4c6188")})

			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
			
		elseif playerSettings:get("COLOR_PRESET") == "O/B/R/G    " then
			table.insert(queueSettingsChange,{"HOSTILE_COL",util.color.rgb(204/255,187/255,0)})
			table.insert(queueSettingsChange,{"NEUTRAL_COL",util.color.rgb(204/255,187/255,0)})
			table.insert(queueSettingsChange,{"HOSTILE_DAMAGED_COL",util.color.rgb(204/255,42/255,0)})
			table.insert(queueSettingsChange,{"NEUTRAL_DAMAGED_COL",util.color.rgb(204/255,42/255,0)})
			
			table.insert(queueSettingsChange,{"ALLY_COL",		 util.color.rgb(18/255,99/255,176/255)})
			table.insert(queueSettingsChange,{"ALLY_DAMAGED_COL",util.color.rgb(173/255,99/255,100/255)})

			
			table.insert(queueSettingsChange,{"DAMAGE_COL",util.color.hex("a00004")})
			table.insert(queueSettingsChange,{"HEAL_COL",util.color.hex("3ca01e")})
			
			
			--	HPBAR_COL = util.color.rgb(204/255,(42+145*currentHealth/maxHealth)/255,0/255)
			--	ALLY_HPBAR_COL = util.color.rgb((18+155*(1-currentHealth/maxHealth))/255,99/255,(100+76*currentHealth/maxHealth)/255)
			----default =  util.color.hex("1263b0"), --blue
			----default =  util.color.hex("999999"), --gray-white
			----default =  util.color.hex("ccbb00"), --yellow
			----default = util.color.hex("9a5e3a"), --tan (unused)
			----default =  util.color.hex("c5a15e"), --paper
			----default =  util.color.hex("b55500"), --orange
			----default =  util.color.hex("a00004"), --red
		end
	end
	for a,c in pairs(barCache) do
		if c.bar then
			c.bar:destroy()
		end
		c.bar = nil
		c.cachedHealth = types.Actor.stats.dynamic.health(c.actor).current
		c.cachedLerpHealth = c.lerpHealth
		c.allyCache = nil
		c.cachedHealthLag = c.healthLag
		c.cachedIncomingHealing = 0
		c.cachedBorderAlpha = 0.5
		c.textVisible = true
		c.lastBuffUpdate = core.getRealTime()
		c.hasBuffs = true
	end
end
 
function AI_update(param)
	
	AI_DB[param.id] = AI_DB[param.id] or {}
	if param.package == "Combat" then
		AI_DB[param.id].Combat = core.getSimulationTime()
	elseif param.package == "Follow" then
		AI_DB[param.id].Follow = core.getSimulationTime()
	end
end

playerSettings:subscribe(async:callback(updateSettings))


--heightAdjusting Toolkit





return {    
	engineHandlers = {
		onFrame = onFrame,
		onKeyPress = onKey
    },
	eventHandlers = {
        FHB_AI_update = AI_update,
    }
}
