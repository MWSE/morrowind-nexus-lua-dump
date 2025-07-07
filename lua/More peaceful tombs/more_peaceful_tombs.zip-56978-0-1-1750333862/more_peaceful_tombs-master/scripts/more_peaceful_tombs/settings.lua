-- NB: in case of multiplayer, settings should be server-side

local I = require('openmw.interfaces')

local core = require('openmw.core')

local settings = {
      {
         key = 'player_detect',
         name = 'settings_modCat1_setting_player_detect_name',
         description = 'settings_modCat1_setting_player_detect_desc',
         renderer = 'select',
         default = 'player_detect_rank',
         argument = {
            disabled = false,
            l10n = 'more_peaceful_tombs',
            items = {
               'player_detect_rank',
               'player_detect_speaker_began',
               'player_detect_speaker_during',
            },
         },
      },
      {
         key = 'min_rank',
         name = 'settings_modCat1_setting_min_rank_name',
         description = 'settings_modCat1_setting_min_rank_desc',
         default = 4,
         renderer = 'number',
         argument = { min = 0, max = 9 },
      },
      {
         key = 'is_debug',
         name = 'settings_modCat1_setting_is_debug_name',
         description = 'settings_modCat1_setting_is_debug_desc',
         default = false,
         renderer = 'checkbox',
      },
}

if not core.contentFiles.has('TR_Mainland.esm') then
   table.remove(settings, 1)
end

I.Settings.registerGroup({
   key = 'Settings_more_peaceful_tombs',
   page = 'more_peaceful_tombs',
   l10n = 'more_peaceful_tombs',
   name = 'settings_modCat1_name',
   permanentStorage = true,
   settings = settings,
})

return