local config = require("StormAtronach.TUD.config").config

local function registerModConfig()
    local template = mwse.mcm.createTemplate("The Ungrateful Dead")
    template:saveOnClose("sa_TUD_config", config)

    local page = template:createSideBarPage({
        label = "The Ungrateful Dead",
        description = (
            "When you summon an Ancestral Ghost, you are summoning... an ancestor, with all their personality and little quirks. A blessing or a curse? Well, all families have their own... interesting characters :)\n\n"
        )
    })

    page:createOnOffButton{
        label = "Enable Mod",
        description = "Toggle the ancestral wisdom mechanic on or off.",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config
        }
    }

    page:createSlider{
        label = "Wisdom Effect Duration (seconds)",
        description = "How long the ancestral wisdom effects last (default: 600 seconds = 10 minutes).",
        min = 10,
        max = 3600,
        step = 10,
        jump = 60,
        variable = mwse.mcm.createTableVariable{
            id = "duration",
            table = config
        }
    }

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)
