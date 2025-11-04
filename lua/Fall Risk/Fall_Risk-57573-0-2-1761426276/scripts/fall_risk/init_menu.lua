-- fall_risk/init_menu.lua — v0.2
local input = require('openmw.input')
local L10N_CTX = 'FallRisk'

input.registerAction{
    key = 'FR_Hold',
    type = input.ACTION_TYPE.Boolean,
    name = 'FR.Binding.Hold.Name',
    description = 'FR.Binding.Hold.Desc',
    l10n = L10N_CTX,
    defaultValue = false,
}
