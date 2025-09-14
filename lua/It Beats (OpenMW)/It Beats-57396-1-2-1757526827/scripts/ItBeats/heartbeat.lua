local storage = require("openmw.storage")
local ambient = require('openmw.ambient')
local time = require("openmw_aux.time")
local self = require("openmw.self")
require("scripts.ItBeats.cells")

local sectionHeartbeat = storage.playerSection("SettingsItBeats_heartbeat")
local sectionVolume = storage.playerSection("SettingsItBeats_volume")
local sectionDebug = storage.playerSection("SettingsItBeats_debug")

local soundsFolder = "Sound/ItBeats/"
-- you can edit it!
local files = {
    ["It Beats"] = {
        [EXTERIOR] =            "1. Mountain.wav",
        [GENERIC_INTERIOR] =    "2. Interiors.wav",
        [DAGOTH_UR] =           "3. Dagoth Ur.wav",
        [FACILITY_CAVERN] =     "4. Facility Cavern.wav",
        [AKULAKHANS_CHAMBER] =  "5. Akulakhans Chamber.wav",
    },
    ["Heartthrum HoF"] = {
        [EXTERIOR] =            "Heartthrum - Heart of Lorkhan.wav",
        [GENERIC_INTERIOR] =    "Heartthrum - Heart of Lorkhan.wav",
        [DAGOTH_UR] =           "Heartthrum - Heart of Lorkhan.wav",
        [FACILITY_CAVERN] =     "Heartthrum - Heart of Lorkhan.wav",
        [AKULAKHANS_CHAMBER] =  "Heartthrum - Heart of Lorkhan.wav",
    },
    ["Heartthrum HoF Vanilla"] = {
        [EXTERIOR] =            "Heartthrum - Heart of Lorkhan (vanilla.wav",
        [GENERIC_INTERIOR] =    "Heartthrum - Heart of Lorkhan (vanilla.wav",
        [DAGOTH_UR] =           "Heartthrum - Heart of Lorkhan (vanilla.wav",
        [FACILITY_CAVERN] =     "Heartthrum - Heart of Lorkhan (vanilla.wav",
        [AKULAKHANS_CHAMBER] =  "Heartthrum - Heart of Lorkhan (vanilla.wav",
    }
}

local function getVolume(cellType)
    -- defined in the function so it would actually update with settings changing
    local volumeByCellType = {
        [EXTERIOR] =            sectionVolume:get("exteriorVolume"),
        [GENERIC_INTERIOR] =    sectionVolume:get("genericInteriorVolume"),
        [DAGOTH_UR] =           sectionVolume:get("dagothUrVolume"),
        [FACILITY_CAVERN] =     sectionVolume:get("facilityCavernVolume"),
        [AKULAKHANS_CHAMBER] =  sectionVolume:get("akulakhansChamberVolume"),
    }
    local masterVolume = sectionVolume:get("masterVolume")
    return volumeByCellType[cellType] / 50 * masterVolume / 20
end

local function doHeartbeat()
    local cellType = GetRMCellType(self.cell)
    local volume = getVolume(cellType)
    local sfxGroup = sectionHeartbeat:get("sfx")
    local filePath = files[sfxGroup][cellType]

    ambient.playSoundFile(
        soundsFolder .. filePath, {
            volume = volume,
            pitch = 1,
        })
end

local function startHeartbeat()
    -- more like "try starting heartbeat"
    if (PlayerState.inRM or sectionDebug:get("ignoreRegionRequirement"))
        and (not PlayerState.heartIsDead or sectionDebug:get("ignoreQuestRequirement"))
    then
        local offset = math.random(0, sectionHeartbeat:get("maxOffset") * 100) / 100
        local callback = time.registerTimerCallback("Heartbeat", doHeartbeat)
        time.newSimulationTimer(offset, callback)
    end
end

time.runRepeatedly(
    startHeartbeat,
    sectionHeartbeat:get("tempo"),
    { type = time.SimulationTime })
