return {
    modName = "Hot Beverages",--change the name of the mod here
    modDescription =--Give the mod a description for the MCM
[[
Denina's Hot Beverages adds tea, coffee and hot cocoa to Morrowind.
This MWSE module will have a % chance to replace vanilla cups and mugs with hot beverages.

CREDITS:

    Scripting: Merlord, adapted to Hot Beverages by Danae
    Models: Kiteflyer
    Everything else: Denina
]],
    mcmDefaultValues = {
        enabled = true, 
        replacementChance = 50,--set the % chance to replace with booze here
        debug = false,
    },
    
    replacements = {
        --Remember to make these lowercase!
        misc_flask_03 = "dhb_mug_tea",
        misc_flask_01 = "dhb_mug_empty",
        misc_de_glass_yellow_01 = "dhb_mug_coffee",
        misc_de_glass_green_01 = "dhb_mug_hotcocoa",
    },

}