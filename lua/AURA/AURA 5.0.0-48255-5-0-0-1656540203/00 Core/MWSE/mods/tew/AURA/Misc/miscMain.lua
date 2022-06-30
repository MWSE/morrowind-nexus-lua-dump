local modversion = require("tew.AURA.version")
local version = modversion.version
local config=require("tew.AURA.config")

local function init()
    local moduleAmbientOutdoor = config.moduleAmbientOutdoor
    local playSplash = config.playSplash
    local playYurtFlap = config.playYurtFlap
    local rainSounds = config.rainSounds

    if playSplash and not moduleAmbientOutdoor then
        print("[AURA "..version.."] Loading file: waterSplash.lua")
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\waterSplash.lua")
    end

    if playSplash and moduleAmbientOutdoor then
        print("[AURA "..version.."] OA module and Misc (Splash) option enabled. OA splash logic takes precedence.")
    end

    if playYurtFlap then
        print("[AURA "..version.."] Loading file: yurtFlap.lua")
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\yurtFlap.lua")
    end

    if rainSounds then
        print("[AURA "..version.."] Loading file: rainSounds.lua")
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\rainSounds.lua")
    end
end


print("[AURA "..version.."] Miscellaneous module initialised.")
init()