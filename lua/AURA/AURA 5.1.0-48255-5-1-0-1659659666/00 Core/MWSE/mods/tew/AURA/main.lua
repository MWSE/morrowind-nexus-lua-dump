-- Make sure we have all i18n data beforehand
dofile("tew.AURA.i18n.init")

local modversion = require("tew.AURA.version")
local version = modversion.version
local soundBuilder = require("tew\\AURA\\soundBuilder")
local config = require("tew.AURA.config")
local messages = require(config.language).messages

-- Because MW sound engine is the worst --
local function warning(e)
    if not e.newlyCreated then
        return
    end
    tes3.messageBox(string.format("[AURA]: %s", messages.audioWarning))
end

local function init()

    mwse.log(string.format("[AURA] %s %s %s", messages.version, version, messages.initialised))

    local moduleAmbientOutdoor = config.moduleAmbientOutdoor
    local moduleAmbientInterior = config.moduleAmbientInterior
    local moduleInteriorWeather = config.moduleInteriorWeather
    local moduleServiceVoices = config.moduleServiceVoices
    local moduleContainers = config.moduleContainers
    local moduleAmbientPopulated = config.moduleAmbientPopulated
    local moduleUI = config.moduleUI
    local moduleMisc = config.moduleMisc
    local modulePC = config.modulePC

    event.register("uiActivated", warning, { filter = "MenuAudio" })

    mwse.log(string.format("\n\n[AURA %s] %s", version, messages.buildingSoundsStarted))
    soundBuilder.build()
    mwse.log(string.format("[AURA %s] %s\n\n", version, messages.buildingSoundsFinished))

    if moduleAmbientOutdoor then
        mwse.log(string.format("[AURA %s] %s outdoorMain.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Ambient\\Outdoor\\outdoorMain.lua")
    end

    if moduleAmbientInterior then
        mwse.log(string.format("[AURA %s] %s interiorMain.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Ambient\\Interior\\interiorMain.lua")
    end

    if moduleAmbientPopulated then
        mwse.log(string.format("[AURA %s] %s populatedMain.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Ambient\\Populated\\populatedMain.lua")
    end

    if moduleInteriorWeather then
        mwse.log(string.format("[AURA %s] %s interiorWeatherMain.lua.", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Interior Weather\\interiorWeatherMain.lua")
    end

    if moduleServiceVoices then
        mwse.log(string.format("[AURA %s] %s serviceVoicesMain.lua.", version, messages.loadingFile))

        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Service Voices\\serviceVoicesMain.lua")
    end

    if moduleMisc then
        mwse.log(string.format("[AURA %s] %s miscMain.lua", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\miscMain.lua")
    end

    if moduleUI then
        mwse.log(string.format("[AURA %s] %s UIMain.lua", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\UI\\UIMain.lua")
    end

    if moduleContainers then
        mwse.log(string.format("[AURA %s] %s containersMain.lua", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Containers\\containersMain.lua")
    end

    if modulePC then
        mwse.log(string.format("[AURA %s] %s PCMain.lua", version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\PC\\PCMain.lua")
    end

    -- Old version deleter --
    if lfs.directoryexists("Data Files\\MWSE\\mods\\AURA") then
        lfs.rmdir("Data Files\\MWSE\\mods\\AURA", true)
        mwse.log(string.format("[AURA %s] %s", version, messages.oldFolderDeleted))
    end
    if lfs.directoryexists("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\travelFee.lua") then
        os.remove("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\travelFee.lua")
        mwse.log(string.format("[AURA %s] %s: travelFee.lua.", version, messages.oldFileDeleted))
    end
end

-- Registers MCM menu --
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\AURA\\mcm.lua")
end)


event.register("initialized", init)
