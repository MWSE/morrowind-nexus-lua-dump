local this = {}

local function isTable(t)
    return type(t) == "table"
end

local function isString(t)
    return type(t) == "string"
end

local function cleanUpConfig()
    for k, v in pairs(this.config) do
        if not isTable(v) then
            if isString(v) then
                this.config[k] = tonumber(v)
            end
        else
            for nestedK, nestedV in pairs(this.config[k]) do
                if isString(nestedV) then
                    this.config[k][nestedK] = tonumber(nestedV)
                end
            end
        end
    end
end

local function createGeneralSettings(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    category:createOnOffButton{
        label = "Allow healing always",
        description = "Default: Off. Allows healing regardless of combat status.",
        variable = mwse.mcm.createTableVariable{
            id = "allowAlways",
            table = this.config
        }
    }

    category:createOnOffButton{
        label = "Enable injuries",
        description = "Default: On. Injuries are enabled.",
        variable = mwse.mcm.createTableVariable{
            id = "enableInjuries",
            table = this.config
        }
    }

    category:createOnOffButton{
        label = "Show injury messages",
        description = "Default: On. Shows injury messages when you get injured.",
        variable = mwse.mcm.createTableVariable{
            id = "showInjuryMessages",
            table = this.config
        }
    }

    category:createTextField{
        label = "Out of Combat duration",
        description = "Default: 15 seconds. The amount of time since you have been hit to count as out of combat.",
        variable = mwse.mcm.createTableVariable{
            id = "combatDuration",
            table = this.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Base health percentage healed per tick",
        description = "Default: 0.1 or 10% health per tick",
        variable = mwse.mcm.createTableVariable{
            id = "healthPercentPerTick",
            table = this.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Duration for healing ticks",
        description = "Default: 3 seconds.",
        variable = mwse.mcm.createTableVariable{
            id = "durationHealthTick",
            table = this.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Minimum fatigue to reduce healing",
        description = "Default: 0.5 or 50% fatigue.",
        variable = mwse.mcm.createTableVariable{
            id = "minFatigueMod",
            table = this.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Minimum health to reduce healing",
        description = "Default: 0.5 or 50% fatigue.",
        variable = mwse.mcm.createTableVariable{
            id = "minHealthMod",
            table = this.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Resting hours required for injuries",
        description = "Default: 8 hours. The required minimum of hours resting to heal your injuries.",
        variable = mwse.mcm.createTableVariable{
            id = "restingHoursRequired",
            table = this.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Base injury chance",
        description = "Default: 5% chance.",
        variable = mwse.mcm.createTableVariable{
            id = "baseInjuryChance",
            table = this.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Weakned bonus injury chance",
        description = "Default: 5% chance. The extra chance to be injured when you are zero fatigue and health.",
        variable = mwse.mcm.createTableVariable{
            id = "weakenedInjuryChanceBonus",
            table = this.config,
            numbersOnly = true
        },
    }

    category:createOnOffButton{
        label = "Debug messages",
        description = "Default: Off. Shows debug messages such as healing per tick and injury chance per hit.",
        variable = mwse.mcm.createTableVariable{
            id = "debug",
            table = this.config
        }
    }
end

-- Handle mod config menu.
function this.registerModConfig()
    local template = mwse.mcm.createTemplate("Realistic Healing and Injuries")
    template.onClose = function()
        cleanUpConfig()
        mwse.saveConfig("Realistic Healing and Injuries", this.config)
    end

    --[[
        General settings
    ]]--
    local page = template:createSideBarPage{
        label = "Settings",
        description = "Configure healing and injury settings."
    }
    createGeneralSettings(page)

    mwse.mcm.register(template)
end

return this