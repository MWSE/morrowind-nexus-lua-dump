local config = require("DynamicMusicPause.config")

local template = mwse.mcm.createTemplate("Dynamic Music Pause")

template.onClose = function()
    if config.minPause > config.maxPause then
        config.minPause = config.maxPause
    end
end

template:saveOnClose("DynamicMusicPauseConfig", config)
template:register()

local page = template:createSideBarPage{
	label = "Settings",
	description = "Configure the random pause between music tracks."
}

page:createSlider{
    label = "Minimum Pause (seconds)",
    description = "The shortest possible silence between tracks.",
    min = 1,
    max = 360,
    step = 1,
    jump = 10,
    variable = mwse.mcm.createTableVariable{
        id = "minPause",
        table = config,
    },
}

page:createSlider{
    label = "Maximum Pause (seconds)",
    description = "The longest possible silence between tracks.",
    min = 1,
    max = 600,
    step = 1,
    jump = 20,
    variable = mwse.mcm.createTableVariable{
        id = "maxPause",
        table = config,
    },
}

page:createSlider{
    label = "Pause Chance (%)",
    description = "Percentage likelihood that a pause will occur.",
    min = 0,
    max = 100,
    step = 1,
    jump = 5,
    variable = mwse.mcm.createTableVariable{
        id = "pauseChance",
        table = config,
    },
}

