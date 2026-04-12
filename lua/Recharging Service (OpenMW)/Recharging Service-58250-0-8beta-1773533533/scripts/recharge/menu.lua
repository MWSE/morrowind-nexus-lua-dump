local async     = require 'openmw.async'
local core      = require 'openmw.core'
local input     = require('openmw.input')
local menu      = require 'openmw.menu'
local storage   = require 'openmw.storage'
local ISettings = require('openmw.interfaces').Settings

local L10N      = 'none'
local PAGE      = 'Page_Recharge'
local GROUP     = 'Settings_Recharge'

local settingTemplate = {
  key              = GROUP,
  page             = PAGE,
  l10n             = L10N,
  name             = 'Settings',
  permanentStorage = true,
  settings         = {
    {
      key         = 'gemPatch',
      renderer    = 'checkbox',
      name        = 'Soulgem Price Patch',
      description = 'Adjusts prices to match nerfed soulgem prices.\n(Default: Yes)',
      default     = true,
    },
    {
      key         = 'priceMult',
      renderer    = 'number',
      name        = 'Recharge Price Multiplier',
      description = 'Modifier to increase or decrease recharge prices.\n(Default: 1)',
      default     = 1,
      argument    = { min = 0.0, max = 10.0 },
    },
  },
}

--local group = storage.playerSection(GROUP)

ISettings.registerGroup(settingTemplate)

ISettings.registerPage {
  key         = PAGE,
  l10n        = L10N,
  name        = 'Recharging Service',
  description = 'Recharging Service',
}

settingsSection = storage.playerSection('Settings_Recharge')

function readAllSettings()
	for i, entry in pairs(settingTemplate.settings) do
  
		_G[entry.key] = settingsSection:get(entry.key)
	end
end

readAllSettings()

local updateSettings = function (_,setting)
	--print(setting.." changed to "..settingsSection:get(setting))
	readAllSettings()
end

settingsSection:subscribe(async:callback(updateSettings))
