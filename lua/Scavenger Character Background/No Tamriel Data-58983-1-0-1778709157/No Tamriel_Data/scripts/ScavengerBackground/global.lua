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
    "sc_mindfeeder",
    "sc_bloodthief",
    "sc_greaterdomination",
    "sc_ninthbarrier",
    "sc_summongoldensaint"
} 

local uncommonPool = { 
    "Misc_SoulGem_Greater", 
    "ingred_daedra_skin_01",
    "ingred_fire_salts_01",
    "ingred_frost_salts_01",
    "ingred_ghoul_heart_01",
    "ingred_pearl_01",
    "ingred_shalk_resin_01",
    "ingred_void_salts_01",
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
    "ingred_hackle-lo_leaf_01",
    "ingred_moon_sugar_01",
    "ingred_racer_plumes_01",
    "ingred_resin_01",
    "ingred_scales_01",
    "ingred_scamp_skin_01",
    "ingred_scrap_metal_01",
    "ingred_scuttle_01",
    "ingred_sload_soap_01",
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
    local item = world.createObject(loot, math.random(1,2))
    item:moveInto(player)
end

return { 
    eventHandlers = {
        scavengerItemSpawned = rollItem
    }
}
