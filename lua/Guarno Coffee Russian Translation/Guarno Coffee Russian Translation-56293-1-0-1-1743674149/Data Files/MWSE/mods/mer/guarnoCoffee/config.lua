return {
    --Mod name will be used for the MCM menu as well as the name of the config .json file.
    modName = "Кофе Гуарно",
    configPath = "Guarno Coffee",
    --Description for the MCM sidebar
    modDescription =
[[
Редкий и очень ценный вид кофе можно сварить из частично переваренных ягод комуники, собранных из помета гуара.
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