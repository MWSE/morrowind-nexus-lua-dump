local v3 = common.openmw.util.vector3

return {

	byAnim = {

	["meshes/"] = {},
	["meshes/base_anim.nif"] = {},
	["meshes/base_anim_female.nif"] = {},
	["meshes/base_animkna.nif"] = {},
	["meshes/epos_kha_upr_anim_f.nif"] = {},
	["meshes/epos_kha_upr_anim_m.nif"] = {},
	["meshes/pi_tsa_base_anim.nif"] = {},

	["am_beggar.nif"] = { 35, keys={"idle2", "idle3", "idle4", "idle"} },		-- headnode 0 3 49
	["am_dreamera.nif"] = { 45, keys={"idle2", "idle"} },
	["am_dreamerb.nif"] = { 45, keys={"idle6", "idle"} },
	["am_drummer03.nif"] = { 45, keys={"idle2", "idle"} },
	["am_eater.nif"] = { keys={"idle2"}, focal=v3(0, 25, 40) },	--headnode 0 10 58	headpos 52
	["am_fishman.nif"] = { 45, keys={"idle2", "idle3", "idle"} },
	["am_luteplaying.nif"] = { 45, keys={"idle2", "idle"}, focal=v3(0, 0, 44) },	--headnode 0 7 58	headpos 62
	["am_reader2.nif"] = { 45, keys={"idle2", "idle3", "idle4"} },
	["am_sitting.nif"] = { 52, keys={"idle2", "idle3", "idle4"}, focal=v3(0, 30, 40) },	-- headpos 52
	["am_writer02.nif"] = { 45, keys={"idle2", "idle3", "idle4"} },

	["am_sitbar.nif"] = { 45, keys={"idle8", "idle9"} },
	["bandit.nif"] = { 45, keys={"idle8"} },
	["farmer.nif"] = { 45, keys={"idle8"} },
	["farmer2.nif"] = {45, keys={"idle9"} },
	["prayerdf.nif"] = {53, keys={"idle9"} },
	["prayerdm.nif"] = {53, keys={"idle9"} },	-- headnode 0 13.5 76		idle 0 5.5 124.5
	["slavesitting.nif"] = { 35, keys={"idle9"} },

	["va_sitting.nif"] = { 45, keys={"idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8", "idle9"} },
	["va_sittingdunmertest.nif"] = { 45, keys={"idle2"} },

	["barsitter.nif"] = { 52, keys={"idle2", "idle3", "idle4", "idle5"}, focal=v3(0, 30, 35) },	-- headpos 52
	["wallean.nif"] = { 120, keys={"idle9"}, focal=v3(0, -29, 102) },	-- headpos 120

	["anim_sitpleading.nif"] = { 45, keys={"idle9"} },
	["anim_sitthreatening.nif"] = { 45, keys={"idle9"} },

	-- Shadow of Aetherius
	["sit1.nif"] = { keys={"idle9"}, focal=v3(0, -11, 90) },	-- headpos 90
	["sit2.nif"] = { keys={"idle9"}, focal=v3(0, -30, 25)},		-- headpos -40, 25
	["sit3.nif"] = { keys={"idle9"}, focal=v3(0, 0, 40)},		-- headpos 52

	-- Riders
	["mountedguar1.nif"] = {
		keys= { "idle", "idle3", "idle6", "idle2", "idle7", "idle8", "idle9",
			idle4 = v3(0, 25, 165), idle5 = v3(0, 50, 165),
			default = v3(0, 10, 190)
		},
		focal = v3(0, 10, 190), distance = 100
	},
	["mountedguar1muzzle.nif"] = {
		keys= { "idle", "idle3", "idle6", "idle2", "idle7", "idle8", "idle9",
			idle4 = v3(0, 25, 165), idle5 = v3(0, 50, 165),
			default = v3(0, 10, 190)
		},
		focal = v3(0, 10, 190), distance = 100
	},
	["mountedguar2.nif"] = {
		keys= { "idle", "idle3", "idle6", "idle2", "idle7", "idle8", "idle9",
			idle4 = v3(0, 50, 165), idle5 = v3(0, 70, 160),
			default = v3(0, 30, 195)
		},
		focal = v3(0, 30, 195), distance = 100
	},
	["mountedguar2muzzle.nif"] = {
		keys= { "idle", "idle3", "idle6", "idle2", "idle7", "idle8", "idle9",
			idle4 = v3(0, 50, 165), idle5 = v3(0, 70, 160),
			default = v3(0, 30, 195)
		},
		focal = v3(0, 30, 195), distance = 100
	},


--	["meshes/luce/am/am_luteplaying.nif"] = { }


	},

	byModel = {

		{ id="scamp_fetch.nif", height=90 },
		{ id="tr_vile_dae_c.nif", height=145 },

--[[
		{id="guar.nif$", height=120, radius=165},
		{id="^guar_", height=120, radius=165},
	--	{id="guar.nif$", height=120, radius=140, scale=0.3},
	--	{id="^guar_", height=120, radius=140, scale=0.3},
	--	{id="tr_gremlin", height=45},
--]]

	}

}
