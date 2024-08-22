local util = require('openmw.util')
local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'MostWantedNerevarine',
   l10n = 'MostWantedNerevarine',
   name = 'page_name',
   description = 'page_description',
})

I.Settings.registerGroup({
   key = 'SettingsMostWantedNerevarine',
   page = 'MostWantedNerevarine',
   l10n = 'MostWantedNerevarine',
   name = "ui_settings_group",
   permanentStorage = false,
   settings = {
      {
         key = 'hideNoBounty',
         name = "hideNoBounty_name",
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'hideInMenu',
         name = "hideInMenu_name",
         default = false,
         renderer = 'checkbox',
      },
      {
         key = 'hideDetails',
         name = 'hideDetails_name',
         default = false,
         renderer = 'checkbox',
      },
      {
         key = 'iconSize',
         name = 'iconSize_name',
         description = 'iconSize_description',
         default = 48,
         renderer = 'number',
         argument = {
            integer = true,
            min = 1,
         },
      },
      {
         key = 'screenPosition',
         name = 'screenPosition_name',
         default = util.vector2(0.5, 0),
         renderer = 'MostWantedNerevarine_ScreenPosition',
      },
      {
         key = 'verticalHud',
         name = 'verticalHud_name',
         default = false,
         renderer = 'checkbox',
      },
      {
         key = 'bountyLevelSound',
         name = 'bountyLevelSound_name',
         default = true,
         renderer = 'checkbox',
      },
   },
})
