local config = require("WeatherChances.config")
local this = {}

-- Runs on game load, on receiving certain journal entries, and on closing the MCM.
this.changeWeatherChances = function()

    -- Receiving index 20 for this quest changes the weather at Red Mountain.
    local endGameIndex = tes3.getJournalIndex{ id = "C3_DestroyDagoth" }

    -- This global is set by the weather machine under Mournhold, depending on what weather it's set to.
    local mournWeather = tes3.findGlobal("MournWeather").value

    -- Go through each region in the game's data, one at a time.
    for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
        local regionId = region.id
        local currentRegion = nil

        -- Iterate through each region in the config file, looking for a match.
        for _, configRegion in ipairs(config.weatherChances) do
            local configRegionId = configRegion.id

            if configRegionId == regionId then
                currentRegion = configRegion
                break
            end
        end

        -- If no match is found, the current region is not in the config file, so do nothing.
        if currentRegion then
            local currentWeathers = currentRegion.weathers

            -- Go through each weather chance for the current region and set it to the value in the config file.
            for _, weather in ipairs(currentWeathers) do
                local weatherId = weather.id
                local weatherChance = weather.chance

                -- Weather IDs are 0-9, but this table uses 1-10, so add 1 to the ID.
                region.weatherChances[weatherId + 1] = weatherChance
            end

            -- Everything that follows is needed to handle exceptions for Red Mountain and Mournhold.
            local adjustWeathers = false
            local adjust = {}

            -- Current region is Red Mountain and the Main Quest is not complete, so it should be 100% blight.
            if regionId == "Red Mountain Region" and endGameIndex < 20 then
                adjustWeathers = true
                adjust.blight = 100

            -- Current region is Mournhold, so check the state of the weather machine.
            elseif regionId == "Mournhold Region" then
                adjustWeathers = true

                if mournWeather == 1 then
                    adjust.clear = 100
                elseif mournWeather == 2 then
                    adjust.cloudy = 100
                elseif mournWeather == 3 then
                    adjust.foggy = 100
                elseif mournWeather == 4 then
                    adjust.overcast = 100
                elseif mournWeather == 5 then
                    adjust.rain = 100
                elseif mournWeather == 6 then
                    adjust.thunder = 100
                elseif mournWeather == 7 then
                    adjust.ash = 100

                -- The weather machine is not active or is set to normal weather, so make no adjustment.
                else
                    adjustWeathers = false
                end
            end

            -- Override the config settings if we need to make an exception for Red Mountain or Mournhold.
            if adjustWeathers then
                region.weatherChanceClear = adjust.clear or 0
                region.weatherChanceCloudy = adjust.cloudy or 0
                region.weatherChanceFoggy = adjust.foggy or 0
                region.weatherChanceOvercast = adjust.overcast or 0
                region.weatherChanceRain = adjust.rain or 0
                region.weatherChanceThunder = adjust.thunder or 0
                region.weatherChanceAsh = adjust.ash or 0
                region.weatherChanceBlight = adjust.blight or 0
                region.weatherChanceSnow = 0
                region.weatherChanceBlizzard = 0
            end
        end
    end
end

return this