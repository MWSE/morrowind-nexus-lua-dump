local logger = require("logging.logger")

--- Setup MCM.
local function registerModConfig()
    local config = require("rfuzzo.ImmersiveTravel.config")
    local log = logger.getLogger(config.mod)

    local template = mwse.mcm.createTemplate(config.mod)
    template:saveOnClose("ImmersiveTravel", config)

    local page = template:createSideBarPage({ label = "Settings" })
    page.sidebar:createInfo {
        text = ("%s v%.1f\n\nBy %s"):format(config.mod, config.version,
            config.author)
    }

    local settingsPage = page:createCategory("Settings")
    local generalCategory = settingsPage:createCategory("General")

    generalCategory:createDropdown {
        label = "Logging Level",
        description = "Set the log level.",
        options = {
            { label = "TRACE", value = "TRACE" },
            { label = "DEBUG", value = "DEBUG" },
            { label = "INFO",  value = "INFO" },
            { label = "WARN",  value = "WARN" },
            { label = "ERROR", value = "ERROR" },
            { label = "NONE",  value = "NONE" }
        },
        variable = mwse.mcm.createTableVariable {
            id = "logLevel",
            table = config
        },
        callback = function(self)
            if log ~= nil then log:setLogLevel(self.variable.value) end
        end
    }

    local striderCategory = settingsPage:createCategory("Silt Strider")
    striderCategory:createDropdown {
        label = "Silt Strider Walking Animation",
        description = "Change the Strider walking animation.",
        options = {
            { label = "runForward",  value = "runForward" },
            { label = "walkForward", value = "walkForward" }
        },
        variable = mwse.mcm.createTableVariable {
            id = "a_siltstrider_forwardAnimation",
            table = config
        }
    }


    template:register()
end

event.register("modConfigReady", registerModConfig)
