local async     = require 'openmw.async'
local core      = require 'openmw.core'
local input     = require('openmw.input')
local menu      = require 'openmw.menu'
local storage   = require 'openmw.storage'
local ISettings = require('openmw.interfaces').Settings

local L10N      = 'none'
local PAGE      = 'Page_Salchemy'
local GROUP     = 'Settings_Salchemy'

local settingTemplate = {
  key              = GROUP,
  page             = PAGE,
  l10n             = L10N,
  name             = 'Settings',
  permanentStorage = true,
  settings         = {
    {
      key         = 'normalOn',
      renderer    = 'checkbox',
      name        = 'Reverse activation behavior',
      description = 'Regular behavior is shift-activate to enter vanilla alchemy.\n(Default: No)',
      default     = true,
    },
  },
}

--local group = storage.playerSection(GROUP)

ISettings.registerGroup(settingTemplate)

ISettings.registerPage {
  key         = PAGE,
  l10n        = L10N,
  name        = 'Standard Alchemy',
  description = 'Standard Alchemy',
}

settingsSection = storage.playerSection('Settings_Salchemy')

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
