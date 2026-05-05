local defaultConfig = {
    sitKey = { keyCode = tes3.scanCode.x },
    sitAnimationGroup = 1,
    forceThirdPerson = false,
	cameraOffset = 50
}

local config = mwse.loadConfig("SitToggleConfig", defaultConfig)

return config