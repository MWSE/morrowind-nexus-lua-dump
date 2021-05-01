return {
    --Mod name will be used for the MCM menu as well as the name of the config .json file.
    modName = "Dynamic Book Size Adjuster",
    --Description for the MCM sidebar
    modDescription =
[[
Many items in Morrowind are unrealistically large, but none moreso than books. 

This mod doesn't affec the size of books already placed in the game, as that would make libraries look extremely scarce. Instead, this mod will adjust the scale of any book newly placed down by the player.
]],
    mcmDefaultValues = {
        enabled = true, 
        scale = 75,
        debug = false,
    },

}