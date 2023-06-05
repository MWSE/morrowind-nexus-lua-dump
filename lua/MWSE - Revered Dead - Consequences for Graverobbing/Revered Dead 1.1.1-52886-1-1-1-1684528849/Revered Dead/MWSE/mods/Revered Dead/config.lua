local defaultConfig = {
    modName = "Revered Dead",
    modVersion = "1.1",
    enabled = true,
    logLevel = "WARN",
    minSuspiciousValue = 25,
    minAlarmingValue = 500,
    graveRobberBounty = 1000,
    mortalRemainsForbidden = true,
    warnOnTombEntry = true,
    inconspicuousArtifacts = false;
    includeBurialCaverns = true;
    difficultyMod = 0,
    blacklist = { -- Items that anybody might hesitate to buy.
        "misc_skull00",
        "misc_skull10",
        "AB_Misc_Bone", -- OAAB items
        "AB_Misc_BoneSkelArmL", 
        "AB_Misc_BoneSkelArmR",
        "AB_Misc_BoneSkelArmUpperL",
        "AB_Misc_BoneSkelArmUpperL.1",
        "AB_Misc_BoneSkelArmUpperR",
        "AB_Misc_BoneSkelArmUpperR.1",
        "AB_Misc_BoneSkelArmWristL",
        "AB_Misc_BoneSkelArmWristL.1",
        "AB_Misc_BoneSkelArmWristR",
        "AB_Misc_BoneSkelArmWristL.1",
        "AB_Misc_BoneSkelFootL",
        "AB_Misc_BoneSkelFootL.1",
        "AB_Misc_BoneSkelFootR",
        "AB_Misc_BoneSkelFootR.1",
        "AB_Misc_BoneSkelHandL",
        "AB_Misc_BoneSkelHandL.1",
        "AB_Misc_BoneSkelHandR",
        "AB_Misc_BoneSkelHandR.1",
        "AB_Misc_BoneSkelLegL",
        "AB_Misc_BoneSkelLegR",
        "AB_Misc_BoneSkelLegShinL",
        "AB_Misc_BoneSkelLegShinL.1",
        "AB_Misc_BoneSkelLegShinR",
        "AB_Misc_BoneSkelLegShinR.1",
        "AB_Misc_BoneSkelLegUpperL",
        "AB_Misc_BoneSkelLegUpperL.1",
        "AB_Misc_BoneSkelLegUpperR",
        "AB_Misc_BoneSkelLegUpperR.1",
        "AB_Misc_BoneSkelPelvis",
        "AB_Misc_BoneSkelRibs",
        "AB_Misc_BoneSkelSkullGhoul",
        "AB_Misc_BoneSkelSkullJaw",
        "AB_Misc_BoneSkelSkullNoJaw",
        "AB_Misc_BoneSkelTorso",
        "AB_Misc_BoneSkelTorsoBroken",
        "T_Com_SkeletonHandL_01", -- Tamriel Data items
        "T_Com_SkullArgonian_01",
        "T_Com_SkullArgonian_02",
        "T_Com_SkullKhajiit_01",
        "T_Com_SkullKhajiit_02",
        "T_Com_SkullOrc_01",
        "T_Com_SkullOrc_02"
    },
    whitelist = { -- specific quest items and containers that should never be flagged as grave goods.
        "amulet_Agustas_unique",
        "Extravagant_Robe_01_Red",
        "misc_de_goblet_01_redas",
        "dwarven war axe_redas"
    },
    unique_whitelist = { -- Unique and special items found in tombs that may be optionally made excluded or non-obvious
        "Rusty_Dagger_UNIQUE",
        "ring_mentor_unique",
        "longbow_shadows_unique",
        "ring_denstagmer_unique",
        "ring_phynaster_unique",
        "staff_hasedoki_unique",
        "T_Dae_UNI_MeridiaDagger", -- Tamriel Rebuilt
        "T_Nor_UNI_GodsbloodAxe",
        "T_Nor_UNI_GodsbloodSpear",
        "T_Nor_UNI_GodsbloodSeax",
        "TR_m2_q_22_SwordofTaldeus",
        "TR_m2_q_22_SwordofTaldeuss"
    }
}

local mwseConfig = mwse.loadConfig("Revered Dead", defaultConfig)

return mwseConfig
