local modInfo = require('scripts.holidaysandbirthdays.modInfo')
local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')

local Helpers = {}


Helpers.dateToDecimalDate = function(date)
    local dateParts = {
        year = tonumber(calendar.formatGameTime("%Y", date)),
        month = tonumber(calendar.formatGameTime("%m", date)),
        day = tonumber(calendar.formatGameTime("%d", date)),
    }
    local dateFraction = 0.0
    for i = 0, dateParts.month - 2, 1 do
        dateFraction = dateFraction + calendar.daysInMonth(i)
    end
    dateFraction = dateFraction + dateParts.day
    dateFraction = dateFraction / 365
    local decimalDate = dateParts.year + dateFraction
    return decimalDate
end

--#region StatsWindow
Helpers.addOrModifySection = function(method, sectionId, locationId, params)
    if locationId == nil then
        method(sectionId, params)
    else
        method(sectionId, locationId, params)
    end
end
--#endregion

Helpers.matchString = function(subject, pattern, start, plain)
    local pl = plain or false
    local pos = start or 1
    if string.find(subject, pattern, pos, pl) then
        return true
    else
        return false
    end
end

Helpers.getNumericString = function(text)
    local str = ""
    string.gsub(text, "%d+", function(e) str = str .. e end)
    return str;
end

Helpers.validateNumericInput = function(input, minValue, maxValue)
    local sanitizedInput = input
    if (tonumber(sanitizedInput) ~= nil) then -- we got digits, moving on
        sanitizedInput = sanitizedInput
    else
        sanitizedInput = Helpers.getNumericString(sanitizedInput) -- keeping only digits
    end

    if sanitizedInput ~= "" then
        if tonumber(sanitizedInput) > maxValue then     -- clamping max
            sanitizedInput = tostring(maxValue)
        elseif tonumber(sanitizedInput) < minValue then -- clamping minumum causes input issues if minimum is over 1 digit long. Clamp to actual minimum happens later
            sanitizedInput = tostring(minValue)         -- only clamping to e.g. positive numbers here
        else
            sanitizedInput = sanitizedInput
        end
    end
    return sanitizedInput
end

Helpers.validateAlphaNumericInput = function(input, maxLen)
    local sanitizedInput = input
    if string.len(sanitizedInput) <= #tostring(maxLen) then -- limiting the length
        sanitizedInput = sanitizedInput
    else
        sanitizedInput = string.sub(sanitizedInput, 1, maxLen)
    end

    return sanitizedInput
end

Helpers.ordinalNumber = function(n)
    local ordinal, digit = { "st", "nd", "rd" }, string.sub(n, -1)
    -- special cases
    if tonumber(digit) > 0 and tonumber(digit) <= 3 and string.sub(n, -2) ~=
        "11" and string.sub(n, -2) ~= "12" and string.sub(n, -2) ~= "13" then
        return n .. ordinal[tonumber(digit)]
    else
        return n .. "th"
    end
end

Helpers.getAbsoluteGameStartTime = function()
    local startTime = 427 * time.day * calendar.daysInYear
    for i = 0, 6 do -- 7 full months
        startTime = startTime + time.day * calendar.daysInMonth(i)
    end
    startTime = startTime + 14 * time.day
    return startTime
end

Helpers.getRelativeGameStartTime = function()
    -- formatGameTime operates on assumption that it receives a relative time from game start, not absolute time. So gamestartYear years are always added to formatted output.
    -- Intentionally creating a date that is gameStartDate - 427 years.
    local startTime = 0
    for i = 0, 6 do -- 7 full months
        startTime = startTime + time.day * calendar.daysInMonth(i)
    end
    startTime = startTime + 14 * time.day
    return startTime
end

Helpers.zeroPadNumericString = function(n, padTo)
    padTo = padTo or 2
    local numericString = tostring(n)
    local paddedString = numericString
    if #numericString < padTo then
        for i = 1, padTo - 1, 1 do
            paddedString = "0" .. paddedString
        end
    end
    return paddedString
end

Helpers.key = function(suffix)
    return string.format("%s_%s", modInfo.name, suffix)
end

Helpers.table_shallow_copy = function(t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = v end
    return t2
end

return Helpers
