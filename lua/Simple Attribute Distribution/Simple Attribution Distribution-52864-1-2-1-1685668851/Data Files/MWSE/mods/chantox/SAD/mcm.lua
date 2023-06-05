local config = require("chantox.SAD.config")
local log = require("chantox.SAD.log")

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Simple Attribute Distribution")
    template:saveOnClose("Simple Attribute Distribution", config)

    local settings = template:createSideBarPage{description = "Simple Attribute Distribution"}

    settings:createTextField {
        label = "Attribute cap",
        description =
            "The maximum level attributes can go to.\n" ..
            "Use the attribute uncap option from MCP to ensure correct function.\n" ..
            "\n" ..
            "Default: 100",
        numbersOnly = true,
        variable = mwse.mcm:createTableVariable{id = "attributeLvlCap", table = config},
        callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id])
			tes3.messageBox(self.label .. " set to " .. config[self.variable.id])
		end
    }

    settings:createSlider{
        label = "Points per level",
        description =
            "The amount of attribute points you can distribute on each level-up.\n" ..
            "\n" ..
            "Default: 10",
        variable = mwse.mcm:createTableVariable{id = "pointsPerLevel", table = config},
        min = 0,
        max = 20,
        defaultSetting = 10
    }

    settings:createSlider{
        label = "Max points per attribute",
        description =
            "The maximum amount of attribute points you can distribute to a single attribute per level.\n" ..
            "A value of 0 lets you allocate as many points as you want.\n" ..
            "A value of 5 replicates vanilla restrictions.\n" ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm:createTableVariable{id = "maxPointsPerAttribute", table = config},
        min = 0,
        max = 20,
        defaultSetting = 0
    }

    settings:createOnOffButton{
        label = "Alt level-up messages",
        description =
            "Replaces a duplicate level-up message with one from TES 4: Oblivion.\n" ..
            "\n" ..
            "Default: On",
        variable = mwse.mcm:createTableVariable{id = "altLevelMsgs", table = config},
        defaultSetting = true
    }

    settings:createOnOffButton{
        label = "Death protection",
        description =
            "Sets maximum health to a minimum of 1 when updating it.\n" ..
            "Helps prevent untimely death by attribute lowering effects.\n"..
            "\n" ..
            "Default: Off",
        variable = mwse.mcm:createTableVariable{id = "minHealth", table = config}
    }

    settings:createDropdown{
        label = "Log Level",
        description =
            "Sets the logging level for this mod.\n" ..
            "Messages appear on mwse.log and the game console.\n" ..
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
