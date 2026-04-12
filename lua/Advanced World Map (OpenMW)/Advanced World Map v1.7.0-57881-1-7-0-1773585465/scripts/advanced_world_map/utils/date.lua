local core = require("openmw.core")
local playerRef = require("openmw.self")
local calendar = require("openmw_aux.calendar")
local commonData = require("scripts.advanced_world_map.common")

local l10n = core.l10n(commonData.l10nKey)


local this = {}


local dayLength = 86400
local startYear = 427
local startDay = 15
local startMonth = 8


local startDayOffset = calendar.gameTime{
    year = startYear,
    month = startMonth,
    day = startDay,
}

local globalDayTimestamp = core.getGameTime()
local changedTimestamp = 0


function this.requestTimeUpdate()
    core.sendGlobalEvent("QGL:requestTimeUpdate", playerRef.object)
end


function this.getGlobalTimestamp()
    local tm = core.getGameTime()
    local offset = tm - changedTimestamp + changedTimestamp % dayLength

    return globalDayTimestamp + offset
end


function this.setGlobalTime(day, month, year)
    changedTimestamp = core.getGameTime()
    local gTm = calendar.gameTime{
        year = year,
        month = month + 1,
        day = day,
    } - startDayOffset

    globalDayTimestamp = gTm
end


---@param time number
---@return string
function this.getDateByTime(time)
    local result = calendar.formatGameTime(l10n("dateFormat"), time)

    return result
end


---@param days number Days since start date
---@return number timestamp
function this.getTimestampByDate(days)
    local timestamp = days * 86400
    return timestamp
end


return this