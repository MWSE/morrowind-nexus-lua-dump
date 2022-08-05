local modversion = require("tew.AURA.version")
local version = modversion.version
local config = require("tew.AURA.config")
local messages = require(config.language).messages

local function init()
    local moduleAmbientOutdoor = config.moduleAmbientOutdoor
    local playSplash = config.playSplash
    local playYurtFlap = config.playYurtFlap
    local rainSounds = config.rainSounds
    local windSounds = config.windSounds

    if playSplash and not moduleAmbientOutdoor then
        mwse.log(string.format("[AURA %s] %s waterSplash.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\waterSplash.lua")
    end

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
end

init()
