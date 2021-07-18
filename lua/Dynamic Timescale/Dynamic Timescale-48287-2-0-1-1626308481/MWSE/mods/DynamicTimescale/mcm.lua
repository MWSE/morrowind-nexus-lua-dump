local modInfo = require("DynamicTimescale.modInfo")
local config = require("DynamicTimescale.config")
local common = require("DynamicTimescale.common")

local function createTableVar(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config,
    }
end

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod changes how quickly time passes in-game depending on where you are and what you're doing.\n" ..
            "\n" ..
            "The timescale represents how quickly in-game time passes as a multiple of real time. A timescale of 30 means that 30 seconds of in-game time pass for each second of real time.\n" ..
            "\n" ..
            "The settings on this page are listed in order from highest to lowest priority. In other words, the timescale priority is: turbo, fast forward, combat, sneaking, wary, still, town interior, dungeon, town exterior, named location, wilderness.\n" ..
            "\n" ..
            "Hover over a setting to learn more about it.",
    }

    local categoryFastForward = page:createCategory("Fast Forward Settings")

    categoryFastForward:createKeyBinder{
        label = "Assign Fast Forward key",
        description =
            "The hotkey to enter Fast Forward mode. The Fast Forward timescale will be applied as long as the key is held down. If the control key is also pressed, the Turbo timescale will be applied instead.\n" ..
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

    categoryFastForward:createTextField{
        label = "Turbo timescale",
        description =
            "The timescale during Turbo mode (control+hotkey is held down).\n" ..
            "\n" ..
            "Default: 3600",
        numbersOnly = true,
        variable = createTableVar("turboTimescale"),
        defaultSetting = 3600,
    }

    categoryFastForward:createTextField{
        label = "Fast Forward timescale",
        description =
            "The timescale during Fast Forward mode (hotkey is held down without the control key).\n" ..
            "\n" ..
            "Default: 360",
        numbersOnly = true,
        variable = createTableVar("fastForwardTimescale"),
        defaultSetting = 360,
    }

    local categoryCombat = page:createCategory("Combat Settings")

    categoryCombat:createYesNoButton{
        label = "Enable combat timescale",
        description =
            "If enabled, the mod will apply the combat timescale when you're in combat. If disabled, the combat timescale will never be applied.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("enableCombatTimescale"),
        defaultSetting = true,
    }

    categoryCombat:createTextField{
        label = "Combat timescale",
        description =
            "The timescale while you're in combat.\n" ..
            "\n" ..
            "Default: 10",
        numbersOnly = true,
        variable = createTableVar("combatTimescale"),
        defaultSetting = 10,
    }

    local categorySneak = page:createCategory("Sneak Settings")

    categorySneak:createYesNoButton{
        label = "Enable sneaking timescale",
        description =
            "If enabled, the mod will apply the sneaking timescale when you're sneaking. If disabled, the sneaking timescale will never be applied.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("enableSneakingTimescale"),
        defaultSetting = true,
    }

    categorySneak:createTextField{
        label = "Sneaking timescale",
        description =
            "The timescale while you're sneaking. This timescale applies whenever you're in sneak mode, whether you're moving or not.\n" ..
            "\n" ..
            "Default: 10",
        numbersOnly = true,
        variable = createTableVar("sneakingTimescale"),
        defaultSetting = 10,
    }

    local categoryWary = page:createCategory("Wariness Settings")

    categoryWary:createYesNoButton{
        label = "Enable wary timescale",
        description =
            "If enabled, the mod will apply the wary timescale when you're \"wary.\" You're wary for several seconds after certain events occur. If disabled, the wary timescale will never be applied.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("enableWaryTimescale"),
        defaultSetting = true,
    }

    categoryWary:createTextField{
        label = "Wary timescale",
        description =
            "The timescale while you're wary.\n" ..
            "\n" ..
            "Default: 10",
        numbersOnly = true,
        variable = createTableVar("waryTimescale"),
        defaultSetting = 10,
    }

    categoryWary:createSlider{
        label = "Wary time limit",
        description =
            "The number of seconds after any of the enabled wariness-triggering actions occur during which you'll be wary.\n" ..
            "\n" ..
            "Default: 10",
        variable = createTableVar("waryTime"),
        min = 1,
        max = 60,
        defaultSetting = 10,
    }

    categoryWary:createYesNoButton{
        label = "Attacks trigger wariness",
        description =
            "If enabled, attacking or being attacked with weapon or fists will trigger wariness.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("waryOnAttacks"),
        defaultSetting = true,
    }

    categoryWary:createYesNoButton{
        label = "Spellcasting triggers wariness",
        description =
            "If enabled, attempting to cast a spell, whether successful or not, will trigger wariness.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("waryOnSpellCast"),
        defaultSetting = true,
    }

    categoryWary:createYesNoButton{
        label = "Damage triggers wariness",
        description =
            "If enabled, receiving a certain amount of damage in a single attack (or other damaging event) will trigger wariness.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("waryOnDamage"),
        defaultSetting = true,
    }

    categoryWary:createSlider{
        label = "Damage threshold",
        description =
            "The percentage of your max health you must take as damage in a single attack (or other damaging event) in order for the damage to trigger wariness.\n" ..
            "\n" ..
            "Default: 5",
        variable = createTableVar("damageThreshold"),
        max = 100,
        defaultSetting = 5,
    }

    categoryWary:createYesNoButton{
        label = "Activating objects triggers wariness",
        description =
            "If enabled, activating any object (e.g. taking an item, speaking with an NPC, opening a door) will trigger wariness.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("waryOnActivate"),
        defaultSetting = true,
    }

    local categoryStill = page:createCategory("Stillness Settings")

    categoryStill:createYesNoButton{
        label = "Enable still timescale",
        description =
            "If enabled, the mod will apply the still timescale when you've been still for a certain length of time. If disabled, the still timescale will never be applied.\n" ..
            "\n" ..
            "Default: yes",
        variable = createTableVar("enableStillTimescale"),
        defaultSetting = true,
    }

    categoryStill:createTextField{
        label = "Still timescale",
        description =
            "The timescale while you have been still for a certain length of time.\n" ..
            "\n" ..
            "Default: 5",
        numbersOnly = true,
        variable = createTableVar("stillTimescale"),
        defaultSetting = 5,
    }

    categoryStill:createSlider{
        label = "Still time delay",
        description =
            "The number of seconds you must remain still before the still timescale is applied.\n" ..
            "\n" ..
            "Default: 5",
        variable = createTableVar("stillTime"),
        max = 60,
        defaultSetting = 5,
    }

    local categoryCell = page:createCategory("Cell Settings")

    categoryCell:createTextField{
        label = "Town interior timescale",
        description =
            "The timescale while you're in interior cells in civilized areas.\n" ..
            "\n" ..
            "Specifically, this applies in any interior cell that's illegal to sleep in.\n" ..
            "\n" ..
            "Default: 10",
        numbersOnly = true,
        variable = createTableVar("interiorTimescale"),
        defaultSetting = 10,
    }

    categoryCell:createTextField{
        label = "Dungeon timescale",
        description =
            "The timescale while you're in dungeons.\n" ..
            "\n" ..
            "Specifically, this applies in any interior cell that's legal to sleep in.\n" ..
            "\n" ..
            "Default: 15",
        numbersOnly = true,
        variable = createTableVar("dungeonTimescale"),
        defaultSetting = 15,
    }

    categoryCell:createTextField{
        label = "Town exterior timescale",
        description =
            "The timescale while you're in exterior cells in civilized areas.\n" ..
            "\n" ..
            "Specifically, this applies in any exterior cell that's illegal to sleep in. It also applies in the \"exterior\" Mournhold cells, which are technically interiors.\n" ..
            "\n" ..
            "Default: 20",
        numbersOnly = true,
        variable = createTableVar("townTimescale"),
        defaultSetting = 20,
    }

    categoryCell:createTextField{
        label = "Named location timescale",
        description =
            "The timescale while you're in named exterior locations such as major ruins or strongholds.\n" ..
            "\n" ..
            "Specifically, this applies in any exterior cell that's legal to sleep in but has a specific name (e.g. Ald Daedroth, Valenvaryon, Bal Isra).\n" ..
            "\n" ..
            "Default: 30",
        numbersOnly = true,
        variable = createTableVar("namedTimescale"),
        defaultSetting = 30,
    }

    categoryCell:createTextField{
        label = "Wilderness timescale",
        description =
            "The timescale while you're in unnamed wilderness cells.\n" ..
            "\n" ..
            "Specifically, this applies in any exterior cell that's legal to sleep in and has no specific name (e.g. Bitter Coast Region).\n" ..
            "\n" ..
            "Default: 120",
        numbersOnly = true,
        variable = createTableVar("wildernessTimescale"),
        defaultSetting = 120,

        -- Call this function here so any change to the wilderness timescale will also (depending on settings) immediately adjust fast travel time.
        callback = function()
            common.changeFastTravelTime(config.wildernessTimescale)

            -- This is normally displayed on making a change, but the callback disables this, so let's manually add it back.
            tes3.messageBox("New value: \'%.0f\'", config.wildernessTimescale)
        end,
    }

    local categoryNight = page:createCategory("Night Settings")

    categoryNight:createTextField{
        label = "Night timescale multiplier",
        description =
            "Whichever of the above timescales is applied will be multiplied by this value at night (after the night beginning hour or before the night ending hour). The night multiplier will never be applied to the Fast Forward or Turbo timescales.\n" ..
            "\n" ..
            "Set this above 1.0 to make time pass more quickly at night than during the day, or set it below 1.0 to make time pass more slowly at night.\n" ..
            "\n" ..
            "Default: 1.0",
        numbersOnly = true,
        variable = createTableVar("nightMultiplier"),
        defaultSetting = 1.0,
    }

    categoryNight:createTextField{
        label = "Night begins",
        description =
            "The hour at which night begins and the night timescale multiplier is applied. (This affects only when the multiplier is applied, not the actual sunset time.)\n" ..
            "\n" ..
            "This value is based on a 24-hour clock, so, for example, 18 is 18:00 (6 PM).\n" ..
            "\n" ..
            "Decimal fractions of an hour can also be specified. For example, 19.75 is 19:45 (7:45 PM).\n" ..
            "\n" ..
            "Default: 18",
        numbersOnly = true,
        variable = createTableVar("nightBegin"),
        defaultSetting = 18,
    }

    categoryNight:createTextField{
        label = "Night ends",
        description =
            "The hour at which night ends and the night timescale multiplier is no longer applied. (This affects only when the multiplier is no longer applied, not the actual sunrise time.)\n" ..
            "\n" ..
            "This value is based on a 24-hour clock, so, for example, 6 is 06:00 (6 AM).\n" ..
            "\n" ..
            "Decimal fractions of an hour can also be specified. For example, 5.25 is 05:15 (5:15 AM).\n" ..
            "\n" ..
            "Default: 6",
        numbersOnly = true,
        variable = createTableVar("nightEnd"),
        defaultSetting = 6,
    }

    local categoryMisc = page:createCategory("Miscellaneous Settings")

    categoryMisc:createYesNoButton{
        label = "Adjust fast travel time",
        description =
            "If enabled, the mod will adjust the time that elapses during fast travel proportionally with the configured wilderness timescale.\n" ..
            "\n" ..
            "With a timescale of 30, the boat ride from Ebonheart to Sadrith Mora will take 11 hours, as in vanilla Morrowind. With a timescale of 120, the same trip will take 46 hours. (Fast travel time is always an integer number of hours; this is a game limitation.)\n" ..
            "\n" ..
            "Travel time when traveling via gondola will be based on the town exterior timescale rather than the wilderness timescale, since the travel takes place entirely within a city.\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("adjustFastTravelTime"),
        defaultSetting = false,

        -- If the player changes this to true, the GMST will be changed immediately.
        callback = function()
            common.changeFastTravelTime(config.wildernessTimescale)
        end,
    }

    categoryMisc:createYesNoButton{
        label = "Treat \"Kogoruhn, Charma's Breath\" as wilderness",
        description =
            "If enabled, the cell \"Kogoruhn, Charma's Breath\" will be treated as a wilderness cell rather than a dungeon cell. (This cell connects the stronghold of Kogoruhn to a geographically distant exit.)\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("charmasBreathWilderness"),
        defaultSetting = false,
    }

    categoryMisc:createYesNoButton{
        label = "Display messages on timescale change",
        description =
            "If enabled, the mod will display a message showing the new timescale each time the timescale changes.\n" ..
            "\n" ..
            "Default: no",
        variable = createTableVar("displayMessages"),
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("Dynamic Timescale")
template:saveOnClose("DynamicTimescale", config)

createPage(template)

mwse.mcm.register(template)