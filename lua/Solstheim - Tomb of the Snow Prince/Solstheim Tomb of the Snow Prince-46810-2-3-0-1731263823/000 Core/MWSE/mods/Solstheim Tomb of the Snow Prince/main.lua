local ashfall = include("mer.ashfall.interop")
if ashfall then
	ashfall.registerHeatSources{
		SP_Glb_HotSpring_Circle512_01 = 50,
		SP_Glb_HotSpring_Circle1024_01 = 50,
	}
	ashfall.registerWaterSource{
        name = "Well (Dirty)",
        isDirty = true,
        ids = {
            "Ex_colony_well",
        }
    }
end