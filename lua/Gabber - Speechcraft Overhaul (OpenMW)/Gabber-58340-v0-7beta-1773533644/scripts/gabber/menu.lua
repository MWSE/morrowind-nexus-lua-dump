local async     = require 'openmw.async'
local core      = require 'openmw.core'
local input     = require('openmw.input')
local menu      = require 'openmw.menu'
local storage   = require 'openmw.storage'
local ISettings = require('openmw.interfaces').Settings

local L10N      = 'none'
local PAGE      = 'Page_Gabber'
local GROUP     = 'Settings_Gabber'

local settingTemplate = {
  key              = GROUP,
  page             = PAGE,
  l10n             = L10N,
  name             = 'Settings',
  permanentStorage = true,
  settings         = {
    {
      key         = 'posMult',
      renderer    = 'number',
      name        = 'Success multiplier',
      description = 'Base multiplier for disposition gain on successful action.\n(Default: 3)',
      default     = 1.5,
      argument    = { min = 0.00, max = 10.00 },
    },
    {
      key         = 'negMult',
      renderer    = 'number',
      name        = 'Failure multiplier',
      description = 'Base multiplier for disposition gain on failed action.\n(Default: 1.5)',
      default     = 3.0,
      argument    = { min = 0.00, max = 10.00 },
    },
    {
      key         = 'critMult',
      renderer    = 'number',
      name        = 'Crit multiplier',
      description = 'Additional multiplier for critical success.\n(Default: 2.5)',
      default     = 2.5,
      argument    = { min = 0.00, max = 10.00 },
    },
    {
      key         = 'fatigueMult',
      renderer    = 'number',
      name        = 'Fatigue Use',
      description = 'Multiplier for fatigue use per action.\n(Default: 0.1)',
      default     = 0.1,
      argument    = { min = 0.00, max = 10.00 },
    },
    {
      key         = 'baseTopics',
      renderer    = 'number',
      integer     = true,
      name        = 'Base Topics',
      description = 'Number of topics at speechcraft 0.\n(Default: 1)',
      default     = 1,
      argument    = { min = 1, max = 5 },
    },
  },
}

--local group = storage.playerSection(GROUP)

ISettings.registerGroup(settingTemplate)

ISettings.registerPage {
  key         = PAGE,
  l10n        = L10N,
  name        = 'Gabber',
  description = 'Gabber, Speechcraft Overhaul',
}

settingsSection = storage.playerSection('Settings_Gabber')

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
