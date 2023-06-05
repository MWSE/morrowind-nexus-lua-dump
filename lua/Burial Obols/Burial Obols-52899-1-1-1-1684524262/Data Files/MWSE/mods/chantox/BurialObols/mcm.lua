local config = require("chantox.BurialObols.config")
local log = require("chantox.BurialObols.log")

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Burial Obols")
    template:saveOnClose("Burial Obols", config)

    local settings = template:createSideBarPage{description = "Burial Obols"}

    settings:createTextField {
        label = "Coin Amount",
        description =
            "The amount of tombs that will contain a coin.\n" ..
            "\n" ..
            "Default: 10",
        numbersOnly = true,
        variable = mwse.mcm:createTableVariable{id = "amount", table = config},
        callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id])
			tes3.messageBox(self.label .. " set to " .. config[self.variable.id])
		end
    }

    settings:createDropdown{
        label = "Log Level",
        description =
            "Sets the logging level for this mod.\n" ..
            "Messages appear on mwse.log and the game console (when possible).\n" ..
            "\n" ..
            "Default: INFO",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{id = "logLevel", table = config},
        callback = function(self)
            log.logLevel = self.variable.value
        end,
    }

    -- Finish up.
    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)
