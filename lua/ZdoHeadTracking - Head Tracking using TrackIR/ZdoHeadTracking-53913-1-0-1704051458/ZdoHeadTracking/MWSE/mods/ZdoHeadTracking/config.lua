local defaultConfig = {
	enable = true,
	debug = false,
	version = "v1.0",

	file = "D:/Games/morrowind_headtracking.txt",

	pitch = -1,
	yaw = 1,
	roll = 1,
	x = 0,
	y = 0,
	z = 0,
	maxHeadOffset = 24,

	stepLength = 180,
    stepHeight = 3,
    maxRoll = 0.2
}

local config = mwse.loadConfig("ZdoHeadTracking", defaultConfig)
return config