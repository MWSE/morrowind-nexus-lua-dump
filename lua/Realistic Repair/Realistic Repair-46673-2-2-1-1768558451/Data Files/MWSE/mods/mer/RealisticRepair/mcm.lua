local config = require("mer.RealisticRepair.config")

local  sideBarDefault = [[
Adds the following mechanics:

Degradation:

When failing a repair attempt, the item will "degrade", which lowers the maximum condition it can be repaired to. You can reduce the amount of degradation by using an anvil or forge instead. If the bonus given by anvils/forges exceeds the degradation amount, you can even remove degradation from your items. You can also completely remove degradation by repairing your items at a blacksmith.

Enhancement:

At a repair station, fully-repaired items can be enhanced beyond their base maximum condition. Enhancement adds temporary condition points (10-50% of base) that degrade before the real condition. Enhanced items cannot be degraded until enhancement is worn off. Items with degradation must be fully restored before enhancement can be applied.

Damaged Loot:

When an NPC dies, their equipment will have a random amount of damage applied to it.
]]

local function addSideBar(component)
    component.sidebar:createInfo{ text = sideBarDefault}
    component.sidebar:createHyperLink{
        text = "Made by Merlord",
        exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
        postCreate = (
            function(self)
                self.elements.outerContainer.borderAllSides = self.indent
                self.elements.outerContainer.alignY = 1.0
                self.elements.outerContainer.layoutHeightFraction = 1.0
                self.elements.info.layoutOriginFractionX = 0.5
            end
        ),
    }
end


local function doGeneralSettings(page)
    ---General
    local generalSettings = page:createCategory("General Settings")

    generalSettings:createOnOffButton{
        label = "Enable Realistic Repair",
        variable = mwse.mcm.createTableVariable{
            id = "enableRealisticRepair",
            table = config.mcm
        },
        description = "Enable or disable the mod entirely."
    }

    generalSettings:createOnOffButton{
        label = "Enable dynamic damage/armor rating tooltips",
        variable = mwse.mcm.createTableVariable{
            id = "enableDynamicTooltips",
            table = config.mcm
        },
        description = "When enabled, item tooltips will show dynamic damage and armor ratings based on current condition."
    }

    generalSettings:createOnOffButton{
        label = "Enable repair stations",
        variable = mwse.mcm.createTableVariable{
            id = "enableStations",
            table = config.mcm
        },
        description = "When enabled, you must use anvils and forges to repair items."
    }

    generalSettings:createLogLevelOptions{
        configKey = "logLevel",
    }
end

---@param page mwseMCMSideBarPage
local function doCostSettings(page)
    ---Cost Settings
    local costSettings = page:createCategory("Cost Settings")
    --Time cost
    costSettings:createOnOffButton{
        label = "Enable time cost to repair",
        variable = mwse.mcm.createTableVariable{
            id = "enableTimeCost",
            table = config.mcm
        },
        description = "When enabled, repairing items will take in-game time based on the amount repaired.",
    }

    --repairTimeMin
    costSettings:createSlider{
        label = "Time in hours to repair at low skill",
        decimalPlaces = 2,
        min = 0.1,
        max = 5.0,
        step = 0.1,
        variable = mwse.mcm.createTableVariable{
            id = "repairTimeMin",
            table = config.mcm
        }
    }

    --repairTimeMax
    costSettings:createSlider{
        label = "Time in hours to repair at high skill",
        decimalPlaces = 2,
        min = 0.1,
        max = 5.0,
        step = 0.1,
        variable = mwse.mcm.createTableVariable{
            id = "repairTimeMax",
            table = config.mcm
        }
    }

    --Fatigue cost
    costSettings:createOnOffButton{
        label = "Enable fatigue cost to repair",
        variable = mwse.mcm.createTableVariable{
            id = "enableFatigueCost",
            table = config.mcm
        },
        description = "When enabled, repairing items will cost fatigue based on the amount repaired.",
    }

    --repairFatigueMin
    costSettings:createSlider{
        label = "Fatigue cost per point repaired at low skill",
        min = 1,
        max = 50,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "repairFatigueMin",
            table = config.mcm
        }
    }

    --repairFatigueMax
    costSettings:createSlider{
        label = "Fatigue cost per point repaired at high skill",
        min = 1,
        max = 50,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "repairFatigueMax",
            table = config.mcm
        }
    }

end


local function doDegradationSettings(page)
    local degradationSettings = page:createCategory("Degradation Settings")

    degradationSettings:createOnOffButton{
        label = "Enable item degradation on failed repair",
        variable = mwse.mcm.createTableVariable{
            id = "enableDegradation",
            table = config.mcm
        },
        description = "When enabled, items will lose max condition when a repair attempt fails."
    }

    degradationSettings:createSlider{
        label = "Min Degradation (High Skill)",
        description = "Degradation amount at 100 armorer skill",
        min = 0,
        max = 20,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "minDegradation",
            table = config.mcm
        }
    }
    degradationSettings:createSlider{
        label = "Max Degradation (Low Skill)",
        description = "Degradation amount at 0 armorer skill",
        min = 1,
        max = 50,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "maxDegradation",
            table = config.mcm
        }
    }

    degradationSettings:createSlider{
        label = "Station Success Chance Modifier",
        description = "Percentage added to repair success chance when using a station (anvil/forge)",
        min = 0,
        max = 50,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "stationChanceModifier",
            table = config.mcm
        }
    }
end

local function doEnhancementSettings(page)
       ---Enhancement Settings
    local enhancementSettings = page:createCategory("Enhancement Settings")

    --enable Enhancement
    enhancementSettings:createOnOffButton{
        label = "Enable item enhancement on successful repair",
        variable = mwse.mcm.createTableVariable{
            id = "enableEnhancement",
            table = config.mcm
        },
        description = "When enabled, items can be enhanced beyond their base max condition when repaired at a station."
    }

    enhancementSettings:createSlider{
        label = "Min Enhancement Amount",
        description = "Enhancement amount per successful repair at 0 armorer skill",
        min = 1,
        max = 1000,
        step = 1,
        jump = 100,
        variable = mwse.mcm.createTableVariable{
            id = "minEnhancement",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Max Enhancement Amount",
        description = "Enhancement amount per successful repair at 100 armorer skill",
        min = 1,
        max = 1000,
        step = 1,
        jump = 100,
        variable = mwse.mcm.createTableVariable{
            id = "maxEnhancement",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Min Enhancement Cap (Low Skill)",
        description = "Maximum enhancement percentage at 0 armorer skill",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "minEnhancementCap",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Max Enhancement Cap (High Skill)",
        description = "Maximum enhancement percentage at 100 armorer skill",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "maxEnhancementCap",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Min Enhancement Chance",
        description = "Chance to enhance on successful repair at 0 armorer skill",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "minEnhancementChance",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Max Enhancement Chance",
        description = "Chance to enhance on successful repair at 100 armorer skill",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "maxEnhancementChance",
            table = config.mcm
        }
    }
end

local function doLootDamageSettings(page)
    ---Loot Damage
    local lootCategory = page:createCategory("Loot Damage Settings")

    lootCategory:createOnOffButton{
        label = "Enable damaged loot",
        variable = mwse.mcm.createTableVariable{
            id = "enableLootDamage",
            table = config.mcm
        },
        description = (
            "When enabled, NPC equipment will be heavily damaged upon death. " ..
            "This is to balance the economy by making it more difficult to make " ..
            "money looting enemies for gear."
        )
    }
    lootCategory:createSlider{
        label = "Minimum Condition Percentage on Looted Gear",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "minCondition",
            table = config.mcm
        }
    }
    lootCategory:createSlider{
        label = "Maximum Condition Percentage on Looted Gear",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "maxCondition",
            table = config.mcm
        }
    }
end

event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate{
        name = "Realistic Repair",
        config = config.mcm,
        defaultConfig = config.mcmDefault,
        showDefaultSetting = true
    }
    template:saveOnClose(config.configPath, config.mcm)
    template:register()

    local page = template:createSideBarPage{ showReset = true}
    addSideBar(page)
    doGeneralSettings(page)
    doCostSettings(page)
    doDegradationSettings(page)
    doEnhancementSettings(page)
    doLootDamageSettings(page)
end)
