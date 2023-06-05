local this = {}

this.forbiddenEffectsIds = { -- for abilities and diseases
    [14] = true,
    [15] = true,
    [16] = true,
    [18] = true,
    [22] = true,
    [23] = true,
    [24] = true,
    [25] = true,
    [26] = true,
    [27] = true,
    [132] = true,
    [133] = true,
    [135] = true,
}

this.forbiddenIds = {
    ["war_axe_airan_ammu"] = true,
    ["shadow_shield"] = true,
    ["bonebiter_bow_unique"] = true,
    ["heart_of_fire"] = true,
    ["T_WereboarRobe"] = true,
    ["WerewolfRobe"] = true,


    ["vivec_god"] = true,
    ["wraith_sul_senipul"] = true,

    ["ToddTest"] = true,

    ["WerewolfHead"] = true,
    --morrowind quest items
    ["lugrub's axe"] = true,
    ["dwarven war axe_redas"] = true,
    ["ebony staff caper"] = true,
    ["Rusty_Dagger_UNIQUE"] = true,
    ["devil_tanto_tgamg"] = true,
    ["daedric wakizashi_hhst"] = true,
    ["glass_dagger_enamor"] = true,
    ["fork_horripilation_unique"] = true,
    ["dart_uniq_judgement"] = true,
    ["bonemold_gah-julan_hhda"] = true,
    ["bonemold_founders_helm"] = true,
    ["bonemold_tshield_hrlb"] = true,
    ["amulet of ashamanu (unique)"] = true,
    ["amuletfleshmadewhole_uniq"] = true,
    ["amulet_Agustas_unique"] = true,
    ["expensive_amulet_delyna"] = true,
    ["expensive_amulet_aeta"] = true,
    ["sarandas_amulet"] = true,
    ["exquisite_amulet_hlervu1"] = true,
    ["Julielle_Aumines_Amulet"] = true,
    ["Linus_Iulus_Maran Amulet"] = true,
    ["amulet_skink_unique"] = true,
    ["Linus_Iulus_Stendarran_Belt"] = true,
    ["sarandas_belt"] = true,
    ["common_glove_l_balmolagmer"] = true,
    ["common_glove_r_balmolagmer"] = true,
    ["extravagant_rt_art_wild"] = true,
    ["expensive_glove_left_ilmeni"] = true,
    ["extravagant_glove_left_maur"] = true,
    ["extravagant_glove_right_maur"] = true,
    ["common_pants_02_hentus"] = true,
    ["sarandas_pants_2"] = true,
    ["Adusamsi's_Ring"] = true,
    ["extravagant_ring_aund_uni"] = true,
    ["ring_blackjinx_uniq"] = true,
    ["exquisite_ring_brallion"] = true,
    ["common_ring_danar"] = true,
    ["sarandas_ring_2"] = true,
    ["ring_keley"] = true,
    ["expensive_ring_01_BILL"] = true,
    ["expensive_ring_aeta"] = true,
    ["sarandas_ring_1"] = true,
    ["Expensive_Ring_01_HRDT"] = true,
    ["exquisite_ring_processus"] = true,
    ["ring_dahrkmezalf_uniq"] = true,
    ["Extravagant_Robe_01_Red"] = true,
    ["robe of st roris"] = true,
    ["exquisite_robe_drake's pride"] = true,
    ["sarandas_shirt_2"] = true,
    ["exquisite_shirt_01_rasha"] = true,
    ["sarandas_shoes_2"] = true,
    ["therana's skirt"] = true,
    ["sanguineamuletenterprise"] = true,
    ["sanguineamuletglibspeech"] = true,
    ["sanguineamuletnimblearmor"] = true,
    ["sanguinebeltbalancedarmor"] = true,
    ["sanguinebeltdeepbiting"] = true,
    ["sanguinebeltdenial"] = true,
    ["sanguinebeltfleetness"] = true,
    ["sanguinebelthewing"] = true,
    ["sanguinebeltimpaling"] = true,
    ["sanguinebeltmartialcraft"] = true,
    ["sanguinebeltsmiting"] = true,
    ["sanguinebeltstolidarmor"] = true,
    ["sanguinebeltsureflight"] = true,
    ["sanguinerglovehornyfist"] = true,
    ["sanguinelglovesafekeeping"] = true,
    ["sanguinergloveswiftblade"] = true,
    ["sanguineringfluidevasion"] = true,
    ["sanguineringgoldenw"] = true,
    ["sanguineringgreenw"] = true,
    ["sanguineringredw"] = true,
    ["sanguineringsilverw"] = true,
    ["sanguineringsublimew"] = true,
    ["sanguineringtranscendw"] = true,
    ["sanguineringtransfigurw"] = true,
    ["sanguineringunseenw"] = true,
    ["sanguineshoesleaping"] = true,
    ["sanguineshoesstalking"] = true,
    --tribunal quest items
    ["ebony war axe_elanande"] = true,
    ["dwarven mace_salandas"] = true,
    ["silver dagger_droth_unique_a"] = true,
    ["silver dagger_droth_unique"] = true,
    ["ebony shortsword_soscean"] = true,
    ["silver spear_uvenim"] = true,
    ["ebony_cuirass_soscean"] = true,
    ["silver_helm_uvenim"] = true,
    ["amulet_salandas"] = true,
    ["extravagant_robe_02_elanande"] = true,
    --bloodmoon
    ["bm nordic pick"] = true,
    ["steel arrow_Carnius"] = true,
    ["steel longbow_carnius"] = true,
    ["steel saber_elberoth"] = true,
    ["BM_dagger_wolfgiver"] = true,
    ["fur_colovian_helm_white"] = true,
    ["amulet of infectious charm"] = true,
    ["expensive_ring_erna"] = true,
}

this.forbiddenModels = { -- lowercase
    ["pc\\f\\pc_help_deprec_01.nif"] = true,
}

this.scriptWhiteList = {
    ["LegionUniform"] = true,
    ["OrdinatorUniform"] = true,
}

this.obtainableArtifacts = {["boots_apostle_unique"]=true,["tenpaceboots"]=true,["cuirass_savior_unique"]=true,["dragonbone_cuirass_unique"]=true,["lords_cuirass_unique"]=true,["daedric_helm_clavicusvile"]=true,["ebony_shield_auriel"]=true,["towershield_eleidon_unique"]=true,["spell_breaker_unique"]=true,["ring_vampiric_unique"]=true,["ring_warlock_unique"]=true,["warhammer_crusher_unique"]=true,["staff_hasedoki_unique"]=true,["staff_magnus_unique"]=true,["ebony_bow_auriel"]=true,["longbow_shadows_unique"]=true,["claymore_chrysamere_unique"]=true,["claymore_iceblade_unique"]=true,["longsword_umbra_unique"]=true,["dagger_fang_unique"]=true,["mace of slurring"]=true,["robe_lich_unique"]=true,}

this.skillByEffectId = {[0]=11,[1]=11,[2]=11,[3]=11,[4]=11,[5]=11,[6]=11,[7]=11,[8]=11,[9]=11,[10]=11,[11]=11,[12]=11,[13]=11,[14]=10,[15]=10,[16]=10,[17]=10,[18]=10,[19]=10,[20]=10,[21]=10,[22]=10,[23]=10,[24]=10,[25]=10,[26]=10,[27]=10,[28]=10,[29]=10,[30]=10,[31]=10,[32]=10,[33]=10,[34]=10,[35]=10,[36]=10,[37]=10,[38]=10,[39]=12,[40]=12,[41]=12,[42]=12,[43]=12,[44]=12,[45]=12,[46]=12,[47]=12,[48]=12,[49]=12,[50]=12,[51]=12,[52]=12,[53]=14,[54]=12,[55]=12,[56]=12,[57]=14,[58]=14,[59]=14,[60]=14,[61]=14,[62]=14,[63]=14,[64]=14,[65]=14,[66]=14,[67]=14,[68]=14,[69]=15,[70]=15,[71]=15,[72]=15,[73]=15,[74]=15,[75]=15,[76]=15,[77]=15,[78]=15,[79]=15,[80]=15,[81]=15,[82]=15,[83]=15,[84]=15,[85]=14,[86]=14,[87]=14,[88]=14,[89]=14,[90]=15,[91]=15,[92]=15,[93]=15,[94]=15,[95]=15,[96]=15,[97]=15,[98]=15,[99]=15,[100]=15,[101]=13,[102]=13,[103]=13,[104]=13,[105]=13,[106]=13,[107]=13,[108]=13,[109]=13,[110]=13,[111]=13,[112]=13,[113]=13,[114]=13,[115]=13,[116]=13,[117]=15,[118]=13,[119]=13,[120]=13,[121]=13,[122]=13,[123]=13,[124]=13,[125]=13,[126]=13,[127]=13,[128]=13,[129]=13,[130]=13,[131]=13,[132]=10,[133]=10,[134]=13,[135]=10,[136]=10,[137]=nil,[138]=13,[139]=13,[140]=13,}

this.herbsOffsets = {["flora_bittergreen_07"]=70,["flora_bittergreen_06"]=40,["flora_bittergreen_08"]=50,["flora_bittergreen_09"]=60,["flora_bittergreen_10"]=50,["flora_sedge_01"]=25,["flora_sedge_02"]=25,["flora_kreshweed_02"]=120,["flora_green_lichen_02"]=0,["flora_green_lichen_01"]=5,["flora_ash_yam_02"]=10,["flora_muckspunge_01"]=80,["flora_kreshweed_01"]=80,["flora_muckspunge_05"]=110,["flora_muckspunge_06"]=100,["flora_muckspunge_02"]=90,["flora_ash_yam_01"]=20,["flora_kreshweed_03"]=90,["flora_muckspunge_04"]=80,["flora_muckspunge_03"]=80,["flora_stoneflower_02"]=45,["flora_marshmerrow_02"]=60,["flora_bc_mushroom_07"]=0,["flora_marshmerrow_03"]=70,["flora_saltrice_01"]=50,["flora_bc_mushroom_06"]=10,["flora_saltrice_02"]=50,["flora_bc_mushroom_05"]=15,["flora_wickwheat_01"]=40,["flora_bc_mushroom_03"]=15,["flora_wickwheat_03"]=20,["flora_wickwheat_04"]=25,["flora_bc_shelffungus_03"]=0,["flora_bc_shelffungus_04"]=0,["flora_bc_shelffungus_02"]=0,["flora_chokeweed_02"]=100,["flora_roobrush_02"]=30,["flora_marshmerrow_01"]=70,["flora_wickwheat_02"]=20,["flora_bc_mushroom_01"]=15,["flora_bc_shelffungus_01"]=0,["flora_stoneflower_01"]=40,["flora_plant_05"]=30,["flora_black_lichen_02"]=5,["flora_plant_02"]=30,["flora_black_lichen_01"]=5,["flora_plant_03"]=20,["flora_plant_06"]=30,["flora_plant_08"]=-10,["flora_plant_07"]=5,["flora_fire_fern_01"]=30,["flora_fire_fern_03"]=20,["flora_black_anther_02"]=20,["flora_bc_podplant_01"]=10,["flora_fire_fern_02"]=20,["flora_bc_podplant_02"]=10,["flora_heather_01"]=5,["flora_rm_scathecraw_02"]=70,["flora_comberry_01"]=50,["flora_rm_scathecraw_01"]=100,["flora_bc_mushroom_02"]=15,["flora_bc_mushroom_04"]=15,["flora_bc_mushroom_08"]=10,["flora_plant_04"]=20,["flora_bc_fern_01"]=70,["flora_black_anther_01"]=50,["flora_gold_kanet_01"]=30,["flora_bm_belladonna_01"]=30,["flora_corkbulb"]=0,["flora_bm_belladonna_02"]=30,["flora_gold_kanet_02"]=30,["flora_bittergreen_01"]=60,["flora_bm_holly_02"]=160,["flora_bm_holly_04"]=160,["flora_bm_holly_01"]=160,["flora_bm_holly_05"]=160,["flora_gold_kanet_02_uni"]=30,["flora_bm_belladonna_03"]=30,["flora_bm_wolfsbane_01"]=25,["tramaroot_04"]=40,["flora_bittergreen_04"]=20,["tramaroot_05"]=30,["flora_bittergreen_05"]=50,["tramaroot_03"]=45,["flora_bittergreen_02"]=50,["tramaroot_02"]=85,["flora_willow_flower_01"]=40,["flora_willow_flower_02"]=30,["flora_bittergreen_03"]=80,["contain_trama_shrub_05"]=140,["contain_trama_shrub_01"]=120,["flora_bc_podplant_03"]=10,["flora_bc_podplant_04"]=10,["flora_red_lichen_01"]=5,["flora_red_lichen_02"]=5,["flora_hackle-lo_02"]=20,["flora_hackle-lo_01"]=20,["contain_trama_shrub_02"]=140,["tramaroot_01"]=50,["contain_trama_shrub_03"]=70,["contain_trama_shrub_04"]=120,["contain_trama_shrub_06"]=120,["kollop_01_pearl"]=5,["kollop_02_pearl"]=5,["kollop_03_pearl"]=5,}

function this.checkRequirementsForItem(item)
    if item ~= nil and not item.deleted and item.name ~= nil and item.name ~= "" and
            not this.forbiddenIds[item.id] and item.name ~= "<Deprecated>" and
            not (item.icon == nil or item.icon == "" or item.icon == "default icon.dds") and
            item.mesh and tes3.getFileSource("Meshes\\"..item.mesh) and not this.forbiddenModels[item.mesh:lower()] then
        return true
    end
    return false
end

return this