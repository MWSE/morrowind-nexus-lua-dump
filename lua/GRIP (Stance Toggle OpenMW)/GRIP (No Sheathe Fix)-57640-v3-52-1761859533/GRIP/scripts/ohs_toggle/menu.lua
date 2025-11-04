-- scripts/ohs_toggle/menu.lua (OpenMW 0.49)
-- Menu-context script: registers the Settings page/group and our trigger.
-- Must be listed under [Menu] in your .omwscripts so this runs at main menu.

local input     = require('openmw.input')
local ISettings = require('openmw.interfaces').Settings

local L10N  = 'ohs_toggle'
local PAGE  = 'OHS_Toggle_Page'
local GROUP = 'SettingsOHS_Toggle'
local TRIG  = 'ohs_toggle'  -- must match player.lua

local _done = false

local function doRegister()
  if _done then return end

  -- Make sure the trigger exists before exposing it in the binding renderer.
  pcall(function()
    input.registerTrigger {
      key         = TRIG,
      l10n        = L10N,
      name        = 'toggle_binding_name',
      description = 'toggle_binding_desc',
    }
  end)

  -- Page
  ISettings.registerPage {
    key         = PAGE,
    l10n        = L10N,
    name        = 'settings_page_name',
    description = 'settings_page_desc',
  }

  -- Group + settings
  ISettings.registerGroup {
    key  = GROUP,
    page = PAGE,
    l10n = L10N,
    name = 'settings_group_name',
    permanentStorage = true,
    settings = {
      {
        key         = 'ToggleBinding',
        renderer    = 'inputBinding',
        name        = 'toggle_binding_name',
        description = 'toggle_binding_desc',
        default     = "O",                              -- inputBinding needs a string default
        argument    = { key = TRIG, type = 'trigger' }, -- bind to our trigger
      },
      {
        key         = 'AlwaysThrustSpears',
        renderer    = 'checkbox',
        name        = 'always_thrust_name',
        description = 'always_thrust_desc',
        default     = false,
      },
      {
        key         = 'OneHandDamageMult',
        renderer    = 'number',
        name        = 'onehand_mult_name',
        description = 'onehand_mult_desc',
        default     = 0.85,
        argument    = { min = 0.10, max = 1.00 },
      },
      {
        key         = 'TwoHandDamageMult',
        renderer    = 'number',
        name        = 'twohand_mult_name',
        description = 'twohand_mult_desc',
        default     = 1.35,
        argument    = { min = 1.00, max = 2.50 },
      },
      {
        key         = 'DebugLog',
        renderer    = 'checkbox',
        name        = 'debug_checkbox_name',
        description = 'debug_checkbox_desc',
        default     = false,
      },
    },
  }

  _done = true
end

return {
  engineHandlers = {
    onInit = doRegister,
    onLoad = doRegister,
  },
  eventHandlers = {},
}
