local config = require("TLADLights.config")
local modInfo = require("TLADLights.modInfo")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod implements highly customizable light source overrides. By default it changes the game's light sources to match those in True Lights and Darkness. It also has options implementing the \"Necro edit\" settings and the \"logical flicker\" (AetherSeraph9 edit) settings.\n" ..
            "\n" ..
            "Each light attribute (such as color, radius, time, name, weight, value, flicker and more) is individually customizable. So, for example, you could choose to have TLAD radius and time values, Necro edit colors, AetherSeraph9's flicker settings, and vanilla light names and weight/value.\n" ..
            "\n" ..
            "This mod is intended to work well with Let There Be Darkness. Just disable the light source overrides in LTBD to avoid any conflict. (You can still disable negative lights, lights without a mesh and/or flicker with LTBD.)\n" ..
            "\n" ..
            "Hover over each setting to learn more about it. Any changes will require restarting Morrowind.",
    }

    page:createDropdown{
        label = "Name",
        description =
            "Choose between vanilla, TLAD and Necro edit light names.\n" ..
            "\n" ..
            "TLAD changes light names in a couple ways. Word order is adjusted (e.g. \"Candlestick Bamboo\") so that lights of the same type will cluster together in your inventory. Also, more descriptive terms are added, such as \"Poor\" and \"High Quality\" for torches, and color names for some candles.\n" ..
            "\n" ..
            "The Necro edit names maintain most of TLAD's changes, but remove the color names.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
            {
                label = "Necro edit",
                value = "necro",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "name",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Weight",
        description =
            "Choose between vanilla and TLAD weights for light sources.\n" ..
            "\n" ..
            "TLAD adjusts the weights of a number of lights for greater consistency and realism.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "weight",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Value",
        description =
            "Choose between vanilla and TLAD gold values for light sources.\n" ..
            "\n" ..
            "Like with weights, TLAD adjusts the gold value of some lights to make more sense.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "value",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Time",
        description =
            "Choose between vanilla and TLAD time values for lights.\n" ..
            "\n" ..
            "The \"time\" value represents how long a light will last before it burns out. TLAD's changes in this area generally increase times, often considerably. This has the effect of making lights more useful, because they burn out less frequently.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "time",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Radius",
        description =
            "Choose between vanilla and TLAD light radius.\n" ..
            "\n" ..
            "TLAD increases the radius of many lights, making them appear brighter and illuminate a wider area.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "radius",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Color",
        description =
            "Choose between vanilla, TLAD and Necro edit light colors.\n" ..
            "\n" ..
            "TLAD makes many changes to light colors. Some of these changes are relatively minor tweaks, while some are more radical changes that can substantially change the mood of some areas of the game.\n" ..
            "\n" ..
            "The Necro edit tones down some of TLAD's more radical color changes, preserving more of a vanilla feel.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
            {
                label = "Necro edit",
                value = "necro",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "color",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Dynamic flag",
        description =
            "Choose between vanilla and TLAD settings for the \"dynamic\" flag for light sources.\n" ..
            "\n" ..
            "The dynamic flag determines whether a light affects dynamically moving objects, such as NPCs. TLAD changes this flag for a few lights.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "dynamic",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Off by default flag",
        description =
            "Choose between vanilla and TLAD settings for the \"off by default\" flag for light sources.\n" ..
            "\n" ..
            "This flag determines whether a light will actually emit light when it's encountered in the world. TLAD turns this flag off for a couple lights, meaning that they will now emit light.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "defaultOff",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Flicker",
        description =
            "Choose how to handle the \"flicker effect\" possessed by many lights.\n" ..
            "\n" ..
            "In vanilla, many lights flicker, and TLAD makes very few changes to flicker settings. The Necro edit removes the flicker effect from many lights (with flicker settings drawn from Di.still.ed Lights).\n" ..
            "\n" ..
            "The \"logical flicker\" settings were created by AetherSeraph9. These settings apply flicker in a more consistent, realistic way.\n" ..
            "\n" ..
            "If you wish to disable flicker entirely, then set this setting to vanilla and disable flicker with Let There Be Darkness.",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "TLAD",
                value = "tlad",
            },
            {
                label = "Necro edit",
                value = "necro",
            },
            {
                label = "Logical",
                value = "logical",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "flicker",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "tlad",
    }

    page:createDropdown{
        label = "Mesh",
        description =
            "Choose between vanilla and Glowing Flames meshes.\n" ..
            "\n" ..
            "Glowing Flames includes a \"No More Lightless Flames\" plugin which assigns certain lights new meshes. This prevents those lights from glowing or having visible flames when they shouldn't.\n" ..
            "\n" ..
            "The \"Glowing Flames\" option replicates that plugin, allowing you to disable the plugin while still using the correct Glowing Flames meshes for the affected lights.\n" ..
            "\n" ..
            "This REQUIRES the assets (meshes and textures) from Glowing Flames. Using this option without having the Glowing Flames assets installed will result in errors. If you're not using Glowing Flames, keep this option set to \"Vanilla\".",
        options = {
            {
                label = "Vanilla",
                value = "vanilla",
            },
            {
                label = "Glowing Flames",
                value = "glowing",
            },
        },
        variable = mwse.mcm.createTableVariable{
            id = "mesh",
            table = config,
        },
        restartRequired = true,
        defaultSetting = "vanilla",
    }

    page:createOnOffButton{
        label = "Debug mode",
        description =
            "This option enables extensive logging to MWSE.log.\n" ..
            "\n" ..
            "Default: off",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("TLAD Lights")
template:saveOnClose("TLADLights", config)

createPage(template)

mwse.mcm.register(template)