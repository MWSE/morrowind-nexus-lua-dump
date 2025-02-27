local I = require('openmw.interfaces')

I.Settings.registerPage({
    key = 'SimpleHealthRegeneration',
    l10n = 'SimpleHealthRegeneration',
    name = 'page_name',
    description = 'page_description',
 })

 I.Settings.registerGroup({
    key = 'SettingsSimpleHealthRegeneration',
    page = 'SimpleHealthRegeneration',
    l10n = 'SimpleHealthRegeneration',
    name = "ui_settings_group",
    permanentStorage = false,
    settings = {
      {
         key = 'hitdelay',
         name = 'hitdelay_name',
         description = 'hitdelay_description',
         default = 5,
         renderer = 'number',
         argument = {
            min = 0,
            max = 100,
         },
      },
      {
         key = 'endurancemod',
         name = 'endurancemod_name',
         description = 'endurancemod_description',
         default = 0.1,
         renderer = 'number',
         argument = {
            min = 0,
            max = 1,
         },
      },
       {
          key = 'healthregenmulti',
          name = 'healthregenmulti_name',
          description = 'healthregenmulti_description',
          default = 1,
          renderer = 'number',
          argument = {
             min = 0,
             max = 10,
          },
       },
    },
 })