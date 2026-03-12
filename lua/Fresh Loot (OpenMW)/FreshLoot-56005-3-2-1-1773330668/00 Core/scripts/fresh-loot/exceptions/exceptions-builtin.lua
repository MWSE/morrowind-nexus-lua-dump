-- IDs shall be lowercase
return {
    actorLevelOverrides = {
        -- Nerf Bloodmoon NPCs from levelled lists
        bm_berserker_f1 = 10,
        bm_berserker_m1 = 10,
        bm_berserker_f2 = 20,
        bm_berserker_m2 = 20,
        bm_berserker_f3 = 30,
        bm_berserker_m3 = 30,
        bm_frysehag_3 = 4,
        bm_frysehag_1 = 10,
        bm_frysehag_2 = 20,
        bm_reaver_30 = 20,
        bm_reaver_50 = 30,
        bm_reaver_archer_30 = 20,
        bm_reaver_archer_50 = 30,
    },
    excludedActorIds = {
        ["alvis teri"] = true, -- to prevent breaking the Redoran's quest "Founder's Helm"
        ["redoran guard_andasreth"] = true, -- to prevent breaking the Redoran's quest "Recover Shields from Andasreth"
        ["pc_m1_willytheunbitten"] = true, -- from Project Cyrodiil, an mwscript uses HitOnMe, and expects the weapon "T_Com_Steel_Shortsword_01"
        ["ienas sarandas"] = true, -- don't convert items he may return to their owners
    },
    excludedContainerIds = {
        stolen_goods = true -- don't convert player's stolen goods when he goes to jail
    },
}
