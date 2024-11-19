local common = require("mer.darkShard.common")

local CometEffect = require("mer.darkShard.components.CometEffect")
local Quest = require("mer.darkShard.components.Quest")

---@type DarkShard.CometEffect.Condition[]
local cometConditions = {
    {
        id = "questActive",
        initEvents = function(callback)
            event.register("journal", function(e)
                local quest = Quest.quests.afq_main
                if e.topic.id == quest.id then
                    callback()
                end
            end)
        end,
        getEffectStrength = function ()
            if not Quest.quests.afq_main:isActive() then
                return 0
            end
            local progress = Quest.quests.afq_main:getProgress()
            return math.remap(progress, 0, 1, 0.75, 1)
        end
    },
    {
        id = "isNightTime",
        initEvents = function(callback)
            event.register("simulate", function()
                if tes3.player.cell.isOrBehavesAsExterior then
                    local hour = tes3.worldController.hour.value
                    if hour >= 18 or hour <= 6 then
                        callback()
                    end
                end
            end)
        end,
        getEffectStrength = function()
            --starts increasing from 6pm, peaks from 9pm to 3am, then decreases to 6am
            local hour = tes3.worldController.hour.value
            local startTime = 18
            local peakStart = 19
            local peakEnd = 6
            local endTime = 7

            --Fading in
            if hour >= startTime and hour <= peakStart then
                return ((hour - startTime) / (peakStart - startTime))
            end
            --Fully active
            if hour > peakStart or hour < peakEnd then
                return 1
            end
            --Fading out
            if hour >= peakEnd and hour <= endTime then
                return 1 - (hour - peakEnd) / (endTime - peakEnd)
            end
            --Inactive
            return 0
        end
    },
    {
        id = "isClearWeather",
        initEvents = function(callback)
            local events = {
                tes3.event.weatherChangedImmediate,
                tes3.event.weatherCycled,
                tes3.event.weatherTransitionFinished,
                tes3.event.cellChanged,
                tes3.event.loaded
            }
            for _, eventId in ipairs(events) do
                event.register(eventId, callback)
            end
        end,
        getEffectStrength = function()
            if tes3.player.cell.isOrBehavesAsExterior then
                local wc = tes3.worldController.weatherController
                local transition = wc.transitionScalar or 0
                if wc.nextWeather and wc.nextWeather.index == tes3.weather.clear then
                    return transition
                end
                if wc.currentWeather.index == tes3.weather.clear then
                    return 1 - transition
                end
            else
                --get the weather in the last exterior cell
                local weather = common.getRegion().weather
                if weather == tes3.weather.clear then
                    return 1
                end
            end
            return 0
        end
    }
}

for _, data in ipairs(cometConditions) do
    CometEffect.registerCondition(data)
end