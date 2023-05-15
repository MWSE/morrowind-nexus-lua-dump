local defaultConfig = {
    modName = "Revered Dead",
    enabled = true,
    logLevel = "WARN",
    minSuspiciousValue = 25,
    minAlarmingValue = 500,
    graveRobberBounty = 1000,
    mortalRemainsForbidden = true,
    warnOnTombEntry = true,
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
    whitelist = { -- specific items and containers that should not be flagged as grave goods.
        "amulet_Agustas_unique",
        "Extravagant_Robe_01_Red",
        "misc_de_goblet_01_redas",
        "dwarven war axe_redas"
    }
}

local mwseConfig = mwse.loadConfig(modName, defaultConfig)

return mwseConfig
