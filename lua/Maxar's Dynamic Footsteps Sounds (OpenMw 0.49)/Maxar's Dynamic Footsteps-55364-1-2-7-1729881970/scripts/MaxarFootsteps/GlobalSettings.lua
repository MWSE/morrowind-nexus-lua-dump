local Interfaces = require('openmw.interfaces')

Interfaces.Settings.registerGroup({
    key = "Settings_foot",
    page = "maxarsFootsteps",
    l10n = "MaxarsFootsteps",
    name = "Maxar's Dynamic Footsteps",
    permanentStorage = true,
    settings = {
        {
            key = "volume",
            default = 100,
            renderer = "number",
            name = "Footsteps volume",
            argument = {
                integer = true,
                min = 0,
                max = 500,
            },
        },
        {
            key = "imUsingController",
            default = false,
            renderer = "checkbox",
            name = "Footsteps timing based on actual speed.",
        },
        {
            key = "baseRunningSpeed",
            default = 105,
            renderer = "number",
            name = "Base Running Speed",
            argument = {
                integer = false,
                min = 1,
                max = 500,
            },
        },
        {
            key = "baseWalkingSpeed",
            default = 70,
            renderer = "number",
            name = "Base Walking Speed",
            argument = {
                integer = true,
                min = 1,
                max = 500,
            },
        },
        {
            key = "baseBeastRunningSpeed",
            default = 85,
            renderer = "number",
            name = "Base Beast Running Speed",
            argument = {
                integer = true,
                min = 1,
                max = 500,
            },
        },
        {
            key = "baseBeastWalkingSpeed",
            default = 53,
            renderer = "number",
            name = "Base Beast Walking Speed",
            argument = {
                integer = true,
                min = 1,
                max = 500,
            },
        },
        {
            key = "baseSneakingSpeed",
            default = 54,
            renderer = "number",
            name = "Base Sneaking Speed",
            argument = {
                integer = true,
                min = 1,
                max = 500,
            },
        },
        {
            key = "baseBeastSneakingSpeed",
            default = 54,
            renderer = "number",
            name = "Base Beast Sneaking Speed",
            argument = {
                integer = true,
                min = 1,
                max = 500,
            },
        },
        {
            key = "footstepInterval",
            default = 1.0,
            renderer = "number",
            name = "Footstep Interval",
            argument = {
                integer = false,
                min = 0.1,
                max = 5.0,
            },
        },
        {
            key = "lightArmorVolume",
            default = 50,
            renderer = "number",
            name = "Light Armor Volume",
            argument = {
                integer = true,
                min = 0,
                max = 500,
            },
        },
        {
            key = "mediumArmorVolume",
            default = 70,
            renderer = "number",
            name = "Medium Armor Volume",
            argument = {
                integer = true,
                min = 0,
                max = 500,
            },
        },
        {
            key = "heavyArmorVolume",
            default = 90,
            renderer = "number",
            name = "Heavy Armor Volume",
            argument = {
                integer = true,
                min = 0,
                max = 500,
            },
        }
    },
})