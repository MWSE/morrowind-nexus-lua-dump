local config = require("DirectionalSunrays.config")

----------------------
-- MCM Template --
----------------------

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Directional Sunrays"}
    template:saveOnClose("DirectionalSunrays", config)

    -- Preferences Page
    local preferences = template:createSideBarPage{
        label = "Settings",
        noScroll = true,
    }

    preferences.sidebar:createCategory{ label = "Directional Sunrays" }
    preferences.sidebar:createInfo{ text = "Hides or reduces the intensity of Glow in the Dahrk's sunrays depending on where the sun currently is." }

    -- Feature Toggles
    local settings = preferences:createCategory{}
    settings:createOnOffButton{
        label = "Enabled",
        description = "Enables or disables the mod.\nRequires Reload.\n\nDefault: On",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config
        },
    }

    settings:createSlider{
        label = "Outer Limit: %s Degrees",
        description = "Rays that are greater than this angle of the sun will not shine at all. Rays that are in-between the Inner Limit and Outer Limit will still shine, but less brightly." ..
                        "\nRequires Reload.\n\nDefault: 70",
        min = 45,
        max = 180,
        variable = mwse.mcm.createTableVariable{ id = "outerLimit", table = config }
    }

    settings:createSlider{
        label = "Inner Limit: %s Degrees",
        description = "Sunrays within this angle of the sun will shine at full intensity. If this value is greater than the Outer Limit, then Directional Sunrays will treat it as being equal to the Outer Limit" ..
                        "\nRequires Reload.\n\nDefault: 35",
        min = 0,
        max = 180,
        variable = mwse.mcm.createTableVariable{ id = "innerLimit", table = config }
    }

    template:createExclusionsPage{
        label = "Nonstandard Windows",
        description = "Glow in the Dahrk's meshes have the angle of each sunray specified in the NIF files, allowing for Directional Sunrays to easily determine whether they should be visible. However, other mods might have made the sunrays in their meshes differently, which will cause this approach to fail." ..
                        " Selecting an object in this page will cause Directional Sunrays to instead look at every vertex of that object's sunrays to determine their direction. This approach will work in more cases, but is much more expensive and can lead to a noticeable loss in performance if a cell has many such objects.",
        leftListLabel = "Nonstandard Windows",
        rightListLabel = "Statics and Activators",
        variable = mwse.mcm.createTableVariable{ id = "nonstandardMeshes", table = config },
        filters = {
            { type = "Object", objectType = { tes3.objectType.activator, tes3.objectType.static } },
        }
    }

    template:createExclusionsPage{
        label = "Ignored Windows",
        description = "If a window's sunrays do not work with Directional Sunrays or should not be affected by it for some reason, then Directional Sunrays can be set to ignore the object here.",
        leftListLabel = "Ignored Windows",
        rightListLabel = "Statics and Activators",
        variable = mwse.mcm.createTableVariable{ id = "ignoredMeshes", table = config },
        filters = {
            { type = "Object", objectType = { tes3.objectType.activator, tes3.objectType.static } },
        }
    }

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)