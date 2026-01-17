local metadata = toml.loadMetadata("AURA")
local version = metadata.package.version
local config = require("tew.AURA.config")
local messages = require(config.language).messages

local function init()
    local playYurtFlap = config.playYurtFlap
    local rainSounds = config.rainSounds
    local windSounds = config.windSounds
    local playRainOnStatics = config.playRainOnStatics

    mwse.log(string.format("[AURA %s] %s underwater.lua.", version, messages.loadingFile))
    dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\underwater.lua")

    if playYurtFlap then
        mwse.log(string.format("[AURA %s] %s yurtFlap.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\yurtFlap.lua")
    end

    if rainSounds then
        mwse.log(string.format("[AURA %s] %s rainSounds.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\rainSounds.lua")
    end

    if windSounds then
        mwse.log(string.format("[AURA %s] %s windSounds.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\windSounds.lua")
    end

    if playRainOnStatics then
        mwse.log(string.format("[AURA %s] %s rainOnStatics.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\rainOnStatics.lua")
    end
end

init()
