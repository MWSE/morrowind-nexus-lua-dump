local config = require("BipedalCreatureSounds.config")

----------------------
-- MCM Template --
----------------------

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Bipedal Creature Sounds"}
    template:saveOnClose("BipedalCreatureSounds", config)

    -- Preferences Page
    local preferences = template:createSideBarPage{
        label = "Settings",
        noScroll = true,
    }

    preferences.sidebar:createCategory{ label = "Bipedal Creature Sounds" }
    preferences.sidebar:createInfo{ text = "Allows bipedal creatures to make their \"moan\" sound (if it exists) in the middle of some idle animations or at random rather than remaining completely silent unless they are moving or in combat." }

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
        label = "Minimum Wait for a Random Sound: %s Seconds",
        description = "The minimum time between instances of a bipedal creature playing its moan sound if it is not set to use the idle3 or idle4 animation groups." ..
                        "\n\nDefault: 20",
        min = 5,
        max = 30,
        variable = mwse.mcm.createTableVariable{ id = "minimumWait", table = config }
    }

    settings:createSlider{
        label = "Maximum Wait for a Random Sound: %s Seconds",
        description = "The maximum time between instances of a bipedal creature playing its moan sound if it is not set to use the idle3 or idle4 animation groups." ..
                        "\n\nDefault: 40",
        min = 30,
        max = 60,
        variable = mwse.mcm.createTableVariable{ id = "maximumWait", table = config }
    }

    settings:createSlider{
        label = "Random Sound Chance: %s%%",
        description = "The chance of a bipedal creature playing its moan sound after waiting if it is not set to use the idle3 or idle4 animation groups." ..
                        "\n\nDefault: 66",
        min = 0,
        max = 100,
        variable = mwse.mcm.createTableVariable{ id = "chance", table = config }
    }

    settings:createSlider{
        label = "Attack Roar Chance: %s%%",
        description = "The chance of a bipedal creature playing its roar sound when attacking." ..
                        "\n\nDefault: 33",
        min = 0,
        max = 100,
        variable = mwse.mcm.createTableVariable{ id = "roarChance", table = config }
    }

    template:createExclusionsPage{
        label = "Blacklist",
        leftListLabel = "Blacklisted Creatures",
        rightListLabel = "Bipedal Creatures",
        variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config },
        filters = {
            { callback = (function ()
                local creatures = {}
                for creature in tes3.iterateObjects(tes3.objectType.creature) do
                 ---@cast creature tes3creature
                    if creature.biped then table.insert(creatures, creature.id) end
                end

                table.sort(creatures)
                return creatures
            end )}
        }
    }

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)