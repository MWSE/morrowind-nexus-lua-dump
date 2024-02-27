return {
    modName = "Booze for Purists",--change the name of the mod here
    modDescription =--Give the mod a description for the MCM
[[
Adds various alcoholic beverages to inns based on their region. Also adds a chance to replace certain bottles with booze, and adds a rare chance for NPCs to have booze added to their inventory, based on their race.
 
CREDITS:

    Scripting: Merlord
    Models: Rougetet
    What's left: Danae
]],
    mcmDefaultValues = {
        enabled = true, 
        bottleChance = 1,--set the % chance to replace with booze here
        debug = false,
    },
    
    bottleReplacements = {--bottles that can be replaced with booze
        --Remember to make these lowercase!
        misc_com_bottle_08 = "lfl_br_morrowind",
        misc_com_bottle_05 = "lfl_br_vvardenfell",
        misc_com_bottle_04 = "lfl_br_tamriel",
    },

    raceReplacements = {
        ["argonian"] = "aa_booze_argo",
        ["breton"] = "aa_booze_bret",
        ["dark elf"] = "aa_booze_dun",
        ["high elf"] = "aa_booze_alt",
        ["imperial"] = "aa_booze_imp",
        ["khajiit"] = "aa_booze_khajiit",
        ["nord"] = "aa_booze_nord",
        ["orc"] = "aa_booze_orc",
        ["redguard"] = "aa_booze_rg",
        ["wood elf"] = "aa_booze_bos",
    },

}