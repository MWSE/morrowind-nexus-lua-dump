local config = require("SedrynTyros.ORLL.config")
local log = require("SedrynTyros.ORLL.log")

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Oblivion Remastered Like Leveling")
    template:saveOnClose("Oblivion Remastered Like Leveling", config)

    local settings = template:createSideBarPage{description = [[Oblivion Remastered Like Leveling
(Based on 'Simple Attribute Distribution' by chantox)]]}

    settings:createTextField {
        label = "Attribute cap",
        description =
            "The maximum value for attributes.\n" ..
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
        label = "Virtues per level",
        description =
            "The amount of Virtue points you can spend on each level-up.\n" ..
            "12 Virtues replicates level-up value in Oblivion Remastered.\n" ..
			"Luck costs 4 Virtue points. All other attributes cost 1.\n" ..
            "\n" ..
            "Default: 12",
        variable = mwse.mcm:createTableVariable{id = "pointsPerLevel", table = config},
        min = 0,
        max = 20,
        defaultSetting = 12
    }

    settings:createSlider{
        label = "Max points per attribute",
        description =
            "The maximum amount of attribute points you can distribute to a single attribute per level.\n" ..
            "A value of 5 replicates restrictions in vanilla Morrowind and Oblivion Remastered.\n" ..
            "A value of 0 lets you allocate as many points as you want (essentially the same as 20).\n" ..
            "\n" ..
            "Default: 5",
        variable = mwse.mcm:createTableVariable{id = "maxPointsPerAttribute", table = config},
        min = 0,
        max = 20,
        defaultSetting = 5
    }

    settings:createOnOffButton{
        label = "Retroactive Endurance Health",
        description =
            "If enabled, the current base Endurance value is applied retroactively when leveling up to all past and future level-up Health gains, as in Oblivion Remastered.\n" ..
            "If disabled, vanilla Morrowind level-up health gains are used.\n" ..
            "\n" ..
            "Default: On",
        variable = mwse.mcm:createTableVariable{id = "retroHealth", table = config},
        defaultSetting = true
    }

    settings:createOnOffButton{
        label = "Restrict Luck increases to 1",
        description =
            "If enabled, Luck may only be raised by 1 point per level-up (costing 4 Virtues).\n" ..
            "This replicates Oblivion Remastered behavior exactly.\n\n" ..
            "Default: On",
        variable = mwse.mcm:createTableVariable{id = "restrictLuckToOne", table = config},
        defaultSetting = true
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
            "Ensures that max health is never set below 1 during recalculations.\n" ..
            "Useful if attribute damage would otherwise reduce max health to 0.\n" ..
            "May help prevent untimely death by attribute lowering effects.\n"..
            "(Carried over from original SAD mod. Not sure how relevant it is now.)\n"..
            "\n" ..
            "Default: Off",
        variable = mwse.mcm:createTableVariable{id = "deathProtection", table = config},
        defaultSetting = false,
        callback = function(self)
            config.minHealth = self.variable.value and 1 or 0
        end
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