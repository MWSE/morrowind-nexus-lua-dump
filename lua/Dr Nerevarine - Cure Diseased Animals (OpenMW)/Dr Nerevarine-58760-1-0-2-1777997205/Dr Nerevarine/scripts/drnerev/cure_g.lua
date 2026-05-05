local types = require('openmw.types')
local core = require('openmw.core')
local world = require('openmw.world')

local msg = core.l10n('drnerev', 'en')
local player = world.players[1]

local soundCure = {
    ["alit"] = "Sound/Cr/alit/moan.wav",
    ["guar"] = "Sound/Cr/guar/moan.wav",
    ["kagouti"] = "Sound/Cr/kagouti/moan.wav",
    ["kwama worker"] = "Sound/Cr/kwamwk/moan.wav",
    ["kwama warrior"] = "Sound/Cr/kwamwr/moan.wav",
    ["kwama forager"] = "Sound/Cr/kwamf/moan.wav",
    ["kwama queen"] = "Sound/Cr/kwanq/moan.wav",
    ["mudcrab"] = "Sound/Cr/mdcrb/moan.wav",
    ["nix-hound"] = "Sound/Cr/nix/moan.wav",
    ["rat"] = "Sound/Cr/rat/moan.wav",
    ["scrib"] = "Sound/Cr/scrib/moan.wav",
    ["shalk"] = "Sound/Cr/shalk/moan.wav"

}

local rewards_type = {"key", "food", "food"} -- , "gold"}

local rewards_key = {"key_abebaalslaves_01", "key_addamasartusslaves_01", "key_aharunartusslaves_01", "key_ahnassi",
                     "key_ald_redaynia", "key_alvur", "key_anja", "key_archcanon_private", "key_arenim",
                     "key_armigers_stronghold", "key_arobarmanorguard_01", "key_arobarmanor_01", "key_arvs-drelen_cell",
                     "key_ashalmawia_prisoncell", "key_ashurninibi", "key_ashurninibi_lost", "key_assi",
                     "key_assarnudslaves_01", "key_aurane1", "key_balmorag_tong_01", "key_bivaleteneran_01",
                     "key_bolayn", "key_brallion", "key_bthuand", "key_cabin", "key_caius_cosades",
                     "key_calderaslaves_01", "key_caryarel", "key_cell_buckmoth_01", "key_chest_aryniorethi_01",
                     "key_chest_coduscallonus_01", "key_chest_drinarvaryon_01", "key_ciennesintieve_01", "key_desele",
                     "key_divayth_fyr", "key_divayth00", "key_divayth01", "key_divayth02", "key_divayth03",
                     "key_divayth04", "key_divayth05", "key_divayth06", "key_divayth07", "key_dralor", "key_dren_manor",
                     "key_dren_storage", "key_drenplantationslaves_01", "key_dreynos", "key_dumbuk_strongbox",
                     "key_dura_gra-bol", "key_dvaults1", "key_dvaults2", "key_elmussadamori", "key_fals",
                     "key_fg_nchur", "key_forge of rolamus", "key_gatewayinnslaves_01", "key_galmis",
                     "key_gnisis_eggmine", "key_gro-bagrat", "key_gshipwreck", "key_habinbaesslaves_01",
                     "key_hasphat_antabolis", "key_helvi", "key_hinnabislaves_01", "key_hlaalo_manor",
                     "key_hlormarenslaves_01", "key_hvaults1", "key_hvaults2", "key_ibardad_tomb", "key_impcomsecrdoor",
                     "key_indalen", "key_itar", "key_ivrosa", "key_jeanne", "key_j'zhirr", "key_khartag",
                     "key_manor_sarethi", "key_marvani_tomb", "key_mudan_dragon", "key_mudcave",
                     "key_neshans_strongbox", "key_odros", "key_ohman", "key_oritius", "key_othrelas_door",
                     "key_palansour", "key_pelagiad_fighters", "key_persius_mercius", "key_redoran_treasury",
                     "key_rvaults1", "key_sandas", "key_senim_tomb", "key_shushishi", "key_slave_addamasartus",
                     "key_standard_01_darvam hlaren", "key_standard_01_pel_fort_prison", "key_standard_darius_chest",
                     "key_summoning_room", "key_table_mudan00", "key_tel_denim_private", "key_tel_mora_slaves",
                     "key_telvos_private", "key_tureynul", "key_turedus_strongbox", "key_uldr_vatrus_01",
                     "key_vampire_crypt", "key_velas", "key_verick", "key_vivec_arena_cell", "key_vivec_hlaalu_cell",
                     "key_vivec_redoran_cell", "key_vivec_telvanni_cell", "key_volrina_01", "key_vorarhelas"}

local reward_food = {

    ["cliff racer"] = "ingred_crab_meat_01",
    ["alit"] = "ingred_rat_meat_01",
    ["durzog"] = "ingred_scrib_jerky_01",
    ["kagouti"] = "ingred_ash_yam_01",
    ["kwama forager"] = "ingred_rat_meat_01",
    ["kwama queen"] = "food_kwama_egg_02",
    ["kwama worker"] = "food_kwama_egg_01",
    ["kwama warrior"] = "ingred_fire_petal_01",
    ["mudcrab"] = "ingred_pearl_01",
    ["nix-hound"] = "ingred_guar_hide_01",
    ["rat"] = "ingred_corkbulb_root_01",
    ["scrib"] = "ingred_bloat_01",
    ["shalk"] = "ingred_guar_hide_01",
    ["netch_betty"] = "ingred_hackle-lo_leaf_01",
    ["netch_bull"] = "ingred_hackle-lo_leaf_01",
    ["t_mw_fau_beetlebl_01"] = "ingred_red_lichen_01",
    ["t_mw_fau_beetlebr_01"] = "ingred_red_lichen_01",
    ["t_mw_fau_beetlegr_01"] = "ingred_red_lichen_01",
    ["t_mw_fau_beetlehr_01"] = "ingred_red_lichen_01",
    ["t_mw_fau_thresher_01"] = "ingred_human_meat_01",
    ["t_mw_fau_molec_01"] = "ingred_scales_01"

}

local function drnrReward(data)
    -- print ("drnrReward", data.reward)
    local reward = world.createObject(data.reward, data.count)
    reward:teleport(data.cell, data.pos, {
        onGround = true
    })
end

local function getGratitude(healfyId, cell, pos)
    local path = soundCure[healfyId]
    local message

    if math.random() > 0.25 then
        message = msg("drnrGratitude")
    else
        local reward
        local count = 1
        local type = rewards_type[math.random(1, #rewards_type)]

        if type == "gold" then
            reward = "gold_dae_cursed_001"
            message = msg("drnrGold")
        elseif type == "key" then
            reward = rewards_key[math.random(1, #rewards_key)]
            message = msg("drnrKey")
        elseif type == "food" then
            reward = reward_food[healfyId]
            message = msg("drnrFood")
        end

        if reward then
            drnrReward({
                reward = reward,
                count = count,
                cell = cell,
                pos = pos
            })
        end
    end

    if path then
        core.sound.playSoundFile3d(path, player)
    end
    if message then
        player:sendEvent("drnrShowMessage", {message = message})
    end

end

return {
    getGratitude = getGratitude
}
