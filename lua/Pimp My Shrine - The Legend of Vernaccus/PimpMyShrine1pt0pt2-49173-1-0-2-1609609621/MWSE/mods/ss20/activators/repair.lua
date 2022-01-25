local interop = include("mer.RealisticRepair.interop")
if interop then
    local stations = {
        
        { id = "ss20_furn_dae_workbench_01", name = "Workbench", toolIdPattern = "hammer"  },
        { id = "ss20_furn_dae_workbench_01", name = "Workbench", toolIdPattern = "whetstone"  },
        { id = "ss20_furn_dae_grindstone_01", name = "Grindstone", toolIdPattern = "prong"   },
        { id = "ss20_furn_dae_grindstone_01", name = "Grindstone", toolIdPattern = "whetstone"   },
    }
    for _, newStation in ipairs(stations) do
        interop.addStation(newStation)
    end
end