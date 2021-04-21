--Enter race ids as lower case
local config =  {
    undead = {
        creatureType = tes3.creatureType.undead,
        races = {
            ["skeletonrace"] = true,
            ["deadite"] = true,
            ["deadite_g"] = true,
            ["deadite_m"] = true,
            ["deadite_p"] = true,
            ["deadite_y"] = true,
            ["undead"] = true,
            ["zombie"] = true,
            ["ancestral_ghost_race"] = true,
            ["greater_bw_race"] = true,
            ["lesser_bw_race"] = true,
            ["lich_race_ap"] = true,
            ["skeleton_race_ap"] = true,
            ["ghoul"] = true,
            ["draugr lord"] = true,
        }
    },

    ash = {
        creatureType = tes3.creatureType.humanoid,
		spell = "corprus",
        races = {
            ["ash ghoul"] = true,
            ["ascended_sleeper_race"] = true,
            ["ash_ghoul_race"] = true,
            ["ash_slave_race"] = true,
            ["ash_vampire_race"] = true,
            ["ash_zombie_race"] = true,
            ["corprus_stalker_race"] = true,
            ["dagoth_race"] = true,
            ["lame_corprus_race"] = true,
            ["dagoth"] = true,
        }
    },

    daedraRaces = {
        creatureType = tes3.creatureType.daedra,
        races = {
            ["war_golden saint"] = true,
            ["war_gs2"] = true,
            ["twilght winged beastrace"] = true,
            ["twilight winged"] = true,
            ["loth"] = true,
            ["scamprace"] = true,
            ["azura_prince_race"] = true,
            ["clanfear_race_ap"] = true,
            ["daedroth_race_ap"] = true,
            ["dremora_race_ap"] = true,
            ["flame_atronach_race"] = true,
            ["golden_saint_ap_race"] = true,
            ["hircine_prince_race"] = true,
            ["scamp_race_ap"] = true,
            ["or_greendaemon"] = true,
            ["or_reddaemon"] = true,
            ["or_whitedaemon"] = true,
            ["dremorarace"] = true,
            ["dk_dremoragolden"] = true,
            ["dk_dremoras"] = true,
            ["dk_dremorsflame"] = true,
            ["daedi"] = true,
            ["twilight"] = true,
            ["twilightsiren"] = true,
            ["_eb_dominion"] = true,
            ["clanfear_race_wm"] = true,
            ["dremora_rts"] = true,
            ["war_dremora"] = true,
        }
    }
}


local function onRefNodeCreated(e)
    if not ( tes3.player and tes3.player.object and tes3.player.object.race ) then return end

    local playerRace = tes3.player.object.race.id:lower()
    local refType = e.reference.object.type

    for _, data in pairs(config) do
        if data.creatureType ~= nil then
			if data.races[playerRace] and refType == data.creatureType then
				e.reference.mobile.fight = 0
				return
			end
		end
		if data.spell ~= nil then
			local spell = tes3.getObject(data.spell)
			if spell and tes3.mobilePlayer:isAffectedByObject(spell) then
				e.reference.mobile.fight = 0
				return
			end
		end
    end
 end
 
 event.register("mobileActivated", onRefNodeCreated)
