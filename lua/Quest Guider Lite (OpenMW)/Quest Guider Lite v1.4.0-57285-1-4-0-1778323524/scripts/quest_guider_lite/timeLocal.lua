local core = require("openmw.core")
local playerRef = require("openmw.self")
local calendar = require("openmw_aux.calendar")
local dateLib = require("scripts.quest_guider_lite.utils.date")
local config = require("scripts.quest_guider_lite.config")

local this = {}

this.getDateByTime = dateLib.getDateByTime

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


---@param dt questGuider.playerQuest.storageQuestInfo
---@return number
function this.getTimestamp(dt)
    if dt.globalTime and config.data.journal.useGlobalDate then
        return dt.globalTime
    end
    return dt.timestamp or 0
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


return this