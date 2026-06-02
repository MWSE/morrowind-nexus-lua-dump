local I = require('openmw.interfaces')
local config = require('scripts.ancestor_ghost.config')

local M = {}

function M.registerPage()
  I.Settings.registerPage({
    key = config.settingsPageKey,
    l10n = 'AncestorGhost',
    name = 'AncestorGhost',
    description = 'settingsPageDescription',
  })
end

function M.registerGroup()
  I.Settings.registerGroup({
    key = config.settingsGroupKey,
    page = config.settingsPageKey,
    l10n = 'AncestorGhost',
    name = 'modSettings',
    description = 'modSettingsDescription',
    permanentStorage = false,
    order = 0,
    settings = {
      {
        key = config.settingNormalWeaponsKey,
        renderer = 'select',
        name = 'normalWeaponsImmunity',
        description = 'normalWeaponsImmunityDescription',
        default = config.settingDefaults.normalWeaponsImmunity,
        argument = {
          l10n = 'AncestorGhost',
          items = { 100, 50, 0 },
        },
      },
      {
        key = config.settingDiseaseResistKey,
        renderer = 'checkbox',
        name = 'commonDiseaseImmunity',
        description = 'commonDiseaseImmunityDescription',
        default = config.settingDefaults.commonDiseaseImmunity,
      },
      {
        key = config.settingLevitateKey,
        renderer = 'checkbox',
        name = 'ghostlyLevitate',
        description = 'ghostlyLevitateDescription',
        default = config.settingDefaults.ghostlyLevitate,
      },
      {
        key = config.settingUndeadFriendlyKey,
        renderer = 'checkbox',
        name = 'undeadFriendly',
        description = 'undeadFriendlyDescription',
        default = config.settingDefaults.undeadFriendly,
      },
    },
  })
end

return M
