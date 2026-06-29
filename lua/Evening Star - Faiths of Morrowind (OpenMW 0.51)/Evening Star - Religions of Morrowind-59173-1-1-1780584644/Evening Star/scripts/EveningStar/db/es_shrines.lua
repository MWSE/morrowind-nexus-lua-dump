ES = ES or {}
ES.DB = ES.DB or {}

ES.DB.shrines = {
	shrineIds = {
		-- vivec shrines
		["ac_shrine_palace"]              = { deity = "vivec" }, -- palace of vivec
		["furn_shrine_vivec_cure_01"]     = { deity = "vivec" }, -- vivec fury shrine
		["ac_shrine_stopmoon"]            = { deity = "vivec" }, -- grace of daring (stop the moon)
		["ac_shrine_puzzlecanal"]         = { deity = "vivec" }, -- grace of courtesy (puzzle canal waterbreathing)
		["ac_shrine_gnisis"]              = { deity = "vivec" }, -- gnisis shrine
		["ac_shrine_gnisis_mv"]           = { deity = "vivec" }, -- gnisis secret shrine
		["furn_shrine_tribunal_cure_01"]  = { deity = {"vivec", "sothasil", "almalexia"} }, -- almsivi shrine
		["t_de_var_shrinesothamastery_01"]  = { deity = "sothasil" },
		["t_de_var_shrinealmamercy_01"]  = { deity = "almalexia" },
		-- in_sotha_sil00 sotha sil corpse
	},
	
	blessSpells = {
		["vivec's mystery"] = { deity = "vivec" },
		["soul of sotha sil"] = { deity = "sothasil" },
		["lady's grace shrine"] = { deity = "almalexia" },		
		["shrine_palace_sp"] = { deity = "vivec" },
		["shrine_stopmoon_sp"] = { deity = "vivec" },
		["shrine_puzzle_sp"] = { deity = "vivec" },
		["shrine_gnisis_sp"] = { deity = "vivec" },
		["shrine_bless_gnisis_mv"] = { deity = "vivec" },
		["t_de_res_sothasilsmastery"] = { deity = "sothasil" },
		["t_de_res_almalexiasmercy"] = { deity = "almalexia" },
		["t_de_var_shrineandothren_01"] = { deity = "almalexia" },
	},
}