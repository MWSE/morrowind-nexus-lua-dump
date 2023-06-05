---@class KeyScroll.Config
local config = {}
config.configPath = "KeyScroll"
config.metadata = toml.loadFile("Data Files\\KeyScroll-metadata.toml") --[[@as MWSE.Metadata]]

config.skipMenus = {
    MenuVideo = true,
    MenuCtrls = true,
    MenuDialog = true
}

config.upKeys = {
    [tes3.scanCode.keyUp] = { blockOnTextInput = false },
    [tes3.scanCode["w"]] =  { blockOnTextInput = true },
}

config.downKeys = {
    [tes3.scanCode.keyDown] = { blockOnTextInput = false },
    [tes3.scanCode["s"]] = { blockOnTextInput = true },
}

---@class ScrollData.Config.defaultMCM
local defaultMCM = {
    enabled = true,
    logLevel = "INFO",
}

---@type ScrollData.Config.defaultMCM
config.mcm = mwse.loadConfig(config.configPath, defaultMCM)
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end

return config