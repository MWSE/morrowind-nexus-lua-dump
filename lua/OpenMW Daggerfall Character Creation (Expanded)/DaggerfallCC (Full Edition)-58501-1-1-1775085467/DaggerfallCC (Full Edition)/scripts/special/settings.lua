local I = require('openmw.interfaces')

I.Settings.registerPage {
   key = 'special',
   l10n = 'special',
   name = 'setting_special_page',
}

I.Settings.registerGroup {
   key = 'Settings_special',
   l10n = 'special',
   name = 'setting_special_group',
   page = 'special',
   permanentStorage = false,
   settings = {
      {
         key = 'enable_special_skill_progression_modifier',
         name = 'setting_disable_special_skill_progression_modifier',
         description = 'setting_disable_special_skill_progression_modifier_description',
         renderer = 'checkbox',
         default = true,
      },
   },
}
