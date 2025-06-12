local recipes = {}

recipes.recipeList = {
    ingred_moon_sugar_01 = {
        result = "potion_skooma_01",
        name = "Skooma",
        required = 10,
        difficulty = 50
    },
    ingred_saltrice_01 = {
        result = "potion_local_brew_01",
        name = "Mazte",
        required = 10,
        difficulty = 0
    },
    ingred_wickwheat_01 = {
        result = "potion_local_liquor_01",
        name = "Sujamma",
        required = 10,
        difficulty = 20
    },
    ingred_comberry_01 = {
        result = "potion_comberry_wine_01",
        name = "Shein",
        required = 10,
        difficulty = 10
    },
    potion_comberry_wine_01 = {
        result = "potion_comberry_brandy_01",
        name = "Greef",
        required = 10,
        difficulty = 40
    },
    Ingred_meadow_rye_01 = {
        result = "potion_cyro_whiskey_01",
        name = "Flin",
        required = 10,
        difficulty = 80
    }
}

--[[
    meadow rye = flin
    shein = greef
    comberry = shein
    wickwheat = sujamma
]]

recipes.mainIngredIds = {}
for id in pairs(recipes.recipeList) do
    recipes.mainIngredIds[id] = true
end

return recipes