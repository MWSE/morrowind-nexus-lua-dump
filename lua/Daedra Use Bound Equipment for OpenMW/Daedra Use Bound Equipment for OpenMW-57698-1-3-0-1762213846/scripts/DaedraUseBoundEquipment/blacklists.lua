local module = {}                           -- <Mod>   - <Daedra> - <Item>

module.daedraIdBlackList = {
    ['scamp_creeper'              ] = true, -- Vanilla - Creeper (All the treasures sold to Creeper are safe)
    -- [''] = true, --  - 
}

module.weaponIdBlackList = {
    ['BM_hunterspear_unique'      ] = true, -- Vanilla - Hircine's Aspect of Guile - Spear of the Hunter
    ['daedric_crescent_unique'    ] = true, -- Vanilla - Lord Dregas Volar - Unique Daedric Crescent
    ['TR_m1_FW_MG09_Witherbrand'  ] = true, -- TR & PT - Xivilai Tatho - Witherbrand
    ['TR_m1_w_glaive_anarchy_real'] = true, -- TR & PT - Lord Drekhva Yashaz - Anarchy
    ['TR_m3_Kha_ForceOfTheWind'   ] = true, -- TR & PT - Uridimmu - Force of the Wind
    ['TR_m3_w_HellfireGreatMace'  ] = true, -- TR & PT - Vyssar - Great Mace of Hellfire
    ['TR_m4_w_AurmazlKaariMace'   ] = true, -- TR & PT - Kaari - Kaari's Judgment
    ['TR_m7_Shatterwright'        ] = true, -- TR & PT - Xivilai Lotan - Shatterwright
    ['T_Com_UNI_TyposSophia'      ] = true, -- TR & PT - Lord Rathine Morgal - Staff of the Typos Sophia
    ['T_Dae_UNI_BowHeavensHail_01'] = true, -- TR & PT - Lord Kraatas Zathan - Bow of Heaven's Hail
    ['T_Dae_UNI_MoonReiver'       ] = true, -- TR & PT - Lord Methats Uldun - Sword of the Moon Reiver
    ['axe_queen_of_bats_unique'   ] = true, -- CRF     - Molag Grunda - Wings of the Queen of Bats
    ['stendar_hammer_unique_x'    ] = true, -- Kog Ext - Velrekt The Spawn of Stendarr - Stendarr's Hammer
    -- [''] = true, --  -  - 
}

module.armorIdBlackList = {
    ['ebony_closed_helm_fghl'     ] = true, -- Vanilla - Hunger - Sarano Ebony Helm
    ['T_Dae_UNI_BootsOfPeace_01'  ] = true, -- TR & PT - Lord Drekhva Yashaz - Boots of Peace
    ['T_Dae_UNI_GauntletOfPoor_L' ] = true, -- TR & PT - Lord Mhas Vathor - Left Gauntlet of the Poor
    ['T_Dae_UNI_GauntletOfPoor_R' ] = true, -- TR & PT - Lord Mhas Vathor - Right Gauntlet of the Poor
    ['slave_bracer_left'          ] = true, -- TR & PT - Dead Dremora Lord - Slave's Left Bracer
    ['slave_bracer_right'         ] = true, -- TR & PT - Dead Dremora Lord - Slave's Right Bracer
    -- [''] = true, --  -  - 
}

return module
