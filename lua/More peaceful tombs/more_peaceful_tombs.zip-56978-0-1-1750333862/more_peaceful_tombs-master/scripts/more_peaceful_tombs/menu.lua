-- NB: in case of multiplayer, settings should be server-side

local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'more_peaceful_tombs',
   l10n = 'more_peaceful_tombs',
   name = 'settings_modName',
   description = 'settings_modDesc',
})

return
