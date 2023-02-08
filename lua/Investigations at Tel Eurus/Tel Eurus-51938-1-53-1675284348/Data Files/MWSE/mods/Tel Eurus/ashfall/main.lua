local ashfall = include("mer.ashfall.interop")
if ashfall then

    ashfall.registerActivators{
		DD_Flora_parasol_01 = "tree",
		DD_Flora_parasol_02 = "tree",
		DD_Flora_parasol_03 = "tree"
    }

    ashfall.registerWaterContainers{
		DD_EmptyJar = "glass",
        DD_EmptySVial = "bottle"
    }

    ashfall.registerFoods{
		DD_FoodTentacle = "meat",
		DD_FoodTwistBread = "food"
    }
	
end