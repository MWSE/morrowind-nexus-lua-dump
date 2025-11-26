local presets = {

	-- dirnae beast walk
	kna = { id="walkforward_spd09", velocity=154 },
	kna07 = { id="walkforward_spd07", velocity=130 },
	kna05 = { id="walkforward_spd05", velocity=108 },

	-- better/vanilla f walk + dirnae m walk
	f = { id="walkforward_spd09", velocity=154 },
	f07 = { id="walkforward_spd07", velocity=134 },
	f05 = { id="walkforward_spd05", velocity=115 },
	m = { id="walkforward_spd09", velocity=154 },
	m07 = { id="walkforward_spd07", velocity=130 },
	m05 = { id="walkforward_spd05", velocity=104 },

	march_f = { id="walkforward_march", velocity=134 },
	march_f07 = { id="walkforward_march", velocity=134 },
	march_m = { id="walkforward_march", velocity=130 },
	march_m07 = { id="walkforward_march", velocity=130 },


	noble = { id="walkforward_noble", velocity=135, maxSpeed=0.6 },
	base = { id="walkforward", velocity=154 },

	idle_armsakimbo = { id = "armsakimbo", priority = 0,
		opt = {loops=1, priority=1, blendMask=12, isBlend=true}
	},
--[[
	idle_armsakimbo_switch = { id = "armsakimbo_switch", priority = 0,
		opt = {loops=1, priority=1, blendMask=12, isBlend=true}
	},
--]]
	idle_armsakimbo_switch = { id = "armsakimbo", priority = 0,
		masks={4, 8, 12, 4, 8, 12}, opt = { loops=2, priority=1 }
	},
	idle_sunshield = { id = "armssunshield", priority = 0,
		opt = {loops=1, priority=1, blendMask=12}
	},
	walk_armsatback = { id = "armsatback", interval = 5, opt = {priority=6, blendMask=12} },
	walk_handonhip = { id="armsakimbo", interval=5, masks={4, 8, 4, 8}, opt={ priority=6} },
	idle_armsfolded = { id = "armsfolded", priority = 0,
		opt = {loops=1, priority=1, blendMask=12}
	},
	idle4 = { id = "idle4", priority = 0, opt = {priority=1, blendMask=8} },
	idle5 = { id = "idle5", priority = 0, opt = {priority=1, blendMask=8} },
	idle7 = { id = "idle7", priority = 0, opt = {priority=1, blendMask=8} },
	idle8 = { id = "idle8", priority = 0, opt = {priority=1, blendMask=8} },

	halfSpeed = { priority = 0, modify = {speed=0.5} }

}

-- Base presets
presets.odar_config = {}
presets.odar_noble_f = {
	walkforward = presets.walk_handonhip,
	odar_wander = presets.noble,
	walkforward_07 = presets.noble,
	walkforward_05 = presets.noble,
	idle2 = presets.idle_armsakimbo_switch,
}
presets.odar_female = {
	idle2 = presets.idle_armsakimbo_switch,
}
presets.odar_male = {
	idle2 = {
	--	presets.idle5,
		presets.idle7,
		presets.idle_armsfolded,
		presets.idle8,
		presets.idle_armsfolded,
		priority = 0, n = 4, interval = 5
	}
}


local npcTable = {

--[[
	gothren = {
		idle2 = {
			id = "vagothren", priority = 0, opt = {priority=1, loops=1, isBlend=true}
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
