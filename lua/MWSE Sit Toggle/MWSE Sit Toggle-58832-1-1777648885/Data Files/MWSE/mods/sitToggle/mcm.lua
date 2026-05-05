local config = require("sitToggle.config")

local template = mwse.mcm.createTemplate("Sit Toggle")
template:saveOnClose("SitToggleConfig", config)
template:register()

local page = template:createSideBarPage{
    label = "Settings",
    description = "Configure the sit/stand toggle key and animation settings."
}

page:createKeyBinder{
    label = "Sit/Stand Hotkey",
	description = "Hotkey for toggling sitting / standing.",
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable{
        id = "sitKey",
        table = config,
    },
}

page:createYesNoButton{
    label = "Force third-person when sitting",
	description = "With this option enabled, the camera will automatically switch to third person upon sitting.",
    variable = mwse.mcm.createTableVariable{
        id = "forceThirdPerson",
        table = config,
    },
}
	
page:createSlider{
    label = "Sit Animation",
	description = "Which sit animation to use when sitting.",
    min = 1,
    max = 8,
    step = 1,
    jump = 1,
    variable = mwse.mcm.createTableVariable{
        id = "sitAnimationGroup",
        table = config,
    },
}
	
page:createSlider{
    label = "Camera Height Offset",
    description = "How far the camera should lower when sitting. A higher value pulls the camera down further.",
    min = 0,
    max = 80,
    step = 1,
    jump = 5,
    variable = mwse.mcm.createTableVariable{
        id = "cameraOffset",
        table = config,
    }
}
