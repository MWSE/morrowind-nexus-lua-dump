-- If you make edits to this file, you must delete the "Data Files\MWSE\config\SpellMemory.json file."

local config = {}

config.configPath = "SpellMemory"

config.default = {
	enabled = true,

	openCombo = {
		keyCode = tes3.scanCode.r,
		mouseButton = nil,
		mouseWheel = nil,
		isShiftDown = true,
		isAltDown = false,
		isControlDown = false,
	},

	levelOneMemoryCap = 10,
	maxMemory = 50,
	levelCurvePower = 0.65,
	minimumAttributeFactor = 0.60,

	requireTownOrCity = true,

	memorizedBonusEnabled = true,
	memorizedCastChanceBonus = 25,

	unmemorizedPenaltyEnabled = true,
	unmemorizedCastChancePenalty = 15,

	showMessages = true,
	debugLog = false,
}

config.current = mwse.loadConfig(config.configPath, config.default)

config.current.enabled = config.current.enabled
if config.current.enabled == nil then
	config.current.enabled = config.default.enabled
end

config.current.openCombo = config.current.openCombo or config.current.combo or config.default.openCombo

config.current.levelOneMemoryCap = config.current.levelOneMemoryCap or config.default.levelOneMemoryCap
config.current.maxMemory = config.current.maxMemory or config.default.maxMemory
config.current.levelCurvePower = config.current.levelCurvePower or config.default.levelCurvePower
config.current.minimumAttributeFactor = config.current.minimumAttributeFactor or config.default.minimumAttributeFactor

config.current.requireTownOrCity = config.current.requireTownOrCity
if config.current.requireTownOrCity == nil then
	config.current.requireTownOrCity = config.default.requireTownOrCity
end

config.current.memorizedBonusEnabled = config.current.memorizedBonusEnabled
if config.current.memorizedBonusEnabled == nil then
	config.current.memorizedBonusEnabled = config.default.memorizedBonusEnabled
end

config.current.memorizedCastChanceBonus = config.current.memorizedCastChanceBonus or config.default.memorizedCastChanceBonus

config.current.unmemorizedPenaltyEnabled = config.current.unmemorizedPenaltyEnabled
if config.current.unmemorizedPenaltyEnabled == nil then
	config.current.unmemorizedPenaltyEnabled = config.default.unmemorizedPenaltyEnabled
end

config.current.unmemorizedCastChancePenalty = config.current.unmemorizedCastChancePenalty or config.default.unmemorizedCastChancePenalty

config.current.showMessages = config.current.showMessages
if config.current.showMessages == nil then
	config.current.showMessages = config.default.showMessages
end

config.current.debugLog = config.current.debugLog
if config.current.debugLog == nil then
	config.current.debugLog = config.default.debugLog
end

return config