local config = require("Sprinting.config").config

local isZoomEnabled = config.enableMod and config.enableSprintingZoom

local callbackOnCloseComponents = {}

local function registerModConfig()

    local template = mwse.mcm.createTemplate{ name = "Sprinting" }
    template.onClose = function()
            config.save(true)

            isZoomEnabled = isZoomEnabled or (config.enableMod and config.enableSprintingZoom)

            for _, component in ipairs(callbackOnCloseComponents) do
                component:callback()
            end
        end
    template:register()


    local activeComponent
    do -- Page: General Settings

        local pageGeneralSettings = template:createPage{
            label = "General Settings"
        }

        activeComponent = pageGeneralSettings:createYesNoButton{
            label = "Enable Sprinting",
            variable = mwse.mcm.createTableVariable{
                id = "enableMod",
                table = config
            },
            restartRequired = isZoomEnabled,
            callback = function(self)
                    self.restartRequired = isZoomEnabled and config.enableMod
                end
        }
        table.insert(callbackOnCloseComponents, activeComponent)

        do -- Category: Sprinting Options

            local categorySprintingOptions = pageGeneralSettings:createCategory{
                label = "Sprinting Options"
            }

            categorySprintingOptions:createTextField{
                label = "Max Speed Multiplier",
                variable = mwse.mcm.createTableVariable{
                    id = "speedMultiplierMaxAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categorySprintingOptions:createTextField{
                label = "Speed Multiplier Modifier",
                variable = mwse.mcm.createTableVariable{
                    id = "speedMultiplierIncrement",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categorySprintingOptions:createKeyBinder{
                label = "Sprinting Hotkey",
                variable = mwse.mcm.createTableVariable{
                    id = "keySprinting",
                    table = config
                },
                allowCombinations  = false
            }

            categorySprintingOptions:createOnOffButton{
                label = "Multi-Directional Movement",
                variable = mwse.mcm.createTableVariable{
                    id = "enableMultiDirectionalMovement",
                    table = config
                }
            }

        end -- /Category: Sprinting Options

        do -- Category: Fatigue Options

            local categoryFatigueOptions = pageGeneralSettings:createCategory{
                label = "Fatigue Options"
            }

            categoryFatigueOptions:createTextField{
                label = "Min Fatigue Drawback",
                variable = mwse.mcm.createTableVariable{
                    id = "fatigueDrawbackMinAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryFatigueOptions:createTextField{
                label = "Max Fatigue Drawback",
                variable = mwse.mcm.createTableVariable{
                    id = "fatigueDrawbackMaxAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryFatigueOptions:createTextField{
                label = "Fatigue Drawback Skill Modifier",
                variable = mwse.mcm.createTableVariable{
                    id = "fatigueDrawbackAthleticsModifier",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryFatigueOptions:createOnOffButton{
                label = "Fatigue Collapsing",
                variable = mwse.mcm.createTableVariable{
                    id = "fatigueDrawbackAllowFainting",
                    table = config
                }
            }

        end -- /Category: Fatigue Options

        do -- Category: Recovery Options

            local categoryRecoveryOptions = pageGeneralSettings:createCategory{
                label = "Recovery Options"
            }

            categoryRecoveryOptions:createTextField{
                label = "Min Recovery Duration",
                variable = mwse.mcm.createTableVariable{
                    id = "minimumRecoveryDuration",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryRecoveryOptions:createTextField{
                label = "Required Fatigue Percentage",
                variable = mwse.mcm.createTableVariable{
                    id = "minimumRecoveryFatiguePercentage",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryRecoveryOptions:createOnOffButton{
                label = "Notifications",
                variable = mwse.mcm.createTableVariable{
                    id = "enableRecoveryNotifications",
                    table = config
                }
            }

        end -- /Category: Recovery Options

        do -- Category: Zooming Options

            local categoryZoomingOptions = pageGeneralSettings:createCategory{
                label = "Zooming Options"
            }

            activeComponent = categoryZoomingOptions:createYesNoButton{
                label = "Enable Sprinting Zoom",
                variable = mwse.mcm.createTableVariable{
                    id = "enableSprintingZoom",
                    table = config
                },
                restartRequired = isZoomEnabled,
                callback = function(self)
                        self.restartRequired = isZoomEnabled and config.enableSprintingZoom
                    end
            }
            table.insert(callbackOnCloseComponents, activeComponent)

            categoryZoomingOptions:createTextField{
                label = "Default Zoom Amount",
                variable = mwse.mcm.createTableVariable{
                    id = "defaultZoomAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryZoomingOptions:createTextField{
                label = "Sprinting Zoom Amount",
                variable = mwse.mcm.createTableVariable{
                    id = "sprintingZoomMaxAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryZoomingOptions:createTextField{
                label = "Zooming Modifier",
                variable = mwse.mcm.createTableVariable{
                    id = "sprintingZoomSpeed",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

        end -- /Category: Zooming Options

    end -- /Page: General Settings

    mwse.log("[Sprinting] MCM Registered")

end

event.register("modConfigReady", registerModConfig)