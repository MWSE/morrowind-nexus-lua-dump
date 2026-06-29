-- JSONScheduleManager.lua
-- Central data layer for the ProceduralChatter NPC Scheduling System.
-- GLOBAL script context — pure data; no Relocator or OccupancyTracker dependencies.
--
-- Loads ScheduleData.json once on first access and provides deterministic lookups
-- for the JSONScheduleModule and DynamicFallback modules.
--
-- ScheduleData.json structure:
--   {
--     "npc_record_id": {                 -- lowercase record ID key
--       "Name": "Display Name",
--       "City": "CityName",
--       "BaseExterior": "Exterior: x, y",
--       "Schedule": {
--         "Sunday": {                    -- English day names
--           "00-07": "CellName",         -- "HH-HH" time blocks
--           "18-21": "CellName",
--           "22-24": "CellName"
--         },
--         "Monday": { ... }
--       }
--     }
--   }
--
-- Day mapping: Morrowind day index (0=Sundas) -> JSON English name
-- Time blocks: "HH-HH" where start < end (normal) or start > end (wrapping midnight)
-- Exterior destinations: "Market:Exterior", "Exterior: x, y" -> NPC stays at native pos

local JSONScheduleManager = {}
local GeneratedScheduleManager = require("scripts.ProceduralChatter.schedule.GeneratedScheduleManager")
local BakedScheduleLoader = require("scripts.ProceduralChatter.BakedScheduleLoader")

-- =============================================================================
-- Day name mapping
-- Morrowind day index (0-6) -> English day name used in ScheduleData.json
-- =============================================================================

local DAY_INDEX_TO_JSON = {
    [0] = "Sunday",     -- Sundas
    [1] = "Monday",     -- Morndas
    [2] = "Tuesday",    -- Tirdas
    [3] = "Wednesday",  -- Middas
    [4] = "Thursday",   -- Turdas
    [5] = "Friday",     -- Fredas
    [6] = "Saturday",   -- Loredas
}

local function getDayName(dayIndex)
    if dayIndex == nil then return nil end
    return DAY_INDEX_TO_JSON[dayIndex % 7]
end

-- =============================================================================
-- Lazy-loaded schedule data
-- =============================================================================

local scheduleData = nil
local loaded = false

--- Load baked schedule JSON if not already loaded.
-- Called by every public function. Idempotent.
local function ensureLoaded()
    if loaded then return end
    loaded = true
    local data = BakedScheduleLoader.getData()
    if type(data) == "table" then
        scheduleData = data
        -- Count entries for diagnostics
        local count = 0
        for _ in pairs(data) do count = count + 1 end
        print(string.format("[JSONScheduleManager] Loaded baked schedules: %d NPC entries", count))
    else
        print("[JSONScheduleManager] WARNING: Failed to load baked schedules")
    end
end

local function getEntry(recordId)
    ensureLoaded()
    if not recordId then return nil end
    local key = string.lower(tostring(recordId))
    if scheduleData and scheduleData[key] then
        return scheduleData[key], "static"
    end
    local generated = GeneratedScheduleManager.getSchedule(key)
    if generated then
        return generated, "generated"
    end
    return nil, nil
end

local function forEachEntry(callback)
    ensureLoaded()
    local emitted = {}
    for recordId, entry in pairs(scheduleData or {}) do
        emitted[string.lower(recordId)] = true
        callback(string.lower(recordId), entry, "static")
    end
    for recordId, entry in pairs(GeneratedScheduleManager.getAllSchedules()) do
        local key = string.lower(recordId)
        if not emitted[key] then
            callback(key, entry, "generated")
        end
    end
end

-- =============================================================================
-- Helper: classify a destination string
-- =============================================================================

--- Returns true if the cell name string represents an exterior/market placeholder.
-- These mean "NPC stays at their native position" — not an interior to teleport to.
local function isExteriorDestination(cellName)
    if not cellName then return false end
    -- "Market:Exterior" — explicit exterior market placeholder
    if cellName:find("Market:Exterior", 1, true) then return true end
    -- "Exterior: x, y" — raw grid coordinate placeholder
    if cellName:match("^Exterior:%s*%-?%d+") then return true end
    return false
end

local function parseTimeBlock(timeBlock)
    if not timeBlock then return nil, nil end
    local startStr, endStr = tostring(timeBlock):match("^(%d+)-(%d+)$")
    if not startStr or not endStr then return nil, nil end
    return tonumber(startStr), tonumber(endStr)
end

local function normalizeDestination(cellName)
    if not cellName then return nil end
    if isExteriorDestination(cellName) then return "__exterior__" end
    return string.lower(tostring(cellName))
end

local function blockEndsAtHour(startH, endH, hour)
    if not startH or not endH or startH == endH then return false end
    local normalizedEnd = endH == 24 and 0 or endH
    return normalizedEnd == hour
end

local function canBePreviousBlockOnDayOffset(dayOffset, startH, endH, currentStart)
    if not blockEndsAtHour(startH, endH, currentStart) then return false end
    if dayOffset ~= 0 then return true end

    -- At midnight, same-day blocks ending at 00 are tonight's future blocks in
    -- the schedule table; the actual previous block is on the prior day.
    if currentStart == 0 then return false end
    return true
end

local function hasContiguousSameDestination(entry, dayIndex, startHour, cellName)
    if not entry or not entry.Schedule or startHour == nil or not cellName then return false end
    local wanted = normalizeDestination(cellName)
    if not wanted then return false end

    for _, dayOffset in ipairs({ 0, -1 }) do
        local dayName = getDayName((dayIndex or 0) + dayOffset)
        local daySchedule = dayName and entry.Schedule[dayName] or nil
        if daySchedule then
            for prevBlock, prevCellName in pairs(daySchedule) do
                local prevStart, prevEnd = parseTimeBlock(prevBlock)
                if canBePreviousBlockOnDayOffset(dayOffset, prevStart, prevEnd, startHour)
                        and normalizeDestination(prevCellName) == wanted then
                    return true
                end
            end
        end
    end

    return false
end

-- =============================================================================
-- Public API
-- =============================================================================

--- Returns true if the given NPC record ID has a JSON schedule entry.
-- @param recordId string  lowercase record ID (e.g. "tr_m2_feliwa")
-- @return bool
function JSONScheduleManager.hasSchedule(recordId)
    ensureLoaded()
    if not recordId then return false end
    return getEntry(recordId) ~= nil
end

--- Get the NPC's scheduled destination cell for a specific game time.
--
-- @param recordId string  lowercase NPC record ID (use string.lower(npc.recordId))
-- @param dayIndex number  0-6 (from TimeService.getDayIndex(); 0=Sundas)
-- @param gameHour number  0-24 fractional hour (from TimeService.getHour())
-- @return string|nil      cell name string, or nil if no schedule / gap / no entry
-- @return string|nil      "interior" or "exterior", or nil if no match
-- @return table|nil       assignment details:
--                         {
--                           timeBlock = "HH-HH",
--                           startHour = number,
--                           endHour = number,
--                           hourInt = number,
--                           isStartHour = bool,
--                         }
function JSONScheduleManager.getCurrentAssignment(recordId, dayIndex, gameHour)
    ensureLoaded()
    if not recordId then return nil, nil end

    local entry = getEntry(recordId)
    if not entry or not entry.Schedule then return nil, nil end

    local dayName = getDayName(dayIndex)
    if not dayName then return nil, nil end

    local daySchedule = entry.Schedule[dayName]
    if not daySchedule then return nil, nil end

    -- Integer hour for range comparisons
    -- Use math.floor so hour 18.9 still matches "18-21"
    local hourInt = math.floor(gameHour) % 24

    for timeBlock, cellName in pairs(daySchedule) do
        -- Parse "HH-HH" format (both parts are zero-padded or not)
        local startH, endH = parseTimeBlock(timeBlock)
        if startH and endH then

            local inBlock = false
            if startH < endH then
                -- Normal range: e.g. "09-11" covers hours 9, 10
                inBlock = (hourInt >= startH and hourInt < endH)
            elseif startH == endH then
                -- Degenerate 0-length block; skip
                inBlock = false
            else
                -- Wrapping range: e.g. "22-07" covers 22,23,0,1,2,3,4,5,6
                inBlock = (hourInt >= startH or hourInt < endH)
            end

            -- Special case: "22-24" means "22:00 to midnight" (not wrapping)
            -- endH==24 is treated as endH==0 but for a non-wrapping block
            if endH == 24 then
                inBlock = (hourInt >= startH and hourInt < 24)
            end

            if inBlock then
                local details = {
                    timeBlock = timeBlock,
                    startHour = startH,
                    endHour = endH,
                    hourInt = hourInt,
                    isContinuation = hasContiguousSameDestination(entry, dayIndex, startH, cellName),
                }
                details.isStartHour = (hourInt == startH and not details.isContinuation)
                if isExteriorDestination(cellName) then
                    return cellName, "exterior", details
                else
                    return cellName, "interior", details
                end
            end
        end
    end

    -- No time block covers the current hour (gap in schedule)
    return nil, nil, nil
end

--- Return the latest interior assignment block that ended at or before gameHour.
-- Used by exterior reconciliation to decide which door an NPC should appear from
-- when returning to their native exterior position.
-- @param recordId string
-- @param dayIndex number
-- @param gameHour number
-- @return table|nil { cellName, timeBlock, startHour, endHour, hourInt, isFreshEndHour }
function JSONScheduleManager.getLastEndedInteriorAssignment(recordId, dayIndex, gameHour)
    ensureLoaded()
    if not recordId then return nil end

    local entry = getEntry(recordId)
    if not entry or not entry.Schedule then return nil end

    local hourInt = math.floor(gameHour) % 24
    local currentAbs = 24 + hourInt
    local best = nil

    for _, dayOffset in ipairs({ -1, 0 }) do
        local dayName = getDayName((dayIndex or 0) + dayOffset)
        local daySchedule = dayName and entry.Schedule[dayName] or nil
        if daySchedule then
            local dayBase = dayOffset < 0 and 0 or 24
            for timeBlock, cellName in pairs(daySchedule) do
                local startH, endH = parseTimeBlock(timeBlock)
                if startH and endH and startH ~= endH and not isExteriorDestination(cellName) then
                    local endAbs = nil
                    if endH == 24 then
                        endAbs = dayBase + 24
                    elseif startH < endH then
                        endAbs = dayBase + endH
                    else
                        endAbs = dayBase + 24 + endH
                    end

                    if endAbs <= currentAbs
                            and (not best or endAbs > best.endAbs
                                or (endAbs == best.endAbs and dayOffset > best.dayOffset)) then
                        best = {
                            cellName = cellName,
                            timeBlock = timeBlock,
                            startHour = startH,
                            endHour = endH,
                            endAbs = endAbs,
                            dayOffset = dayOffset,
                        }
                    end
                end
            end
        end
    end

    if not best then return nil end
    return {
        cellName = best.cellName,
        timeBlock = best.timeBlock,
        startHour = best.startHour,
        endHour = best.endHour,
        hourInt = hourInt,
        isFreshEndHour = (best.endAbs == currentAbs),
    }
end

--- Get the NPC's home city from schedule data.
-- @param recordId string  lowercase record ID
-- @return string|nil      city name, or nil if not in schedule
function JSONScheduleManager.getCity(recordId)
    ensureLoaded()
    if not recordId then return nil end
    local entry = getEntry(recordId)
    return entry and entry.City or nil
end

--- Get all NPC record IDs that have schedules associated with a given city.
-- Useful for pre-allocating occupancy on cell/region entry.
-- @param cityName string  exact city name (case-insensitive match)
-- @return table           array of lowercase record IDs
function JSONScheduleManager.getNpcsByCity(cityName)
    ensureLoaded()
    if not cityName then return {} end
    local result = {}
    local lowerCity = cityName:lower()
    forEachEntry(function(recordId, entry)
        if entry.City and entry.City:lower() == lowerCity then
            result[#result + 1] = recordId
        end
    end)
    return result
end

--- Get all destination cells currently in use for a city at the given time.
-- Returns a map from cell name to list of record IDs scheduled there.
-- Used to pre-reserve occupancy slots before NPCs activate.
--
-- @param cityName string
-- @param dayIndex number
-- @param gameHour number
-- @return table  { [cellName] = { recordId1, recordId2, ... } }
function JSONScheduleManager.getOccupancyMap(cityName, dayIndex, gameHour)
    ensureLoaded()
    if not cityName then return {} end
    local map = {}
    local lowerCity = cityName:lower()
    forEachEntry(function(recordId, entry)
        if entry.City and entry.City:lower() == lowerCity then
            local cellName, cellType = JSONScheduleManager.getCurrentAssignment(recordId, dayIndex, gameHour)
            if cellName and cellType == "interior" then
                if not map[cellName] then map[cellName] = {} end
                map[cellName][#map[cellName] + 1] = recordId
            end
        end
    end)
    return map
end

--- Parse the BaseExterior field for an NPC and return a world-space position.
-- BaseExterior format: "Exterior: x, y"  where x, y are grid coordinates.
-- World position: (gridX * 8192 + 4096,  gridY * 8192 + 4096,  0)
-- Returns util.vector3 or nil if the entry is missing / unparseable.
function JSONScheduleManager.getBaseExteriorPos(recordId)
    ensureLoaded()
    if not recordId then return nil end
    local entry = getEntry(recordId)
    if not entry then return nil end
    local raw = entry.BaseExterior
    if not raw then return nil end
    -- Match "Exterior: x, y" with optional whitespace and negative values
    local xs, ys = raw:match("Exterior:%s*(%-?%d+),%s*(%-?%d+)")
    if not xs or not ys then return nil end
    local gx = tonumber(xs)
    local gy = tonumber(ys)
    if not gx or not gy then return nil end
    local util = require("openmw.util")
    return util.vector3(gx * 8192 + 4096, gy * 8192 + 4096, 0)
end

--- Get all NPC record IDs scheduled for a specific interior cell at the given time.
-- This is the authoritative list; it does not depend on cached handles.
-- @param cellName  string  interior cell name (case-insensitive)
-- @param dayIndex  number  0-6
-- @param gameHour  number  0-24 fractional
-- @return table   array of lowercase record IDs
function JSONScheduleManager.getNpcsForCell(cellName, dayIndex, gameHour)
    ensureLoaded()
    if not cellName then return {} end
    local result = {}
    local loCell = string.lower(cellName)
    forEachEntry(function(recordId, _entry)
        local targetCell, targetType = JSONScheduleManager.getCurrentAssignment(recordId, dayIndex, gameHour)
        if targetCell and targetType == "interior" and string.lower(targetCell) == loCell then
            result[#result + 1] = recordId
        end
    end)
    return result
end

--- Get all NPC record IDs whose current schedule is exterior or unscheduled.
-- Exterior reconciliation uses this to find NPCs that need to leave interiors
-- even when the per-session known-NPC cache was cold.
-- @param dayIndex  number  0-6
-- @param gameHour  number  0-24 fractional
-- @return table   array of lowercase record IDs
function JSONScheduleManager.getExteriorScheduledNpcs(dayIndex, gameHour)
    ensureLoaded()
    local result = {}
    forEachEntry(function(recordId, _entry)
        local targetCell, targetType = JSONScheduleManager.getCurrentAssignment(recordId, dayIndex, gameHour)
        if not targetCell or targetType ~= "interior" then
            result[#result + 1] = recordId
        end
    end)
    return result
end

--- Force a reload of schedule data on the next query.
-- Call this if ScheduleData.json changes at runtime (dev/testing only).
function JSONScheduleManager.invalidate()
    scheduleData = nil
    loaded = false
    print("[JSONScheduleManager] Cache invalidated; will reload on next access")
end

return JSONScheduleManager
