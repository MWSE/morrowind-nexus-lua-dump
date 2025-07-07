local blocklist = {

	-- if you have npc id names to block, add them to the list below. Lowercase letters only.
	-- any npc id that starts with the string will be blocked

		"aakarrv_poshlatrader1",
		"aakarrv_poshlatrader2",
		"aakarrv_poshlaguest2",
		"aakarrv_poshlaguest1",
		"aakarrv_poshlaguest4",
		"aakarrv_poshlaguest5",

}


local allow = {

	-- these id names will always be allowed, and will override the blocklist. Lowercase letters only.
	-- any npc id that starts with the string will be allowed

		"am_camonna",
		"am_cleaner",

}


	-- do not modify entries below this line


local niflist = {

	["am_alchemist.nif"] = {"idle9", "idle"},
	["am_bard2.nif"] = {"idle2"},
	["am_beggar.nif"] = {"idle2", "idle3", "idle4", "idle"},
	["am_dreamera.nif"] = {"idle2", "idle"},
	["am_dreamerb.nif"] = {"idle6", "idle"},
	["am_drummer03.nif"] = {"idle2", "idle"},
	["am_eater.nif"] = {"idle2"},
	["am_fishman.nif"] = {"idle2", "idle3", "idle"},
	["am_luteplaying.nif"] = {"idle2", "idle"},
	["am_reader1.nif"] = {"idle", "idle2", "idle3"},
	["am_reader2.nif"] = {"idle2", "idle3", "idle4"},
	["am_sitting.nif"] = {"idle2", "idle3", "idle4"},
	["am_smith.nif"] = {"idle", "idle2", "idle3"},
--	["am_writer02.nif"] = {"idle2", "idle3", "idle4"},
	["am_writer02.nif"] = {"all"},

	["am_sitbar.nif"] = {"idle8", "idle9"},
	["bandit.nif"] = {"idle8"},
	["farmer.nif"] = {"idle8"},
	["farmer2.nif"] = {"idle8", "idle9"},
	["miner.nif"] = {"idle8", "idle9"},
	["miner2.nif"] = { "all" },
	["prayerdf.nif"] = {"idle8", "idle9"},
	["prayerdm.nif"] = {"idle8", "idle9"},
	["slavesitting.nif"] = {"idle9"},

	["va_sitting.nif"] = { "idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8", "idle9" },
	["va_sittingdunmertest.nif"] = { "idle2" },

	["anim_drunk0x2.nif"] = { "idle9" },
	["anim_girlsitdrinktea.nif"] = { "idle9" },
	["anim_sitpleading.nif"] = { "idle9" },
	["anim_sitthreatening.nif"] = { "idle9" },

	["mountedguar1.nif"] = { "all" },
	["mountedguar1muzzle.nif"] = { "all" },
	["mountedguar2.nif"] = { "all" },
	["mountedguar2muzzle.nif"] = { "all" },

	-- Shadow of Aetherius
	["sit1.nif"] = { "idle9" },
	["sit2.nif"] = { "idle9" },
	["sit3.nif"] = { "idle9" },


}


local config = {


--	{ id = "am_alch", idle = 1 },
	{ id = "am_camonna", idle = 3 },
	{ id = "am_cleaner", idle = 1 },
--	{ id = "am_smith", turn = false, reset = true, idle = 1 },

}

return { block=blocklist, allow = allow, byAnim = niflist, config=config }

