local config = require("CreepingBlight.config")
local this = {}

-- Runs on game load, on receiving certain journal entries, on cell change before the Main Quest is complete, and on closing the MCM.
this.changeWeatherChances = function()

    -- Receiving index 20 for this quest changes the weather at Red Mountain. Also resets questStage to 0.
    local endGameIndex = tes3.getJournalIndex{ id = "C3_DestroyDagoth" }

    -- This global is set by the weather machine under Mournhold, depending on what weather it's set to.
    local mournWeather = tes3.findGlobal("MournWeather").value

    -- Give the Dwemer Puzzle Box to Hasphat Antabolis. Triggers questStage 1.
    local antabolisIndex = tes3.getJournalIndex{ id = "A1_2_AntabolisInformant" }

    -- Receive notes on the Ashlanders from Hassour Zainsubani. Triggers questStage 2.
    local zainsubaniIndex = tes3.getJournalIndex{ id = "A1_11_ZainsubaniInformant" }

    -- Defeat Dagoth Gares. Triggers questStage 3.
    local garesIndex = tes3.getJournalIndex{ id = "A2_2_6thHouse" }

    -- Take the cure from Divayth Fyr. Triggers questStage 4.
    local cureIndex = tes3.getJournalIndex{ id = "A2_3_CorprusCure" }

    -- Receive Moon-and-Star from Azura. Triggers questStage 5.
    local incarnateIndex = tes3.getJournalIndex{ id = "A2_6_Incarnate" }

    -- Receive a working Wraithguard from Vivec or Yagrum Bagarn. Triggers questStage 6.
    local vivecIndex = tes3.getJournalIndex{ id = "B8_MeetVivec" }
    local backPathIndex = tes3.getJournalIndex{ id = "CX_BackPath" }

    local questStage

    -- Determine the current stage of the Main Quest.
    if endGameIndex >= 20 then
        questStage = 0
    elseif vivecIndex >= 50 or backPathIndex >= 50 then
        questStage = 6
    elseif incarnateIndex >= 50 then
        questStage = 5
    elseif cureIndex >= 50 then
        questStage = 4
    elseif garesIndex >= 50 then
        questStage = 3
    elseif zainsubaniIndex >= 50 then
        questStage = 2
    elseif antabolisIndex >= 10 then
        questStage = 1
    else
        questStage = 0
    end

    -- Determine the quest progression component of the blight increase, depending on questStage.
    local maxQuestFactor = 0.01 * config.maxQuestFactor
    local currentQuestFactor = ( questStage / 6 ) * maxQuestFactor

    local daysPassed = tes3.findGlobal("DaysPassed").value - 1

    -- Using math.min to ensure the time factor can never exceed the max time factor.
    local relativeDaysPassed = math.min(daysPassed / config.daysToMax, 1)

    -- Determine the time elapsed component of the blight increase, depending on DaysPassed.
    local maxTimeFactor = 0.01 * config.maxTimeFactor
    local currentTimeFactor = relativeDaysPassed * maxTimeFactor

    -- Main Quest is complete, so no more blight.
    if endGameIndex >= 20 then
        currentTimeFactor = 0
    end

    -- Determine the overall proportion of ashstorms transformed to blight by adding the two factors.
    -- Using math.min to ensure it can never exceed 100%.
    local combinedFactor = math.min(currentQuestFactor + currentTimeFactor, 1)

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

            -- Everything that follows is needed to handle exceptions for Red Mountain and Mournhold, and for blight before the Main Quest is complete.
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

            -- Main Quest is not complete and not Mournhold or Red Mountain, so replace ashstorms with blight storms.
            if combinedFactor > 0
            and regionId ~= "Mournhold Region"
            and regionId ~= "Red Mountain Region" then
                local currentAshChance = region.weatherChanceAsh

                -- No point in proceeding if there are no ashstorms to replace.
                if currentAshChance > 0 then
                    local currentBlightChance = region.weatherChanceBlight

                    -- How much to actually subtract from ash chance and add to blight chance.
                    -- Must be an integer. Using math.floor to be conservative, though it can still be equal to currentAshChance if combinedFactor = 1.
                    local chanceAdjust = math.floor(combinedFactor * currentAshChance)

                    -- Only change ash/blight chances if they'd actually change.
                    if chanceAdjust > 0 then
                        local newAshChance = currentAshChance - chanceAdjust
                        local newBlightChance = currentBlightChance + chanceAdjust

                        region.weatherChanceAsh = newAshChance
                        region.weatherChanceBlight = newBlightChance
                    end
                end
            end
        end
    end
end

return this