local logger = require("logging.logger")

--- Setup MCM.
local function registerModConfig()
    local config = require("Flin.config") ---@type FlinConfig

    local log = logger.getLogger(config.mod)
    local template = mwse.mcm.createTemplate(config.mod)
    template:saveOnClose("Flin", config)

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
            { label = "INFO",  value = "INFO" }, { label = "WARN", value = "WARN" },
            { label = "ERROR", value = "ERROR" }, { label = "NONE", value = "NONE" }
        },
        variable = mwse.mcm.createTableVariable {
            id = "logLevel",
            table = config
        },
        callback = function(self)
            if log ~= nil then log:setLogLevel(self.variable.value) end
        end
    }

    generalCategory:createKeyBinder({
        label = "Play a card keybind",
        description = "Assign a new keybind.",
        variable = mwse.mcm.createTableVariable {
            id = "openkeybind",
            table = config
        },
        allowCombinations = true
    })

    generalCategory:createOnOffButton({
        label = "Enable Hints",
        description = "Enable hints during the card game.",
        variable = mwse.mcm.createTableVariable {
            id = "enableHints",
            table = config
        }
    })

    generalCategory:createOnOffButton({
        label = "Enable Messages",
        description = "Enable more message boxes during the card game.",
        variable = mwse.mcm.createTableVariable {
            id = "enableMessages",
            table = config
        }
    })

    generalCategory:createOnOffButton({
        label = "Trick Sounds",
        description = "Play sounds after winning or losing a trick.",
        variable = mwse.mcm.createTableVariable {
            id = "enableTrickSounds",
            table = config
        }
    })


    template:register()
end

event.register("modConfigReady", registerModConfig)
