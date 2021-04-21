local config = require("ImmersiveWait.config")
local common = require("ImmersiveWait.common")

local function createTableVar(id, number)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config,
        numbersOnly = number,
    }
end

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            "Immersive Wait\n" ..
            "v0.9.1\n" ..
            "\n" ..
            "This mod is intended to change waiting behavior into a pretty, animated experience. " ..
            "Instead of a progress bar, you will see time accelerating and passing smoothly, with all of the regeneration mechanics still in place. " ..
            "Fatigue will always be restored, whereas if you're in a location that allows resting, your character will automatically rest, regenerating magicka and health as well.\n" ..
            "Waiting is still impossible when in combat mode, but (for now, at least) nothing prevents you from moving or casting spells during wait. " ..
            "So it's up to you how realistically will you be using that.\n" ..
            "\n" ..
            "Caveat: resting using Immersive Wait is not recognized by the game and thus will not trigger events such as level-up." ..
            "\n" ..
            "Hover over an option to learn more about it.",
    }

    page:createTextField{
        label = "Normal timescale",
        description =
            "The timescale during normal gameplay. " ..
            "This represents the number of in-game seconds that will pass for each real-life second. " ..
            "With the default setting, time will pass 30 times faster in-game than in real life.\n" ..
            "\n" ..
            "Default: 30",
        numbersOnly = true,
        variable = createTableVar("normalTimescale", true),
        defaultSetting = 30,

        -- Call this function here so any change to normal timescale in the MCM will be immediately effective.
        callback = function(self)
            common.changeTimescale(self.variable.value, false)
            common.adjustTravelTimeIfConfigured()

            -- This is normally displayed on making a change, but the callback disables this, so let's manually add it back.
            tes3.messageBox("New value: \'%.0f\'", self.variable.value)
        end,
    }

    page:createTextField{
        label = "Wait timescale",
        description =
            "The timescale during Immersive Wait mode (as long as the Wait hotkey is held down). " ..
            "With the default setting, ten minutes will pass in-game for each real-life second in Immersive Wait mode.\n" ..
            "\n" ..
            "Default: 600",
        numbersOnly = true,
        variable = createTableVar("waitTimescale", true),
        defaultSetting = 600,
    }

    page:createSlider{
        label = "Safe distance",
        description =
            "The minimum distance to hostile NPCs/creatures required to deem the situation safe to wait. " ..
            "This is a workaround to the problem that mods cannot detect the 'combat' status directly.\n" ..
            "Setting this too low will break realism, letting you wait and regenerate fatigue with the opponent right in front of you.\n" ..
            "\n" ..
            "Default: 4000",
        numbersOnly = true,
        variable = createTableVar("safeDistance", true),
        defaultSetting = 4000,
        min = 1000, 
        max = 5000,
        jump = 200,
        step = 10
    }

    page:createKeyBinder{
        label = "Wait key",
        description =
            "The key to enter Immersive Wait mode. " ..
            "As long as the key is held down, time will speed up and regeneration will kick in for those statistics that can regenerate in the current circumstances " ..
            "(resting in cells where resting is legal, waiting otherwise). Releasing this key brings everything back to normal.\n" ..
            "\n" ..
            "Default: T (intended to use instead of the default wait key - rebind that somewhere else)",
        allowCombinations = false,
        variable = createTableVar("waitHotkey"),
        defaultSetting = {
            keyCode = tes3.scanCode.t,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
    }

    page:createYesNoButton{
        label = "Adjust travel time",
        description =
            "If enabled, the mod will adjust the time that elapses during travel proportionally with the configured normal timescale.\n" ..
            "If you're playing on a default normal timescale (30), you don't need to switch this on.\n" ..
            "\n" ..
            "With a timescale of 30, the boat ride from Ebonheart to Sadrith Mora will take 11 hours, as in vanilla Morrowind. With a timescale of 6, the same trip will take two hours. (Travel time is always an integer number of hours; this is a game limitation.)\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("adjustTravelTime"),
        defaultSetting = false,

        -- If the player changes this, the GMST will be changed immediately.
        callback = function(self)
            common.adjustTravelTimeIfConfigured()
        end,
    }

    page:createYesNoButton{
        label = "Display debug messages",
        description =
            "If enabled, the mod will display a message showing the new timescale each time you enter and exit Immersive Wait mode.\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("debugMessages"),
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("Immersive Wait")
template:saveOnClose("ImmersiveWait", config)

createPage(template)

mwse.mcm.register(template)
