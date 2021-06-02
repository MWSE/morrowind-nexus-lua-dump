return {
    modName = "Shinies",--change the name of the mod here
    modDescription =--Give the mod a description for the MCM
[[
This mod adds a random chance to replace certain chests with animated chests filled with treasure, and adds a rare chance for certain creatures and NPC classes to have additional treasure in their inventory.

CREDITS:

    Scripting: Merlord
    Models: Gawain Luminair W3
    Everything Else: Danae
]],
    mcmDefaultValues = {
        enabled = true, 
        shinyChance = 1,--set the % chance to replace with shinies here
        debug = false,
    },
    
    replacees = {--containers that can be replaced with shinies
        --Remember to make these lowercase!
        t_cyrimp_furn_chs1g025 = true,
        t_cyrimp_furn_chs1g050 = true,
        t_cyrimp_furn_chs1gem = true,
        t_cyrimp_furn_chs2g025 = true,
        t_cyrimp_furn_chs2g050 = true,
        t_cyrimp_furn_chs2gem = true,
        t_mwde_furn_chs2gem = true,
        chest_small_01_goldr500 = true,
        chest_small_01_gold_50 = true,
        chest_small_01_gold_25 = true,
        chest_small_01_gold_ran = true,
        chest_small_02_gems = true,
        chest_small_02_diamonds = true,
        chest_small_02_gold_25 = true,
        chest_small_02_gold_50 = true,
        chest_small_02_rndgold = true,
    },
    
    replacers = {--Ids of shinies. The mod will pick one at random
        --Remember to make these lowercase!
        "aa_chest_small_anim",
    },

    actorShinies = {--add shinies for creatures and classes here
        {
            creatureType = "daedra",
            shinyId = "aa_runes_rare",--must be leveled item
        },
        {
            class = "Noble",
            shinyId = "aa_all_gems_nobles",--must be leveled item
        }
    },
}
