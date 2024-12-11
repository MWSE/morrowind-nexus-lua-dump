local I = require('openmw.interfaces')


I.Settings.registerPage({
   key = "impactEffects",
   l10n = "ImpactEffects",
   name = "settings_modName",
   description = "settings_modDesc",
})

I.Settings.registerGroup({
   key = "Settings_impacteffects",
   page = 'impactEffects',
   l10n = "ImpactEffects",
   name = "settings_modCat1_name",
   permanentStorage = true,
   settings = {
      {
         key = "enable",
         name = "settings_modCat1_setting01_name",
         default = true,
         renderer = 'checkbox',
      },
      {
         key = "volume_mst",
         name = "settings_modCat1_setting02_name",
         default = 30,
         renderer = "number",
         argument = { min = 0, max = 100 },
      },
      {
         key = "enable_npc",
         name = "settings_modCat1_setting03_name",
         description = "settings_modCat1_setting03_desc",
         default = true,
         renderer = 'checkbox',
      },
      {
         key = "enable_hitmark",
         name = "settings_modCat1_setting04_name",
         default = true,
         renderer = 'checkbox',
      },
   },
})

return
