local defaultConfig = {
    modEnabled = true,
    bobCustomizableFrequencyMultiplier = 90,
    sneakFrequencyMultiplier = 75,
    bobCustomizableAmplitudeMultiplier = 70,
    smoothValue = 10,
    minimumLookAtDistance = 250,
    armAmplitudeMultiplier = 50,
    thirdPersonBobEnabled = true,
    thirdPersonBobMultiplier = 60,
    syncFootsteps = true,
    walkingCustomizableAmplitudeMultiplierX = 80,
    walkingCustomizableAmplitudeMultiplierY = 100,
    runningCustomizableAmplitudeMultiplierX = 80,
    runningCustomizableAmplitudeMultiplierY = 100,
    sneakingCustomizableAmplitudeMultiplierX = 90,
    sneakingCustomizableAmplitudeMultiplierY = 110,
}

local configPath = "simpleConfigurableHeadBobbing"

local mwseConfig = {
    loaded = mwse.loadConfig(configPath, defaultConfig),
    default = defaultConfig
}

return mwseConfig