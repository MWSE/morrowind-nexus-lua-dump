local starChildLuckClear = 50
local starChildLuckCloudy = 25
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    data.starChild = data.starChild or {
        luck = nil
    }
    return data
end

return {
    id = "starChild",
    name = "Star Child",
    description = (
        "You were born under starlight, and have gained the favor of the Celestials. " ..
        "When outdoors at night, your Luck increases by " ..
        starChildLuckClear .. " points during clear weather and " ..
        starChildLuckCloudy.. " points during partially cloudy weather. "

    ),
    callback = function()

        local function update()
            local data = getData()
            if data.currentBackground ~= "starChild" then return end

            local hour = tes3.worldController.hour.value
            local isNight = hour <= 6 or hour >= 20
            local isOutdoors = not tes3.getPlayerCell().isInterior

            local luckLevel
            local weather = tes3.getCurrentWeather() and tes3.getCurrentWeather().index or 0
            if weather == tes3.weather.clear then
                luckLevel = starChildLuckClear
            elseif weather == tes3.weather.cloudy then
                luckLevel = starChildLuckCloudy
            end

            if isNight and isOutdoors and luckLevel then

                if not data.starChild.luck or luckLevel ~= data.starChild.luck then

                    local change = luckLevel - ( data.starChild.luck or 0 )
                    tes3.modStatistic({
                        reference = tes3.player,
                        attribute = tes3.attribute.luck,
                        value = change
                    })
                    data.starChild.luck = luckLevel
                    tes3.messageBox("The Celestials smile upon you.")
                end
            else
                if data.starChild.luck then

                    tes3.modStatistic({
                        reference = tes3.player,
                        attribute = tes3.attribute.luck,
                        value = -data.starChild.luck
                    })
                    data.starChild.luck = false
                end
            end
        end

        timer.start{
            type = timer.game,
            iterations = -1,
            duration = 0.05,
            callback = update
        }
        update()

        event.unregister("cellChanged", update)
        event.register("cellChanged", update)
        event.unregister("weatherTransitionFinished", update)
        event.register("weatherTransitionFinished", update)
        event.unregister("weatherChangedImmediate ", update)
        event.register("weatherChangedImmediate ", update)
    end
}