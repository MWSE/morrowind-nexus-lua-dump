local this = {}
this.name = "DPS Tooltips"
local config = require("longod.DPSTooltips.config")

function this.OnModConfigReady()
    local data = config.Load()

    local template = mwse.mcm.createTemplate(this.name)
    template:saveOnClose(config.configPath, data)
    template:register()

    local page = template:createSideBarPage {
        label = "Settings",
        description = (
            "This mod analytically calculates weapon DPS (damage per second) including enchantment effects and displays it in weapon tooltips.\n" ..
            "You can know which weapons are actually stronger for your player character."
            )
    }

    ---@param value boolean
    ---@return string
    local function GetOnOff(value)
        if value then
            return "On"
        end
        return "Off"
    end

    ---@param value boolean
    ---@return string
    local function GetYesNo(value)
        if value then
            return "Yes"
        end
        return "No"
    end

    page:createOnOffButton {
        label = "Enable DPS Tooltip",
        description = (
            "Enable this tooltip feature.\n" ..
            "\nDefault: " .. GetOnOff(config.defaultConfig.enable)
            ),
        variable = mwse.mcm.createTableVariable {
            id = "enable",
            table = data,
        }
    }

    page:createYesNoButton {
        label = "Use Difficulty",
        description = (
            "Apply damage multiplier by Difficulty option.\n" ..
            "\nDefault: " .. GetYesNo(config.defaultConfig.difficulty)
            ),
        variable = mwse.mcm.createTableVariable {
            id = "difficulty",
            table = data,
        }
    }

    do
        local sub = page:createCategory("Accurate DPS")
        sub:createOnOffButton {
            label = "Accurate Weapon Damage",
            description = (
                "Use accurate weapon damage dealt, taking into account the player character's attributes and the weapon condition.\n" ..
                "\nDefault: " .. GetOnOff(config.defaultConfig.accurateDamage)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "accurateDamage",
                table = data,
            }
        }
        sub:createYesNoButton {
            label = "Use Best Weapon Condition",
            description = (
                "Always determine DPS as the weapon with the best durability. This is useful when you want to consider theoretical values.\n" ..
                "\nDefault: " .. GetYesNo(config.defaultConfig.maxDurability)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "maxDurability",
                table = data,
            }
        }
    end

    do
        local sub = page:createCategory("Appearance")
        sub:createYesNoButton {
            label = "Display Min - Max",
            description = (
                "Show minimum to maximum DPS range. When disabled, only display maximum.\n" ..
                "In Morrowind, the weapon's damage range is determined by how long the attack key is held, not by RNG. Therefore, the average value does not become DPS.\n" ..
                "\nDefault: " .. GetYesNo(config.defaultConfig.minmaxRange)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "minmaxRange",
                table = data,
            }
        }

        sub:createYesNoButton {
            label = "Insert Pre-Divider",
            description = (
                "Insert a dividing line BEFORE the DPS display. Makes it easier to distinguish when using other tooltips mods.\n" ..
                "\nDefault: " .. GetYesNo(config.defaultConfig.preDivider)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "preDivider",
                table = data,
            }
        }

        sub:createYesNoButton {
            label = "Insert Post-Divider",
            description = (
                "Insert a dividing line AFTER the DPS display. Makes it easier to distinguish when using other tooltips mods.\n" ..
                "\nDefault: " .. GetYesNo(config.defaultConfig.postDivider)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "postDivider",
                table = data,
            }
        }
    end

    do
        local sub = page:createCategory("Breakdown Appearance")
        sub:createOnOffButton {
            label = "DPS Breakdown",
            description = (
                "You can know the difference in damage for each weapon swing type, and damages caused by enchantments.\n" ..
                "\nDefault: " .. GetOnOff(config.defaultConfig.breakdown)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "breakdown",
                table = data,
            }
        }
        sub:createYesNoButton {
            label = "Coloring Text",
            description = (
                "For each damage, add color to text by elemental or school.\n" ..
                "\nDefault: " .. GetYesNo(config.defaultConfig.coloring)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "coloring",
                table = data,
            }
        }
        sub:createYesNoButton {
            label = "Display Effect Icons",
            description = (
                "For each damage, display enchantment icons that affected it. For example, it makes it easier to see what the weakness spell has affected.\n" ..
                "\nDefault: " .. GetYesNo(config.defaultConfig.showIcon)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "showIcon",
                table = data,
            }
        }
    end

    do
        local sub = page:createCategory("Development")
        sub:createDropdown {
            label = "Logging Level",
            description = (
                "Set the log level.\n" .. "\nDefault: "  .. config.defaultConfig.logLevel
                ),
            options = {
                { label = "TRACE", value = "TRACE" },
                { label = "DEBUG", value = "DEBUG" },
                { label = "INFO",  value = "INFO" },
                { label = "WARN",  value = "WARN" },
                { label = "ERROR", value = "ERROR" },
                { label = "NONE",  value = "NONE" },
            },
            variable = mwse.mcm.createTableVariable { id = "logLevel", table = data },
            callback = function(self)
                local logger = require("longod.DPSTooltips.logger")
                logger:setLogLevel(self.variable.value)
            end
        }

        sub:createOnOffButton {
            label = "Unit Test",
            description = (
                "Run unit test on launch.\n" ..
                "\nDefault: " .. GetOnOff(config.defaultConfig.unittest)
                ),
            variable = mwse.mcm.createTableVariable {
                id = "unittest",
                table = data,
            }
        }
    end
end

return this
