local ashfall = include("mer.ashfall.interop")
if ashfall then

    ashfall.registerActivators{
		vv23_Flora_TallTree01 = "tree",
		vv23_Flora_TallTree02 = "tree",
		vv23_Flora_TallTree03 = "tree",
		VV23_Fx_WaterFallSmall = "waterDirty",
		VV23_Fx_WaterRect256c = "waterDirty",
		vv23_Terr_StreamGravelPyShort01 = "partial",
		vv23_Terr_StreamGravelPyShort02 = "partial",
    }

    ashfall.registerWaterContainers{
        -- ab_misc_6thmug = "mug",
        -- ab_misc_combottle_01 = "bottle",
		-- ab_misc_comkagoutihorn = "flask",
		-- AB_Misc_GobletSkull = "goblet",
        -- ab_misc_compewtercup01 = "cup",
        -- ab_misc_compewterpot_01 = "pot",
        -- ab_misc_comsilvertank_01 = "tankard"
    }

    ashfall.registerFoods{
		-- AB_IngCrea_SturgeonMeat03 = "meat",
		-- AB_IngCrea_SturgeonRoe = "food",
		-- AB_IngFlor_ViMuscaria_01 = "mushroom",
		-- AB_IngFlor_Harrada_02 = "vegetable",
		-- AB_IngFlor_BlueKanet_01 = "herb"
    }
	
	ashfall.registerWoodAxes{
		-- "AB_w_ToolWoodAxe",
		-- "AB_w_ImpEtool"
	
	}

    ashfall.registerHeatSources{
		-- AB_Fx_Lava1024 = 250,
		-- AB_In_LavaCrust03 = 100
    }


end