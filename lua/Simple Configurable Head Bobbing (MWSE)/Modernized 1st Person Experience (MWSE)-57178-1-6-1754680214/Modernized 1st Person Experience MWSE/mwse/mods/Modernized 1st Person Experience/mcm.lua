--[[
	Mod: Modernized 1st Person Experience
	Author: rhjelte
	Version: 1.6
]]--


local EasyMCM = require ("easyMCM.EasyMCM")
local config = require("Modernized 1st Person Experience.config").loaded
local defaultConfig = require("Modernized 1st Person Experience.config").default

local modName = ("Modernized 1st Person Experience")
local template = EasyMCM.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()

local common = require("Modernized 1st Person Experience.common")


local page = template:createSideBarPage({
    label = "Main Settings",
    description = "Version 1.6\n\nThis mod adds procedural, natural head bobbing, view rolling, and camera noise, when moving around in the world. Head bobbing has different feel for Walking, Running, Sneaking, Swimming and Levitating.\n\nThe mod also syncs steps to head bobbing motion (toggleable), which is comptible with both vanilla and Character Sound Overhaul, Abot's Footprints etc.\n\nThe mod also covers smooth camera motion when entering and exiting sneaking, body inertia and corner peeking mechanic.",
    showReset = true
})

------------------------------------------------------------------------------------------------------------------------------- Main tweaks
local settings = page:createCategory ("Modernized 1st Person Experience - Main tweaks")

settings:createOnOffButton{
    label = "Enable Mod",
    description = "Turn this mod on or off.",
    defaultSetting = defaultConfig.modEnabled,
    showDefaultSetting = true,
    callback = function()
        common.updateSneakSettingsFromMenu()
    end,
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
    label = "Arm bobbing following amplitude",
    description = "100 = no percievable bobbing motion on the arms. 0 = a LOT of percievable bobbing motion on the arms.\n\nAs the arms are very close to the camera, the effect on the arms is comically big if not adjusted. To counter this the arms bob the same as the camera, but with an amplitude that is percentually lower than the camera. 100% means following the camera exactly. 0% means the arms don't bob at all.",
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
    label = "3rd person effects enabled",
    description = "Toggles wether the head bobbing effect, jumping, view rolling, corner peeking, and anything else compatible with 3rd person should be on when using the third person camera as well or not.\n\nEven though 1st person is the focus of the mod, I have made everything as compatible as possible with 3rd person as well. Recommended to be on for a more dynamic experience.",
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

settings:createOnOffButton{
    label = "Jump pitch feedback",
    description = "Toggles whether you get a slight pitch rotation when jumping (basically headbobbing for the jumping, just done with rotation instead of movement).",
    defaultSetting = defaultConfig.jumpEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "jumpEnabled",
        table = config
    }
}


settings:createOnOffButton{
    label = "Enable view rolling (rotation when strafing)",
    description = "With this function enabled, the camera will tilt left and right when the player moves left or right to highten the feel of movement. Can be a cause of nausea, so if you experience nausea, do turn it off.",
    defaultSetting = defaultConfig.viewRollingEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "viewRollingEnabled",
        table = config
    }
}

settings:createOnOffButton{
    label = "Camera noise movement (perlin noise)",
    description = "Toggles a very slight (but tweakable if you want more) movement on the camera to simulate breathing and just that it's hard to stand still. It uses samples from a perlin noise generated on start.",
    defaultSetting = defaultConfig.noiseEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "noiseEnabled",
        table = config
    }
}

settings:createOnOffButton{
    label = "Body Inertia (arms follow a bit after camera)",
    description = "Toggles wether the arms are looked to the camera, or smoothly follows them to simulate body inertia.",
    defaultSetting = defaultConfig.bodyInertiaEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "bodyInertiaEnabled",
        table = config
    }
}

settings:createOnOffButton{
    label = "Smooth sneak camera enabled",
    description = "This option toggles on or off the smooth sneak camera.\n\nAny other mod that lowers the camera will only work with this setting DISABLED. If you want a lower smooth camera, use the slider below.",
    defaultSetting = defaultConfig.sneakCameraSmoothingEnabled,
    showDefaultSetting = true,
    callback = function()
        common.updateSneakSettingsFromMenu()
    end,
    variable = mwse.mcm.createTableVariable{
        id = "sneakCameraSmoothingEnabled",
        table = config
    }
}

settings:createOnOffButton{
    label = "Corner peeking mechanic",
    description = "Toggles whether the you can peek around corners or not. NPCs should not be able to have line of sight to you behind a corner even when you peek around it.\n\nWhile peeking, you can not move, but you can freely look around. When you are done with peeking (if you are in 1st person), the camera will reset to the position it was in when you started peeking.",
    defaultSetting = defaultConfig.peekEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekEnabled",
        table = config
    }
}

local cornerPeekKeyBinds = settings:createCategory("Corner peeking key binds")

cornerPeekKeyBinds:createKeyBinder{
    label = "Left peek key",
    description = "While this is held, you will lean to Left. Does nothing without enabling the corner peek mechanic.",
    allowCombinations = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekLeftKey",
        table = config
    }
}

cornerPeekKeyBinds:createKeyBinder{
    label = "Right peek key",
    description = "While this is held, you will lean to Right. Does nothing without enabling the corner peek mechanic.",
    allowCombinations = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekRightKey",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Detailed bobbing tweaks
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

sneakingTweaks:createSlider{
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

local levitationTweaks = detailTweaks:createCategory ("Tweaks for Levitating")

levitationTweaks:createSlider{
    label = "Levitating - Vertical amplitude multiplier",
    description = "This multiplier that determine how big the vertical amplitude (up and down motion) is when levitating. 100 means the default value, 50 means 50% of default value etc.\n\nLevitating by default is a slightly more pronounced motion in both vertical and horizontal direction compared to walking.",
    max = 400,
    min = 0,
    defaultSetting = defaultConfig.flyingCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingCustomizableAmplitudeMultiplierY",
        table = config
    }
}

levitationTweaks:createSlider{
    label = "Levitating - Horizontal amplitude multiplier",
    description = "This multiplier that determine how big the horizontal amplitude (side to side motion) is when levitating. 100 means the default value, 50 means 50% of default value etc.\n\nLevitating by default is a slightly more pronounced motion in both vertical and horizontal direction compared to walking.",
    max = 400,
    min = 0,
    defaultSetting = defaultConfig.flyingCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingCustomizableAmplitudeMultiplierX",
        table = config
    }
}

levitationTweaks:createSlider{
    label = "Levitating - Being still frequency multiplier",
    description = "When standing still while levitating, you will still head bob a bit. This slider determines how much, as a multiplier on the default",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.flyingFrequencyMultiplierStill,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingFrequencyMultiplierStill",
        table = config
    }
}

levitationTweaks:createSlider{
    label = "Levitating - Moving frequency multiplier",
    description = "When moving while levitating, your head bobbing will this percentage fast relative to the ordinary walking bobbing speed.",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.flyingFrequencyMultiplierMoving,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingFrequencyMultiplierMoving",
        table = config
    }
}

local swimmingTweaks = detailTweaks:createCategory ("Tweaks for Swimming")

swimmingTweaks:createSlider{
    label = "Swimming - Vertical amplitude multiplier",
    description = "This multiplier that determine how big the vertical amplitude (up and down motion) is when swimming. 100 means the default value, 50 means 50% of default value etc.\n\nSwimming by default is a slightly more pronounced motion in both vertical and horizontal direction compared to walking.",
    max = 400,
    min = 0,
    defaultSetting = defaultConfig.swimmingCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingCustomizableAmplitudeMultiplierY",
        table = config
    }
}

swimmingTweaks:createSlider{
    label = "Swimming - Horizontal amplitude multiplier",
    description = "This multiplier that determine how big the horizontal amplitude (side to side motion) is when swimming. 100 means the default value, 50 means 50% of default value etc.\n\nSwimming by default is a slightly more pronounced motion in both vertical and horizontal direction compared to walking.",
    max = 400,
    min = 0,
    defaultSetting = defaultConfig.swimmingCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingCustomizableAmplitudeMultiplierX",
        table = config
    }
}

swimmingTweaks:createSlider{
    label = "Swimming - Being still frequency multiplier",
    description = "When standing still while swimming, you will still head bob a bit. This slider determines how much, as a multiplier on the default",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.swimmingFrequencyMultiplierStill,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingFrequencyMultiplierStill",
        table = config
    }
}

swimmingTweaks:createSlider{
    label = "Swimming - Moving frequency multiplier",
    description = "When moving while swimming, your head bobbing will this percentage fast relative to the ordinary walking bobbing speed.",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.swimmingFrequencyMultiplierMoving,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingFrequencyMultiplierMoving",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Perlin noise settings
local perlinNoiseTweaks = template:createSideBarPage({
    label = "Perlin noise settings",
    description = "Here you can tweak details on how the perlin noise affects the camera movement. None of these settings do anything unless the Perlin noise feature is enabled.\n\nThe perlin noise feature can be toggled on and off under the main tweaks tab.",
    showReset = true
})

perlinNoiseTweaks:createSlider{
    label = "Noise speed",
    description = "How fast the camera moves when sampling the noise loop. A higher value means faster movement.",
    max = 5,
    min = 0.1,
    step = 0.01,
    decimalPlaces = 2,
    defaultSetting = defaultConfig.noiseScale,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "noiseScale",
        table = config
    }
}

perlinNoiseTweaks:createSlider{
    label = "Noise amplitude",
    description = "How big the camera movement is when sampling from the noise loop. A higher value means a bigger movement.",
    max = 5,
    min = 0.01,
    step = 0.01,
    decimalPlaces = 2,
    defaultSetting = defaultConfig.noiseAmplitude,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "noiseAmplitude",
        table = config
    }
}

perlinNoiseTweaks:createSlider{
    label = "Levitation Noise Amplitude Multiplier",
    description = "Multiplier for making the noise motion bigger when levitating. 100 means the same as deafult value, 50 means 50% of default value etc.",
    max = 400,
    min = 50,
    step = 1,
    defaultSetting = defaultConfig.flyingNoiseAmplitudeMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingNoiseAmplitudeMultiplier",
        table = config
    }
}

perlinNoiseTweaks:createSlider{
    label = "Swimming Noise Amplitude Multiplier",
    description = "Multiplier for making the noise motion bigger when swimming. 100 means the same as deafult value, 50 means 50% of default value etc.",
    max = 400,
    min = 50,
    step = 1,
    defaultSetting = defaultConfig.swimmingNoiseAmplitudeMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingNoiseAmplitudeMultiplier",
        table = config
    }
}
------------------------------------------------------------------------------------------------------------------------------- Body inertia settings
local page = template:createSideBarPage({
    label = "Body inertia settings",
    description = "Body inertia controls how fast the arms follow the camera motion.",
    showReset = true
})

local bodyInertiaSettings = page:createCategory ("Body inertia settings")

bodyInertiaSettings:createSlider{
    label = "Body inertia speed",
    description = "Lower number means arms follow slower, high follows faster.",
    max = 1000,
    min = 50,
    step = 1,
    defaultSetting = defaultConfig.armSpeed,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "armSpeed",
        table = config
    }
}

bodyInertiaSettings:createSlider{
    label = "Arm max angle.",
    description = "When moving left or right, the arms rotates a bit to signal the movement. This dictates the maximum the arms may rotate.",
    max = 15,
    min = 0.01,
    step = 0.01,
    decimalPlaces = 2,
    defaultSetting = defaultConfig.armMaxAngle,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "armMaxAngle",
        table = config
    }
}

bodyInertiaSettings:createSlider{
    label = "Arm roll smoothing",
    description = "This dictates how fast the arms rotate, both outwards when turning, and back when standing still. Higher means a snappier movement, and lower means slower movement.",
    max = 20,
    min = 0.01,
    step = 0.01,
    decimalPlaces = 2,
    defaultSetting = defaultConfig.armRollingSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "armRollingSmoothing",
        table = config
    }
}

bodyInertiaSettings:createSlider{
    label = "1st person camera smoothing",
    description = "For the body inertia to look smooth, the camera also needs to be smoothed. This dictates how smooth the camera should be. A low value means a slower movement, a high value is more direct.",
    max = 750,
    min = 400,
    step = 1,

    defaultSetting = defaultConfig.firstPersonCameraSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "firstPersonCameraSmoothing",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- View rolling settings
local viewRollingDetailedTweak = template:createSideBarPage({
    label = "View rolling settings",
    description = "View rolling is when the camera tilts in the direction you are strafing. Here you can tweak detailed settings for this feature.",
    showReset = true
})

viewRollingDetailedTweak:createSlider{
    label = "View rolling max angle",
    description = "The maximum the camera is allowed to roll to left and right. This option will do nothing if view rolling is not enabled.",
    max = 2,
    min = 0.1,
    step = 0.1,
    decimalPlaces = 1,
    defaultSetting = defaultConfig.viewRollingMaxAngle,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "viewRollingMaxAngle",
        table = config
    }
}

viewRollingDetailedTweak:createSlider{
    label = "View rolling smoothing",
    description = "High number = more direct. Low number = more smooth. How smooth the motion of rolling is. This option will do nothing if view rolling is not enabled.",
    max = 25,
    min = 1,
    defaultSetting = defaultConfig.viewRollingSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "viewRollingSmoothing",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Corner peeking settings
local cornerPeekingDetailSettings = template:createSideBarPage({
    label = "Corner peeking settings",
    description = "Corner peeking allows you to look around corners in both first and third person.",
    showReset = true
})

cornerPeekingDetailSettings:createSlider{
    label = "Peek smoothing",
    description = "High number = more direct. Low number = more smooth. How smooth the motion is when transitioning to the peek camera location. This option will do nothing if view rolling is not enabled.",
    max = 15,
    min = 1,
    defaultSetting = defaultConfig.peekSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekSmoothing",
        table = config
    }
}

cornerPeekingDetailSettings:createSlider{
    label = "Peek distance",
    description = "How far the camera is moved when pressing the peek button.",
    max = 75,
    min = 20,
    defaultSetting = defaultConfig.peekLength,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekLength",
        table = config
    }
}

cornerPeekingDetailSettings:createSlider{
    label = "Peek rotation",
    description = "The angle the camera tilts to when peeking.",
    max = 15,
    min = 0,
    defaultSetting = defaultConfig.peekRotation,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekRotation",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Jumping and landing settings
local jumpingPage = template:createSideBarPage({
    label = "Jumping Settings",
    description = "These are detailed tweak for the jump mechanic. I tried to make these as easy as possible to understand, but they are a bit more technical because of the nature of how the jumping pitch rotation feature works. Feel free to experiement and see what suits you.\n\nThe default balancing here is meant to give a descent amount of feedback even at low acrobatics levels, and still not go overboard when using something like scroll of Icarian flight, while at the same time give some kind of progression in feel up through different jump levels.",
    showReset = true
})

jumpingPage:createSlider{
    label = "Jump velocity clamp value",
    description = "This value dictates at what jumping speed (in units per second) that the jumping rotation will reach 100% of max. Note that this value only has to do with the rotation effect. It will in no way affect the actual jump speed in the game.\n\nA higher value will make the jumping effect map to a larger range of values. In more easy to understand terms it means: Low value, more noticeable effect at low values. High value, bigger difference between low value and high, but low values very much less noticable.",
    max = 0.5,
    min = 0.1,
    decimalPlaces = 2,
    step = 0.01,
    defaultSetting = defaultConfig.jumpVelocityMax,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "jumpVelocityMax",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Jump max angle",
    description = "Dictates the maximum amount the camera pitches downwards when jumping. This gradually resets to 0 based on the players speed (jump velocity clamp value) when it decreases to the apex of the jump.",
    max = 10,
    min = 4,
    decimalPlaces = 1,
    step = 0.1,
    defaultSetting = defaultConfig.jumpMaxAngle,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "jumpMaxAngle",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Landing max angle",
    description = "Dictates the maximum amount the camera pitches downwards when landing. The faster one falls (up to Jump velocity clamp value) will trigger a higher value with this as a max when landing.",
    max = 10,
    min = 4,
    decimalPlaces = 1,
    step = 0.1,
    defaultSetting = defaultConfig.landingMaxAngle,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "landingMaxAngle",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Jump angle smoothing",
    description = "Dictates how smooth the pitch rotation is when jumping. High value = more direct, low value = slower movement.",
    max = 20,
    min = 1,
    defaultSetting = defaultConfig.jumpAngleSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "jumpAngleSmoothing",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Landing, ease away smoothing",
    description = "This dictates how fast the downward movement will be when landing.",
    max = 25,
    min = 1,
    defaultSetting = defaultConfig.landingEaseAwaySmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "landingEaseAwaySmoothing",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Landing, ease back smoothing",
    description = "This dictates how fast the recovery to normal pitch rotation (read: 0 pitch rotation) movement will be when landing.",
    max = 25,
    min = 1,
    defaultSetting = defaultConfig.landingEaseBackSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "landingEaseBackSmoothing",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Smooth stealth camera change

local sneakPage = template:createSideBarPage({
    label = "Sneak transition settings",
    description = "These settings details how the smoothing works for sneak camera transitions. Toggling OFF the sneak camera setting will reset ",
    showReset = true
})

sneakPage:createSlider{
    label = "Sneak camera height",
    description = "This dictates how low the camera will go. 0 means don't move the camera at all, 100 means move the camera all the way down to the feet.\n\nThis value mimics how the GMST for lower camera height while sneaking works, but it does not affect it at all (as in, the GMST should be saved down and reused when disabling the setting).",
    max = 100,
    min = 10,
    defaultSetting = defaultConfig.sneakCameraHeight,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakCameraHeight",
        table = config
    }
}

sneakPage:createSlider{
    label = "3rd person sneak camera height multiplier",
    description = "This dictates how far relative to the normal camera height, the camera will move when in 3rd person. 100 means it will follow to a 100%, 0 means it will act as vanilla (not move at all).",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.sneak3rdPersonHeightMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneak3rdPersonHeightMultiplier",
        table = config
    }
}

sneakPage:createSlider{
    label = "Sneak camera smoothing",
    description = "This dictates how quickly the camera moves to and from sneak position.",
    max = 25,
    min = 1,
    defaultSetting = defaultConfig.sneakCameraSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakCameraSmoothing",
        table = config
    }
}


