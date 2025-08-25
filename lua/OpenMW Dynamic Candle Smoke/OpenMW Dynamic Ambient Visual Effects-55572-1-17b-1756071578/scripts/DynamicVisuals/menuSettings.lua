local I = require("openmw.interfaces")


I.Settings.registerPage({
   key = "dynamicVisuals",
   l10n = "DynamicVisuals",
   name = "settings_modName",
   description = "settings_modDesc",
})

I.Settings.registerGroup({
   key = "Settings_DAVE_player",
   page = "dynamicVisuals",
   l10n = "DynamicVisuals",
   name = "settings_modCat2_name",
   permanentStorage = true,
   settings = {
      {
         key = "dust_density",
         name = "settings_modCat2_setting01_name",
         description = "settings_modCat2_setting01_desc",
         default = "opt_medium",
         renderer = "select",
         argument = { disabled = false,
         l10n = "DynamicVisuals",
         items = { "opt_medium", "opt_heavy", "opt_disabled" }
         },
      },
   },
})

return
