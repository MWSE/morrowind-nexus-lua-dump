local blocklist = {

	-- block an NPC from turning to face the player and playing idle animations
	-- add the record ID of the NPC to the list below. Lowercase letters only.
	-- any NPC ID that starts with the string will be blocked

	"aakarrv_poshlatrader1",
	"aakarrv_poshlatrader2",
	"aakarrv_poshlaguest2",
	"aakarrv_poshlaguest1",
	"aakarrv_poshlaguest4",
	"aakarrv_poshlaguest5",

}


local allow = {

	-- always allow an NPC to be animated. Will override the blocklist. Lowercase letters only.
	-- any NPC ID that starts with the string will be allowed

		"am_camonna",

}


return { block=blocklist, allow = allow }

