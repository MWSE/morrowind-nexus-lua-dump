local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'special',
   l10n = 'special',
   name = 'setting_special_page',
})

I.Settings.registerGroup({
   key = 'Settings_special',
   l10n = 'special',
   name = 'setting_special_group',
   page = 'special',
   permanentStorage = false,
   settings = {
      {
         key = 'open_special_main_element_key',
         name = 'setting_open_special_main_element_key',
         description = 'setting_open_special_main_element_key_description',
         renderer = 'textLine',
         default = 'u',
      },
      {
         key = 'enable_special_skill_progression_modifier',
         name = 'setting_disable_special_skill_progression_modifier',
         description = 'setting_disable_special_skill_progression_modifier_description',
         renderer = 'checkbox',
         default = true,
      },
   },
})
