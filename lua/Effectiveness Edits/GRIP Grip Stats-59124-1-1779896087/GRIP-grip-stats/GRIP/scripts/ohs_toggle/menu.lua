local async     = require 'openmw.async'
local core      = require 'openmw.core'
local input     = require('openmw.input')
local menu      = require 'openmw.menu'
local storage   = require 'openmw.storage'
local ISettings = require('openmw.interfaces').Settings

local L10N      = 'ohs_toggle'
local PAGE      = 'OHS_Toggle_Page'
local GROUP     = 'SettingsOHS_Toggle'
local TRIG      = 'OHS_ToggleSpear' -- must match player.lua

input.registerTrigger {
  key         = TRIG,
  l10n        = L10N,
  name        = '',
  description = '',
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
      argument    = { key = TRIG, type = 'trigger' },
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
      key         = 'EnableGripStats',
      renderer    = 'checkbox',
      name        = 'enable_grip_stats_name',
      description = 'enable_grip_stats_desc',
      default     = true,
    },
    {
      key         = 'OneHandSpeedMult',
      renderer    = 'number',
      name        = 'onehand_speed_name',
      description = 'onehand_speed_desc',
      default     = 1.05,
      argument    = { min = 0.50, max = 1.50 },
    },
    {
      key         = 'TwoHandSpeedMult',
      renderer    = 'number',
      name        = 'twohand_speed_name',
      description = 'twohand_speed_desc',
      default     = 0.95,
      argument    = { min = 0.50, max = 1.50 },
    },
    {
      key         = 'OneHandReachMult',
      renderer    = 'number',
      name        = 'onehand_reach_name',
      description = 'onehand_reach_desc',
      default     = 0.95,
      argument    = { min = 0.50, max = 1.50 },
    },
    {
      key         = 'TwoHandReachMult',
      renderer    = 'number',
      name        = 'twohand_reach_name',
      description = 'twohand_reach_desc',
      default     = 1.10,
      argument    = { min = 0.50, max = 1.50 },
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
  print('Sending mult update')
  core.sendGlobalEvent('OHS_UpdateGlobalData', {
    OneHandDamageMult = group:get('OneHandDamageMult'),
    TwoHandDamageMult = group:get('TwoHandDamageMult'),
    EnableGripStats   = group:get('EnableGripStats'),
    OneHandSpeedMult  = group:get('OneHandSpeedMult'),
    TwoHandSpeedMult  = group:get('TwoHandSpeedMult'),
    OneHandReachMult  = group:get('OneHandReachMult'),
    TwoHandReachMult  = group:get('TwoHandReachMult'),
    DebugLog          = group:get('DebugLog'),
  })
end

group:subscribe(async:callback(updateMult))

return {
  eventHandlers = {
    OHS_RequestGlobalData = updateMult,
  },
}
