local config = require("animationBlending.config")
config.version = 1.0

local template = mwse.mcm.createTemplate({ name = "Animation Blending" })
template:saveOnClose("animationBlending", config)
template:register()

local page = template:createSideBarPage({})

page.sidebar:createInfo({
    text = (
        "Animation Blending v%.1f\n"
        .. "By Greatness7\n\n"
        .. "Provides smooth animation transitions between animation groups.\n\n"
    ):format(config.version),
})

-- Performance Settings

local settings = page:createCategory({ label = "Performance Settings" })

settings:createOnOffButton({
    label = "Player Only",
    description = (
        "Do animation blending only for the player.\n\n"
        .. "May improve performance in areas with many NPCs.\n\n"
        .. "Default: Off"
    ),
    variable = mwse.mcm.createTableVariable({
        id = "playerOnly",
        table = config,
    }),
})

settings:createSlider({
    label = "Max Distance: %s",
    description = (
        "The maximum distance from the camera at which animation blending will occur.\n\n"
        .. "Lower values may improve performance.\n\n"
        .. "Default: 4096"
    ),
    min = 0,
    max = 8192,
    step = 512,
    jump = 2048,
    variable = mwse.mcm.createTableVariable({
        id = "maxDistance",
        table = config,
    }),
})


-- Developer Settings

local developer = page:createCategory({ label = "Developer Settings" })

developer:createOnOffButton({
    label = "Enabled",
    description = "Enable or disable the mod.\n\nDefault: On",
    variable = mwse.mcm.createTableVariable({
        id = "enabled",
        table = config,
    }),
})

developer:createDropdown({
    label = "Logging Level",
    description = "Set the log level. Only intended to be used for debugging purposes.\n\nDefault: INFO",
    options = {
        { label = "TRACE", value = "TRACE" },
        { label = "DEBUG", value = "DEBUG" },
        { label = "INFO",  value = "INFO" },
        { label = "WARN",  value = "WARN" },
        { label = "ERROR", value = "ERROR" },
        { label = "NONE",  value = "NONE" },
    },
    variable = mwse.mcm.createTableVariable({
        id = "logLevel",
        table = config,
    }),
    callback = function(self)
        local log = require("animationBlending.log")
        log:setLogLevel(self.variable.value)
    end,
})
