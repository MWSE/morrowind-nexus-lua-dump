local metadata = toml.loadMetadata("AURA")
local version = metadata.package.version
local config = require("tew.AURA.config")
local messages = require(config.language).messages

local function init()
    local pcVitalSigns = config.pcVitalSigns
    local PCtaunts = config.PCtaunts

    if pcVitalSigns then
        mwse.log(string.format("[AURA %s] %s vitalSigns.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\PC\\vitalSigns.lua")
    end

    if PCtaunts then
        mwse.log(string.format("[AURA %s] %s taunts.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\PC\\taunts.lua")
    end

end

init()
