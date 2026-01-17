local self = require("openmw.self")
local types = require("openmw.types")

local fightV = {
	--Morrowind
	["alit"] = 83,
	["alit_diseased"] = 85,
	["cliff racer"] = 85,
	["cliff racer_diseased"] = 87,
	["guar"] = 70,
	["guar_feral"] = 82,
	["kagouti"] = 83,
	["kagouti_diseased"] = 85,
	["kwama forager"] = 82,
	["mudcrab"] = 81,
	["nix-hound"] = 83,
	["rat"] = 81,
	["rat_diseased"] = 83,
	["rat_cave_fgrh"] = 82,
	["rat_cave_fgt"] = 82,
	["shalk"] = 81,
	["shalk_diseased"] = 83,
	["slaughterfish"] = 87,
	["slaughterfish_small"] = 81,
	--Bloodmoon
	["bm_bear_black"] = 82,
	["bm_bear_brown"] = 85,
	["bm_bear_snow_unique"] = 85,
	["bm_frost_boar"] = 83,
	["bm_wolf_grey"] = 83,
	["bm_wolf_grey_lvl_1"] = 83,
	["bm_wolf_red"] = 85,
	--Ttooth Ecology
	["ttooth_guar"] = 70,
	["ttooth_rat"] = 81,
	["ttooth_shalk"] = 81,
	["ttooth_kwama forager"] = 82,
	--OAAB
	["ab_fau_bat"] = 81,
	--Tamriel_Data
	["t_cyr_fau_bearcol_01"] = 83,
	["t_cyr_fau_bearcolds_01"] = 85,
	["t_cyr_fau_rat_01"] = 81,
	["t_cyr_fau_wolfcol_01"] = 83,
	["t_cyr_fau_wolfcolds_01"] = 85,
	["t_cyr_fau_wolfcol_02"] = 83,
	["t_cyr_fau_wolfcolds_02"] = 85,
	["t_glb_fau_bat_01"] = 81,
	["t_glb_fau_ratbk_01"] = 81,
	["t_glb_fau_fishslds_01"] = 90,
	["t_glb_fau_fishslsmds_01"] = 83,
	["t_mw_fau_ceph_01"] = 81,
	["t_mw_fau_cephds_01"] = 83,
	["t_mw_fau_cephbg_01"] = 83,
	["t_mw_fau_cephbgds_01"] = 85,
	["t_mw_fau_mucklch_01"] = 82,
	["t_sky_fau_bearbk_01"] = 82,
	["t_sky_fau_bearbkds_01"] = 85,
	["t_sky_fau_bearbr_01"] = 83,
	["t_sky_fau_bearbrds_01"] = 85,
	["t_sky_fau_bearred_01"] = 83,
	["t_sky_fau_bearredds_01"] = 85,
	["t_sky_fau_bearsn_01"] = 85,
	["t_sky_fau_wolfbla_01"] = 83,
	["t_sky_fau_wolfblasml_01"] = 83,
	["t_sky_fau_wolfblads_01"] = 85,
	["t_sky_fau_wolfgr_01"] = 83,
	["t_sky_fau_wolfgr_dis_01"] = 85,
	["t_sky_fau_wolfred_01"] = 83,
	["t_sky_fau_wolfredds_01"] = 85,
}

local function onInit()
	--print(self.object.recordId)
	if self.type.record(self.recordId).type == types.Creature.TYPE.Creatures then
		local newFightV = fightV[self.recordId]
		if newFightV then
			types.Actor.stats.ai.fight(self).base = newFightV
			--print(types.Actor.stats.ai.fight(self).modified)
		end
	end
end

return { engineHandlers = { onInit = onInit, onLoad = onInit } }
