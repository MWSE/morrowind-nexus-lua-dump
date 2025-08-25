local fileName = "Place Stacks"

---@class placeStacks.config
---@field version string A [semantic version](https://semver.org/).
---@field default placeStacks.config Access to the default config can be useful in the MCM.
---@field fileName string
local default = {
	logLevel = mwse.logLevel.info,
	buttonEnabled = true,
	transferGold = false,
	closeMenu = false,
	filterOwned = true,
	activateEnabled = true,
	activateDelay = 0.25,
	---@type mwseKeyCombo
	keybind = {
		keyCode = tes3.scanCode.v,
	},
	placeStacksOutOfMenu = true,
	distanceMax = 250,
	-- This variable isn't configurable.
	heightMax = 128 * 1.5,
	shortTransferReport = false,
	detailedTransferReport = true,
}

local config = mwse.loadConfig(fileName, default)
config.version = "1.0.1"
config.default = default
config.fileName = fileName

return config
