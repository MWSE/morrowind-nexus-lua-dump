-- the following actors will not pursue
-- lowercase record id
-- restart the game to for the changes to take effect, or reloadlua in the console
-- todo: blacklist UI ingame
local bl = {
    ["vivec_god"] = true,
    ["yagrum bagarn"] = true,
    ["almalexia"] = true,
    ["TR_m3_Hormidac Farralie"] = true,
    ["Almalexia_warrior"] = true,
    -- ["add_your_own_actor_id_here_to_blacklist_it"] = true,

    -- Creatures that definitely cannot reach a door handle,
    ["rat"] = true,
    ["rat_blighted"] = true,
    ["rat_cave"] = true,
    ["rat_cave_fgrh"] = true,
    ["rat_cave_fgt"] = true,
    ["rat_cave_hhte1"] = true,
    ["rat_cave_hhte2"] = true,
    ["rat_diseased"] = true,
    ["Rat_pack_rerlas"] = true,
    ["glenmoril_raven"] = true,
    ["glenmoril_raven_cave"] = true,
    ["Rat_plague"] = true,
    ["Rat_plague_hall1"] = true,
    ["Rat_plague_hall1a"] = true,
    ["Rat_plague_hall2"] = true,
    ["Rat_rerlas"] = true,
    ["rat_telvanni_unique"] = true,
    ["rat_telvanni_unique_2"] = true,
    -- Flying stuff that can't open doors,
    ["cliff racer"] = true,
    ["cliff racer_blighted"] = true,
    ["cliff racer_diseased"] = true,
    -- Doesnt even have HANDS MAN....
    ["mudcrab"] = true,
    ["mudcrab-Diseased"] = true,
    ["mudcrab_hrmudcrabnest"] = true,
    ["mudcrab_unique"] = true,
    -- More flying stuff
    ["netch_betty"] = true,
    ["netch_betty_ilgn"] = true,
    ["netch_betty_ranched"] = true,
    ["netch_bull"] = true,
    ["netch_bull_ilgn"] = true,
    ["netch_bull_ranched"] = true,
    ["netch_giant_unique"] = true,
    -- I just dont like these guys
    ["nix-hound"] = true,
    ["nix-hound blighted"] = true,
    -- Again, no hands... 
    ["scrib"] = true,
    ["scrib blighted"] = true,
    ["scrib diseased"] = true,
    ["scrib_vaba-amus"] = true,
    ["scrib_rerlas"] = true,
    -- Bruh
    ["shalk"] = true,
    ["shalk_blighted"] = true,
    ["shalk_diseased"] = true,
    ["shalk_diseased_hram"] = true,
    -- It's a fish...
    ["slaughterfish_small"] = true,
    ["slaughterfish_hr_sfavd"] = true,
    ["slaughterfish"] = true,
    -- Bruh x2
    ["kagouti"] = true,
    ["kagouti_blighted"] = true,
    ["kagouti_diseased"] = true,
    ["kagouti_hrk"] = true,
    ["kagouti_mating"] = true,
    -- Kwamas belong in Mines.
    ["kwama forager"] = true,
    ["kwama forager blighted"] = true,
    ["kwama forager_tb"] = true,
    ["kwama queen"] = true,
    ["kwama queen_abaesen"] = true,
    ["kwama queen_ahanibi"] = true,
    ["kwama queen_akimaes"] = true,
    ["kwama queen_eluba"] = true,
    ["kwama queen_eretammus"] = true,
    ["kwama queen_gnisis"] = true,
    ["kwama queen_hairat"] = true,
    ["kwama queen_hhem"] = true,
    ["kwama queen_madas"] = true,
    ["kwama queen_maesa"] = true,
    ["kwama queen_matus"] = true,
    ["kwama queen_mudan"] = true,
    ["kwama queen_mudan_c"] = true,
    ["kwama queen_panabanit"] = true,
    ["kwama queen_sarimisun"] = true,
    ["kwama queen_shurdan"] = true,
    ["kwama queen_shurdan_c"] = true,
    ["kwama queen_sinamusa"] = true,
    ["kwama queen_zalkin"] = true,
    ["kwama warrior"] = true,
    ["kwama warrior blighted"] = true,
    ["kwama warrior shurdan"] = true,
    ["kwama worker"] = true,
    ["kwama worker blighted"] = true,
    ["kwama worker diseased"] = true,
    ["kwama worker entrance"] = true,
    -- Guar out of here
    ["guar"] = true,
    ["guar_feral"] = true,
    ["guar_hrmudcrabnest"] = true,
    ["guar_llovyn_unique"] = true,
    ["guar_pack"] = true,
    ["guar_pack_tarvyn_unique"] = true,
    ["guar_rollie_unique"] = true,
    ["guar_white_unique"] = true,
    -- Bears are scary 
    ["BM_bear_black"] = true,
    ["BM_bear_black_Claw_UNIQ"] = true,
    ["BM_bear_black_fat"] = true,
    ["BM_bear_black_summon"] = true,
    ["BM_bear_be_UNIQUE"] = true,
    ["BM_bear_snow_unique"] = true,
    ["BM_bear_SPR_UNIQUE"] = true,
    ["BM_bear_brown"] = true,
    -- Scarier than bears
    ["durzog_diseased"] = true,
    ["durzog_wild"] = true,
    ["durzog_wild_weaker"] = true,
    ["durzog_war"] = true,
    ["durzog_war_trained"] = true,
    -- Same as Kagouti
    ["alit"] = true,
    ["alit_blighted"] = true,
    ["alit_diseased"] = true,
    -- They gotta stay in clockwork city
    ["fabricant_machine_1"] = true,
    ["fabricant_summon"] = true,
    ["fabricant_verm_attack"] = true,
    ["fabricant_verminous"] = true,
    ["fabricant_verminous-rs"] = true,
    ["fabricant_verminous_C"] = true,
    ["fabricant_verminousDead"] = true,
    ["fabricant_hulkin_attack"] = true,
    ["fabricant_hulking"] = true,
    ["fabricant_hulking_attac"] = true,
    ["fabricant_hulking_C"] = true,
    ["fabricant_hulking_C_L"] = true,
    ["fabricant_hulking_ss"] = true,
    ["Imperfect"] = true,
    -- THEY DONT HAVE ARMS
    ["BM_horker"] = true,
    ["BM_horker_dead"] = true,
    ["BM_horker_large"] = true,
    ["BM_horker_swim_UNIQUE"] = true,

    ["BM_frost_boar"] = true,
    -- Dogs stay outside
    ["BM_wolf_bone_summon"] = true,
    ["BM_wolf_skeleton"] = true,
    ["BM_werewolf_ritual"] = true,
    ["BM_wolf_caenlorn1"] = true,
    ["BM_wolf_caenlorn2"] = true,
    ["BM_wolf_caenlorn3"] = true,
    ["BM_wolf_grey"] = true,
    ["BM_wolf_grey_lvl_1"] = true,
    ["BM_wolf_grey_summon"] = true,
    ["BM_wolf_hroldar"] = true,
    ["BM_wolf_red"] = true,
    ["BM_wolf_snow_unique"] = true,
    -- Ghost definitely cant open doors... can they?
    ["ancestor_ghost"] = true,
    ["ancestor_ghost_greater"] = true,
    ["ancestor_ghost_summon"] = true,
    ["ancestor_ghost_vabdas"] = true,
    ["ancestor_ghost_Variner"] = true,
    ["ancestor_guardian_fgdd"] = true,
    ["ancestor_guardian_heler"] = true,
    ["ancestor_mg_wisewoman"] = true,
    ["gateway_haunt"] = true,
    ["wraith_sul_senipul"] = true,

    ["Dahrk Mezalf"] = true,
    ["dwarven ghost"] = true,
    ["dwarven ghost_jeanne_U"] = true,
    ["dwarven ghost_radac"] = true,

    ["corprus_stalker_fyr01"] = true,
    ["corprus_stalker_fyr02"] = true,
    ["corprus_stalker_fyr03"] = true,

    ["corprus_lame_fyr01"] = true,
    ["corprus_lame_fyr02"] = true,
    ["corprus_lame_fyr03"] = true,
    ["corprus_lame_fyr04"] = true,

    ["heart_akulakhan"] = true,

    ["vedelea othril"] = true,

     -- Rescue Varvur Sarethi --

    ["bevadar bels"] = true, 
    ["idros givyn"] = true, 
    ["nathyne uvelas"] = true, 
    ["nidryne redas"] = true, 
    ["novor gorvas"] = true, 
    ["tereri irethi"] = true, 
    ["malsa ules"] = true, 
    ["tidras deltis"] = true, 
    ["velsa orethi"] = true,   
    ["vevul alver"] = true, 

    -- Lord's Mail quest --
    ["furius acilius"] = true,

    -- question of size...:

    ["ogrim"] = true,
    ["ogrim titan"] = true,
    ["ogrim titan_velas"] = true,
    ["ogrim_az"] = true,

    ["bm_frost_giant"] = true,

    ["BM_hircine"] = true,
    ["BM_hircine2"] = true,
    ["BM_hircine_straspect"] = true,

    ["BM_ice_troll"] = true,
    ["BM_ice_troll_sun"] = true,
    ["BM_ice_troll_tough"] = true,
    ["BM_icetroll_FG_Uni"] = true,
}

local function handleLazy(t, key)
    for k, v in pairs(t) do
        if k:lower() == key then
            return v
        end
    end
end
return setmetatable(bl, {
    __index = handleLazy
})
