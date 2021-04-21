local mod = "Weather Chances Adjuster"
local version = "1.0.2"

local config = require("WeatherChances.config")
local common = require("WeatherChances.common")
local data = require("WeatherChances.data")

local sumsText = "Sum of all chances for "
local chancesSums = {}
local chancesSumsText = {}

-- Runs each time any slider is changed.
local function updateSum(region, weathers)
    local sum = 0

    -- Fix the displayed name of these regions.
    local name = region
    if name == "Molag Mar Region" then
        name = "Molag Amur Region"
    elseif name == "Sheogorad" then
        name = "Sheogorad Region"
    end

    -- Go through each weather chance for this region and add them all up.
    for _, weather in ipairs(weathers) do
        local chance = weather.chance
        sum = sum + chance
    end

    -- Set variables for the sum of all chances for this region and the display text for the MCM.
    chancesSums[region] = sum
    local sumDisplay = string.format("%s: %d", name, chancesSums[region])
    chancesSumsText[region] = sumsText .. sumDisplay

    -- Refresh the MCM so the new sum will display right away. This happens twice, and that's necessary otherwise it won't work right.
    event.trigger("MCM:refresh")
end

local function createPage(template)
    local page = template:createPage{}

    page:createInfo{
		text =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod allows you to customize the weather chances in the game's regions. Use the sliders below to set the chance for each weather condition in each region.\n" ..
            "\n" ..
            "All ten chances for each region should add up to 100. Nothing particularly horrible will happen if they don't, but the game won't behave as you expect when choosing a new weather.",
    }

    -- This button resets the entire config.weatherChances table to default values.
    -- This is actually effective right away, but the slider positions in the MCM won't be reset until the player restarts.
    page:createButton{
        label = "Reset weather chances to defaults (restart required)",
        buttonText = "Reset",
        restartRequired = true,
        callback = function()
            local defaultTable = data.defaults
            config.weatherChances = defaultTable
        end,
    }

    -- Iterate through each region in the config file one at a time.
    for _, configRegion in ipairs(config.weatherChances) do
        local configRegionId = configRegion.id
        local configRegionWeathers = configRegion.weathers

        -- Fix the displayed name of these regions.
        local regionName = configRegionId
        if regionName == "Molag Mar Region" then
            regionName = "Molag Amur Region"
        elseif regionName == "Sheogorad" then
            regionName = "Sheogorad Region"
        end

        -- Create a new category for this region.
        local category = page:createCategory(regionName)

        -- Add descriptive text for certain regions.
        if configRegionId == "Red Mountain Region" then
            category:createInfo{ text = "These sliders determine weather chances for Red Mountain only after the Main Quest is complete. Before finishing the Main Quest, Red Mountain is 100% blight.", }
        elseif configRegionId == "Mournhold Region" then
            category:createInfo{ text = "These values will be overridden while the weather machine is active during the Tribunal Main Quest.", }
        elseif configRegionId == "Firemoth Region" then
            category:createInfo{ text = "If you don't have the official plugin \"Siege at Firemoth\" installed, these settings will do nothing.", }
        end

        local sum = 0

        -- Go through each weather chance for the current region.
        for _, currentWeather in ipairs(configRegionWeathers) do
            local currentWeatherId = currentWeather.id
            local currentWeatherChance = currentWeather.chance

            -- Add up the weather chances for this region.
            sum = sum + currentWeatherChance

            -- Create our slider for the current weather chance.
            category:createSlider{

                -- currentWeatherId is a string "0" - "9". table.find looks up the name of the corresponding weather condition.
                -- It returns an all lowercase string (e.g. "clear"), so we use string.gsub to find the first lowercase letter and change it to uppercase.
                label = string.gsub(table.find(tes3.weather, tonumber(currentWeatherId)), "%l", string.upper, 1),
                variable = mwse.mcm.createTableVariable{
                    id = "chance",
                    table = currentWeather,
                },
                max = 100,
                callback = function()

                    -- Update the sum of chances for this region when the player changes the slider.
                    updateSum(configRegionId, configRegionWeathers)

                    -- Refresh MCM so the chances sum created below will update immediately. This happens twice, and that's necessary otherwise it won't work right.
                    event.trigger("MCM:refresh")
                end,
            }
        end

        -- Set variables for the sum of all chances for this region and the display text for the MCM.
        chancesSums[configRegionId] = sum
        local sumDisplay = string.format("%s: %d", regionName, chancesSums[configRegionId])
        chancesSumsText[configRegionId] = sumsText .. sumDisplay

        -- createActiveInfo creates an info text element that can be updated in-game.
        -- We're using it to display the sum of all weather chances for this region.
        category:createActiveInfo{
            variable = mwse.mcm.createTableVariable{
                id = configRegionId,
                table = chancesSumsText,
            },

            -- This runs each time the info text is updated. Make the text green if the sum is 100, red otherwise.
            update = function(self)
                if chancesSums[configRegionId] == 100 then
                    self.elements.info.color = tes3ui.getPalette("fatigue_color")
                else
                    self.elements.info.color = tes3ui.getPalette("health_color")
                end

                -- This is needed, otherwise the text will be blank.
                if self.variable and self.variable.value then
                    self.text = self.variable.value
                end
            end,
        }
    end

    return page
end

local template = mwse.mcm.createTemplate("Weather Chances")

-- Using onClose instead of saveOnClose so we can update regions right away when the player closes the MCM.
template.onClose = function()
    mwse.saveConfig("WeatherChances", config)
    common.changeWeatherChances()
end

createPage(template)

mwse.mcm.register(template)