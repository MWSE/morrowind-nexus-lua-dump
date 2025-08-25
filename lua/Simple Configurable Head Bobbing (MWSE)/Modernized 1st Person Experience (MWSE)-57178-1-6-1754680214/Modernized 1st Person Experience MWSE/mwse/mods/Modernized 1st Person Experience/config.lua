--[[
	Mod: Modernized 1st Person Experience
	Author: rhjelte
	Version: 1.6
]]--

local defaultConfig = {
    modEnabled = true,
    bobCustomizableFrequencyMultiplier = 90,
    sneakFrequencyMultiplier = 75,
    bobCustomizableAmplitudeMultiplier = 70,
    smoothValue = 10,
    minimumLookAtDistance = 250,
    armAmplitudeMultiplier = 60,
    thirdPersonBobEnabled = true,
    thirdPersonBobMultiplier = 60,
    syncFootsteps = true,
    viewRollingEnabled = true,
    viewRollingMaxAngle = 0.5,
    viewRollingSmoothing = 10,
    walkingCustomizableAmplitudeMultiplierX = 80,
    walkingCustomizableAmplitudeMultiplierY = 100,
    runningCustomizableAmplitudeMultiplierX = 80,
    runningCustomizableAmplitudeMultiplierY = 100,
    sneakingCustomizableAmplitudeMultiplierX = 90,
    sneakingCustomizableAmplitudeMultiplierY = 110,
    flyingCustomizableAmplitudeMultiplierX = 200,
    flyingCustomizableAmplitudeMultiplierY = 330,
    swimmingCustomizableAmplitudeMultiplierX = 140,
    swimmingCustomizableAmplitudeMultiplierY = 100,
    flyingFrequencyMultiplierMoving = 30,
    flyingFrequencyMultiplierStill = 18,
    swimmingFrequencyMultiplierMoving = 50,
    swimmingFrequencyMultiplierStill = 30,
    noiseEnabled = true,
    noiseScale = 2.3,
    noiseAmplitude = 3,
    flyingNoiseAmplitudeMultiplier = 250,
    swimmingNoiseAmplitudeMultiplier = 300,
    bodyInertiaEnabled = true,
    armSpeed = 300,
    armMaxAngle = 4,
    armRollingSmoothing = 6,
    thirdPersonCameraSmoothing = 100,
    firstPersonCameraSmoothing = 750,
    peekEnabled = true,
    peekLeftKey = { keyCode = tes3.scanCode.c, },
    peekRightKey = { keyCode = tes3.scanCode.v, },
    peekSmoothing = 5,
    peekLength = 50,
    peekRotation = 5,
    jumpEnabled = true,
    jumpVelocityMax = 0.2,
    jumpMaxAngle = 8,
    jumpAngleSmoothing = 6,
    landingEaseAwaySmoothing = 20,
    landingEaseBackSmoothing = 15,
    landingMaxAngle = 9,
    sneakCameraSmoothingEnabled = true,
    sneakCameraHeight = 30,
    sneakCameraSmoothing = 10,
    sneak3rdPersonHeightMultiplier = 60
}

local configPath = "Modernized 1st Person Experience"

local mwseConfig = {
    loaded = mwse.loadConfig(configPath, defaultConfig),
    default = defaultConfig
}

return mwseConfig