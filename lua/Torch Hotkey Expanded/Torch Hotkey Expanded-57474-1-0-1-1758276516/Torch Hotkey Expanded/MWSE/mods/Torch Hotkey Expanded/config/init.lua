local fileName = "Torch Hotkey Expanded"

---@class TorchHotkeyExpanded.config
---@field version string A [semantic version](https://semver.org/).
---@field default TorchHotkeyExpanded.config Access to the default config can be useful in the MCM.
---@field fileName string
local default = {
	logLevel = mwse.logLevel.info,
	--- @type mwseKeyCombo
	hotkey = {
		keyCode = tes3.scanCode.c
	}
}

local config = mwse.loadConfig(fileName, default)
config.version = "1.0.1"
config.default = default
config.fileName = fileName

return config
