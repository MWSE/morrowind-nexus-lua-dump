-- Enchant Transfer — Settings (MENU) for OpenMW 0.49
-- Exposes an inputBinding for a Boolean ACTION.

local I     = require('openmw.interfaces')
local input = require('openmw.input')

local L10N       = 'EnchantXfer'
local PAGE_KEY   = 'Enchant Transfer'
local GROUP_KEY  = 'SettingsGlobalEnchantXfer'
local ACTION_KEY = 'EnchantXfer_OpenMenu' -- changed: no colon; unique and stable

local function ensureActionRegistered()
  -- Must exist in MENU so the row can bind to it (idempotent).
  if not input.actions[ACTION_KEY] then
    input.registerAction({
      key          = ACTION_KEY,
      l10n         = L10N,
      name         = '',
      description  = '',
      type         = input.ACTION_TYPE.Boolean,
      defaultValue = false,
    })
  end
end

local function registerSettings()
  I.Settings.registerPage{
    key = PAGE_KEY, l10n = L10N,
    name = 'Enchant Transfer',
    description = 'Configure a hotkey to open the Enchantment Transfer window',
  }

  I.Settings.registerGroup{
    key = GROUP_KEY, page = PAGE_KEY, l10n = L10N,
    name = 'Hotkey',
    description = 'Pick a key to open the Enchantment Transfer window',
    permanentStorage = true,
    settings = {
      {
        key = 'OpenMenuBinding',
        renderer = 'inputBinding',
        name = 'Open Menu',
        description = 'Press to open the Enchantment Transfer window',
        default = '', -- inputBinding default should be a STRING; empty = unbound
        argument = {
          key  = ACTION_KEY,
          type = 'action',
        },
      },
    },
  }
end

return {
  engineHandlers = {
    onInit = function()
      ensureActionRegistered()
      registerSettings()
    end,
  },
}
