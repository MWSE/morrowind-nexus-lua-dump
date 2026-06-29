-- ScheduleOccupancyLedger.lua
-- Generation-time occupancy accounting. This is intentionally separate from
-- runtime OccupancyTracker, which owns materialized in-cell placement.

local Ledger = {}

local function normalize(value)
    return string.lower(tostring(value or ""))
end

function Ledger.key(city, dayName, timeBlock, destination)
    return normalize(city) .. "|" .. normalize(dayName) .. "|" .. normalize(timeBlock) .. "|" .. normalize(destination)
end

function Ledger.clone(src)
    local out = {}
    for key, value in pairs(src or {}) do
        out[key] = value
    end
    return out
end

function Ledger.count(ledger, city, dayName, timeBlock, destination)
    return (ledger or {})[Ledger.key(city, dayName, timeBlock, destination)] or 0
end

function Ledger.canReserve(ledger, city, dayName, timeBlock, destination, cap)
    if not destination or destination == "" then return false end
    if destination == "Market:Exterior" then
        return Ledger.count(ledger, city, dayName, timeBlock, destination) < cap
    end
    return Ledger.count(ledger, city, dayName, timeBlock, destination) < cap
end

function Ledger.reserve(ledger, city, dayName, timeBlock, destination, amount)
    if not ledger or not destination or destination == "" then return nil end
    local key = Ledger.key(city, dayName, timeBlock, destination)
    ledger[key] = (ledger[key] or 0) + (amount or 1)
    return key
end

function Ledger.release(ledger, city, dayName, timeBlock, destination, amount)
    if not ledger or not destination or destination == "" then return end
    local key = Ledger.key(city, dayName, timeBlock, destination)
    local nextValue = (ledger[key] or 0) - (amount or 1)
    if nextValue > 0 then
        ledger[key] = nextValue
    else
        ledger[key] = nil
    end
end

function Ledger.canReserveAll(ledger, city, days, timeBlocks, destination, cap)
    for _, dayName in ipairs(days or {}) do
        for _, timeBlock in ipairs(timeBlocks or {}) do
            if not Ledger.canReserve(ledger, city, dayName, timeBlock, destination, cap) then
                return false
            end
        end
    end
    return true
end

function Ledger.reserveAll(ledger, city, days, timeBlocks, destination, amount)
    local reservations = {}
    for _, dayName in ipairs(days or {}) do
        for _, timeBlock in ipairs(timeBlocks or {}) do
            local key = Ledger.reserve(ledger, city, dayName, timeBlock, destination, amount)
            if key then
                reservations[#reservations + 1] = {
                    key = key,
                    city = city,
                    day = dayName,
                    timeBlock = timeBlock,
                    destination = destination,
                    amount = amount or 1,
                }
            end
        end
    end
    return reservations
end

function Ledger.seedFromSchedules(scheduleData)
    local ledger = {}
    for _, entry in pairs(scheduleData or {}) do
        local city = entry.City or ""
        local schedule = entry.Schedule or {}
        for dayName, daySchedule in pairs(schedule) do
            for timeBlock, destination in pairs(daySchedule or {}) do
                if destination and destination ~= "" and destination ~= "Market:Exterior" then
                    Ledger.reserve(ledger, city, dayName, timeBlock, destination, 1)
                elseif destination == "Market:Exterior" then
                    Ledger.reserve(ledger, city, dayName, timeBlock, destination, 1)
                end
            end
        end
    end
    return ledger
end

function Ledger.merge(base, extra)
    local out = Ledger.clone(base)
    for key, value in pairs(extra or {}) do
        out[key] = (out[key] or 0) + value
    end
    return out
end

function Ledger.applyReservations(ledger, reservations)
    for _, reservation in ipairs(reservations or {}) do
        if reservation.key then
            ledger[reservation.key] = (ledger[reservation.key] or 0) + (reservation.amount or 1)
        elseif reservation.city and reservation.day and reservation.timeBlock and reservation.destination then
            Ledger.reserve(ledger, reservation.city, reservation.day, reservation.timeBlock, reservation.destination, reservation.amount or 1)
        end
    end
end

return Ledger
