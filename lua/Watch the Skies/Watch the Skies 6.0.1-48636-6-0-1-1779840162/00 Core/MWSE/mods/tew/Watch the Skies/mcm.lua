local configPath = "Watch the Skies"
local config = require("tew.Watch the Skies.config")
local metadata = toml.loadMetadata("Watch the Skies")
local events = require("tew.Watch the Skies.components.events") -- contains services table
local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

-- helper to register variables
local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config,
    }
end

-- create template
local template = mwse.mcm.createTemplate {
    name = metadata.package.name,
    headerImagePath = "\\Textures\\tew\\Watch the Skies\\WtS_logo.tga",
}

-- main page
local mainPage = template:createSideBarPage {
    label = "Main Settings",
    description = [[

A MWSE Lua-based weather overhaul for Morrowind. Makes weather more dynamic and immersive.

Features:
- Enable weather changes indoors
- Randomised cloud textures
- Dynamic weather timing
- Seasonal weather
- Dynamic daylight hours
- Particle & fog enhancements
]],
}

-- =========================
-- Core Settings
-- =========================
mainPage:createCategory { label = "Core Settings:" }
mainPage:createYesNoButton {
    label = "Enable Watch the Skies?",
    description = "Turns the 'Watch the Skies' mod on or off. Disabling will revert to default game weather and sky behavior.",
    variable = registerVariable("modEnabled"),
}
mainPage:createYesNoButton {
    label = "Enable debug mode?",
    description = "Activates detailed logging for troubleshooting. Requires restart.",
    variable = registerVariable("debugLogOn"),
    restartRequired = true,
}

-- =========================
-- Sky & Clouds
-- =========================
mainPage:createCategory { label = "Sky textures" }
mainPage:createYesNoButton {
    label = "Enable randomised cloud textures?",
    description = "Randomises cloud textures for a more varied and dynamic sky appearance.",
    variable = registerVariable("skyTexture"),
}
mainPage:createYesNoButton {
    label = "Use vanilla sky textures?",
    description = "Additionally use vanilla textures for more variation. Textures must be unpacked in the Data Files\\Textures folder.",
    variable = registerVariable("useVanillaSkyTextures"),
}
mainPage:createYesNoButton {
    label = "Enable variable rain textures?",
    description = "Uses a three-tiered system (light, medium, heavy) for rainy weather type based on max particles. Interops with AURA.\nVariable rain is dependent on sky texture randomisation option and will not work otherwise.\n\n!!! WARNING !!! This will temporarily overwrite your Weather Adjuster preset. Do not save the preset unless this option is off.",
    variable = registerVariable("variableRain"),
}

mainPage:createCategory { label = "Cloud speed" }
mainPage:createYesNoButton {
    label = "Enable randomised clouds speed?",
    description = "Varies the speed at which clouds move across the sky. Interops with AURA for wind sound effects.",
    variable = registerVariable("cloudSpeed"),
}
mainPage:createDropdown {
    label = "Cloud speed mode:",
    description = "Select cloud speed mode. 'Vanilla' keeps standard speed, 'Skies .iv' is faster and works with Skies .iv meshes.",
    options = {
        { label = "Vanilla",   value = 100 },
        { label = "Skies .iv", value = 500 },
    },
    variable = registerVariable("cloudSpeedMode"),
}

-- =========================
-- Weather Dynamics
-- =========================
mainPage:createCategory { label = "Weather dynamics:" }
mainPage:createYesNoButton {
    label = "Enable randomised hours between weather changes?",
    description = "Makes weather changes occur at random intervals for a more unpredictable environment.",
    variable = registerVariable("dynamicWeatherChanges"),
}
mainPage:createYesNoButton {
    label = "Enable weather changes in interiors?",
    description = "Allows interior areas to process weather changes. Best paired with AURA.",
    variable = registerVariable("interiorTransitions"),
}
mainPage:createYesNoButton {
    label = "Enable seasonal weather?",
    description = "Adjusts weather patterns according to the in-game season (month).",
    variable = registerVariable("seasonalWeather"),
}
mainPage:createYesNoButton {
    label = "Enable seasonal daytime hours?",
    description = "Changes the length of day/night to match the in-game season and latitude.",
    variable = registerVariable("seasonalDaytime"),
}

-- =========================
-- Particles & Fog
-- =========================
mainPage:createCategory { label = "Particles & fog:" }
mainPage:createYesNoButton {
    label = "Enable randomised max particles?",
    description = "Randomises the maximum number of weather particles.",
    variable = registerVariable("particleAmount"),
}
mainPage:createYesNoButton {
    label = "Enable randomised rain and snow particle meshes?",
    description = "Randomises the shapes of rain and snow particles for visual variety. Requires restart.",
    variable = registerVariable("particleMesh"),
    restartRequired = true,
}
mainPage:createYesNoButton {
    label = "Enable variable fog?",
    description = "Variable fog distance and offset per region and season in addition to weather.",
    variable = registerVariable("variableFog"),
}

-- onClose: start/stop only changed services + handle vanilla textures
template.onClose = function()
    local oldConfig = mwse.loadConfig(configPath) or {}
    mwse.saveConfig(configPath, config)

    -- Handle overall mod disable
    if not config.modEnabled then
        debugLog("Mod disabled — stopping all services.")
        for _, service in pairs(events.services) do
            service.stop()
        end
        return
    end

    -- Handle mod re-enabled
    if not oldConfig.modEnabled and config.modEnabled then
        debugLog("Mod enabled — starting enabled services.")
        for serviceName, service in pairs(events.services) do
            if config[serviceName] then
                debugLog(string.format("Starting service: %s", serviceName))
                service.init()
            end
        end
        return
    end

    -- Handle individual service toggles
    for serviceName, service in pairs(events.services) do
        local oldEnabled = oldConfig[serviceName]
        local newEnabled = config[serviceName]

        if oldEnabled ~= newEnabled then
            if newEnabled then
                debugLog(string.format("Enabling service: %s", serviceName))
                service.init()
            else
                debugLog(string.format("Disabling service: %s", serviceName))
                service.stop()
            end
        end
    end

    -- Handle vanilla sky textures toggle dynamically
    if oldConfig.useVanillaSkyTextures ~= config.useVanillaSkyTextures then
        local skyTexture = require("tew.Watch the Skies.services.skyTexture")
        if config.useVanillaSkyTextures then
            debugLog("Vanilla sky textures enabled — adding to texture table.")
            skyTexture.addVanillaTextures()
        else
            debugLog("Vanilla sky textures disabled — removing from texture table.")
            skyTexture.removeVanillaTextures()
        end
    end

    -- Handle cloud speed toggle dynamically
    if oldConfig.cloudSpeedMode ~= config.cloudSpeedMode then
        local cloudSpeed = require("tew.Watch the Skies.services.cloudSpeed")
        if config.cloudSpeed then
            cloudSpeed.restoreDefaults()
            cloudSpeed.init()
            debugLog("Cloud speed changed to " .. config.cloudSpeedMode)
        end
    end
end

mwse.mcm.register(template)
