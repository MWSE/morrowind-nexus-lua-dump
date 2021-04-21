-- Add IDs here for actors you want to not be allowed to enter combat.
local blockCombat = {
-- Vanilla pack creatures
	["rat_pack_rerlas"] = true,
	["scrib_rerlas"] = true,
	["rat_rerlas"] = true,
-- Beast Companions by Tizzo
	["aa1_paxon"] = true,
	["aa1_tetra"] = true,
-- Companion dogs by Emma
	["1a_comp_dog1"] = true,
	["1a_comp_dog2"] = true,
	["1a_comp_dog3"] = true,
	["1a_comp_dog4"] = true,
-- Companion cats by Emma
	["1em_cat11"] = true,
	["1em_cat3"] = true,
	["1em_cat4"] = true,
	["1em_cat5"] = true,
	["1em_cat8"] = true,
	["1em_kitten2"] = true,
	["1em_kitten6"] = true,
	["1em_kitten8"] = true,
	["1em_kitten9"] = true,
-- Pack Donkeys by Emma and Grumpy
	["1em_pdonk1"] = true,
	["1em_pdonk2"] = true,
	["1em_pdonk3"] = true,
-- Pack Animal Merchant by Baratheon79
	["bar_packguar_comp"] = true,
	["bar_packrat_comp"] = true,
-- A Little Friend by KAGS
	["db_unicorn_friend"] = true,
-- Little Hazel by MentalElf
	["zm_hazel"] = true,
-- Hircine's Quest by Gavrilo93 and Danae
	["aa_mj20_fox_comp"] = true,
-- Outlaws/CM_Partners
	["aa_cm_scrib"] = true,
	["cm_guar"] = true,
	["cm_t_Goat"] = true,
	["cm_tr_hoom"] = true,
	["cm_t_Rooster"] = true,
	["cm_tr_Velk"] = true,
-- Staff Agency by Danae, includes Little Rupert by Mental Elf
	["aa_sa_cat_f"] = true,
	["aa_sa_cat_m"] = true,
	["aa_sa_guar"] = true,
	["aa_sa_kitten1"] = true,
	["aa_sa_kitten2"] = true,
	["zm_rupert"] = true,
-- Pegasus Estate by Danae
	["aa_cat_ench"] = true,
	["aa_cat_f"] = true,
	["aa_cat_m"] = true,
	["aa_guar"] = true,
	["aa_kitten1"] = true,
	["aa_kitten2"] = true,
	["aa_md_worg_cub"] = true,
	["aa_md_worg_cub2"] = true,
	["aa_scrib_pet"] = true,
}

local function onCombatStart(e)
	if (blockCombat[e.actor.object.baseObject.id:lower()]) then
		return false
	end
end
event.register("combatStart", onCombatStart)