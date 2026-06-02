local world = require("openmw.world")
local types = require("openmw.types")
local vfs = require("openmw.vfs")
local util = require("openmw.util")
local markup = require("openmw.markup")

-- ============================================================================
-- Data Loading
-- ============================================================================

local climates = {}
local regions = {}
local meshMap = {}

local forcedSeason = 'none'

local function loadData()
    if vfs.fileExists("scripts/seasonalSwitcher/data/climates.yaml") then
        local data = vfs.open("scripts/seasonalSwitcher/data/climates.yaml"):read("*all")
        climates = markup.decodeYaml(data)
    end
    if vfs.fileExists("scripts/seasonalSwitcher/data/regions.yaml") then
        local data = vfs.open("scripts/seasonalSwitcher/data/regions.yaml"):read("*all")
        regions = markup.decodeYaml(data)
    end
    if vfs.fileExists("scripts/seasonalSwitcher/data/foliage_replacements.yaml") then
         local data = vfs.open("scripts/seasonalSwitcher/data/foliage_replacements.yaml"):read("*all")
         local parsed = markup.decodeYaml(data)
         if parsed and parsed.seasonal_mesh_replacements then
             for k, v in pairs(parsed.seasonal_mesh_replacements) do
                 meshMap[k:lower()] = v
             end
         end
    end
end
loadData()

-- ============================================================================
-- Calendar Helpers
-- ============================================================================

local MONTH_DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function getDayOfYear(month, day)
    local doy = 0
    for i = 1, month - 1 do doy = doy + MONTH_DAYS[i] end
    return doy + day
end

-- ============================================================================
-- Season Resolution (supports old month-map and new schedule formats)
-- ============================================================================

local function getSeasonFromSchedule(climateData, month, day)
    -- month is 1-indexed (1 = Morning Star)
    if not climateData.seasons or #climateData.seasons == 0 then
        return "summer"
    end

    local seasons = climateData.seasons
    local n = #seasons
    local currentDoy = getDayOfYear(month, day)

    for i, season in ipairs(seasons) do
        local startDoy = getDayOfYear(season.startMonth, season.startDay)
        local nextIdx = (i % n) + 1
        local nextSeason = seasons[nextIdx]
        local endDoy = getDayOfYear(nextSeason.startMonth, nextSeason.startDay) - 1

        if endDoy < startDoy then
            -- Season wraps around the year end (e.g. winter: Dec -> Feb)
            if currentDoy >= startDoy or currentDoy <= endDoy then
                return season.name
            end
        else
            if currentDoy >= startDoy and currentDoy <= endDoy then
                return season.name
            end
        end
    end

    -- Fallback: return the last defined season
    return seasons[n].name
end

local function getClimateForRegion(regionName)
    if regionName and regions[regionName] then
        return regions[regionName]
    end
    return "temperate"
end

local function getSeasonForMonth(climate, month)
    if forcedSeason ~= 'none' then
        return forcedSeason
    end

    local climateData = climates[climate]
    if not climateData then
        return "summer"
    end

    -- New format: climate has a 'seasons' array
    if climateData.seasons then
        -- month from mwscript is 0-indexed (0 = Morning Star)
        local oneBasedMonth = month + 1
        -- Use mid-month for mesh-swap granularity (mesh swaps are month-driven)
        return getSeasonFromSchedule(climateData, oneBasedMonth, 15)
    end

    -- Old format: direct month mapping (0-indexed keys from legacy climates.yaml)
    if climateData[month] then
        return climateData[month]
    end

    -- YAML parsers sometimes return string keys for numbers
    if climateData[tostring(month)] then
        return climateData[tostring(month)]
    end

    return "summer"
end

-- ============================================================================
-- Mesh Replacement Logic
-- ============================================================================

local currentMonth = -1
local swapQueued = false
local overrideRecords = {}
local replacedObjectSet = {}
local objectDeleteQueue = {}

local function replaceObject(object, newModel)
    if replacedObjectSet[object] then return end
    if not newModel then return end

    local oldRecordId = object.recordId
    local oldRecord = types.Activator.records[oldRecordId]
    local recordType = types.Activator
    if not oldRecord then
        oldRecord = types.Static.records[oldRecordId]
        recordType = types.Static
    end
    if not oldRecord then return end

    -- types.Static.createRecordDraft was added in 0.51; fall back to Activator on 0.50
    if not recordType.createRecordDraft then
        recordType = types.Activator
    end

    if not overrideRecords[newModel] then overrideRecords[newModel] = {} end
    local moduleRecords = overrideRecords[newModel]

    if not moduleRecords[oldRecordId] then
        local newRecordParams = { model = newModel }
        if oldRecord.name then newRecordParams.name = oldRecord.name end
        local draft = recordType.createRecordDraft(newRecordParams)
        moduleRecords[oldRecordId] = world.createRecord(draft).id
    end

    local targetRecordId = moduleRecords[oldRecordId]
    local replacement = world.createObject(targetRecordId)
    replacement:setScale(object.scale)
    replacement:teleport(object.cell.name, object.position, object.rotation)

    objectDeleteQueue[#objectDeleteQueue + 1] = { delay=3, obj=object, remove=false }
    replacedObjectSet[object] = replacement
end

local function processSeasonChange()
    -- Build a set of original objects being restored so we can clear their
    -- pending disable entries from the queue in one pass (O(n) instead of O(n²)).
    local restoreSet = {}
    for origObj, _ in pairs(replacedObjectSet) do
        restoreSet[origObj] = true
    end
    for i = #objectDeleteQueue, 1, -1 do
        local q = objectDeleteQueue[i]
        if q and not q.remove and restoreSet[q.obj] then
            table.remove(objectDeleteQueue, i)
        end
    end

    for origObj, repObj in pairs(replacedObjectSet) do
        if repObj and repObj:isValid() then
            objectDeleteQueue[#objectDeleteQueue + 1] = { delay=3, obj=repObj, remove=true }
        end
        if origObj and origObj:isValid() then
            pcall(function() origObj.enabled = true end)
        end
    end
    replacedObjectSet = {}

    for _, cell in ipairs(world.cells) do
        if cell.isExterior then
            local region = cell.region
            local climate = getClimateForRegion(region)
            local season = getSeasonForMonth(climate, currentMonth)

            for _, obj in ipairs(cell:getAll()) do
                if obj.type == types.Static or obj.type == types.Activator then
                    local model = obj.type.records[obj.recordId].model
                    if model then
                        local searchModel = model:gsub("^[/\\]+", ""):lower()
                        if not searchModel:match("^meshes/") then searchModel = "meshes/" .. searchModel end
                        local baseName = searchModel:match("([^/\\]+)$")
                        if baseName and meshMap[baseName] and meshMap[baseName][season] then
                            local newModelName = meshMap[baseName][season]
                            local escapedBaseName = baseName:gsub("%.", "%%.")
                            local newSubPath = searchModel:gsub(escapedBaseName, newModelName)
                            replaceObject(obj, newSubPath)
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- Event / Engine Handlers
-- ============================================================================

return {
    eventHandlers = {
        SeasonalSwitcher_SetForcedSeason = function(season)
            if season ~= forcedSeason then
                forcedSeason = season
                processSeasonChange()
            end
        end,
        SeasonalSwitcher_ExecuteQueuedSwap = function()
            if swapQueued then
                processSeasonChange()
                swapQueued = false
            end
        end
    },
    engineHandlers = {
        onUpdate = function(dt)
            if world.players[1] then
                local rv, monthVars = pcall(world.mwscript.getGlobalVariables, world.players[1])
                if rv and monthVars and monthVars['month'] then
                    local month = monthVars['month']
                    if month ~= currentMonth then
                        currentMonth = month
                        swapQueued = true
                    end
                end
            end

            for i = #objectDeleteQueue, 1, -1 do
                local q = objectDeleteQueue[i]
                if q.delay > 0 then
                    q.delay = q.delay - 1
                else
                    if q.obj and q.obj:isValid() then
                        local ok, err = pcall(function()
                            if q.remove then
                                q.obj:remove()
                            else
                                q.obj.enabled = false
                            end
                        end)
                    end
                    table.remove(objectDeleteQueue, i)
                end
            end
        end,
        onObjectActive = function(object)
            if currentMonth == -1 and forcedSeason == 'none' then return end
            if object.type ~= types.Static and object.type ~= types.Activator then return end
            if not object.cell.isExterior then return end
            if replacedObjectSet[object] then return end

            local region = object.cell.region
            local climate = getClimateForRegion(region)
            local season = getSeasonForMonth(climate, currentMonth)

            local model = object.type.records[object.recordId].model
            if not model then return end

            local searchModel = model:gsub("^[/\\]+", ""):lower()
            if not searchModel:match("^meshes/") then searchModel = "meshes/" .. searchModel end
            local baseName = searchModel:match("([^/\\]+)$")

            if baseName and meshMap[baseName] and meshMap[baseName][season] then
                local newModelName = meshMap[baseName][season]
                local escapedBaseName = baseName:gsub("%.", "%%.")
                local newSubPath = searchModel:gsub(escapedBaseName, newModelName)
                replaceObject(object, newSubPath)
            end
        end,
        onSave = function()
            return {
                overrideRecords = overrideRecords,
                objectDeleteQueue = objectDeleteQueue,
                replacedObjectSet = replacedObjectSet
            }
        end,
        onLoad = function(data)
            currentMonth = -1
            if data then
                if data.overrideRecords then overrideRecords = data.overrideRecords end
                if data.objectDeleteQueue then objectDeleteQueue = data.objectDeleteQueue end
                if data.replacedObjectSet then replacedObjectSet = data.replacedObjectSet end
            end
        end
    }
}
