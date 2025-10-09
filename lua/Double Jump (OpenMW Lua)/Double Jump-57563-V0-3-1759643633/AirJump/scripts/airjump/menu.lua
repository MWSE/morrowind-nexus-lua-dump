-- AirJump (MENU) – register custom action + Settings page (OpenMW 0.49)
-- MENU scripts: no engineHandlers/onInit; just do work at top-level.

local input = require('openmw.input')
local I     = require('openmw.interfaces')

-- 1) Define the custom action so it appears in Options → Controls → Custom.
--    Guard with pcall so we don't error if another script already registered it.
pcall(function()
  input.registerAction{
    key          = 'AirJump',
    type         = input.ACTION_TYPE.Boolean,
    l10n         = 'AirJump',
    name         = 'Air Jump',
    description  = 'Perform a mid-air jump by dropping a brief invisible pad.',
    defaultValue = false,
  }
end)

-- 2) Lua Script Settings page with an inputBinding control to bind the action.
I.Settings.registerPage{
  key = 'AirJumpPage',
  l10n = 'AirJump',
  name = 'Air Jump',
  description = 'Configure the Air Jump hotkey.',
}

I.Settings.registerGroup{
  key = 'SettingsAirJump',
  page = 'AirJumpPage',
  l10n = 'AirJump',
  name = 'Binding',
  description = 'Choose the input used to trigger a mid-air jump.',
  permanentStorage = true,  -- REQUIRED for Menu scripts
  settings = {
    {
      key         = 'BindAirJump',
      renderer    = 'inputBinding',
      name        = 'Air Jump Hotkey',
      description = 'Bind any key/button to trigger Air Jump while airborne.',
      default     = "",  -- renderer expects a string
      argument    = { key = 'AirJump', type = 'action' },
    },
  },
}

return {}
