local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'SongsOfTheAshenWind',
   l10n = 'SongsOfTheAshenWind',
   name = 'page_name',
   description = 'page_description',
})

I.Settings.registerGroup({
   key = 'SongsOfTheAshenWind_playback',
   page = 'SongsOfTheAshenWind',
   l10n = 'SongsOfTheAshenWind',
   name = 'playback_group',
   permanentStorage = true,
   settings = {
      {
         key = 'playOnRead',
         name = 'playOnRead_name',
         description = 'playOnRead_description',
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'stopOnClose',
         name = 'stopOnClose_name',
         description = 'stopOnClose_description',
         default = false,
         renderer = 'checkbox',
      },
   },
})
