local async     = require 'openmw.async'
local core      = require 'openmw.core'
local input     = require('openmw.input')
local menu      = require 'openmw.menu'
local storage   = require 'openmw.storage'
local ISettings = require('openmw.interfaces').Settings

local L10N      = 'none'
local PAGE      = 'Page_Entropy'
local GROUP     = 'Settings_Entropy'

local settingTemplate = {
  key              = GROUP,
  page             = PAGE,
  l10n             = L10N,
  name             = 'Settings',
  permanentStorage = true,
  settings         = {
    {
      key         = 'lossMult',
      renderer    = 'number',
      name        = 'Repair loss multiplier',
      description = 'Modifier to increase or decrease amount of permenant damage from repair.\n(Default: 0.5)',
      default     = 0.5,
      argument    = { min = 0.00, max = 1.00 },
    },
    {
      key         = 'lossMin',
      renderer    = 'number',
      name        = 'Minimum repair loss',
      description = 'Minimum amount of permenant damage that will be applied from repair.\n(Default: 0.1)',
      default     = 0.1,
      argument    = { min = 0.0, max = 1.0 },
    },
    {
      key         = 'skillCapMult',
      renderer    = 'number',
      name        = 'Skill cap multiplier',
      description = 'Player capable of repairing up to\n(armorer / (100 * skillCapMult))% of item condition.\n(Default: 0.5)',
      default     = 0.5,
      argument    = { min = 0.0, max = 1.0 },
    },
    {
      key         = 'fullSmith',
      renderer    = 'checkbox',
      name        = 'NPC smiths always full repair',
      description = 'NPC smiths will never cause permenant damage to items.\n(Default: Yes)',
      default     = true,
    },
  }
}

--local group = storage.playerSection(GROUP)

ISettings.registerGroup(settingTemplate)

ISettings.registerPage {
  key         = PAGE,
  l10n        = L10N,
  name        = 'Entropy',
  description = 'Entropy, A Repair Overhaul',
}

settingsSection = storage.playerSection('Settings_Entropy')

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
