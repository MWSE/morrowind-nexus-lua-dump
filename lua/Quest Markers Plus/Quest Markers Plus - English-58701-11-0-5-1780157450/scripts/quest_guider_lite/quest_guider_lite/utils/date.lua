local core = require("openmw.core")
local calendar = require("openmw_aux.calendar")
local commonData = require("scripts.quest_guider_lite.common")

local l10n = core.l10n(commonData.l10nKey)

local this = {}


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