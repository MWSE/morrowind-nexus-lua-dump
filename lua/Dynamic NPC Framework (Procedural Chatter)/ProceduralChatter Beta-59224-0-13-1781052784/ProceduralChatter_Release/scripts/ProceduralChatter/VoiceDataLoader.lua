-- VoiceDataLoader.lua
-- Runtime loader for voice duration JSON files under data/Dialogue/VoiceData/.
-- Deep-merges the 3-level {race: {gender: {audioId: seconds}}} map.

local JsonMergeLoader = require("scripts.ProceduralChatter.JsonMergeLoader")

local VoiceDataLoader = {}

local PREFIX = "scripts/proceduralchatter/data/dialogue/voicedata/"

local loaded = false
local VoiceData = {}

function VoiceDataLoader.ensureLoaded()
    if loaded then return end
    loaded = true

    local count = JsonMergeLoader.scan(PREFIX, function(data, path)
        JsonMergeLoader.deepMerge(VoiceData, data)
    end)

    local raceCount = 0
    for _ in pairs(VoiceData) do raceCount = raceCount + 1 end

    print(string.format("[VoiceDataLoader] Scan complete: %d json file(s), %d races", count, raceCount))
end

function VoiceDataLoader.getVoiceData()
    VoiceDataLoader.ensureLoaded()
    return VoiceData
end

return VoiceDataLoader
