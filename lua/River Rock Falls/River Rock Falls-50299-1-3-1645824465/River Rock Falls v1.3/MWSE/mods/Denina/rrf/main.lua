local ashfall = include("mer.ashfall.interop")
if ashfall then

    ashfall.registerActivators{
        T_Com_Set_Well_02 = "waterClean",
		OS_gut_trees_pine2 = "tree",
        OS_gut_trees_B5 = "tree",
        FS_flora_tree_ndib5 = "tree",
        OS_gut_trees_F4 = "tree",
        OS_gut_trees_F6 = "tree",
    }

    ashfall.registerWaterContainers{
        rrfm_silver_pitcher = "redwarePitcher",
    }
end