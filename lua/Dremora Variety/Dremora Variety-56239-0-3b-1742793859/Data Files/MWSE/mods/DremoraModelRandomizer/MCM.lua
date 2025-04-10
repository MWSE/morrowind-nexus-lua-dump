-- Simple MCM.lua for DremoraModelRandomizer

local config = require("DremoraModelRandomizer.config")

-- Create template
local template = mwse.mcm.createTemplate("Dremora Model Randomizer")
template:saveOnClose("DremoraModelRandomizer", config)
template:register()

-- Create page
local page = template:createPage({ label = "Settings" })

page:createOnOffButton({
    label = "Enable Model Randomization",
    description = "If enabled, Dremora models will be randomized upon spawning.",
    variable = mwse.mcm.createTableVariable({ id = "enabled", table = config })
})

page:createDropdown({
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

page:createButton({
    label = "Force Refresh Models",
    buttonText = "Refresh",
    callback = function()
        timer.delayOneFrame(function()
            for _, cell in ipairs(tes3.getActiveCells()) do
                for ref in cell:iterateReferences(tes3.objectType.creature) do
                    if ref.sceneNode and not (ref.deleted or ref.disabled) then
                        event.trigger("DremoraModelRandomizer:Refresh", { reference = ref })
                    end
                end
            end
        end)
    end
})
