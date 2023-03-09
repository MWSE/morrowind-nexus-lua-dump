return mwse.loadConfig("protective_helmets", {
	enableBlight = true,
	blightMag = 10,
	enableDisease = true,
	diseaseMag = 10,
	enablePoison = true,
	poisonMag = 10,

	blacklist = {},
	whitelist = {
		-- TR_Data
		["t_imp_chainmail_helm_01"] = true,

		-- RandomPal's Vanilla Friendly Wearables Expansion
		["^_imperial_battlemage_hood"] = true,
		["1ba_scarf_"] = true,
		["ah_ashdustmask"] = true,
		["sm_scarf_head"] = true,
		["tb_a_clothmask1"] = true,
		["tb_a_clothmask2"] = true,
		["tb_a_clothmask3"] = true,
		["vd_ashdustmask"] = true,
		["vd_chitin_mag_mask"] = true,
		["vd_gondaliergoggles"] = true
	}
})