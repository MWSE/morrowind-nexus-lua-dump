local async     = require 'openmw.async'
local core      = require 'openmw.core'
local input     = require('openmw.input')
local menu      = require 'openmw.menu'
local storage   = require 'openmw.storage'
local ISettings = require('openmw.interfaces').Settings

local L10N      = 'none'
local PAGE      = 'Page_Transcription'
local GROUP     = 'Settings_Transcription'

local settingTemplate = {
  key              = GROUP,
  page             = PAGE,
  l10n             = L10N,
  name             = 'Settings',
  permanentStorage = true,
  settings         = {
    {
      key         = 'priceMult',
      renderer    = 'number',
      name        = 'Transcription Price Multiplier',
      description = 'Modifier to increase or decrease transcription prices.\n(Default: 1)',
      default     = 0.5,
      argument    = { min = 0.0, max = 0.5 },
    },
  },
}

--local group = storage.playerSection(GROUP)

ISettings.registerGroup(settingTemplate)

ISettings.registerPage {
  key         = PAGE,
  l10n        = L10N,
  name        = 'Transcription Service',
  description = 'Transcription Service',
}

settingsSection = storage.playerSection('Settings_Transcription')

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
