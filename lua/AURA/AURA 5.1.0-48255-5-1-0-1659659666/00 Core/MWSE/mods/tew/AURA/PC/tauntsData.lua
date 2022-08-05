local this = {}

-- First key = player race
-- Second key = player sex
-- Third key = foe race
this.raceTaunts = {
	["a"] = {
		["f"] = {
			["Redguard"] = "Atk_AF001.mp3",
			["Orc"] = "Atk_AF002.mp3",
			["Nord"] = "Atk_AF003.mp3",
			["Khajiit"] = "Atk_AF004.mp3",
			["Imperial"] = "Atk_AF005.mp3",
			["High Elf"] = "Atk_AF006.mp3",
			["Dark Elf"] = "Atk_AF007.mp3",
			["Breton"] = "Atk_AF008.mp3",
			["Wood Elf"] = "Atk_AF009.mp3"
		},
		["m"] = {
			["Redguard"] = "Atk_AM001.mp3",
			["Orc"] = "Atk_AM002.mp3",
			["Nord"] = "Atk_AM003.mp3",
			["Khajiit"] = "Atk_AM004.mp3",
			["Imperial"] = "Atk_AM005.mp3",
			["High Elf"] = "Atk_AM006.mp3",
			["Dark Elf"] = "Atk_AM007.mp3",
			["Breton"] = "Atk_AM008.mp3",
			["Wood Elf"] = "Atk_AM009.mp3"
		}
	},
	["h"] = {
		["f"] = {
			["Redguard"] = "Atk_HF002.mp3",
			["Orc"] = "Atk_HF003.mp3",
			["Nord"] = "Atk_HF004.mp3",
			["Khajiit"] = "Atk_HF005.mp3",
			["Imperial"] = "Atk_HF006.mp3",
			["Dark Elf"] = "Atk_HF008.mp3",
			["Breton"] = "Atk_HF001.mp3",
			["Wood Elf"] = "Atk_HF009.mp3"
		},
		["m"] = {
			["Nord"] = "Atk_HM004.mp3"
		}
	},
	["k"] = {
		["f"] = {
			["Argonian"] = "Atk_KF009.mp3",
			["Redguard"] = "Atk_KF002.mp3",
			["Orc"] = "Atk_KF003.mp3",
			["Nord"] = "Atk_KF004.mp3",
			["Dark Elf"] = "Atk_KF008.mp3",
			["Wood Elf"] = "Atk_KF010.mp3",
		},
		["m"] = {
			["Argonian"] = "Atk_KM009.mp3",
			["Redguard"] = "Atk_KM002.mp3",
			["Orc"] = "Atk_KM003.mp3",
			["Nord"] = "Atk_KM004.mp3",
			["Dark Elf"] = "Atk_KM008.mp3",
			["Wood Elf"] = "Atk_KM010.mp3",
		}
	}
}

this.NPCtaunts = {

	["a"] = {
		["f"] = {
			"Atk_AF001.mp3",
			"Atk_AF002.mp3",
			"Atk_AF003.mp3",
			"Atk_AF004.mp3",
			"Atk_AF005.mp3",
			"Atk_AF006.mp3",
			"Atk_AF007.mp3",
			"Atk_AF008.mp3",
			"Atk_AF009.mp3",
			"Atk_AF010.mp3",
			"Atk_AF012.mp3",
			"Atk_AF013.mp3",
			"Atk_AF014.mp3",
			"Atk_AF017.mp3",

		},
		["m"] = {
			"Atk_AM001.mp3",
			"Atk_AM002.mp3",
			"Atk_AM003.mp3",
			"Atk_AM004.mp3",
			"Atk_AM005.mp3",
			"Atk_AM006.mp3",
			"Atk_AM007.mp3",
			"Atk_AM008.mp3",
			"Atk_AM009.mp3",
			"Atk_AM010.mp3",
			"Atk_AM011.mp3",
			"Atk_AM012.mp3",
			"Atk_AM013.mp3",
			"Atk_AM014.mp3",
			"Atk_AM015.mp3",

		},

	},
	["b"] = {
		["f"] = {
			"Atk_BF001.mp3",
			"Atk_BF002.mp3",
			"Atk_BF003.mp3",
			"Atk_BF004.mp3",
			"Atk_BF005.mp3",
			"Atk_BF006.mp3",
			"Atk_BF007.mp3",
			"Atk_BF008.mp3",
			"Atk_BF009.mp3",
			"Atk_BF010.mp3",
			"Atk_BF012.mp3",
			"Atk_BF013.mp3",
			"Atk_BF014.mp3",
			"Atk_BF015.mp3",

		},
		["m"] = {
			"Atk_BM001.mp3",
			"Atk_BM002.mp3",
			"Atk_BM003.mp3",
			"Atk_BM004.mp3",
			"Atk_BM005.mp3",
			"Atk_BM006.mp3",
			"Atk_BM007.mp3",
			"Atk_BM008.mp3",
			"Atk_BM009.mp3",
			"Atk_BM010.mp3",
			"Atk_BM012.mp3",
			"Atk_BM013.mp3",
			"Atk_BM014.mp3",
			"Atk_BM015.mp3",

		},

	},
	["d"] = {
		["f"] = {
			"Atk_DF001.mp3",
			"Atk_DF002.mp3",
			"Atk_DF003.mp3",
			"Atk_DF004.mp3",
			"Atk_DF005.mp3",
			"Atk_DF006.mp3",
			"Atk_DF007.mp3",
			"Atk_DF008.mp3",
			"Atk_DF009.mp3",
			"Atk_DF010.mp3",
			"Atk_DF011.mp3",
			"Atk_DF012.mp3",
			"Atk_DF013.mp3",

		},
		["m"] = {
			"Atk_DM001.mp3",
			"Atk_DM002.mp3",
			"Atk_DM003.mp3",
			"Atk_DM004.mp3",
			"Atk_DM005.mp3",
			"Atk_DM006.mp3",
			"Atk_DM007.mp3",
			"Atk_DM008.mp3",
			"Atk_DM009.mp3",
			"Atk_DM010.mp3",
			"Atk_DM011.mp3",
			"Atk_DM012.mp3",
			"Atk_DM013.mp3",
			"Atk_DM014.mp3",

		},

	},
	["h"] = {
		["f"] = {
			"Atk_HF001.mp3",
			"Atk_HF002.mp3",
			"Atk_HF003.mp3",
			"Atk_HF004.mp3",
			"Atk_HF005.mp3",
			"Atk_HF006.mp3",
			"Atk_HF007.mp3",
			"Atk_HF008.mp3",
			"Atk_HF009.mp3",
			"Atk_HF010.mp3",
			"Atk_HF011.mp3",
			"Atk_HF012.mp3",
			"Atk_HF013.mp3",
			"Atk_HF014.mp3",
			"Atk_HF015.mp3",

		},
		["m"] = {
			"Atk_HM001.mp3",
			"Atk_HM002.mp3",
			"Atk_HM003.mp3",
			"Atk_HM004.mp3",
			"Atk_HM005.mp3",
			"Atk_HM006.mp3",
			"Atk_HM007.mp3",
			"Atk_HM008.mp3",
			"Atk_HM009.mp3",
			"Atk_HM010.mp3",
			"Atk_HM011.mp3",
			"Atk_HM012.mp3",
			"Atk_HM013.mp3",
			"Atk_HM014.mp3",
			"Atk_HM015.mp3",

		},

	},
	["i"] = {
		["f"] = {
			"Atk_IF001.mp3",
			"Atk_IF002.mp3",
			"Atk_IF003.mp3",
			"Atk_IF004.mp3",
			"Atk_IF005.mp3",
			"Atk_IF006.mp3",
			"Atk_IF007.mp3",
			"Atk_IF008.mp3",
			"Atk_IF009.mp3",
			"Atk_IF010.mp3",
			"Atk_IF012.mp3",
			"Atk_IF013.mp3",
			"Atk_IF014.mp3",
			"Atk_IF015.mp3",

		},
		["m"] = {
			"Atk_IM001.mp3",
			"Atk_IM002.mp3",
			"Atk_IM003.mp3",
			"Atk_IM004.mp3",
			"Atk_IM005.mp3",
			"Atk_IM006.mp3",
			"Atk_IM007.mp3",
			"Atk_IM008.mp3",
			"Atk_IM009.mp3",
			"Atk_IM010.mp3",
			"Atk_IM011.mp3",
			"Atk_IM012.mp3",
			"Atk_IM013.mp3",
			"Atk_IM014.mp3",

		},

	},
	["k"] = {
		["f"] = {
			"Atk_KF001.mp3",
			"Atk_KF002.mp3",
			"Atk_KF003.mp3",
			"Atk_KF004.mp3",
			"Atk_KF005.mp3",
			"Atk_KF006.mp3",
			"Atk_KF007.mp3",
			"Atk_KF008.mp3",
			"Atk_KF009.mp3",
			"Atk_KF010.mp3",
			"Atk_KF012.mp3",
			"Atk_KF013.mp3",
			"Atk_KF014.mp3",
			"Atk_KF015.mp3",

		},
		["m"] = {
			"Atk_KM001.mp3",
			"Atk_KM002.mp3",
			"Atk_KM003.mp3",
			"Atk_KM004.mp3",
			"Atk_KM005.mp3",
			"Atk_KM006.mp3",
			"Atk_KM007.mp3",
			"Atk_KM008.mp3",
			"Atk_KM009.mp3",
			"Atk_KM010.mp3",
			"Atk_KM012.mp3",
			"Atk_KM013.mp3",
			"Atk_KM014.mp3",
			"Atk_KM015.mp3",

		},

	},
	["n"] = {
		["f"] = {
			"Atk_NF001.mp3",
			"Atk_NF002.mp3",
			"Atk_NF003.mp3",
			"Atk_NF004.mp3",
			"Atk_NF005.mp3",
			"Atk_NF006.mp3",
			"Atk_NF007.mp3",
			"Atk_NF008.mp3",
			"Atk_NF009.mp3",
			"Atk_NF010.mp3",
			"Atk_NF012.mp3",
			"Atk_NF013.mp3",
			"Atk_NF014.mp3",
			"Atk_NF015.mp3",

		},
		["m"] = {
			"Atk_NM001.mp3",
			"Atk_NM002.mp3",
			"Atk_NM003.mp3",
			"Atk_NM004.mp3",
			"Atk_NM005.mp3",
			"Atk_NM006.mp3",
			"Atk_NM007.mp3",
			"Atk_NM008.mp3",
			"Atk_NM009.mp3",
			"Atk_NM010.mp3",
			"Atk_NM011.mp3",
			"Atk_NM012.mp3",
			"Atk_NM013.mp3",
			"Atk_NM020.mp3",

		},

	},
	["o"] = {
		["f"] = {
			"Atk_OF001.mp3",
			"Atk_OF002.mp3",
			"Atk_OF003.mp3",
			"Atk_OF004.mp3",
			"Atk_OF005.mp3",
			"Atk_OF006.mp3",
			"Atk_OF007.mp3",
			"Atk_OF008.mp3",
			"Atk_OF009.mp3",
			"Atk_OF010.mp3",
			"Atk_OF011.mp3",
			"Atk_OF012.mp3",
			"Atk_OF013.mp3",
			"Atk_OF014.mp3",
			"Atk_OF015.mp3",

		},
		["m"] = {
			"Atk_OM001.mp3",
			"Atk_OM002.mp3",
			"Atk_OM003.mp3",
			"Atk_OM004.mp3",
			"Atk_OM005.mp3",
			"Atk_OM006.mp3",
			"Atk_OM007.mp3",
			"Atk_OM008.mp3",
			"Atk_OM009.mp3",
			"Atk_OM010.mp3",
			"Atk_OM011.mp3",
			"Atk_OM012.mp3",
			"Atk_OM013.mp3",
			"Atk_OM014.mp3",
			"Atk_OM015.mp3",

		},

	},
	["r"] = {
		["f"] = {
			"Atk_RF002.mp3",
			"Atk_RF003.mp3",
			"Atk_RF004.mp3",
			"Atk_RF005.mp3",
			"Atk_RF006.mp3",
			"Atk_RF007.mp3",
			"Atk_RF008.mp3",
			"Atk_RF009.mp3",
			"Atk_RF010.mp3",
			"Atk_RF012.mp3",
			"Atk_RF013.mp3",
			"Atk_RF014.mp3",
			"Atk_RF015.mp3",

		},
		["m"] = {
			"Atk_RM001.mp3",
			"Atk_RM002.mp3",
			"Atk_RM003.mp3",
			"Atk_RM004.mp3",
			"Atk_RM005.mp3",
			"Atk_RM006.mp3",
			"Atk_RM007.mp3",
			"Atk_RM008.mp3",
			"Atk_RM009.mp3",
			"Atk_RM010.mp3",
			"Atk_RM011.mp3",
			"Atk_RM012.mp3",
			"Atk_RM013.mp3",
			"Atk_RM014.mp3",
			"Atk_RM015.mp3",
			"Atk_RM016.mp3",
			"Atk_RM017.mp3",
			"Atk_RM018.mp3",

		},

	},
	["w"] = {
		["f"] = {
			"Atk_WF001.mp3",
			"Atk_WF002.mp3",
			"Atk_WF003.mp3",
			"Atk_WF004.mp3",
			"Atk_WF005.mp3",
			"Atk_WF006.mp3",
			"Atk_WF007.mp3",
			"Atk_WF008.mp3",
			"Atk_WF009.mp3",
			"Atk_WF010.mp3",
			"Atk_WF011.mp3",
			"Atk_WF012.mp3",
			"Atk_WF013.mp3",
			"Atk_WF014.mp3",

		},
		["m"] = {
			"Atk_WM001.mp3",
			"Atk_WM002.mp3",
			"Atk_WM003.mp3",
			"Atk_WM004.mp3",
			"Atk_WM005.mp3",
			"Atk_WM006.mp3",
			"Atk_WM007.mp3",
			"Atk_WM008.mp3",
			"Atk_WM009.mp3",
			"Atk_WM010.mp3",
			"Atk_WM011.mp3",
			"Atk_WM012.mp3",
			"Atk_WM013.mp3",
			"Atk_WM018.mp3",

		},

	},

}

this.Crtaunts = {

	["a"] = {
		["f"] = {
			"CrAtk_AF001.mp3",
			"CrAtk_AF002.mp3",
			"CrAtk_AF003.mp3",
			"CrAtk_AF004.mp3",
			"CrAtk_AF005.mp3",

		},
		["m"] = {
			"CrAtk_AM001.mp3",
			"CrAtk_AM002.mp3",
			"CrAtk_AM003.mp3",
			"CrAtk_AM004.mp3",
			"CrAtk_AM005.mp3",

		},

	},
	["b"] = {
		["f"] = {
			"CrAtk_BF001.mp3",
			"CrAtk_BF002.mp3",
			"CrAtk_BF003.mp3",
			"CrAtk_BF004.mp3",
			"CrAtk_BF005.mp3",

		},
		["m"] = {
			"CrAtk_BM001.mp3",
			"CrAtk_BM002.mp3",
			"CrAtk_BM003.mp3",
			"CrAtk_BM004.mp3",
			"CrAtk_BM005.mp3",

		},

	},
	["d"] = {
		["f"] = {
			"CrAtk_DF001.mp3",
			"CrAtk_DF002.mp3",
			"CrAtk_DF003.mp3",
			"CrAtk_DF004.mp3",
			"CrAtk_DF005.mp3",

		},
		["m"] = {
			"CrAtk_AM001.mp3",
			"CrAtk_AM002.mp3",
			"CrAtk_AM003.mp3",
			"CrAtk_AM004.mp3",
			"CrAtk_AM005.mp3",

		},

	},
	["h"] = {
		["f"] = {
			"CrAtk_HF001.mp3",
			"CrAtk_HF002.mp3",
			"CrAtk_HF003.mp3",
			"CrAtk_HF004.mp3",
			"CrAtk_HF005.mp3",

		},
		["m"] = {
			"CrAtk_HM001.mp3",
			"CrAtk_HM002.mp3",
			"CrAtk_HM003.mp3",
			"CrAtk_HM004.mp3",
			"CrAtk_HM005.mp3",

		},

	},
	["i"] = {
		["f"] = {
			"CrAtk_IF001.mp3",
			"CrAtk_IF002.mp3",
			"CrAtk_IF003.mp3",
			"CrAtk_IF004.mp3",
			"CrAtk_IF005.mp3",

		},
		["m"] = {
			"CrAtk_IM001.mp3",
			"CrAtk_IM002.mp3",
			"CrAtk_IM003.mp3",
			"CrAtk_IM004.mp3",
			"CrAtk_IM005.mp3",

		},

	},
	["k"] = {
		["f"] = {
			"CrAtk_KF001.mp3",
			"CrAtk_KF002.mp3",
			"CrAtk_KF003.mp3",
			"CrAtk_KF004.mp3",
			"CrAtk_KF005.mp3",

		},
		["m"] = {
			"CrAtk_KM001.mp3",
			"CrAtk_KM002.mp3",
			"CrAtk_KM003.mp3",
			"CrAtk_KM004.mp3",
			"CrAtk_KM005.mp3",

		},

	},
	["n"] = {
		["f"] = {
			"CrAtk_NF001.mp3",
			"CrAtk_NF002.mp3",
			"CrAtk_NF003.mp3",
			"CrAtk_NF004.mp3",
			"CrAtk_NF005.mp3",

		},
		["m"] = {
			"CrAtk_NM001.mp3",
			"CrAtk_NM002.mp3",
			"CrAtk_NM003.mp3",
			"CrAtk_NM004.mp3",
			"CrAtk_NM005.mp3",

		},

	},
	["o"] = {
		["f"] = {
			"CrAtk_OF001.mp3",
			"CrAtk_OF002.mp3",
			"CrAtk_OF003.mp3",
			"CrAtk_OF004.mp3",
			"CrAtk_OF005.mp3",

		},
		["m"] = {
			"CrAtk_OM001.mp3",
			"CrAtk_OM002.mp3",
			"CrAtk_OM003.mp3",
			"CrAtk_OM004.mp3",
			"CrAtk_OM005.mp3",

		},

	},
	["r"] = {
		["f"] = {
			"CrAtk_RF001.mp3",
			"CrAtk_RF002.mp3",
			"CrAtk_RF003.mp3",
			"CrAtk_RF004.mp3",
			"CrAtk_RF005.mp3",

		},
		["m"] = {
			"CrAtk_RM001.mp3",
			"CrAtk_RM002.mp3",
			"CrAtk_RM003.mp3",
			"CrAtk_RM004.mp3",
			"CrAtk_RM005.mp3",

		},

	},
	["w"] = {
		["f"] = {
			"CrAtk_WF001.mp3",
			"CrAtk_WF002.mp3",
			"CrAtk_WF003.mp3",
			"CrAtk_WF004.mp3",
			"CrAtk_WF005.mp3",

		},
		["m"] = {
			"CrAtk_WM001.mp3",
			"CrAtk_WM002.mp3",
			"CrAtk_WM003.mp3",
			"CrAtk_WM004.mp3",
			"CrAtk_WM005.mp3",

		},

	},

}

return this
