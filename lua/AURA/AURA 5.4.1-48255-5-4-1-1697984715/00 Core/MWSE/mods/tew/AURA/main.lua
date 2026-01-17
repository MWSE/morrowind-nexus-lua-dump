-- Make sure we have all i18n data beforehand
dofile("tew.AURA.i18n.init")

local config = require("tew.AURA.config")
local messages = require(config.language).messages
local metadata = toml.loadMetadata("AURA")

-- Because MW sound engine is the worst --
local function warning(e)
    if not e.newlyCreated then
        return
    end
    tes3.messageBox(string.format("[%s]: %s", metadata.package.name, messages.audioWarning))
end

local function init()

    local version, modName

    local util = require("tew.AURA.util")
    if not (metadata) then
		util.metadataMissing()
	else
        version = metadata.package.version
        modName = metadata.package.name
    end

    local soundBuilder = require("tew.AURA.soundBuilder")

    mwse.log(string.format("[%s] %s %s %s", modName, messages.version, version, messages.initialised))

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

    mwse.log(string.format("[%s %s] %s", modName, version, messages.buildingSoundsStarted))
    soundBuilder.build()
    mwse.log(string.format("[%s %s] %s", modName, version, messages.buildingSoundsFinished))

    mwse.log(string.format("[%s %s] %s volumeSave.lua.", modName, version, messages.loadingFile))
    dofile("Data Files\\MWSE\\mods\\tew\\AURA\\volumeSave.lua")

    if moduleAmbientOutdoor then
        mwse.log(string.format("[%s %s] %s outdoorMain.lua.", modName, version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Ambient\\Outdoor\\outdoorMain.lua")
    end

    if moduleAmbientInterior then
        mwse.log(string.format("[%s %s] %s interiorMain.lua.", modName, version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Ambient\\Interior\\interiorMain.lua")
    end

    if moduleAmbientPopulated then
        mwse.log(string.format("[%s %s] %s populatedMain.lua.", modName, version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Ambient\\Populated\\populatedMain.lua")
    end

    if moduleInteriorWeather then
        mwse.log(string.format("[%s %s] %s interiorWeatherMain.lua.", modName, version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Interior Weather\\interiorWeatherMain.lua")
    end

    if moduleServiceVoices then
        mwse.log(string.format("[%s %s] %s serviceVoicesMain.lua.", modName, version, messages.loadingFile))

        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Service Voices\\serviceVoicesMain.lua")
    end

    if moduleMisc then
        mwse.log(string.format("[%s %s] %s miscMain.lua", modName, version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\miscMain.lua")
    end

    if moduleUI then
        mwse.log(string.format("[%s %s] %s UIMain.lua", modName, version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\UI\\UIMain.lua")
    end

    if moduleContainers then
        mwse.log(string.format("[%s %s] %s containersMain.lua", modName, version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\Containers\\containersMain.lua")
    end

    if modulePC then
        mwse.log(string.format("[%s %s] %s PCMain.lua", modName, version, messages.loadingFile))
        dofile("Data Files\\MWSE\\mods\\tew\\AURA\\PC\\PCMain.lua")
    end

    -- Old version deleter --
    if lfs.directoryexists("Data Files\\MWSE\\mods\\AURA") then
        lfs.rmdir("Data Files\\MWSE\\mods\\AURA", true)
        mwse.log(string.format("[%s %s] %s", modName, version, messages.oldFolderDeleted))
    end
    if lfs.directoryexists("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\travelFee.lua") then
        os.remove("Data Files\\MWSE\\mods\\tew\\AURA\\Misc\\travelFee.lua")
        mwse.log(string.format("[%s %s] %s: travelFee.lua.", modName, version, messages.oldFileDeleted))
    end
end

-- Registers MCM menu --
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\AURA\\mcm.lua")
end)


event.register("initialized", init)
