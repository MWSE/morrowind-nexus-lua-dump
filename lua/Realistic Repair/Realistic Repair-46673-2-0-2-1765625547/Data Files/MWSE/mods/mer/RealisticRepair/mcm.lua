local config = require("mer.RealisticRepair.config")

event.register("modConfigReady", function()
    local  sideBarDefault = [[
Adds the following mechanics:

Degradation:

When failing a repair attempt, the item will "degrade", which lowers the maximum condition it can be repair to. You can reduce the amount of degradation by using an anvil or forge instead. If the bonus given by anvils/forges exceeds the degradation amount, you can even remove degradation from your items. You can also completely remove degradation by repairing your items at a blacksmith.


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


    local template = mwse.mcm.createTemplate("Realistic Repair")
    template:saveOnClose(config.configPath, config.mcm)
    local page = template:createSideBarPage{}
    addSideBar(page)

    ---General
    local generalCategory = page:createCategory("General Settings")

    generalCategory:createOnOffButton{
        label = "Enable Realistic Repair",
        variable = mwse.mcm.createTableVariable{
            id = "enableRealisticRepair",
            table = config.mcm
        },
        description = "Enable or disable the mod entirely."
    }

    generalCategory:createLogLevelOptions{
        config = config.mcm,
        configKey = "logLevel",
    }

    ---Station Settings
    local stationCategory = page:createCategory("Repair Station Settings")
    stationCategory:createOnOffButton{
        label = "Enable repair stations",
        variable = mwse.mcm.createTableVariable{
            id = "enableStations",
            table = config.mcm
        },
        description = "When enabled, you must use anvils and forges to repair items."
    }

    ---Degradation Settings
    local degradationCategory = page:createCategory("Degradation Settings")

    degradationCategory:createOnOffButton{
        label = "Enable item degradation on failed repair",
        variable = mwse.mcm.createTableVariable{
            id = "enableDegradation",
            table = config.mcm
        },
        description = "When enabled, items will lose max condition when a repair attempt fails."
    }

    degradationCategory:createSlider{
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
    degradationCategory:createSlider{
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

    degradationCategory:createSlider{
        label = "Station Degradation Reduction",
        description = "Amount by which degradation is reduced when using a repair station. " ..
            "Can go negative to restore condition.",
        min = -20,
        max = 20,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "stationDegradeReduction",
            table = config.mcm
        }
    }


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

    template:register()
end)
