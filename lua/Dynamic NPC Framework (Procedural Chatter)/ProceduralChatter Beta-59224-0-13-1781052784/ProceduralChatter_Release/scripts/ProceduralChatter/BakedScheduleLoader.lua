-- BakedScheduleLoader.lua
-- Runtime loader for baked schedule JSON files under scripts/ProceduralChatter/data/ScheduleData/BakedSchedules/.
-- Merges all *.json files with last-writer-wins at the top-level NPC record ID.

local JsonMergeLoader = require("scripts.ProceduralChatter.JsonMergeLoader")

local BakedScheduleLoader = {}

local PREFIX = "scripts/proceduralchatter/data/scheduledata/bakedschedules/"

local loaded = false
local ScheduleData = {}

local function countEntries(map)
    local count = 0
    for _ in pairs(map or {}) do count = count + 1 end
    return count
end

function BakedScheduleLoader.ensureLoaded()
    if loaded then return end
    loaded = true

    local count = JsonMergeLoader.scan(PREFIX, function(data, path)
        if type(data) == "table" then
            JsonMergeLoader.mapMerge(ScheduleData, data)
        else
            print(string.format("[BakedScheduleLoader] WARNING: non-table root in '%s', skipping", path))
        end
    end)

    print(string.format("[BakedScheduleLoader] Scan complete: %d json file(s), %d NPC entries", count, countEntries(ScheduleData)))
end

function BakedScheduleLoader.getData()
    BakedScheduleLoader.ensureLoaded()
    return ScheduleData
end

function BakedScheduleLoader.invalidate()
    loaded = false
    ScheduleData = {}
    print("[BakedScheduleLoader] Cache invalidated; will reload on next access")
end

return BakedScheduleLoader
