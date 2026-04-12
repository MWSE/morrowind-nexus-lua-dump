local I = require("openmw.interfaces")

I.Settings.registerPage({
   key = "tt_VisibleFinery",
   l10n = "VisibleFinery",
   name = "settings_modName",
   description = "settings_modDesc",
})

I.Settings.registerGroup({
   key = "Settings_tt_visiblefinery",
   page = "tt_VisibleFinery",
   l10n = "VisibleFinery",
   name = "settings_modCat1_name",
   permanentStorage = true,
   settings = {
      {
		 key = "ShowRings",
		 name = "settings_modCat1_setting04_name",
		 default = true,
         renderer = "checkbox",
      },
	  {
         key = "bareHandsOnly",
         name = "settings_modCat1_setting05_name",
         default = false,
         renderer = "checkbox",
      },
	  {
         key = "defaultModel",
         name = "settings_modCat1_setting01_name",
		 description = "settings_modCat1_setting01_desc",
         default = "meshes/c/c_ring_common05_skins.nif",
         renderer = "select",
		 argument = { disabled = false, l10n = "VisibleFinery",
			items = { "meshes/c/C_ring_Common01_skins.nif", 
					"meshes/c/C_ring_Common02_skins.nif", 
					"meshes/c/C_ring_Common03_skins.nif", 
					"meshes/c/C_ring_Common04_skins.nif", 
					"meshes/c/C_ring_Common05_skins.nif", 
					"meshes/c/c_ring_expensive_1_skins.nif", 
					"meshes/c/c_ring_expensive_2_skins.nif", 
					"meshes/c/c_ring_expensive_3_skins.nif", 
					"meshes/c/c_ring_exquisite_1_skins.nif", 
					"meshes/c/c_ring_extravagant_1_skins.nif", 
					"meshes/c/c_ring_extravagant_2_skins.nif" }
		 },
      },
	  {
		 key = "ShowBelts",
		 name = "settings_modCat1_setting08_name",
		 default = true,
         renderer = "checkbox",
      },
	  {
         key = "defaultBelt",
         name = "settings_modCat1_setting06_name",
		 description = "settings_modCat1_setting06_desc",
         default = "meshes/c/C_belt_Common_5_skins.nif",
		 renderer = "select",
		 argument = { disabled = false, l10n = "VisibleFinery",
			items = { "meshes/c/C_belt_Common_1_skins.nif", 
					"meshes/c/C_belt_Common_2_skins.nif", 
					"meshes/c/C_belt_Common_3_skins.nif", 
					"meshes/c/C_belt_Common_4_skins.nif", 
					"meshes/c/C_belt_Common_5_skins.nif", 
					"meshes/c/C_belt_expensive_1_skins.nif", 
					"meshes/c/C_belt_expensive_2_skins.nif", 
					"meshes/c/C_belt_expensive_3_skins.nif", 
					"meshes/c/C_belt_Exquisite_1_skins.nif", 
					"meshes/c/C_belt_extravagant_1_skins.nif", 
					"meshes/c/C_belt_extravagant_2_skins.nif" }
         },
      },
	  {
		 key = "ShowAmulets",
		 name = "settings_modCat1_setting09_name",
		 default = true,
         renderer = "checkbox",
      },
	  {
         key = "defaultAmulet",
         name = "settings_modCat1_setting07_name",
		 description = "settings_modCat1_setting07_desc",
         default = "meshes/c/Amulet_Common_1_skins.nif",
		 renderer = "select",
		 argument = { disabled = false, l10n = "VisibleFinery",
			items = { "meshes/c/Amulet_Common_1_skins.nif", 
					"meshes/c/Amulet_Common_2_skins.nif", 
					"meshes/c/Amulet_Common_3_skins.nif", 
					"meshes/c/Amulet_Common_4_skins.nif", 
					"meshes/c/Amulet_Common_5_skins.nif", 
					"meshes/c/Amulet_Expensive_1_skins.nif", 
					"meshes/c/Amulet_Expensive_2_skins.nif", 
					"meshes/c/Amulet_Expensive_3_skins.nif", 
					"meshes/c/Amulet_Exquisit_1_skins.nif", 
					"meshes/c/Amulet_Extravagant_1_skins.nif", 
					"meshes/c/Amulet_Extravagant_2_skins.nif" }
         },
      },
      {
         key = "bodyReplacer",
         name = "settings_modCat1_setting02_name",
         default = "opt_better",
         renderer = "select",
         argument = { disabled = false,
         l10n = "VisibleFinery", 
         items = { "opt_vanilla", "opt_vsbr", "opt_better", "opt_robert" }
         },
      },
      {
         key = "bodyReplacer_f",
         name = "settings_modCat1_setting03_name",
         default = "opt_better",
         renderer = "select",
         argument = { disabled = false,
         l10n = "VisibleFinery", 
         items = { "opt_vanilla", "opt_vsbr", "opt_better", "opt_robert" }
         },
      },
      
      {
         key = "frameSkip",
         name = "settings_modCat1_setting10_name",
         description = "settings_modCat1_setting10_desc",
         default = 20,
         renderer = "number",
         argument = { min = 1, max = 100 },
      },
   },
})

return
