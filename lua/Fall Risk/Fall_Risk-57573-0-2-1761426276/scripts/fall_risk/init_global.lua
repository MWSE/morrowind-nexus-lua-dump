-- fall_risk/init_global.lua — v0.3
local storage = require('openmw.storage')
local async = require('openmw.async')

local LOG = '[FallRisk/init_global] '

async:newUnsavableGameTimer(1.0, function()
    local sec = storage.playerSection('SettingsFallRisk')
end)
