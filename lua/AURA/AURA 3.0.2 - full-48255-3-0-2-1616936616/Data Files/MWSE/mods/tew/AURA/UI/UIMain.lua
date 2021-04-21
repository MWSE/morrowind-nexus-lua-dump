local modversion = require("tew\\AURA\\version")
local config = require("tew\\AURA\\config")
local version = modversion.version

local function init()
    local UITravel = config.UITravel
    local UIEating = config.UIEating
    local UISpells = config.UISpells
    local UITraining = config.UITraining
    local UIBarter = config.UIBarter

    if UITravel then
        print("[AURA "..version.."] Loading file: travel.lua")
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\UI\\travel.lua")
    end

    if UIEating then
        print("[AURA "..version.."] Loading file: eating.lua")
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\UI\\eating.lua")
    end

    if UISpells then
        print("[AURA "..version.."] Loading file: spells.lua")
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\UI\\spells.lua")
    end

    if UITraining then
        print("[AURA "..version.."] Loading file: training.lua")
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\UI\\training.lua")
    end

    if UIBarter then
        print("[AURA "..version.."] Loading file: barter.lua")
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\UI\\barter.lua")
    end

end


print("[AURA "..version.."] UI module initialised.")
init()

