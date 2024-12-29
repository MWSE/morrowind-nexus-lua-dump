local I = require("openmw.interfaces")


I.Settings.registerPage({
   key = "tt_visibleRings",
   l10n = "VisibleRings",
   name = "settings_modName",
   description = "settings_modDesc",
})

I.Settings.registerGroup({
   key = "Settings_tt_visiblerings",
   page = "tt_visibleRings",
   l10n = "VisibleRings",
   name = "settings_modCat1_name",
   permanentStorage = true,
   settings = {
      {
         key = "defaultModel",
         name = "settings_modCat1_setting01_name",
         description = "settings_modCat1_setting01_desc",
         default = "meshes/c/c_ring_common05_skins.nif",
         renderer = "textLine",
      },
      {
         key = "frameSkip",
         name = "settings_modCat1_setting02_name",
         description = "settings_modCat1_setting02_desc",
         default = 20,
         renderer = "number",
         argument = { min = 1, max = 100 },
      },
   },
})

return
