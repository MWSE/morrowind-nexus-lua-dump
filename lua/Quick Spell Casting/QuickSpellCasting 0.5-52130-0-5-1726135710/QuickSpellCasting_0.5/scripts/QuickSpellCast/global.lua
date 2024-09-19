local I = require('openmw.interfaces')

I.Settings.registerGroup({
   key = 'Settings_urm_QuickSpellCast_Gameplay',
   page = 'urm_QuickSpellCast',
   l10n = 'urm_QuickSpellCast',
   name = 'gameplay_group_name',
   permanentStorage = false,
   settings = {
      {
         key = 'stanceAnimationSpeedup',
         default = 2.5,
         name = 'stanceAnimationSpeedup_name',
         renderer = 'number',
         argument = {
            min = 0.01,
         },
      },
   },
})
