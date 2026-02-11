
local niflist = {

	["meshes/"] = {},
	["meshes/base_anim.nif"] = {},
	["meshes/base_anim_female.nif"] = {},
	["meshes/base_animkna.nif"] = {},
	["meshes/epos_kha_upr_anim_f.nif"] = {},
	["meshes/epos_kha_upr_anim_m.nif"] = {},
	["meshes/pi_tsa_base_anim.nif"] = { blockAnims=true },
--	[""] = {},


	["am_alchemist.nif"] = {"idle9", "idle"},
	["am_bard2.nif"] = {"idle2"},
	["am_beggar.nif"] = {"idle2", "idle3", "idle4", "idle"},
	["am_cough.nif"] = {},
	["am_dreamera.nif"] = {"idle2", "idle"},
	["am_dreamerb.nif"] = {"idle6", "idle"},
	["am_drummer03.nif"] = {"idle2", "idle"},
	["am_eater.nif"] = {"idle2"},
	["am_fishman.nif"] = {"idle2", "idle3", "idle"},
	["am_luteplaying.nif"] = {"idle2", "idle"},
	["am_reader1.nif"] = {"idle", "idle2", "idle3"},
--	["am_reader2.nif"] = {"idle2", "idle3", "idle4"},
	["am_sitting.nif"] = {"idle2", "idle3", "idle4"},
	["am_smith.nif"] = {"idle", "idle2", "idle3"},
	["am_sweeping.nif"] = {},
--	["am_writer02.nif"] = {"idle2", "idle3", "idle4"},
--	["am_writer02.nif"] = {"all"},

	["am_sitbar.nif"] = {"idle8", "idle9"},
	["meshes/am/ii/bandit.nif"] = {"idle8"},
	["meshes/am/ii/camonna.nif"] = { blockAnims=true },
	["meshes/am/ii/cleaner.nif"] = { "idle7" },
--	["farmer.nif"] = {"idle8"},
--	["farmer2.nif"] = {"idle8", "idle9"},
	["meshes/am/ii/miner.nif"] = {"idle8", "idle9"},
--	["miner2.nif"] = { "all" },
	["prayerdf.nif"] = {"idle8", "idle9"},
	["prayerdm.nif"] = {"idle8", "idle9"},
	["meshes/am/ii/slavesitting.nif"] = {"idle9"},

	["va_sitting.nif"] = { "idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8", "idle9" },
	["va_sittingdunmertest.nif"] = { "idle2" },

	["anim_drunk0x2.nif"] = { "idle9" },
	["anim_girlsitdrinktea.nif"] = { "idle9" },
	["anim_sitpleading.nif"] = { "idle9" },
	["anim_sitthreatening.nif"] = { "idle9" },

--	["mountedguar1.nif"] = { blockAnims=true },
--	["mountedguar1muzzle.nif"] = { blockAnims=true },
--	["mountedguar2.nif"] = { blockAnims=true },
--	["mountedguar2muzzle.nif"] = { blockAnims=true },

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

return { niflist, config }

