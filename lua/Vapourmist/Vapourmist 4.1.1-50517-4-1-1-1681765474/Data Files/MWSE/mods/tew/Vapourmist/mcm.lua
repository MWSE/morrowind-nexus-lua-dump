local configPath = "Vapourmist"
local config = require("tew.Vapourmist.config")
local metadata = toml.loadMetadata("Vapourmist")

local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate {
    name = metadata.package.name,
    headerImagePath = "\\Textures\\tew\\Vapourmist\\logo.dds" }

local mainPage = template:createPage { label = "Main Settings", noScroll = true }
mainPage:createCategory {
    label = metadata.package.name .. " " .. metadata.package.version .. " by tewlwolow.\n" .. metadata.package.description .."\nYou need to wait or change cells for these settings to be applied.\n\nSettings:"
}

mainPage:createYesNoButton {
    label = "Enable debug mode?",
    variable = registerVariable("debugLogOn"),
    restartRequired = true
}
mainPage:createYesNoButton {
    label = "Enable clouds?",
    variable = registerVariable("clouds"),
}
mainPage:createYesNoButton {
    label = "Enable shader-based mist (compatible with NIF-based mist)?",
    variable = registerVariable("mistShader"),
}
mainPage:createYesNoButton {
    label = "Enable NIF-based mist (compatible with shader-based mist)?",
    variable = registerVariable("mistNIF"),
}
mainPage:createYesNoButton {
    label = "Enable interior fog?",
    variable = registerVariable("interior"),
}

mainPage:createSlider {
    label = "Controls how fast clouds move across the sky.\nDefault - 45.\nSpeed coefficient",
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("speedCoefficient")
}

local weathersPage = template:createPage { label = "Allowed weathers", noScroll = true }
weathersPage:createCategory {
    label = "Controls weather types when cloud and mist types can spawn.\n",
}

weathersPage:createExclusionsPage {
    label = "Cloudy weathers",
    description = "Weathers to spawn clouds in:",
    toggleText = "Toggle",
    leftListLabel = "Cloudy weathers",
    rightListLabel = "All weathers",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "cloudyWeathers",
        table = config,
    },

    filters = {

        {
            label = "Weathers",
            callback = (
                function()
                    local weatherNames = {}
                    for weather, _ in pairs(tes3.weather) do
                        if weather == "thunder" then
                            table.insert(weatherNames, "Thunderstorm")
                        else
                            table.insert(weatherNames, weather:sub(1, 1):upper() .. weather:sub(2))
                        end
                    end
                    return weatherNames
                end
            )
        },

    }
}

weathersPage:createExclusionsPage {
    label = "Misty weathers",
    description = "Weathers to spawn mist in (in addition to dawn/dusk and post-rain mist):",
    toggleText = "Toggle",
    leftListLabel = "Misty weathers",
    rightListLabel = "All weathers",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "mistyWeathers",
        table = config,
    },

    filters = {

        {
            label = "Weathers",
            callback = (
                function()
                    local weatherNames = {}
                    for weather, _ in pairs(tes3.weather) do
                        if weather == "thunder" then
                            table.insert(weatherNames, "Thunderstorm")
                        else
                            table.insert(weatherNames, weather:sub(1, 1):upper() .. weather:sub(2))
                        end
                    end
                    return weatherNames
                end
                )
        },

    }
}

local blockedPage = template:createPage { label = "Disallowed weathers", noScroll = true }
blockedPage:createCategory {
    label = "Controls weather types when fog will never spawn, regardless of other settings.\n",
}

blockedPage:createExclusionsPage {
    label = "Cloudy weathers",
    description = "Weathers to block cloud spawns in:",
    toggleText = "Toggle",
    leftListLabel = "Cloudy weathers",
    rightListLabel = "All weathers",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "blockedCloud",
        table = config,
    },

    filters = {

        {
            label = "Weathers",
            callback = (
                function()
                    local weatherNames = {}
                    for weather, _ in pairs(tes3.weather) do
                        if weather == "thunder" then
                            table.insert(weatherNames, "Thunderstorm")
                        else
                            table.insert(weatherNames, weather:sub(1, 1):upper() .. weather:sub(2))
                        end
                    end
                    return weatherNames
                end
                )
        },

    }
}

blockedPage:createExclusionsPage {
    label = "Misty weathers",
    description = "Weathers to block mist spawns in:",
    toggleText = "Toggle",
    leftListLabel = "Misty weathers",
    rightListLabel = "All weathers",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "blockedMist",
        table = config,
    },

    filters = {

        {
            label = "Weathers",
            callback = (
                function()
                    local weatherNames = {}
                    for weather, _ in pairs(tes3.weather) do
                        if weather == "thunder" then
                            table.insert(weatherNames, "Thunderstorm")
                        else
                            table.insert(weatherNames, weather:sub(1, 1):upper() .. weather:sub(2))
                        end
                    end
                    return weatherNames
                end
                )
        },

    }
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
