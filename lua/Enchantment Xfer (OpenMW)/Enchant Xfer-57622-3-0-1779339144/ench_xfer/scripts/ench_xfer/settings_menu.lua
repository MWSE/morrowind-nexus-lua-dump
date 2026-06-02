-- Enchant Transfer — Settings (MENU) for OpenMW 0.49
-- Exposes an inputBinding for a Boolean ACTION.

local I     = require('openmw.interfaces')
local input = require('openmw.input')
local storage = require('openmw.storage')

local L10N       = 'EnchantXfer'
local PAGE_KEY   = 'Enchant Transfer'
local GROUP_KEY  = 'SettingsGlobalEnchantXfer'
local ACTION_KEY = 'EnchantXfer_OpenMenu' -- changed: no colon; unique and stable
local BINDING_KEY = 'OpenMenuBinding'
local BINDING_ID  = 'EnchantXfer_OpenMenuBinding_v1'

local LEGACY_BINDING_IDS = {
  '',
  ACTION_KEY,
  BINDING_KEY,
}

local function ensureActionRegistered()
  -- Must exist in MENU so the row can bind to it (idempotent).
  if not input.actions[ACTION_KEY] then
    input.registerAction({
      key          = ACTION_KEY,
      l10n         = L10N,
      name         = 'action_open_menu_name',
      description  = 'action_open_menu_description',
      type         = input.ACTION_TYPE.Boolean,
      defaultValue = false,
    })
  end
end

local function bindingBelongsToUs(binding)
  return type(binding) == 'table'
    and binding.type == 'action'
    and binding.key == ACTION_KEY
end

local function migrateBindingSetting()
  local settingsSection = storage.playerSection(GROUP_KEY)
  local bindingSection = storage.playerSection('OMWInputBindings')

  local function moveBinding(oldId)
    if type(oldId) ~= 'string' or oldId == BINDING_ID then return end
    local oldBinding = bindingSection:get(oldId)
    if not bindingBelongsToUs(oldBinding) then return end

    local newBinding = bindingSection:get(BINDING_ID)
    if newBinding ~= nil and not bindingBelongsToUs(newBinding) then
      bindingSection:set(BINDING_ID, nil)
      newBinding = nil
    end
    if newBinding == nil then
      bindingSection:set(BINDING_ID, oldBinding)
    end
    bindingSection:set(oldId, nil)
  end

  moveBinding(settingsSection:get(BINDING_KEY))
  for _, oldId in ipairs(LEGACY_BINDING_IDS) do
    moveBinding(oldId)
  end

  if settingsSection:get(BINDING_KEY) ~= BINDING_ID then
    settingsSection:set(BINDING_KEY, BINDING_ID)
  end
end

local function registerSettings()
  I.Settings.registerPage{
    key = PAGE_KEY, l10n = L10N,
    name = 'settings_page_name',
    description = 'settings_page_description',
  }

  I.Settings.registerGroup{
    key = GROUP_KEY, page = PAGE_KEY, l10n = L10N,
    name = 'settings_hotkey_group_name',
    description = 'settings_hotkey_group_description',
    permanentStorage = true,
    settings = {
      {
        key = 'OpenMenuBinding',
        renderer = 'inputBinding',
        name = 'settings_open_menu_name',
        description = 'settings_open_menu_description',
        default = BINDING_ID,
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
      migrateBindingSetting()
      registerSettings()
    end,
  },
}
