-- IDs shall be lowercase
return {
    actorIds = {
        "alvis teri", -- to prevent breaking the Redoran's quest "Founder's Helm"
        "redoran guard_andasreth", -- to prevent breaking the Redoran's quest "Recover Shields from Andasreth"
        "pc_m1_willytheunbitten", -- from Project Cyrodiil, an mwscript uses HitOnMe, and expects the weapon "T_Com_Steel_Shortsword_01"
        "ienas sarandas", -- don't convert items he may return to their owners
    },
    containerIds = {
        "stolen_goods" -- don't convert player's stolen goods when he goes to jail
    },
}
