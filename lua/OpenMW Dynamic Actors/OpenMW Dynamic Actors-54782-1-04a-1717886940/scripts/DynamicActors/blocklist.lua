local blocklist = {

	-- if you have npc id names to block, add them to the list below. Lowercase letters only.
	-- any npc id that starts with the string will be blocked

		"am_",
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

		"am_alch",
		"am_camonna",
		"am_cleaner",

}


local settings = {

	-- do not modify these entries

	{ id = "am_alch", idle = 1 },
	{ id = "am_camonna", idle = 3 },
	{ id = "am_cleaner", idle = 1 },
--	{ id = "am_smith", turn = false, reset = true, idle = 1 },

}

return { block=blocklist, allow = allow, config=settings }

