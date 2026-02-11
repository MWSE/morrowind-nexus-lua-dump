local presets = {

	-- dirnae beast walk
	kna = { g="walkforward_spd09", velocity=154 },
	kna07 = { g="walkforward_spd07", velocity=130 },
	kna05 = { g="walkforward_spd05", velocity=108 },

	-- better/vanilla f walk + dirnae m walk
	f = { g="walkforward_spd09", velocity=154 },
	f07 = { g="walkforward_spd07", velocity=134 },
	f05 = { g="walkforward_spd05", velocity=115 },
	m = { g="walkforward_spd09", velocity=154 },
	m07 = { g="walkforward_spd07", velocity=130 },
	m05 = { g="walkforward_spd05", velocity=104 },

	march_f = { g="walkforward_march", velocity=134 },
	march_f07 = { g="walkforward_march", velocity=134 },
	march_m = { g="walkforward_march", velocity=130 },
	march_m07 = { g="walkforward_march", velocity=130 },


	noble = { g="walkforward_noble", velocity=135, maxSpeed=0.6 },
	base = { g="walkforward", velocity=154 },

	idle_armsakimbo = { g = "armsakimbo", priority = 0,
		modify = { speeds={ 0.7, 0.6, 0.7, 0.8 } },
		o = {loops=2, priority=1, blendMask=12, isBlend=true}
	},
	idle_armsakimbo_switch = { g = "armsakimbo", priority = 0,
		modify = { speeds={ 0.7, 0.6, 0.7, 0.8 } },
		masks={4, 8, 12, 4, 8, 12}, o = { loops=3, priority=1 }
	},
	idle_sunshield = { g = "armssunshield", priority = 0,
		modify = {speed=0.65},
		o = {loops=1, priority=1, blendMask=12}
	},
	walk_armsatback = { g = "armsatback", interval = 5, o = {priority=6, blendMask=12} },
	walk_handonhip = { g="armsakimbo", interval=5, masks={4, 8, 4, 8}, o={ priority=6} },
	idle_armsfolded = { g = "armsfolded", priority = 0,
		modify = { speeds={ 0.7, 0.6, 0.7, 0.8 } },
		o = {loops=2, priority=1, blendMask=12}
	},
	idle4 = { g = "idle4", priority = 0, o = {priority=1, blendMask=8} },
	idle5 = { g = "idle5", priority = 0, o = {priority=1, blendMask=8} },
	idle7 = { g = "idle7", priority = 0, o = {priority=1, blendMask=8, loops=1} },
	idle8 = { g = "idle8", priority = 0, o = {priority=1, blendMask=8, loops=1} },

	speed05 = { priority = 0, modify = {speed=0.5} },
	speed06 = { priority = 0, modify = {speed=0.65} },
	speed07 = { priority = 0, modify = {speed=0.7} },
	speed15 = { priority = 0, modify = {speed=1.5} },

}

-- Base presets
presets.odar_config = {}
presets.odar_noble_f = {
	walkforward = presets.walk_handonhip,
	odar_wander = presets.noble,
	walkforward_07 = presets.noble,
	walkforward_05 = presets.noble,
	idle2 = presets.idle_armsakimbo_switch,
	idle3 = presets.speed07,
	idle4 = presets.speed15,
	idle5 = presets.speed05,
}
presets.odar_female = {
	idle2 = presets.idle_armsakimbo_switch,
	idle3 = presets.speed07,
	idle4 = presets.speed15,
	idle5 = presets.speed05,
}
presets.odar_male = {
	idle2 = {
	--	presets.idle5,
		presets.idle7,
		presets.idle_armsfolded,
		presets.idle8,
		presets.idle_armsfolded,
		modify = { speeds={ 0.7, 0.6, 0.7, 0.8 } },
		priority = 0, n = 4, interval = 7
	},
	idle3 = presets.speed07,
}
presets.ordinator = {
	walkforward = presets.walk_armsatback,
	idle2 = {
		{ g = "armsalmapray", priority = 0, o = {priority=1, blendMask=14, loops=1} },
		presets.idle_armsakimbo,
		modify = { speeds={ 0.7, 0.6, 0.7, 0.8 } },
		priority = 0, n = 2, interval = 7
	},
}

local npcTable = {

--[[
	gothren = {
		idle2 = {
			g = "vagothren", priority = 0, o = {priority=1, loops=1, isBlend=true}
		--	["idle2"] = "vagothren", ["idle3"] = "vagothren",  ["idle4"] = "vagothren"
		},
	},
--]]

	odar_ignore = { odar_ignore = true },
	odar_guard_imp = {
		["walkforward"] = presets.walk_armsatback,
		["idle2"] = presets.idle_armsakimbo,
		["idle3"] = presets.idle_sunshield,
	},
	odar_guard_ord = presets.ordinator,
	odar_guard = {
		["walkforward"] = presets.walk_armsatback,
		["idle2"] = presets.idle_armsakimbo,
	},
	odar_walk_f = {
		walkforward_05 = presets.f05,
		walkforward_07 = presets.f07,
		odar_wander = presets.f
	},
	["maurrie aurmine"] = presets.odar_noble_f,
	["dulnea ralaal"] = presets.odar_noble_f,
	["asciene rane"] = presets.odar_noble_f,
	therana = presets.odar_noble_f,
--	["mehra helas"] = presets.odar_noble_f,

--[[
	-- Animated Morrowind
	["gg_brelyna_hleran "] = {
		settings = { teleport=util.vector3(4162, 4294, 12202) }
		},
	am_bard9 = {
		settings = { teleport=util.vector3(2463, -57077, 1565) }
		},
--	am_writer6 = { settings = { teleport=util.vector3(5195, 4930, 195) } },		-- rotZ 178
--]]

--	["a_siltstrider"] = { ["idle5"] = "idle1" }

	-- Model Lookup
	["am_sweeping.nif"] = {
		odar_custom = true,
		walkforward_05 = presets.f05,
		walkforward_07 = presets.f07,
		odar_wander = presets.f
	},
	["meshes/"] = false,
	["meshes/base_animkna.nif"] = false,
	["meshes/epos_kha_upr_anim_f.nif"] = false,
	["meshes/epos_kha_upr_anim_m.nif"] = false,
	["meshes/pi_tsa_base_anim.nif"] = true,
	["mountedguar1.nif"] = true,
	["mountedguar1muzzle.nif"] = true,
	["mountedguar2.nif"] = true,
	["mountedguar2muzzle.nif"] = true,

}

allowedModels = {
	["meshes/"] = {},
	["meshes/base_anim.nif"] = {},
	["meshes/base_anim_female.nif"] = {},
	["meshes/base_animkna.nif"] = { animKna = true },
	["meshes/epos_kha_upr_anim_f.nif"] = {},
	["meshes/epos_kha_upr_anim_m.nif"] = {},
	["meshes/am/am_sweeping.nif"] = {
		odar_custom = true,
		walkforward_05 = presets.f05,
		walkforward_07 = presets.f07,
		odar_wander = presets.f
	},
}

return { presets, npcTable, allowModels }
