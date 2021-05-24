return {
    modName = "Foods",--change the name of the mod here
    modDescription =--Give the mod a description for the MCM
[[
Taddeus' Foods of Tamriel is a very trimmed down version of Necessities of Morrowind.
This MWSE module will have a % chance to replace vanilla foods with NOM foods.

CREDITS:

    Scripting: Merlord
    Models: Taddeus et al.
    What's left: Danae
]],
    mcmDefaultValues = {
        enabled = true, 
        replacementChance = 1,--set the % chance to replace with booze here
        debug = false,
    },
    
    replacements = {--bottles that can be replaced with booze
        --Remember to make these lowercase!
        ingred_crab_meat_01 = "nom_food_cabbage",
        ingred_rat_meat_01 = "ingred_mouse_meat_mva",
        ingred_hound_meat_01 = "nom_food_chickenleg1",
        ingred_corkbulb_root_01 = "nom_food_corkbulb_roast",
        ingred_kwama_cuttle_01 = "nom_salt",
        ingred_bread_01 = "nom_sltw_food_bread_corn",
        ingred_ash_yam_01 = "nom_food_ash_yam"
    },

}