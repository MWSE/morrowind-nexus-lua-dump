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
	"tol_m7_bathelt",
	"tol_m7_aleko",
	"tol_m7_galmel",
	"tol_m7_soniveln",
	"tol_m7_bathelt2",
	"tol_m7_aleko2",
	"tol_m7_galmel2",
	"tol_m7_soniveln2",
	"tol_m7_ordinator",
	"tol_m2_bathelt",
	"tol_m2_aleko",
	"tol_m2_galmel",
	"tol_m2_soniveln",
	"tol_m2_wc_ord1",
	"tol_m2_wc_ord2",
	"tol_m2_wc_ord3",
	"tol_m2_wc_ord4",
}


local allow = {

	-- always allow an NPC to be animated. Will override the blocklist. Lowercase letters only.
	-- any NPC ID that starts with the string will be allowed

		"am_camonna",

}


return { block=blocklist, allow = allow }

