local ashfall = include("mer.ashfall.interop")
if ashfall then
    --Overrides
    ashfall.registerOverrides{
        ingred_crab_meat_01 = {
            value = 15,
        },
        ingred_hound_meat_01 = {
            value = 15,
        },
        ingred_rat_meat_01 = {
            value = 10,
        }
    }
end