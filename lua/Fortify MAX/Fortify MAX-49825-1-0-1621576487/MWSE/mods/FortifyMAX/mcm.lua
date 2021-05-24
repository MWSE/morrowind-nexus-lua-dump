local modInfo = require("FortifyMAX.modInfo")
local config = require("FortifyMAX.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod causes the Fortify Magicka and Fortify Fatigue magic effects to affect the maximum as well as the current stat. In other words, it does for these effects what the \"Fortify Maximum Health\" feature of Morrowind Code Patch does for Fortify Health.\n" ..
            "\n" ..
            "Note that these changes apply only to the player, not to NPCs or creatures.\n" ..
            "\n" ..
            "Hover over each setting to learn more about it.",
    }

    page:createOnOffButton{
        label = "Magicka component",
        description =
            "Enables the magicka component of the mod. Fortify Magicka will increase maximum as well as current magicka. This makes Fortify Magicka effects more useful, and prevents a couple exploits.\n" ..
            "\n" ..
            "Note that Fortify Magicka is still distinct from the Fortify Maximum Magicka effect, which affects the \"magicka multiplier\" used along with intelligence to calculate max magicka.\n" ..
            "\n" ..
            "Changing this setting requires restarting Morrowind.\n" ..
            "\n" ..
            "Default: on",
        variable = mwse.mcm.createTableVariable{
            id = "magicka",
            table = config,
        },
        defaultSetting = true,
        restartRequired = true,
    }

    page:createOnOffButton{
        label = "Fatigue component",
        description =
            "Enables the fatigue component of the mod. Fortify Fatigue will increase maximum as well as current fatigue. This makes Fortify Fatigue effects more useful, and prevents a couple exploits.\n" ..
            "\n" ..
            "Changing this setting requires restarting Morrowind.\n" ..
            "\n" ..
            "Default: on",
        variable = mwse.mcm.createTableVariable{
            id = "fatigue",
            table = config,
        },
        defaultSetting = true,
        restartRequired = true,
    }

    page:createOnOffButton{
        label = "Attribute-modifying effect tweaks",
        description =
            "If enabled, the mod will tweak the way the Restore and Damage Attribute effects work, in order to prevent magicka or fatigue from being wrongly reset to vanilla in certain circumstances.\n" ..
            "\n" ..
            "These tweaks are very minor; see the readme for more details about exactly what this setting does. It is highly suggested to leave this feature enabled unless you've disabled both the magicka and fatigue components of the mod.\n" ..
            "\n" ..
            "Changing this setting requires restarting Morrowind.\n" ..
            "\n" ..
            "Default: on",
        variable = mwse.mcm.createTableVariable{
            id = "spellTick",
            table = config,
        },
        defaultSetting = true,
        restartRequired = true,
    }

    page:createOnOffButton{
        label = "Enable logging",
        description =
            "This option enables extensive logging to MWSE.log.\n" ..
            "\n" ..
            "Default: off",
        variable = mwse.mcm.createTableVariable{
            id = "logging",
            table = config,
        },
        defaultSetting = false,
    }
end

local template = mwse.mcm.createTemplate("Fortify MAX")
template:saveOnClose("FortifyMAX", config)

createPage(template)

mwse.mcm.register(template)