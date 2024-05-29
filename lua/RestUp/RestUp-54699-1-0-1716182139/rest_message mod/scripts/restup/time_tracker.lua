--[[
    RestUp Mod for OpenMW
    Developed collaboratively by Lex (GPT-4o) and Clemmerson

    This mod is free to use and modify, as long as proper credit is given.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

-- scripts/restup/time_tracker.lua
local current_time_period = "Unknown"
local time_flags = {
    ForBirds = false,
    EarlyMorning = false,
    MidMorning = false,
    Afternoon = false,
    MidAfternoon = false,
    Evening = false,
    Night = false
}

local function calculateInGameTime(currentGameTime)
    local totalHours = (currentGameTime / 3600) % 24
    return totalHours
end

local function getTimePeriod(hours)
    if hours > 2 and hours < 5 then
        return "ForBirds"
    elseif hours >= 5 and hours < 8 then
        return "EarlyMorning"
    elseif hours >= 8 and hours < 11 then
        return "MidMorning"
    elseif hours >= 11 and hours < 15 then
        return "Afternoon"
    elseif hours >= 15 and hours < 18 then
        return "MidAfternoon"
    elseif hours >= 18 and hours < 21 then
        return "Evening"
    elseif hours >= 21 or hours < 2 then
        return "Night"
    else
        return "Unknown"
    end
end

local function updateFlags(hours)
    time_flags.ForBirds = hours > 2 and hours < 5
    time_flags.EarlyMorning = hours >= 5 and hours < 8
    time_flags.MidMorning = hours >= 8 and hours < 11
    time_flags.Afternoon = hours >= 11 and hours < 15
    time_flags.MidAfternoon = hours >= 15 and hours < 18
    time_flags.Evening = hours >= 18 and hours < 21
    time_flags.Night = hours >= 21 or hours < 2
end

local function setTimePeriod(currentGameTime)
    local hours = calculateInGameTime(currentGameTime)
    current_time_period = getTimePeriod(hours)
    updateFlags(hours)
end

local function getTimePeriod()
    return current_time_period
end

local function getFlags()
    return time_flags
end

return {
    setTimePeriod = setTimePeriod,
    getTimePeriod = getTimePeriod,
    getFlags = getFlags
}