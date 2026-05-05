


-- In a player script
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local core = require('openmw.core')



local MOD_ID = "Ray"
local settingsKey = "SettingsPlayer" .. MOD_ID
local settings = storage.playerSection(settingsKey)
local async = require('openmw.async')



I.Settings.registerPage {
    key = MOD_ID,
    l10n = MOD_ID,
    name = 'name',
    description = 'description',
}
I.Settings.registerGroup {
    key = settingsKey,
    page = MOD_ID,
    l10n = MOD_ID,
    name = 'settingsTitle',
    description = '',
    permanentStorage = false,
    settings = {
        {
            key = 'DamageScaleMultiplierForRays',
            renderer = 'number',
            name = 'scalemultiplier',
            description = 'scalemultiplierdesc',
            default = 0.06
        },
        {
            key = "FireRateForRays",
            name = "firerate",
            description = "fireratedesc",
            default = 0.1,
            renderer = 'number'
        },
        {
            key = "CostScaleMultiplierForRays",
            name = "costscale",
            description = "costscaledesc",
            default = 0.05,
            renderer = 'number'
        }
    },
}



local SCALE_FACTOR = settings:get("DamageScaleMultiplierForRays")
local function updateSCALE_FACTOR(_, key)
    if key == "DamageScaleMultiplierForRays" then
        SCALE_FACTOR = settings:get("DamageScaleMultiplierForRays")
		core.sendGlobalEvent('GetModSettingsForDamageObject', {FIRE_RATE=FIRE_RATE,SCALE_FACTOR=SCALE_FACTOR,Cost_SCALE=Cost_SCALE})
    end
end
settings:subscribe(async:callback(updateSCALE_FACTOR))


local FIRE_RATE = settings:get("FireRateForRays")
local function updateFIRE_RATE(_, key)
    if key == "FireRateForRays" then
        FIRE_RATE = settings:get("FireRateForRays")
		core.sendGlobalEvent('GetModSettingsForDamageObject', {FIRE_RATE=FIRE_RATE,SCALE_FACTOR=SCALE_FACTOR,Cost_SCALE=Cost_SCALE})
    end
end
settings:subscribe(async:callback(updateFIRE_RATE))

local Cost_SCALE = settings:get("CostScaleMultiplierForRays")
local function updateCost_SCALE(_, key)
    if key == "CostScaleMultiplierForRays" then
        Cost_SCALE = settings:get("CostScaleMultiplierForRays")
		core.sendGlobalEvent('GetModSettingsForDamageObject', {FIRE_RATE=FIRE_RATE,SCALE_FACTOR=SCALE_FACTOR,Cost_SCALE=Cost_SCALE})
    end
end
settings:subscribe(async:callback(updateCost_SCALE))


--best way to get the settings to non player scripts, make sure to fire in the callbacks as well
core.sendGlobalEvent('GetModSettingsForDamageObject', {FIRE_RATE=FIRE_RATE,SCALE_FACTOR=SCALE_FACTOR,Cost_SCALE=Cost_SCALE})




