local configPath = "Revered Dead" -- The name of the config json file of your mod
local config = require("Revered Dead.config")

local function registerModConfig()
    -- Create the top level component Template
    -- The name will be displayed in the mod list on the lefthand pane
    local template = mwse.mcm.createTemplate({ name = config.modName })

    -- Save config options when the mod config menu is closed
    template:saveOnClose(configPath, config)

    -- Create a simple container Page under Template
    local settings = template:createPage({ label = "Settings" })

    settings:createYesNoButton({
        label = "Enable Mod",
        description = "Enable the mod's functionality.",
        variable = mwse.mcm:createTableVariable({ id = "enabled", table = config }),
    })

    settings:createYesNoButton({
        label = "Warn when entering sacred burial spaces?",
        description = "Notify the player when entering an ancestral tomb where stealing may be taboo.",
        variable = mwse.mcm:createTableVariable({ id = "warnOnTombEntry", table = config }),
    })

    settings:createYesNoButton({
        label = "Forbid trade of plundered mortal remains?",
        description = "All but the most immoral merchants will refuse to buy skulls and bones looted from tombs.",
        variable = mwse.mcm:createTableVariable({ id = "mortalRemainsForbidden", table = config }),
    })

    settings:createSlider{
        label = "Grave Good Recognition Value",
        description = "The minimum value at which people will be able to recognise an item is plundered from a tomb.",
        min = 0,
        max = 10000,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "minSuspiciousValue",
            table = config
        }
    }
    settings:createSlider{
        label = "Grave Good Alert Value",
        description = "The minimum value at which people will be particularly offended by a plundered grave good.",
        min = 0,
        max = 10000,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "minAlarmingValue",
            table = config
        }
    }

    settings:createSlider{
        label = "Graverobbing Bounty",
        description = "The fine levied against grave robbers, in addition to the value of goods taken.",
        min = 0,
        max = 10000,
        step = 10,
        jump = 100,
        variable = mwse.mcm.createTableVariable{
            id = "graveRobberBounty",
            table = config
        }
    }

    template:register()
end

event.register("modConfigReady", registerModConfig)