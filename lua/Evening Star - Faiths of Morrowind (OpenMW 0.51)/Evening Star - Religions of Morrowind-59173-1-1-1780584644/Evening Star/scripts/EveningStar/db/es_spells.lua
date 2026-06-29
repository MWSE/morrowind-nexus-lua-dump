-- spells that grant favor on successful cast

ES = ES or {}
ES.DB = ES.DB or {}

ES.DB.spells = {
	favorSpells = {
		-- prayer
		["almsivi intervention"] = { deity = { "vivec", "almalexia", "sothasil", }, favor = 2 },
		-- vivec spells
		["hand of vivec"]        = { deity = "vivec", favor = 1 },
		["healingtouch_sp_uniq"] = { deity = "vivec", favor = 1 },
		["vivec's feast"]        = { deity = "vivec", favor = 1 },
		["vivec's fury"]         = { deity = "vivec", favor = 1 },
		["vivec's humility"]     = { deity = "vivec", favor = 1 },
		["vivec's kiss"]         = { deity = "vivec", favor = 1 },
		["vivec's mercy"]        = { deity = "vivec", favor = 1 },
		["vivec's mystery"]      = { deity = "vivec", favor = 1 },
		["vivec's tears"]        = { deity = "vivec", favor = 1 },
		["vivec's_wrath"]        = { deity = "vivec", favor = 1 },
		["wrath of vivec"]       = { deity = "vivec", favor = 1 },
		-- almalexia spells
		["lady's grace"]		 = { deity = "almalexia", favor = 1 },
		["almalexia's grace"]	 = { deity = "almalexia", favor = 1 },
		-- sotha sil spells
		["sotha's grace"]	 = { deity = "sothasil", favor = 1 },
		["sotha's mirror"]	 = { deity = "sothasil", favor = 1 },
	},
}