local world = require("openmw.world")

local rarePool = { 
    "ingred_diamond_01", 
    "ingred_ruby_01",
    "ingred_emerald_01",
    "ingred_raw_ebony_01",
    "ingred_raw_glass_01",
    "ingred_vampire_dust_01",
    "ingred_daedras_heart_01",
    "Misc_SoulGem_Grand",
    "T_IngCrea_Ambergris",
    "T_IngCrea_CanahFeather",
    "T_IngCrea_RocEgg_01",
    "T_De_Glass_Rod_01",
    "T_Imp_GoldCandlestick_01",
    "T_Imp_HandMirror_01",
    "sc_mindfeeder",
    "sc_bloodthief",
    "sc_greaterdomination",
    "sc_ninthbarrier",
    "sc_summongoldensaint"
} 

local uncommonPool = { 
    "Misc_SoulGem_Greater", 
    "ingred_daedra_skin_01",
    "T_Imp_CoinAlessian_01",
    "T_IngCrea_BezoarStone_01",
    "T_IngCrea_DridreaSilk_01",
    "ingred_fire_salts_01",
    "ingred_frost_salts_01",
    "ingred_ghoul_heart_01",
    "ingred_pearl_01",
    "ingred_shalk_resin_01",
    "ingred_void_salts_01",
    "T_IngCrea_Ivory",
    "T_IngCrea_Minotaurhorn_01",
    "T_Com_Astrolabe_01",
    "T_Dwe_ExplodoEye_01",
    "sc_reddeath",
    "sc_manarape",
    "sc_balefulsuffering",
    "sc_lordmhasvengeance",
    "sc_purityofbody",
    "sc_drathissoulrot",
    "sc_uthshandofheaven",
    "sc_ekashslocksplitter",
    "sc_psychicprison",
    "sc_restoration",
    "sc_fphyggisgemfeeder",
    "misc_dwrv_coin00"
}

local commonPool = { 
    "Misc_SoulGem_Common", 
    "Misc_SoulGem_Lesser",
    "Misc_SoulGem_Petty",
    "T_Com_CopperKettle_01",
    "T_Com_CopperPan_01",
    "T_Com_CopperPot_01",
    "T_Com_CoppetTeapot_01",
    "T_Nor_CopperTankard",
    "T_Com_ShellOyster_01a",
    "T_Com_Paintbrush_04",
    "T_Imp_SilverWeight_01",
    "T_Com_Soap_02",
    "T_Com_Soap_03",
    "T_Com_Soap_04",
    "ingred_hackle-lo_leaf_01",
    "ingred_moon_sugar_01",
    "ingred_racer_plumes_01",
    "ingred_resin_01",
    "ingred_scales_01",
    "ingred_scamp_skin_01",
    "ingred_scrap_metal_01",
    "ingred_scuttle_01",
    "ingred_sload_soap_01",
    "T_IngCrea_FrogEye_01",
    "T_IngCrea_FlyMusk_01",
    "T_Com_CandleStickBrass_01",
    "T_Com_ShellClam_01",
    "T_Com_ShellCockle_01",
    "T_Com_ShellConch",
    "T_Com_CrystalBall_01",
    "T_Com_ShellKollop_01",
    "T_Com_MetalPieceIron_01",
    "T_Com_CandleStickPewter_02",
    "sc_almsiviintervention",
    "sc_divineintervention",
    "sc_hellfire",
    "sc_tinurshoptoad",
    "sc_ondusisunhinging",
    "Misc_Imp_Silverware_Bowl",
    "misc_imp_silverware_plate_01"
}

local rollItem = function(player)
    local weighted_random = function(pool)
        local poolsize = 0
            for i,v in ipairs(pool) do
            poolsize = poolsize + v[1]
            end
        local selection = math.random(1,poolsize)
            for i,v in ipairs(pool) do
            selection = selection - v[1] 
                if (selection <= 0) then
                return v[2]
            end
        end
    end
    pool = {
        {10, rarePool},
        {25, uncommonPool},
        {65, commonPool}
        }
    local result = weighted_random(pool)
    
    local loot = result[math.random(#result)]
    tostring(loot)
    local item = world.createObject(loot, math.random(1,3))
    item:moveInto(player)
end

return { 
    eventHandlers = {
        scavengerItemSpawned = rollItem
    }
}
