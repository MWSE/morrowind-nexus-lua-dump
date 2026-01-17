local core = require("openmw.core")

local this = {}


local morrowindMonths = {
    {core.getGMST("sMonthMorningstar") or "Morning Star", 31},
    {core.getGMST("sMonthSunsdawn") or "Sun's Dawn", 28},
    {core.getGMST("sMonthFirstseed") or "First Seed", 31},
    {core.getGMST("sMonthRainshand") or "Rain's Hand", 30},
    {core.getGMST("sMonthSecondseed") or "Second Seed", 31},
    {core.getGMST("sMonthMidyear") or "Mid Year", 30},
    {core.getGMST("sMonthSunsheight") or "Sun's Height", 31},
    {core.getGMST("sMonthLastseed") or "Last Seed", 31},
    {core.getGMST("sMonthHeartfire") or "Hearthfire", 30},
    {core.getGMST("sMonthFrostfall") or "Frostfall", 31},
    {core.getGMST("sMonthSunsdusk") or "Sun's Dusk", 30},
    {core.getGMST("sMonthEveningstar") or "Evening Star", 31},
}


local daysInYear = 0
for _, monthData in pairs(morrowindMonths) do
    daysInYear = daysInYear + monthData[2]
end

local monthsInYear = 12

local startHour = 0
local startDay = 15
local startMonth = 8
local startYear = 427


---@param time number
---@return string
function this.getDateByTime(time)
local months_in_year = 12

    local total_seconds = time + (startHour * 3600)

    local total_days = math.floor(total_seconds / 86400)
    local remaining_seconds = total_seconds % 86400

    local hour = math.floor(remaining_seconds / 3600)
    local minute = math.floor((remaining_seconds % 3600) / 60)

    local day = startDay + total_days
    local month = startMonth
    local year = startYear

    while day > morrowindMonths[month][2] do
        day = day - morrowindMonths[month][2]
        month = month + 1
        if month > months_in_year then
            month = 1
            year = year + 1
        end
    end

    local function day_suffix(d)
        if d >= 11 and d <= 13 then return "th" end
        local last = d % 10
        if last == 1 then return "st"
        elseif last == 2 then return "nd"
        elseif last == 3 then return "rd"
        else return "th" end
    end

    local suffix = day_suffix(day)
    local month_name = morrowindMonths[month][1]

    local result = string.format("%d%s %s, 3E %d",
        day, suffix, month_name, year)

    return result
end


---@return number timestamp
function this.getTimestampByDate(day, month, year)
    if year < startYear or (year == startYear and month < startMonth)
        or (year == startYear and month == startMonth and day < startDay) then
            return 0
    end

    local days = 0

    if year == startYear then
        if month == startMonth then
            days = day - startDay
        else
            days = days + morrowindMonths[startMonth][2] - startDay
            for i = startMonth + 1, month - 1 do
                days = days + morrowindMonths[i][2]
            end
            days = days + day
        end

    else
        days = days + morrowindMonths[startMonth][2] - startDay
        for i = startMonth + 1, monthsInYear do
            days = days + morrowindMonths[i][2]
        end

        for i = startYear + 1, year - 1 do
            days = days + daysInYear
        end

        for i = 1, month - 1 do
            days = days + morrowindMonths[i][2]
        end

        days = days + day
    end

    local timestamp = days * 86400

    return timestamp
end


return this