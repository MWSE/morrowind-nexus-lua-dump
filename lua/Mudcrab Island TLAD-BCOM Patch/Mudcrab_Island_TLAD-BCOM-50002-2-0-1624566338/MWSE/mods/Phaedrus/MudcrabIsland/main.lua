local ashfall = include("mer.ashfall.interop")

if ashfall then

	ashfall.registerActivators{
		MI_rain_barrel_02 = "well",
    }

	ashfall.registerHeatSources{
		MI_torch = 20,
		MI_Fire_01 = 60,
		MI_bigfire = 200,
		MI_littlefire = 100,
		MI_firepit = 60,
		MI_firepit_ever = 60,
		MI_stove_fire = 50,
	}
end

mwse.log("[Mudcrab Island] initialised.")
