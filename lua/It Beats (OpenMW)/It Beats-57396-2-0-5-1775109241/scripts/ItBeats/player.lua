local core = require("openmw.core")
local ambient = require("openmw.ambient")
local self = require("openmw.self")
local storage = require("openmw.storage")

require("scripts.ItBeats.utils.consts")
require("scripts.ItBeats.utils.cellPlayer")

local sectionHeartbeat = storage.globalSection("SettingsItBeats_heartbeat")

local function onQuestUpdate(questId, stage)
    if questId == HeartQuest.id and stage >= HeartQuest.stage then
        core.sendGlobalEvent("ItBeats_HeartIsDead")
    end
end

local function playSFX()
    local cellType = GetRMCellType(self.cell)
    if not cellType then return end

    local volume = GetVolumeByCellType(cellType)
    local sfxGroup = sectionHeartbeat:get("sfx")
    local filePath = Files[sfxGroup][cellType]

    ambient.playSoundFile(
        filePath,
        { volume = volume }
    )

    -- print(
    --     "Current cell: " .. self.cell.id ..
    --     "\nCell type: " .. cellType ..
    --     "\nPlaying file: " .. filePath ..
    --     "\nVolume: " .. volume
    -- )
end

return {
    engineHandlers = {
        onQuestUpdate = onQuestUpdate,
    },
    eventHandlers = {
        ItBeats_PlaySFX = playSFX,
    }
}
