local EasyMCM = require ("easyMCM.EasyMCM")
local config = require("simpleConfigurableHeadBobbing.config").loaded
local defaultConfig = require("simpleConfigurableHeadBobbing.config").default

local modName = ("Simple Configurable Head Bobbing")
local template = EasyMCM.createTemplate(modName)
template:saveOnClose("simpleConfigurableHeadBobbing", config)
template:register()

local page = template:createSideBarPage({
    label = "Settings",
    description = "Version 1.1.1\n\nThis mod adds procedural, natural head bobbing when moving around in the world. \n\nCurrently covers Walking, Running and Sneaking. Other movement states and actions (like levitate, swimming and jumping) might be covered in future releases.\n\nThe mod also syncs steps to head bobbing motion (toggleable), which is comptible with both vanilla and Character Sound Overhaul.",
    showReset = true
})

local settings = page:createCategory ("Simple Configurable Head Bobbing - Settings")

settings:createOnOffButton{
    label = "Enable Mod",
    description = "Turn this mod on or off.",
    defaultSetting = defaultConfig.modEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "modEnabled",
        table = config
    }
}

settings:createSlider{
    label = "Smoothing value",
    description = "Lower value = slower transition. Higher value = more direct. \n\nThis value dictates how smooth the transitions when starting and stopping headbobbing, as well as when transitioning between walking, running and sneaking.",
    max = 20,
    min = 5,
    defaultSetting = defaultConfig.smoothValue,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "smoothValue",
        table = config
    }
}

settings:createSlider{
    label = "Closest focal point for eye stabilization",
    description = "The headbobbing uses eye stabilization (as in, the camera rotates towards the point the crosshair points at) to make it feel more natural. At very close distances, the rotation angles becomes extreme, making the effect very exaggerated. \n\nThis value dictates what the shortest distance to a focal point can be, to avoid too extreme movments. Any point closer than this will use a focal point of that many units for its rotation.",
    max = 500,
    min = 100,
    defaultSetting = defaultConfig.minimumLookAtDistance,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "minimumLookAtDistance",
        table = config
    }
}

settings:createSlider{
    label = "Head bobbing speed",
    description = "This is a multiplier that dictates how fast the head bobbing should be in the game. A value of 100 is the same as 100%.",
    max = 150,
    min = 50,
    defaultSetting = defaultConfig.bobCustomizableFrequencyMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "bobCustomizableFrequencyMultiplier",
        table = config
    }
}

settings:createSlider{
    label = "Stealth bobbing speed multiplier",
    description = "This is a multiplier that dictates what speed (relative to walking and running head bobbing speed) the head bobbing should be when sneaking. A value of 75 is the same as 75% of ordinary bobbing speed.",
    max = 100,
    min = 50,
    defaultSetting = defaultConfig.sneakFrequencyMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakFrequencyMultiplier",
        table = config
    }
}

settings:createSlider{
    label = "Head bobbing amplitude",
    description = "This is a multiplier that dictates how large a motion the head bobbing should be in the game. A value of 100 is the same as 100%.",
    max = 150,
    min = 50,
    defaultSetting = defaultConfig.bobCustomizableAmplitudeMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "bobCustomizableAmplitudeMultiplier",
        table = config
    }
}

settings:createSlider{
    label = "Arm bobbing amplitude",
    description = "As the arms are very close to the camera, the effect on the arms is comically big if not adjusted. To counter this the arms bob the same as the camera, but with an amplitude that is percentually lower than the camera. 100% means following the camera exactly. 0% means the arms don't bob at all.",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.armAmplitudeMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "armAmplitudeMultiplier",
        table = config
    }
}

settings:createOnOffButton{
    label = "3rd person camera bobbing",
    description = "Toggles wether the head bobbing effect should be on when using the third person camera as well or not.",
    defaultSetting = defaultConfig.thirdPersonBobEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "thirdPersonBobEnabled",
        table = config
    }
}

settings:createSlider{
    label = "3rd person camera bobbing amplitude multiplier",
    description = "A multiplier that by default lessens the effect of the head bobbing when in third person. The default is lower as the effect seems more extreme in third person. Does nothing if the 3rd person camera bobbing is disabled. 50 means 50% of the first person amount of head bobbing.",
    max = 100,
    min = 10,
    defaultSetting = defaultConfig.thirdPersonBobMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "thirdPersonBobMultiplier",
        table = config
    }
}

settings:createOnOffButton{
    label = "Sync footsteps to head bobbing",
    description = "Toggles whether this mods control when footsteps should be played or not when in 1st person mode. Completely compatible with Character Sound Overhaul and vanilla both.\n\nHighly recommend this option to be enabled, unless it creates bugs in any other mod. Without it, footstep sounds and head bobbing is out of sync.",
    defaultSetting = defaultConfig.syncFootsteps,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "syncFootsteps",
        table = config
    }
}

local detailTweaks = template:createSideBarPage({
    label = "Detailed Tweaks",
    description = "Here you can change multipliers per motion and axis for more detailed control over how the head bobbing works in the game.",
    showReset = true
})

local walkingTweaks = detailTweaks:createCategory ("Tweaks for Walking")

walkingTweaks:createSlider{
    label = "Walking - Vertical amplitude multiplier",
    description = "A multiplier that determine how big the vertical amplitude (up and down motion) is when walking. 100 means the default value, 50 means 50% of default value etc.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.walkingCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "walkingCustomizableAmplitudeMultiplierY",
        table = config
    }
}

walkingTweaks:createSlider{
    label = "Walking - Horizontal amplitude multiplier",
    description = "A multiplier that determine how big the horizontal amplitude (side to side  motion) is when walking. 100 means the default value, 50 means 50% of default value etc.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.walkingCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "walkingCustomizableAmplitudeMultiplierX",
        table = config
    }
}

local sneakingTweaks = detailTweaks:createCategory ("Tweaks for Sneaking")

sneakingTweaks:createSlider{
    label = "Sneaking - Vertical amplitude multiplier",
    description = "A multiplier that determine how big the vertical amplitude (up and down motion) is when sneaking. 100 means the default value, 50 means 50% of default value etc.\n\nSneaking by default has much less pronounced up and down motion to simulate stealthily keeping your head low.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.sneakingCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakingCustomizableAmplitudeMultiplierY",
        table = config
    }
}

sneakingTweaks:createSlider{
    label = "Sneaking - Horizontal amplitude multiplier",
    description = "This multiplier that determine how big the horizontal amplitude (side to side  motion) is when sneaking. 100 means the default value, 50 means 50% of default value etc.\n\nSneaking by default has much less pronounced up and down motion to simulate stealthily keeping your head low.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.sneakingCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakingCustomizableAmplitudeMultiplierX",
        table = config
    }
}

local runningTweaks = detailTweaks:createCategory ("Tweaks for Running")

runningTweaks:createSlider{
    label = "Running - Vertical amplitude multiplier",
    description = "This multiplier that determine how big the vertical amplitude (up and down motion) is when running. 100 means the default value, 50 means 50% of default value etc.\n\nRunning by default is a more pronounced motion in both vertical and horizontal direction compared to walking.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.runningCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "runningCustomizableAmplitudeMultiplierY",
        table = config
    }
}

runningTweaks:createSlider{
    label = "Running - Horizontal amplitude multiplier",
    description = "This multiplier that determine how big the horizontal amplitude (side to side  motion) is when running. 100 means the default value, 50 means 50% of default value etc.\n\nRunning by default is a more pronounced motion in both vertical and horizontal direction compared to walking.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.runningCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "runningCustomizableAmplitudeMultiplierX",
        table = config
    }
}