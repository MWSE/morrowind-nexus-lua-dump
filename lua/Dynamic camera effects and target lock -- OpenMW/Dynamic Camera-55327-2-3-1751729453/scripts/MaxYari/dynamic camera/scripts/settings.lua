local I = require('openmw.interfaces')
local input = require('openmw.input')

local HighSpeedEffectsOpts = {
    Everywhere = "Everywhere",
    Air = "In the air",
    Ground = "On the ground",
    Off = "Off"
}

input.registerTrigger {
    key = 'LockTarget',    
    l10n = 'FPViewDynamics'
}

I.Settings.registerPage {
    key = 'FPViewDynamicsPage',
    l10n = 'FPViewDynamics',
    name = 'Caméra',
    description = "~~ Whoaaa, look how it moves. Some of the settings are not updated in realtime. Open a ~ console and run 'reloadlua' command to apply settings, or restart the game.",
}
I.Settings.registerGroup {
    key = '1FPViewDynamicsControlsSettings',
    page = 'FPViewDynamicsPage',
    l10n = 'FPViewDynamics',
    name = 'Controls',
    permanentStorage = true,    
    settings = {
        {
            key = "LockTargetButton",
            renderer = "inputBinding",
            default = "LockTargetButtonKey",
            name = "Lock Target",
            description = 'Press to lock the view onto a target.',
            argument = {
                type = "trigger",
                key = "LockTarget"
            }
        }
    }
}
I.Settings.registerGroup {
    key = '2FPViewDynamicsVisualSettings',
    page = 'FPViewDynamicsPage',
    l10n = 'FPViewDynamics',
    name = 'Visuals',    
    permanentStorage = true,
    settings = {
        {
            key = "JumpBobStrength",
            renderer = "number",
            default = 100,
            argument = {
                min = 0
            },
            name = "Jump Headbob Strength"
        },
        {
            key = "LandBobStrength",
            renderer = "number",
            default = 100,
            argument = {
                min = 0
            },
            name = "Landing Headbob Strength"
        },        
        {
            key = "ViewmodelIntertiaStrength",
            renderer = "number",
            default = 175,
            argument = {
                min = 0
            },
            name = "Viewmodel Inertia Strength"
        },
        {
            key = 'HighSpeedEffects',
            renderer = 'select',
            default = HighSpeedEffectsOpts.Everywhere,
            argument = {
                l10n = 'FPViewDynamics',
                items = { HighSpeedEffectsOpts.Everywhere, HighSpeedEffectsOpts.Air, HighSpeedEffectsOpts.Ground, HighSpeedEffectsOpts.Off },
            },
            name = 'High Speed Effects'
        },
        {
            key = "HighSpeedEffectStart",
            renderer = "number",
            default = 600,
            argument = {
                min = 0
            },
            name = "High-speed Effect Start",
            description = 'Character speed at which high-speed effects kick in.',
        },
        {
            key = "SpeedBlurStrength",
            renderer = "number",
            default = 100,
            argument = {
                min = 0
            },
            name = "High-speed Blur Strength"
        },
        {
            key = "DofEffects",
            renderer = "checkbox",
            default = true,
            name = "Depth of field effects",
            description = "If enabled uses subtle depth-of-field effects on target lock and cell transitions. Keeping it disabled might improve performace."
        },
        {
            key = "CellTransitionDuration",
            renderer = "number",
            default = 1,
            argument = {
                min = 0
            },
            name = "Cell Transition Animation Duration",
            description = "In seconds"
        },
        {
            key = "SneakVignetteOpacity",
            renderer = "number",
            default = 35,
            argument = {
                min = 0,
                max = 100
            },
            name = "Sneak Vignette Opacity",
            description = "In 0 - 100 range"
        }
    },
}
I.Settings.registerGroup {
    key = '3FPViewDynamicsSoundSettings',
    page = 'FPViewDynamicsPage',
    l10n = 'FPViewDynamics',
    name = 'Sound',
    description = 'Wind goes woooshhhhh',
    permanentStorage = true,
    settings = {
        {
            key = "SpeedWindVolume",
            renderer = "number",
            default = 100,
            argument = {
                min = 0
            },
            name = "High-speed Wind Volume"
        }
    },
}

I.Settings.registerGroup {
    key = '4FPViewDynamicsVisualExtraSettings',
    page = 'FPViewDynamicsPage',
    l10n = 'FPViewDynamics',
    name = 'Extra Visuals',
    description = "For those of unusual tastes.",
    permanentStorage = true,
    settings = {
        {
            key = "BlackBarsRatio",
            renderer = "number",
            default = 0,
            argument = {
                min = 0
            },
            name = "Black Bars Ratio",
            description = "If > 0 - Cinematic black bars will appear upon locking a target. 2.2 is a good starting value."
        },
        {
            key = "StrafeRollStrength",
            renderer = "number",
            default = 0,
            argument = {
                
            },
            name = "Camera Roll Strength (Strafing)",
            description = "Subtly (or not so subtly) tilts the camera from side to side during strafing. 100 is a good starting value. Can be negative."
        },
        {
            key = "LookAroundRollStrength",
            renderer = "number",
            default = 0,
            argument = {
                
            },
            name = "Camera Roll Strength (Looking Around)",
            description = "Subtly (or not so subtly) tilts the camera from side to side when looking around. 100 is a good starting value. Can be negative."
        }
    },
}




return {
    HighSpeedEffectsOpts = HighSpeedEffectsOpts
}
