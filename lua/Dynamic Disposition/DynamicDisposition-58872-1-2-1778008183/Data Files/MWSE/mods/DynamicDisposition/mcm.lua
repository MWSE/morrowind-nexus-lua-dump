local config = require("DynamicDisposition.config")
local template = mwse.mcm.createTemplate("Dynamic Disposition")

template:saveOnClose("DynamicDispositionConfig", config)
template:register()

local page = template:createSideBarPage{
    label = "Settings",
    description = "NPC disposition dynamically adjusted based on your stats, race, and faction relationships.",
}

page:createOnOffButton{
    label = "Enable debug logging",
    description = "Print debug info to the MWSE log and console.",
    variable = mwse.mcm.createTableVariable{
        id = "enableDebug",
        table = config,
    },
}

page:createSlider{
    label = "Maximum stat penalty",
    description =
        "How strongly low speechcraft and personality reduce disposition. ",
    min = 1,
    max = 50,
    step = 1,
    jump = 2,
    variable = mwse.mcm.createTableVariable{
        id = "maxPenalty",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Speechcraft influence",
    description =
        "Multiplier for Speechcraft. A higher value increases the impact your Speechcraft skill "
        .. "has on disposition calculations.",
    min = 0.0,
    max = 2.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "speechcraftScale",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Personality influence",
    description =
        "Multiplier for Personality. A higher value increases the impact your Personality attribute "
        .. "has on disposition calculations.",
    min = 0.0,
    max = 2.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "personalityScale",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Race reaction scale",
    description =
        "Multiplier for racial reactions. A higher value increases the influence of racial biases "
        .. "in the disposition calculation.",
    min = 0.0,
    max = 2.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "raceScale",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Faction reaction scale",
    description =
        "Multiplier for faction relationships. A higher value increases the influence of faction "
        .. "alliances and rivalries in the disposition calculation.",
    min = 0.0,
    max = 2.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "factionScale",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Fame influence",
    description = "How strongly your reputation affects NPC disposition.",
    min = 0.0,
    max = 1.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "fameScale",
        table = config,
    },
}
