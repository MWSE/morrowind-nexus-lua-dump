-- AirJump (MENU) – register the Settings page only (no hotkey/bind UI)

local I = require('openmw.interfaces')

pcall(function()
  I.Settings.registerPage{
    key         = 'AirJump',
    l10n        = 'AirJump',
    name        = 'PageName',
    description = 'PageDesc',
  }
end)

return {}
