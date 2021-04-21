local mod = "Creeping Blight"
local version = "2.1"

local config = require("CreepingBlight.config")
local common = require("CreepingBlight.common")
local data = require("CreepingBlight.data")

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

local function createMainPage(template)
    local mainPage = template:createSideBarPage{
        label = "General Settings",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod allows you to customize the weather chances in the game's regions, and implements an increasing chance of blight as you progress in the Main Quest and as time elapses without completing the Main Quest.\n" ..
            "\n" ..
            "This page contains general settings for the mod. Hover over each setting to learn more about it.",
    }

    mainPage:createSlider{
        label = "Max quest progression factor",
        description =
            "The maximum percentage of ashstorms that will be converted to blight as a result of progression in the Main Quest. This is modified by what stage of the Main Quest you're in, so earlier in the Main Quest the proportion of ashstorms transformed to blight will be lower. Once the Main Quest is complete, ashstorms will no longer be transformed to blight.\n" ..
            "\n" ..
            "For example, by default the Ashlands have base chances of 30% ash and 0% blight. As you progress in the Main Quest, ashstorms will be replaced by blight storms, with increasing frequency the further you progress. With default settings, toward the end of the Main Quest, 90% of what would normally be ashstorms will instead be blight, meaning the Ashlands will have chances of 3% ash and 27% blight (not taking into account time elapsed). Earlier in the Main Quest, ash chance will be higher and blight chance lower.\n" ..
            "\n" ..
            "If a region has no base chance of ash, then blight chance in that region will not increase. Mournhold is not affected by this setting.\n" ..
            "\n" ..
            "The quest progression factor, modified by quest stage, will be added to the time elapsed factor, modified by the number of days that have passed, to determine the actual proportion of ashstorms transformed to blight (with a maximum total factor of 100%). You can disable the quest progression component entirely by setting this factor to 0.\n" ..
            "\n" ..
            "Default: 90",
        variable = mwse.mcm.createTableVariable{
            id = "maxQuestFactor",
            table = config,
        },
        max = 100,
        defaultSetting = 90,
    }

    mainPage:createSlider{
        label = "Max time elapsed factor",
        description =
            "The maximum percentage of ashstorms that will be converted to blight as a result of time elapsed before completing the Main Quest. The actual proportion of ashstorms transformed to blight due to this factor steadily increases (linearly), reaching the maximum value once \"days to max time factor\" number of days have elapsed. Once the Main Quest is complete, ashstorms will no longer be transformed to blight.\n" ..
            "\n" ..
            "For example, by default Molag Amur has base chances of 20% ash and 0% blight. As the days pass without finishing the Main Quest, ashstorms will be replaced by blight storms, with increasing frequency the more days pass. With default settings, once 365 days have passed, 75% of what would normally be ashstorms will instead be blight, meaning Molag Amur will have chances of 5% ash and 15% blight (not taking into account what stage of the Main Quest you're in). Before 365 days have passed, ash chance will be higher and blight chance lower.\n" ..
            "\n" ..
            "If a region has no base chance of ash, then blight chance in that region will not increase. Mournhold is not affected by this setting.\n" ..
            "\n" ..
            "The time elapsed factor, modified by the number of days that have passed, will be added to the quest progression factor, modified by quest stage, to determine the actual proportion of ashstorms transformed to blight (with a maximum total factor of 100%). You can disable the time elapsed component entirely by setting this factor to 0.\n" ..
            "\n" ..
            "Default: 75",
        variable = mwse.mcm.createTableVariable{
            id = "maxTimeFactor",
            table = config,
        },
        max = 100,
        defaultSetting = 75,
    }

    mainPage:createTextField{
        label = "Days to max time factor",
        description =
            "This is the number of days that must pass (without completing the Main Quest) before the time elapsed factor reaches its maximum value.\n" ..
            "\n" ..
            "As the days pass, ashstorms will be transformed into blight, with increasing frequency the more time elapses. The rate of increase is linear, with the proportion of ashstorms converted to blight (not taking into account Main Quest progression) reaching the \"max time elapsed factor\" once this number of days have passed. It will not increase further with the passage of additional time.\n" ..
            "\n" ..
            "Once the Main Quest is complete, ashstorms will no longer be transformed to blight.\n" ..
            "\n" ..
            "Default: 365",
        numbersOnly = true,
        variable = mwse.mcm.createTableVariable{
            id = "daysToMax",
            table = config,
        },
        defaultSetting = 365,
    }

    -- This button resets the entire config.weatherChances table to default values.
    -- This is actually effective right away, but the slider positions in the MCM won't be reset until the player restarts.
    mainPage:createButton{
        label = "Reset base weather chances to defaults",
        description =
            "Press this button to reset all base weather chances to their default values (this mod's defaults, which are different from the vanilla Morrowind defaults).\n" ..
            "\n" ..
            "This will require restarting Morrowind.",
        buttonText = "Reset",
        restartRequired = true,
        callback = function()
            local defaultTable = data.defaults
            config.weatherChances = defaultTable
        end,
    }

    return mainPage
end

local function createRegionPage(template)
    local regionPage = template:createSideBarPage{
        label = "Regions",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            "This mod allows you to customize the weather chances in the game's regions, and implements an increasing chance of blight as you progress in the Main Quest and as time elapses without completing the Main Quest.\n" ..
            "\n" ..
            "This page allows you to modify the base weather chances for all the game's regions. If a region (other than Mournhold) has a base ashstorms chance, a certain portion of that chance will be converted to blight chance during the Main Quest and/or as time elapses, depending on settings on the General Settings page.\n" ..
            "\n" ..
            "All ten chances for each region should add up to 100. Nothing particularly horrible will happen if they don't, but the game won't behave as you expect when choosing a new weather.",
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
        local category = regionPage:createCategory(regionName)

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

            -- currentWeatherId is a string "0" - "9". table.find looks up the name of the corresponding weather condition.
            local currentWeatherName = table.find(tes3.weather, tonumber(currentWeatherId))

            -- Add up the weather chances for this region.
            sum = sum + currentWeatherChance

            -- Create our slider for the current weather chance.
            category:createSlider{

                -- currentWeatherName an all lowercase string (e.g. "clear"), so we use string.gsub to find the first lowercase letter and change it to uppercase.
                label = string.gsub(currentWeatherName, "%l", string.upper, 1),
                description = "The percentage chance of the \"" .. currentWeatherName .. "\" weather condition in the " .. regionName .. ".",
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

    return regionPage
end

local template = mwse.mcm.createTemplate("Creeping Blight")

-- Using onClose instead of saveOnClose so we can update regions right away when the player closes the MCM.
template.onClose = function()
    mwse.saveConfig("CreepingBlight", config)
    common.changeWeatherChances()
end

createMainPage(template)
createRegionPage(template)

mwse.mcm.register(template)