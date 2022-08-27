local ashfall = include("mer.ashfall.interop")
if ashfall then

    ashfall.registerWoodAxes{
        {
            id = "MwG_axe_iron_01",
            registerForBackpacks = true,
        },
        {
            id = "MwG_axe_silver_01",
            registerForBackpacks = true,
        },
        {
            id = "MwG_axe_nordic_01",
            registerForBackpacks = true,
        },
        {
            id = "MwG_axe_steel_01",
            registerForBackpacks = true,
        },
    }
end