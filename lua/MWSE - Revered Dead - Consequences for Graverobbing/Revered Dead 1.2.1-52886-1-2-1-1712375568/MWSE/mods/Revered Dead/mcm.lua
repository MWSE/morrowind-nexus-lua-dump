local config = require("Revered Dead.config")

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = config.modName })

    template:saveOnClose(config.modName, config)
    template:register()

    local settings = template:createSideBarPage({
        label = "Settings",
        description = ("Adds a variety social consequences for plundering ancestral tombs.\n" ..
        "\n" ..
        "Burial places are said to be extremely important in Dunmer culture, so why are you allowed to rummage around in grandma's ashes like you're looking for a toy in the bottom of a cereal box? No more!\n" ..
        "Version: " .. config.modVersion)
    })

    settings:createYesNoButton({
        label = "Enable Mod",
        description = "Enable or Disable the mod's functionality.",
        variable = mwse.mcm:createTableVariable({ id = "enabled", table = config }),
    })

    settings:createYesNoButton({
        label = "Warn when entering sacred burial spaces?",
        description = "When enabled, notifies the player when entering an ancestral tomb where stealing may be taboo.",
        variable = mwse.mcm:createTableVariable({ id = "warnOnTombEntry", table = config }),
    })

    settings:createYesNoButton({
        label = "Forbid trade of plundered mortal remains?",
        description = "When enabled, all but the most immoral merchants will have a much stronger reaction to being offered ancestral remains like bones.",
        variable = mwse.mcm:createTableVariable({ id = "mortalRemainsForbidden", table = config }),
    })

    settings:createYesNoButton({
        label = "Exclude unique artifacts from items offensive to wear?",
        description = "When enabled, People will not become angry when you're wearing certain unique artifact items found in tombs.",
        variable = mwse.mcm:createTableVariable({ id = "inconspicuousArtifacts", table = config }),
    })

    settings:createYesNoButton({
        label = "Include Urshilaku Burial Caverns?",
        description = "When enabled, items in the Urshilaku Burial Caverns will be considered grave goods if they meet the usual requirements.",
        variable = mwse.mcm:createTableVariable({ id = "inconspicuousArtifacts", table = config }),
    })

    settings:createSlider{
        label = "Grave Good Recognition Value",
        description = "The minimum value at which people will be able to recognise an item was plundered from a tomb when offered in a trade.",
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
        description =  "The minimum value at which people will be able to immediately recognise a grave good when the player is wearing it.\n" ..
        "\n" ..
        "Items in this category will also provoke a stronger response when offered in a trade.",
        min = 0,
        max = 100000,
        step = 10,
        jump = 100,
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

    settings:createSlider{
        label = "Custom Reaction Modifier",
        description = "Increase or decrease the basic 'difficulty' of selling grave goods.\n" ..
        "\n" ..
        "This value will be added or subtracted from calculations determining the severity of merchant reactions when attempting to sell them grave goods. Use it to customize the overall gameplay impact of this mod.\n" ..
        "\n" ..
        "Negative values (-) will reduce reaction severity, while positive (+) will make them more extreme. Normal calculated values range between 0 and 100.\n" ..
        "For a detailed list of reaction calculation values, see: https://tinyurl.com/ReveredDeadValues \n",
        min = -150,
        max = 150,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "difficultyMod",
            table = config
        }
    }

end

event.register("modConfigReady", registerModConfig)