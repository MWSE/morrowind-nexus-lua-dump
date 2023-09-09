if require('openmw.core').API_REVISION < 23 then
    error('This mod requires a newer version of OpenMW, please update.')
end

local camera = require('openmw.camera')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

if not I.Camera then
    error('Interface "Camera" is required')
end

local settings = storage.playerSection('SettingsAdvancedCamera')

I.Settings.registerPage({
  key = 'AdvancedCamera',
  l10n = 'AdvancedCamera',
  name = 'AdvancedCamera',
  description = 'AdvancedCameraDescription',
})

local function boolSetting(key, default)
    return {
        key = key,
        renderer = 'checkbox',
        name = key,
        description = key..'Description',
        default = default,
    }
end

I.Settings.registerGroup({
    key = 'SettingsAdvancedCamera',
    page = 'AdvancedCamera',
    l10n = 'AdvancedCamera',
    name = 'Settings',
    permanentStorage = true,
    settings = {
        boolSetting('bowAimingThirdPerson', true),
        boolSetting('bowAimingFirstPerson', false),
        boolSetting('freeCamera', false),
    },
})

local bowAiming = require('scripts.AdvancedCamera.bow_aiming')
local freeCamera = require('scripts.AdvancedCamera.free_camera')

return {
    engineHandlers = {
        onFrame = function(dt)
            freeCamera.onFrame(dt, settings:get('freeCamera'))
        end,
        onUpdate = function(dt)
            bowAiming.onUpdate(dt, settings:get('bowAimingThirdPerson'), settings:get('bowAimingFirstPerson'))
        end,
        onInputAction = function(action)
            if settings:get('freeCamera') then freeCamera.onInputAction(action) end
        end,
    },
}

