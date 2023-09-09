local input = require('openmw.input')
local async = require('openmw.async')
local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'CinematicCamera',
    l10n = 'CinematicCamera',
    name = 'Cinematic Camera',
    description = 'Free camera with smooth controls for recording cinematic videos',
}

I.Settings.registerRenderer('CC_hotkey', function(value, set)
    return {
        template = I.MWUI.templates.textEditLine,
        props = {
            text = input.getKeyName(value),
        },
        events = {
            keyPress = async:callback(function(e)
                set(e.code)
            end),
        }
    }
end)

I.Settings.registerRenderer('CC_number', function(value, set)
    return {
        template = I.MWUI.templates.textEditLine,
        props = {
            text = tostring(value),
        },
        events = {
            textChanged = async:callback(function(text)
                local number = tonumber(text)
                if number then set(number) end
            end),
        }
    }
end)

I.Settings.registerGroup {
    key = 'SettingsCinematicCameraControls',
    page = 'CinematicCamera',
    order = 0,
    l10n = 'CinematicCamera',
    name = 'Keybindings',
    permanentStorage = true,
    settings = {
        {
            key = 'freeHotkey',
            default = input.KEY.C,
            renderer = 'CC_hotkey',
            name = 'Toggle smooth free camera',
        },
        {
            key = 'firstPersonHotkey',
            default = input.KEY.V,
            renderer = 'CC_hotkey',
            name = 'Toggle smooth first person camera',
        },
        {
            key = 'cameraSensitivityX',
            default = 1.0,
            renderer = 'CC_number',
            name = 'Horizontal sensitivity',
        },
        {
            key = 'cameraSensitivityY',
            default = 1.0,
            renderer = 'CC_number',
            name = 'Vertical sensitivity',
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsCinematicCameraSmoothing',
    page = 'CinematicCamera',
    order = 1,
    l10n = 'CinematicCamera',
    name = 'Smoothing parameters',
    permanentStorage = false,
    settings = {
        {
            key = 'rotationSmoothing',
            default = 0.2,
            renderer = 'CC_number',
            name = 'Rotation smoothing',
        },
        {
            key = 'relativeAcceleration',
            default = 0.1,
            renderer = 'CC_number',
            name = 'Relative acceleration',
        },
        {
            key = 'minAcceleration',
            default = 5 * 10 ^ 1,
            renderer = 'CC_number',
            name = 'Minimum acceleration',
        },
        {
            key = 'maxAcceleration',
            default = 1 * 10 ^ 5,
            renderer = 'CC_number',
            name = 'Maximum acceleration',
        },
        {
            key = 'maxRotation',
            default = math.pi * 4,
            renderer = 'CC_number',
            name = 'Rotation limit',
            descripiton = 'In radians per second',
        },
    }
}
