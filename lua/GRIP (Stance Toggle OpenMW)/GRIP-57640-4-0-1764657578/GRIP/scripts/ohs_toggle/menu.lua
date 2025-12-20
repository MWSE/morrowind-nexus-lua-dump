local async     = require 'openmw.async'
local core      = require 'openmw.core'
local input     = require('openmw.input')
local menu      = require 'openmw.menu'
local storage   = require 'openmw.storage'
local ISettings = require('openmw.interfaces').Settings

local L10N      = 'ohs_toggle'
local PAGE      = 'OHS_Toggle_Page'
local GROUP     = 'SettingsOHS_Toggle'
local TRIG      = 'OHS_ToggleSpear'

input.registerAction {
  key          = TRIG,
  l10n         = L10N,
  name         = '',
  description  = '',
  defaultValue = false,
  type         = input.ACTION_TYPE.Boolean,
}

ISettings.registerPage {
  key         = PAGE,
  l10n        = L10N,
  name        = 'settings_page_name',
  description = 'settings_page_desc',
}

ISettings.registerGroup {
  key              = GROUP,
  page             = PAGE,
  l10n             = L10N,
  name             = 'settings_group_name',
  permanentStorage = true,
  settings         = {
    {
      key         = 'ToggleBinding',
      renderer    = 'inputBinding',
      name        = 'toggle_binding_name',
      description = 'toggle_binding_desc',
      default     = "O",
      argument    = { key = TRIG, type = 'action', },
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

local group = storage.playerSection(GROUP)

local function updateMult()
  core.sendGlobalEvent('OHS_UpdateGlobalData', {
    OneHandDamageMult = group:get('OneHandDamageMult'),
    TwoHandDamageMult = group:get('TwoHandDamageMult'),
    DebugLog = group:get('DebugLog'),
  })
end

group:subscribe(async:callback(updateMult))

return {
  eventHandlers = {
    OHS_RequestGlobalData = updateMult,
  },
}
