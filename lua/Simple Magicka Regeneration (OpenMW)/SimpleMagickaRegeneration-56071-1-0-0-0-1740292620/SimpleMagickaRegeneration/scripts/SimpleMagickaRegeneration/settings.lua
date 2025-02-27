local I = require('openmw.interfaces')

I.Settings.registerPage({
    key = 'SimpleMagickaRegeneration',
    l10n = 'SimpleMagickaRegeneration',
    name = 'page_name',
    description = 'page_description',
 })

 I.Settings.registerGroup({
    key = 'SettingsSimpleMagickaRegeneration',
    page = 'SimpleMagickaRegeneration',
    l10n = 'SimpleMagickaRegeneration',
    name = "smr_ui_settings_group",
    permanentStorage = false,
    settings = {
      {
         key = 'usewillpower',
         name = 'usewillpower_name',
         description = 'usewillpower_description',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'delay',
         name = 'delay_name',
         description = 'delay_description',
         default = 5,
         renderer = 'number',
         argument = {
            min = 0,
            max = 100,
         },
      },
      {
         key = 'attributemod',
         name = 'attributemod_name',
         description = 'attributemod_description',
         default = 0.1,
         renderer = 'number',
         argument = {
            min = 0,
            max = 1,
         },
      },
       {
          key = 'magickaregenmulti',
          name = 'magickaregenmulti_name',
          description = 'magickaregenmulti_description',
          default = 1,
          renderer = 'number',
          argument = {
             min = 0,
             max = 10,
          },
       },
    },
 })