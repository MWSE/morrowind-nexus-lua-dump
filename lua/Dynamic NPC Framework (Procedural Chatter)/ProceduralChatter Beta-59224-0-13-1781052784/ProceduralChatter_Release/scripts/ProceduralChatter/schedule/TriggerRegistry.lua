-- TriggerRegistry.lua
-- Trigger factory module for the ProceduralChatter NPC Scheduling System.
-- Global script context.
--
-- Triggers are stateless evaluators: each exposes evaluate(ctx) -> bool.
-- ctx = { gameHour=number, player=object, weatherCode=number|nil }
--
-- Factory functions produce trigger objects; pre-built instances are exported
-- at the bottom for direct use by callers without extra construction.

local TriggerRegistry = {}

local world    = require("openmw.world")

local Config   = require("scripts.ProceduralChatter.data.ScheduleConfig")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")

-- =============================================================================
-- 1. TimeWindowTrigger
-- =============================================================================

-- ... (skipping for clarity) ...

-- =============================================================================
-- 3. PlayerCellTrigger
-- =============================================================================

--- Creates a trigger that is active when the player is standing in an exterior
--- cell whose name appears in Blacklist's named-cell whitelist
--- (Blacklist.isCellWhitelisted).
---
--- Access to player.cell is wrapped in pcall so a missing/stale player object
---- never raises an error.
---
--- @return table   Trigger object (singleton; no parameters needed)
function TriggerRegistry.createPlayerCellTrigger()
    return {
        id = "PlayerCell:Whitelist",

        evaluate = function(ctx)
            if not ctx then return false end
            local player = ctx.player
            if not player then return false end

            local ok, result = pcall(function()
                local cell = player.cell
                if not cell then return false end
                local name = cell.name
                if not name or name == "" then return false end
                return Blacklist.isCellWhitelisted(name)
            end)

            return ok and result == true
        end,
    }
end

-- =============================================================================
-- 4. DayOfWeekTrigger
-- =============================================================================

--- Creates a trigger that is active when the game hour falls within
--- [startHour, endHour).  Handles midnight wrap when startHour > endHour
--- (e.g. 22 -> 6).  When startHour == endHour the trigger is always active
--- (full-day window).
---
--- @param startHour number   Game hour the window opens  (0-23)
--- @param endHour   number   Game hour the window closes (0-23, exclusive)
--- @return table|nil         Trigger object, or nil on bad args
function TriggerRegistry.createTimeWindow(startHour, endHour)
    if type(startHour) ~= "number" or type(endHour) ~= "number" then
        return nil
    end

    local id = string.format("TimeWindow:%g-%g", startHour, endHour)

    return {
        id = id,

        evaluate = function(ctx)
            if not ctx then return false end
            local hour = ctx.gameHour
            if type(hour) ~= "number" then return false end

            -- Full-day window
            if startHour == endHour then
                return true
            end

            -- Normal (non-wrapping) window: e.g. 18 -> 22
            if startHour < endHour then
                return hour >= startHour and hour < endHour
            end

            -- Midnight-wrapping window: e.g. 22 -> 6
            -- Active when hour >= startHour (evening side) OR hour < endHour (morning side)
            return hour >= startHour or hour < endHour
        end,
    }
end

-- =============================================================================
-- 2. WeatherTrigger
-- =============================================================================

--- Creates a trigger that is active during bad weather (ash storms, blizzards,
--- thunderstorms, etc.).  The actual code check is delegated to
--- Blacklist.isWeatherTrigger(weatherCode) so the list stays in one place.
---
--- ctx.weatherCode must be provided by the global script (reads region weather).
--- If ctx.weatherCode is nil the trigger returns false (assume fine weather).
---
--- @return table   Trigger object (singleton; no parameters needed)
function TriggerRegistry.createWeatherTrigger()
    return {
        id = "Weather:BadWeather",

        evaluate = function(ctx)
            if not ctx then return false end
            local code = ctx.weatherCode
            if code == nil then return false end
            return Blacklist.isWeatherTrigger(code) == true
        end,
    }
end

-- =============================================================================
-- 4. DayOfWeekTrigger
-- =============================================================================

--- Creates a trigger that is active on specific days of the week.
--- world.getTimestamp().day: 0 = Sundas, 1 = Morndas, ..., 6 = Loredas.
---
--- @param daySet table   Map of [dayNumber] = true for active days
--- @param idStr  string  Unique suffix for the trigger ID
--- @return table         Trigger object
function TriggerRegistry.createDayOfWeek(daySet, idStr)
    local id = "Day:" .. idStr

    return {
        id = id,

        evaluate = function(ctx)
            local ok, ts = pcall(function() return world.getTimestamp() end)
            if not ok or not ts then return false end
            local day = ts.day
            return daySet[day] == true
        end,
    }
end

-- =============================================================================
-- Pre-built instances
-- Callers can import TriggerRegistry and register these directly.
-- =============================================================================

TriggerRegistry.WEEKEND = TriggerRegistry.createDayOfWeek({ [0]=true, [6]=true }, "Weekend")
TriggerRegistry.WEEKDAY = TriggerRegistry.createDayOfWeek({ [1]=true, [2]=true, [3]=true, [4]=true, [5]=true }, "Weekday")

TriggerRegistry.TAVERN_TIME = TriggerRegistry.createTimeWindow(
    Config.TAVERN_WINDOW_START,
    Config.TAVERN_WINDOW_END
)

TriggerRegistry.HOME_TIME = TriggerRegistry.createTimeWindow(
    Config.HOME_WINDOW_START,
    Config.HOME_WINDOW_END
)

TriggerRegistry.TIME_9_12 = TriggerRegistry.createTimeWindow(9, 12)
TriggerRegistry.TIME_10_16 = TriggerRegistry.createTimeWindow(10, 16)

TriggerRegistry.BAD_WEATHER = TriggerRegistry.createWeatherTrigger()

TriggerRegistry.PLAYER_CELL = TriggerRegistry.createPlayerCellTrigger()


return TriggerRegistry

