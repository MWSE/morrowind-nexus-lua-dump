local core = require('openmw.core')
local storage = require('openmw.storage')
-- openmw.world is only available in global scripts.
-- Lazy-required inside getDayIndex() so this module loads safely in local scripts too.

local TimeService = {}

-- =============================================================================
-- Period boundaries (hours, 0-24). Kept in settings so they can be tuned.
-- =============================================================================
local PERIODS = {
    { name = "dawn",      from =  5, to =  8 },
    { name = "morning",   from =  8, to = 12 },
    { name = "afternoon", from = 12, to = 18 },
    { name = "evening",   from = 18, to = 23 },
    { name = "night",     from = 23, to =  5 }, -- wraps midnight
}

local DAY_NAMES = {
    [0] = "Sundas",
    [1] = "Morndas",
    [2] = "Tirdas",
    [3] = "Middas",
    [4] = "Turdas",
    [5] = "Fredas",
    [6] = "Loredas"
}

--- Current day index (0-6). 0 = Sundas.
-- Uses openmw_aux.calendar (same method as in-game date mods) so the
-- weekday is accurate even when months roll over.
function TimeService.getDayIndex()
    local ok, result = pcall(function()
        local calendar = require('openmw_aux.calendar')
        local t = calendar.formatGameTime('*t')
        -- In os.date-style tables wday is 1=Sunday (Sundas), 7=Saturday (Loredas)
        return (t.wday - 1) % 7
    end)
    if ok and result ~= nil then return result end
    return 0
end

--- Current day name (e.g. "Sundas").
function TimeService.getDayName()
    return DAY_NAMES[TimeService.getDayIndex()]
end

--- Current in-game hour (0–24 float).
function TimeService.getHour()
    return (core.getGameTime() / 3600) % 24
end

--- Returns the period name for a given hour.
-- @param hour  Optional; uses current hour if nil.
-- @return string  "dawn"|"morning"|"afternoon"|"evening"|"night"
function TimeService.getPeriod(hour)
    hour = hour or TimeService.getHour()
    for _, p in ipairs(PERIODS) do
        if p.from < p.to then
            -- Normal range (e.g. 5–8)
            if hour >= p.from and hour < p.to then return p.name end
        else
            -- Wrapping range (e.g. 23–5)
            if hour >= p.from or hour < p.to then return p.name end
        end
    end
    return "night" -- fallback
end

--- Returns true if the given hour falls in [min, max).
-- Handles midnight-wrapping ranges (e.g. min=22, max=4).
function TimeService.isInWindow(min, max, hour)
    hour = hour or TimeService.getHour()
    if min <= max then
        return hour >= min and hour < max
    else
        return hour >= min or hour < max
    end
end

--- Returns true if the hour just crossed a period boundary between prevHour and nowHour.
-- Useful for one-shot triggers in update loops.
-- @param prevHour  Hour value from last frame
-- @param nowHour   Hour value this frame
-- @param boundary  The hour value of the boundary to detect
function TimeService.justCrossed(prevHour, nowHour, boundary)
    -- Handle midnight wrap
    if nowHour < prevHour then
        -- Wrapped: check if boundary is in (prevHour, 24) or [0, nowHour)
        return boundary > prevHour or boundary <= nowHour
    end
    return prevHour < boundary and nowHour >= boundary
end

--- Returns true if a period transition occurred between prevHour and nowHour.
-- @return string|nil  The new period name if a transition happened, else nil.
function TimeService.getPeriodTransition(prevHour, nowHour)
    local prevPeriod = TimeService.getPeriod(prevHour)
    local nowPeriod  = TimeService.getPeriod(nowHour)
    if prevPeriod ~= nowPeriod then
        return nowPeriod
    end
    return nil
end

--- Returns true when the hour is in the "deep night" window where NPCs should
-- already be in bed (player arrived mid-sleep).  Matches SleepManager's
-- DEEP_NIGHT_START/END constants (0–5 by default).
function TimeService.isDeepNight()
    return TimeService.isInWindow(0, 5)
end

--- Convenience: minutes remaining until a given hour boundary.
-- Returns 0 if already past.
function TimeService.minutesUntil(targetHour)
    local hour = TimeService.getHour()
    local diff = targetHour - hour
    if diff < 0 then diff = diff + 24 end
    return diff * 60
end

return TimeService
