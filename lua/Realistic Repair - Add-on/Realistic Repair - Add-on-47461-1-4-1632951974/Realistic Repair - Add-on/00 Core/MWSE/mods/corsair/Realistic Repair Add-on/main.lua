    local interop = require("mer.RealisticRepair.interop")

    local stations = {
        
		{ id = "_cor_LR_anvil_01", name = "Workbench", toolIdPattern = "hammer"  },
		{ id = "_cor_LR_anvil_01", name = "Workbench", toolIdPattern = "whetstone"  },
	    { id = "_cor_LR_forge_01", name = "Grindstone", toolIdPattern = "prong"   },
        { id = "_cor_LR_forge_01", name = "Grindstone", toolIdPattern = "whetstone" },
		{ id = "dr_tbl_grindstone_01", name = "Grindstone", toolIdPattern = "prong"   },
		{ id = "dr_tbl_workbench_01", name = "Workbench", toolIdPattern = "hammer"  },
		{ id = "dr_tbl_workbench_01", name = "Workbench", toolIdPattern = "whetstone"  },
		{ id = "T_Nor_Set_Forge_01", name = "Forge", toolIdPattern = "hammer" },
		{ id = "T_Nor_Set_Forge_02", name = "Forge", toolIdPattern = "hammer" },
        { id = "T_Nor_Set_GrindingWheel_01", name = "Grindstone", toolIdPattern = "prong" },
		{ id = "T_Nor_Set_GrindingWheel_02", name = "Grindstone", toolIdPattern = "prong" },
		{ id = "T_Imp_FurnP_Grindstone_01", name = "Grindstone", toolIdPattern = "prong" },
		{ id = "furn_t_fireplace_01", name = "Forge", toolIdPattern = "whetstone"  },
        { id = "furn_de_forge_01", name = "Forge", toolIdPattern = "whetstone"},
        { id = "furn_de_bellows_01", name = "Forge", toolIdPattern = "whetstone"},
        { id = "Furn_S_forge", name = "Forge", toolIdPattern = "whetstone"},
		{ id = "furn_anvil00", name = "Anvil", toolIdPattern = "whetstone"  },
    }
    for _, newStation in ipairs(stations) do
        interop.addStation(newStation)
    end