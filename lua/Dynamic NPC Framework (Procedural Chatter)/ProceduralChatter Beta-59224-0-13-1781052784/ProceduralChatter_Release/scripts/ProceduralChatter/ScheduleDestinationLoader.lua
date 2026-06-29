-- ScheduleDestinationLoader.lua
-- Runtime loader for schedule destination JSON files under data/ScheduleData/ScheduleGenerationData/.
-- Deep-merges schedule generation destination metadata and classifier reference data.

local JsonMergeLoader = require("scripts.ProceduralChatter.JsonMergeLoader")

local ScheduleDestinationLoader = {}

local PREFIX = "scripts/proceduralchatter/data/scheduledata/schedulegenerationdata/"

local loaded = false
local DestinationData = {}

function ScheduleDestinationLoader.ensureLoaded()
    if loaded then return end
    loaded = true

    local count = JsonMergeLoader.scan(PREFIX, function(data, path)
        JsonMergeLoader.deepMerge(DestinationData, data)
    end)

    print(string.format("[ScheduleDestinationLoader] Scan complete: %d json file(s)", count))
end

function ScheduleDestinationLoader.getData()
    ScheduleDestinationLoader.ensureLoaded()
    return DestinationData
end

return ScheduleDestinationLoader
