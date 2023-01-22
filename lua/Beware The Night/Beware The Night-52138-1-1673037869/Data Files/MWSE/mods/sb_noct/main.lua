local function GetSunrise()
    local wc = tes3.worldController.weatherController
    local sunriseStart = wc.sunriseHour - wc.sunPreSunriseTime
    local sunriseTotalDuration = wc.sunPostSunriseTime + wc.sunriseDuration + wc.sunPreSunriseTime
    return sunriseStart + sunriseTotalDuration
end

local function GetSunset()
    local wc = tes3.worldController.weatherController
    local sunsetStart = wc.sunsetHour - wc.sunPreSunsetTime
    local sunsetTotalDuration = wc.sunPostSunsetTime + wc.sunsetDuration + wc.sunPreSunsetTime
    return sunsetStart + sunsetTotalDuration
end

--- @param e leveledCreaturePickedEventData
local function leveledCreaturePickedCallback(e)
    local gh = tes3.getGlobal("GameHour")
    if (gh >= GetSunset() or gh <= GetSunrise()) then
        if not (e.list.id:startswith("n_") and e.list.id:endswith("_n")) then
            local lc_n = tes3.getObject("n_" .. e.list.id) or tes3.getObject(e.list.id .. "_n")
            if (lc_n and #lc_n.list > 0) then e.pick = lc_n:pickFrom() end
        end
    else
        if (e.list.id:startswith("n_") or e.list.id:endswith("_n")) then
            return
        end
    end
end

event.register(tes3.event.leveledCreaturePicked, leveledCreaturePickedCallback)
