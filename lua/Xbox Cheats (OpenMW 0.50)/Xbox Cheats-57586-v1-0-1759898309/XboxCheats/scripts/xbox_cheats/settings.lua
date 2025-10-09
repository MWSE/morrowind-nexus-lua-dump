local I = require('openmw.interfaces')

I.Settings.registerPage {
  key = 'XboxCheatsPage',
  l10n = 'XboxCheats',
  name = 'page_name',
  description = 'page_desc',
}

I.Settings.registerGroup {
  key = 'SettingsXboxCheats',
  page = 'XboxCheatsPage',
  l10n = 'XboxCheats',
  name = 'group_name',
  description = 'group_desc',
  permanentStorage = true,  -- menu scripts may only register permanent groups
  settings = {
    {
      key = 'requireStatsWindow',
      renderer = 'checkbox',
      name = 'setting_requireStats_name',
      description = 'setting_requireStats_desc',
      default = true,
    },
    {
      key = 'timeoutSec',
      renderer = 'number',
      name = 'setting_timeout_name',
      description = 'setting_timeout_desc',
      default = 5,
      argument = { min = 1, max = 15, integer = true },
    },
    {
      key = 'fillRate',
      renderer = 'number',
      name = 'setting_fillRate_name',
      description = 'setting_fillRate_desc',
      default = 60,
      argument = { min = 1, max = 500, integer = true },
    },
    {
      key = 'debugToasts',
      renderer = 'checkbox',
      name = 'setting_debugToasts_name',
      description = 'setting_debugToasts_desc',
      default = false,
    },

    -- NEW: replicate the OG Xbox bug/quirk
    {
      key = 'bugHoldAExit',
      renderer = 'checkbox',
      name = 'bug_holdA_name',
      description = 'bug_holdA_desc',
      default = false,
    },

    -- Input bindings (string defaults; actual “hardware” mapping is handled in player.lua fallbacks too)
    {
      key = 'bindBlack',
      renderer = 'inputBinding',
      name = 'binding_black_name',
      description = 'binding_black_desc',
      default = '',
      argument = { key = 'XboxCheats.Black', type = 'trigger' },
    },
    {
      key = 'bindWhite',
      renderer = 'inputBinding',
      name = 'binding_white_name',
      description = 'binding_white_desc',
      default = '',
      argument = { key = 'XboxCheats.White', type = 'trigger' },
    },
    {
      key = 'bindHoldA',
      renderer = 'inputBinding',
      name = 'binding_holdA_name',
      description = 'binding_holdA_desc',
      default = '',
      argument = { key = 'XboxCheats.HoldA', type = 'action' },
    },
  },
}
