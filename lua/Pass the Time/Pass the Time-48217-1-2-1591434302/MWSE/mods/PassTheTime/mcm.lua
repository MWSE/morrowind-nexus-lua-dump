local config = require("PassTheTime.config")
local common = require("PassTheTime.common")

local function createTableVar(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            "Pass the Time\n" ..
            "Version 1.2\n" ..
            "\n" ..
            "This mod allows you to speed up the passage of time when a configurable hotkey is held down. Pressing the control key along with the hotkey will speed up time even more, providing a more natural way to wait than the vanilla wait menu. The mod also allows you to configure the normal timescale.\n" ..
            "\n" ..
            "Hover over an option to learn more about it.",
    }

    page:createTextField{
        label = "Normal timescale",
        description =
            "The timescale during normal gameplay. This represents the number of in-game seconds that will pass for each real-life second. With the default setting, time will pass 30 times faster in-game than in real life.\n" ..
            "\n" ..
            "Default: 30",
        numbersOnly = true,
        variable = createTableVar("normalTimescale"),
        defaultSetting = 30,

        -- Call this function here so any change to normal timescale in the MCM will be immediately effective.
        callback = function(self)
            common.changeTimescale(self.variable.value, config.adjustFastTravelTime, false)

            -- This is normally displayed on making a change, but the callback disables this, so let's manually add it back.
            tes3.messageBox("New value: \'%.0f\'", self.variable.value)
        end,
    }

    page:createKeyBinder{
        label = "Assign Fast Forward key",
        description =
            "The hotkey to enter Fast Forward mode. The timescale will be changed to the Fast Forward timescale as long as the key is held down, and returned to the normal timescale when the key is released. Pressing control with the hotkey will apply the Turbo timescale instead.\n" ..
            "\n" ..
            "Default: Y",
        allowCombinations = false,
        variable = createTableVar("fastForwardHotkey"),
        defaultSetting = {
            keyCode = tes3.scanCode.y,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
    }

    page:createTextField{
        label = "Fast Forward timescale",
        description =
            "The timescale during Fast Forward mode (as long as the Fast Forward hotkey is held down). With the default setting, six minutes will pass in-game for each real-life second in Fast Forward mode.\n" ..
            "\n" ..
            "Default: 360",
        numbersOnly = true,
        variable = createTableVar("fastForwardTimescale"),
        defaultSetting = 360,
    }

    page:createTextField{
        label = "Turbo timescale",
        description =
            "The timescale during Turbo mode (when control+hotkey is held down). With the default setting, one hour will pass in-game for each real-life second in Turbo mode.\n" ..
            "\n" ..
            "Default: 3600",
        numbersOnly = true,
        variable = createTableVar("turboTimescale"),
        defaultSetting = 3600,
    }

    page:createYesNoButton{
        label = "Adjust fast travel time",
        description =
            "If enabled, the mod will adjust the time that elapses during fast travel proportionally with the configured normal timescale.\n" ..
            "\n" ..
            "With a timescale of 30, the boat ride from Ebonheart to Sadrith Mora will take 11 hours, as in vanilla Morrowind. With a timescale of 6, the same trip will take two hours. (Fast travel time is always an integer number of hours; this is a game limitation.)\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("adjustFastTravelTime"),
        defaultSetting = false,

        -- If the player changes this to true, the GMST will be changed immediately.
        callback = function(self)
            common.changeFastTravelTime(self.variable.value)
        end,
    }

    page:createYesNoButton{
        label = "Display messages on timescale change",
        description =
            "If enabled, the mod will display a message showing the new timescale each time you enter and exit Fast Forward or Turbo mode.\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("displayMessages"),
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("Pass the Time")
template:saveOnClose("PassTheTime", config)

createPage(template)

mwse.mcm.register(template)