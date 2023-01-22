local common = require('mer.skoomaesthesia.common')
local config = require('mer.skoomaesthesia.config')
local modName = config.static.modName
local modDescription = config.static.modDescription
local mcmConfig = mwse.loadConfig(config.configPath, config.mcmDefault)
--MCM MENU
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName }
    template.onClose = function()
        config.save(mcmConfig)
    end
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = modDescription

    settings:createOnOffButton{
        label = "Enable Hallucinations",
        description = "When enabled, smoking skooma will cause you to experience auditory and visual hallucinations.",
        variable = mwse.mcm.createTableVariable{id = "enableHallucinations", table = mcmConfig}
    }

    settings:createOnOffButton{
        label = "Skooma Pipe Mechanics.",
        description = "When enabled, you can smoke moon sugar with a skooma pipe, which gives you the same effect as drinking skooma.",
        variable = mwse.mcm.createTableVariable{id = "enableSkoomaPipe", table = mcmConfig}
    }

    settings:createOnOffButton{
        label = "Skooma Addiction",
        description = "When enabled, you have a chance to become addicted to Skooma, and suffer withdrawals when you haven't had skooma for two days. To overcome your addiction, survive five days of withdrawals without relapseing.",
        variable = mwse.mcm.createTableVariable{id = "enableAddiction", table = mcmConfig}
    }

    settings:createSlider{
        label = "Hallucination Color Intensity: %s%%",
        description = "Determines the intensity of color change during a skooma trip.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "maxColor", table = mcmConfig}
    }

    settings:createSlider{
        label = "Hallucination Blur Amount: %s%%",
        description = "Determines the size of the edge blur during a skooma trip.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "maxBlur", table = mcmConfig}
    }

    settings:createDropdown{
        label = "Logging Level",
        description = "Set the log level.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = mcmConfig },
        callback = function(self)
            for _, log in ipairs(common.loggers) do
                log:setLogLevel(self.variable.value)
            end
        end
    }
end
event.register("modConfigReady", registerModConfig)