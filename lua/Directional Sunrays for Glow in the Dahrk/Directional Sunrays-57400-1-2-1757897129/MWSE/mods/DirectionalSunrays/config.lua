local defaultConfig = {
	enabled = true,
	innerLimit = 35,
	outerLimit = 70,
	nonstandardMeshes = {},
	ignoredMeshes = {
		["t_imp_setharbor_tradeshipin_01"] = true,
		["t_imp_setharbor_galleonin_cabin"] = true,
		["ab_in_impgalleonfull"] = true,
		["ab_in_impgalleoncabin"] = true,
		["t_imp_setharbor_tradeshipin_02"] = true,
		["t_imp_setharbor_galleonin_decks"] = true,
	}
}

return mwse.loadConfig("DirectionalSunrays", defaultConfig)