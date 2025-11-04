-- fall_risk/settings_menu.lua — v0.7
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local input = require('openmw.input')

local LOGP = '[FallRisk/settings_menu] '

------------------------------------------------------------
-- Bridge : écrit directement dans le storage global
------------------------------------------------------------
local function onSettingUpdate(key, value)
  local ok, sec = pcall(storage.playerSection, 'SettingsFallRisk')
  if not ok or not sec then return end

end


------------------------------------------------------------
-- Page unique
------------------------------------------------------------
I.Settings.registerPage{
    key = 'FallRisk_Page',
    l10n = 'FallRisk',
    name = 'PageName',
    description = 'PageDesc',
}

------------------------------------------------------------
-- Groupe principal (avec callbacks onUpdate)
------------------------------------------------------------
I.Settings.registerGroup{
    key = 'SettingsFallRisk',
    page = 'FallRisk_Page',
    l10n = 'FallRisk',
    name = 'GroupName',
    description = 'GroupDesc',
    permanentStorage = true,
    settings = {
        -- Texture / palette
        {
            key = 'TextureSize',
            renderer = 'select',
            l10n = 'FallRisk',
            name = 'RingSizeName',
            description = 'RingSizeDesc',
            argument = { l10n = 'FallRisk', items = { 'ring64', 'ring128' } },
            default = 'ring128',
            onUpdate = onSettingUpdate,
        },
        {
            key = 'Palette',
            renderer = 'select',
            l10n = 'FallRisk',
            name = 'PaletteName',
            description = 'PaletteDesc',
            argument = { l10n = 'FallRisk', items = { 'default', 'alt' } },
            default = 'default',
            onUpdate = onSettingUpdate,
        },

        -- Binding
        {
            key = 'BindHold',
            renderer = 'inputBinding',
            l10n = 'FallRisk',
            name = 'FR.Binding.Hold.Name',
            description = 'FR.Binding.Hold.Desc',
            argument = { type = 'action', key = 'FR_Hold' },
            default = '',
            onUpdate = onSettingUpdate,
        },

        -- Paramètres regard vers le bas
        {
            key = 'HoldRequireLookDown',
            renderer = 'checkbox',
            l10n = 'FallRisk',
            name = 'HoldRequireLookDownName',
            description = 'HoldRequireLookDownDesc',
            default = false,
            onUpdate = onSettingUpdate,
        },
        {
            key = 'HoldLookDownThreshold',
            renderer = 'number',
            l10n = 'FallRisk',
            name = 'HoldLookDownThresholdName',
            description = 'HoldLookDownThresholdDesc',
            min = -89, max = 0, step = 1,
            default = -10,
            onUpdate = onSettingUpdate,
        },
    },
}

print(LOGP .. 'Groupe SettingsFallRisk enregistré (bridge actif)')
