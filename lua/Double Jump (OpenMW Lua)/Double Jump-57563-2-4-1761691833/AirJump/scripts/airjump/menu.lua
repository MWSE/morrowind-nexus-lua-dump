-- AirJump (MENU) — Settings page and input binding (OpenMW 0.49/0.50)
-- This file only owns the page and the *binding* group. The gameplay group is owned by global.lua.

local I     = require('openmw.interfaces')
local input = require('openmw.input')

-- Localization context
local L10N       = 'AirJump'

-- Settings page key
local PAGE_KEY   = 'AirJump'

-- Binding group key (permanent)
local BIND_GROUP = 'SettingsAirJumpBind'

-- Unique trigger id for THIS mod only
local TRIGGER_KEY = 'GZ_AirJump_Toggle'  -- MUST be unique and namespaced

local function ensureTriggerRegistered()
  -- Make sure the trigger exists so the Settings UI can bind it.
  -- Using pcall to be resilient across reloads or re-registration.
  pcall(function()
    if not (input.triggers and input.triggers[TRIGGER_KEY]) then
      input.registerTrigger {
        key         = TRIGGER_KEY,
        l10n        = L10N,
        name        = 'AirJump_Hotkey_Name',        -- your l10n key
        description = 'AirJump_Hotkey_Description', -- your l10n key
      }
    end
  end)
end

local function registerSettings()
  I.Settings.registerPage{
    key = PAGE_KEY, l10n = L10N,
    name = 'AirJump_Page_Name',          -- l10n key
    description = 'AirJump_Page_Desc',   -- l10n key
  }

  -- Input binding group (persistent). Do NOT store your own key; let the
  -- renderer bind directly to the trigger.
  I.Settings.registerGroup{
    key = BIND_GROUP, page = PAGE_KEY, l10n = L10N,
    name = 'AirJump_Input_Group_Name',        -- l10n key
    description = 'AirJump_Input_Group_Desc', -- l10n key
    permanentStorage = true,
    settings = {
      {
        key         = 'BindAirJump',         -- storage key
        renderer    = 'inputBinding',
        name        = 'AirJump_Bind_Name',         -- l10n key
        description = 'AirJump_Bind_Desc',         -- l10n key
        -- IMPORTANT: inputBinding expects a *string* default
        default     = 'P',
        -- Bind THIS row to THIS trigger
        argument    = { key = TRIGGER_KEY, type = 'trigger' },
      },
    },
  }

  -- NOTE: Do not register the gameplay group here. global.lua is the single owner.
end

return {
  engineHandlers = {
    onInit = function()
      ensureTriggerRegistered()
      registerSettings()
    end,
  },
}
