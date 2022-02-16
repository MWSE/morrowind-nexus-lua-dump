local conf = require("mer.midnightOil.config")
local modName = "The Midnight Oil"

local function registerMCM()
    local config = conf.getConfig()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(conf.configPath, config)
    template:register()

    local page = template:createSideBarPage{
        label = "Settings",
        description = (
            "This mod overhauls lights by adding the following features:\n\n" ..
            "- Lights will no longer be destroyed when they run out of fuel or when they are submerged underwater.\n\n" ..
            "- Refuel lights by purchasing candle and oil refills from traders.\n\n" ..
            "- Hold down a hotkey (default shift) when activating a light to toggle it on or off. This works for both carryable and static lights.\n\n"..
            "- Lanterns and torches in towns will automatically turn off during the day and turn back on at night."
        )
    }

    do
        local generalCategory = page:createCategory("General Settings")

        generalCategory:createYesNoButton{
            label = "Enable mod",
            description = "Turn this mod on or off.",
            variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
        }


        generalCategory:createKeyBinder{
            label = "Hotkey for light toggle",
            description = "Hold this key down when activating a carryable light to toggle it on or off.",
            allowCombinations = true,
            variable = mwse.mcm:createTableVariable{ id = "toggleHotkey", table = config }
        }
    end

    do
        local nightDayCategory = page:createCategory("Town Lights Day/Night Toggle")

        nightDayCategory:createYesNoButton{
            label = "Toggle lights in settlements only",
            description = "If enabled, lights will only turn off during the day if they are in a cell where resting is illegal.",
            variable = mwse.mcm.createTableVariable{ id = "settlementsOnly", table = config }
        }
        nightDayCategory:createYesNoButton{
            label = "Toggle static lights only",
            description = "If enabled, lights will only turn off during the day if they are static (can not be picked up). If disabled, lights you place outdoors will toggle on and off based on time of day. Toggling a light manually will delay this untl the next day.",
            variable = mwse.mcm.createTableVariable{ id = "staticLightsOnly", table = config }
        }

        nightDayCategory:createSlider{
            label = "Dawn Hour",
            description = "The hour of the day lanterns in town will start to turn off.",
            min = 0,
            max = 12,
            step = 1,
            jump = 1,
            variable = mwse.mcm.createTableVariable{ id = "dawnHour", table = config }
        }

        nightDayCategory:createSlider{
            label = "Dusk Hour",
            description = "The hour of the day lanterns in town will start to turn on.",
            min = 12,
            max = 24,
            step = 1,
            jump = 1,
            variable = mwse.mcm.createTableVariable{ id = "duskHour", table = config }
        }

        nightDayCategory:createYesNoButton{
            label = "Use Variance",
            description = "If selected, lanterns will turn on/off over a period of time instead of all at once.",
            variable = mwse.mcm.createTableVariable{ id = "useVariance", table = config }
        }

        nightDayCategory:createSlider{
            label = "Variance in Minutes",
            description = "The interval in which lanterns will start turning on/off.",
            min = 1,
            max = 60,
            step = 1,
            jump = 10,
            variable = mwse.mcm.createTableVariable{ id = "varianceInMinutes", table = config }
        }
    end

end
event.register("modConfigReady", registerMCM)