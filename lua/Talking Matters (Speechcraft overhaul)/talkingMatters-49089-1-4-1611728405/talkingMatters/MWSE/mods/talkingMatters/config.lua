local defaultConfig = {

	modEnabled = true,
    advanceTime = true,
	advanceTime_minutesxtopic = 3,
	advanceTime_maxtime = 2,
	speechcraftLeveling = true,
	classLearning = false,
	dispositionIncrease = true,
	limitedTopics = true,
	minimumTopics = 2,
	repetition = true,
	repetitionReset = 1,
	persuasionLimit = true,
	talkKey = {
		keyCode = tes3.scanCode.y,
		isShiftDown = false,
		isAltDown = false,
		isControlDown = false,
	},
	blackList = {}
}

local mwseConfig = mwse.loadConfig("Talking Matters", defaultConfig)

return mwseConfig;
