return {
    --Mod name will be used for the MCM menu as well as the name of the config .json file.
    modName = "Guarno Coffee",
    --Description for the MCM sidebar
    modDescription =
[[
A rare and highly prized form of coffee can be brewed from partially digested comberries harvested from guar droppings.
]],
    mcmDefaultValues = {
        enabled = true, 
        debug = false,
        digestionInterval = 5
    },
    
    --Other static configs can go in here too
    comberryIds = {
        ingred_comberry_01 = true,
        flora_comberry_01 = true,
    },
    guarnoId = 'ingred_guarno',
}