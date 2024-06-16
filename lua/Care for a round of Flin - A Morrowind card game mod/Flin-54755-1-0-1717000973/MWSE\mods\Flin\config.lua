---@class FlinConfig
---@field mod string
---@field id string
---@field version number
---@field author string
---@field logLevel string
---@field openkeybind table
---@field enableHints boolean
---@field enableMessages boolean
---@field enableTrickSounds boolean
local defaultConfig = {
    mod = "Flin",
    id = "FLI",
    version = 1.0,
    author = "rfuzzo",
    -- configs
    logLevel = "INFO",
    -- keybinds
    openkeybind = { keyCode = tes3.scanCode["o"] },
    enableHints = false,
    enableMessages = true,
    enableTrickSounds = false,
}

---@return FlinConfig
return mwse.loadConfig("Flin", defaultConfig)
