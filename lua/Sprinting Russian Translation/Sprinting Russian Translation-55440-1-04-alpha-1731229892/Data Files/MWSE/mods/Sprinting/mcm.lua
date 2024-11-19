local config = require("Sprinting.config").config

local isZoomEnabled = config.enableMod and config.enableSprintingZoom

local callbackOnCloseComponents = {}

local function registerModConfig()

    local template = mwse.mcm.createTemplate{ name = "Спринт" }
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
            label = "Основные настройки"
        }

        activeComponent = pageGeneralSettings:createYesNoButton{
            label = "Включить спринт",
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
                label = "Опции спринта"
            }

            categorySprintingOptions:createTextField{
                label = "Множитель максимальной скорости",
                variable = mwse.mcm.createTableVariable{
                    id = "speedMultiplierMaxAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categorySprintingOptions:createTextField{
                label = "Модификатор множителя скорости",
                variable = mwse.mcm.createTableVariable{
                    id = "speedMultiplierIncrement",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categorySprintingOptions:createKeyBinder{
                label = "Клавиша спринта",
                variable = mwse.mcm.createTableVariable{
                    id = "keySprinting",
                    table = config
                },
                allowCombinations  = false
            }

            categorySprintingOptions:createOnOffButton{
                label = "Разнонаправленное движение",
                variable = mwse.mcm.createTableVariable{
                    id = "enableMultiDirectionalMovement",
                    table = config
                }
            }

        end -- /Category: Sprinting Options

        do -- Category: Fatigue Options

            local categoryFatigueOptions = pageGeneralSettings:createCategory{
                label = "Опции усталости"
            }

            categoryFatigueOptions:createTextField{
                label = "Мин. остаток усталости",
                variable = mwse.mcm.createTableVariable{
                    id = "fatigueDrawbackMinAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryFatigueOptions:createTextField{
                label = "Макс. остаток усталости",
                variable = mwse.mcm.createTableVariable{
                    id = "fatigueDrawbackMaxAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryFatigueOptions:createTextField{
                label = "Модификатор остатока усталости от навыка",
                variable = mwse.mcm.createTableVariable{
                    id = "fatigueDrawbackAthleticsModifier",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryFatigueOptions:createOnOffButton{
                label = "Урон от усталости",
                variable = mwse.mcm.createTableVariable{
                    id = "fatigueDrawbackAllowFainting",
                    table = config
                }
            }

        end -- /Category: Fatigue Options

        do -- Category: Recovery Options

            local categoryRecoveryOptions = pageGeneralSettings:createCategory{
                label = "Опции восстановления усталости"
            }

            categoryRecoveryOptions:createTextField{
                label = "Мин. продолжительность восстановления",
                variable = mwse.mcm.createTableVariable{
                    id = "minimumRecoveryDuration",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryRecoveryOptions:createTextField{
                label = "Требуемый процент усталости",
                variable = mwse.mcm.createTableVariable{
                    id = "minimumRecoveryFatiguePercentage",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryRecoveryOptions:createOnOffButton{
                label = "Уведомления",
                variable = mwse.mcm.createTableVariable{
                    id = "enableRecoveryNotifications",
                    table = config
                }
            }

        end -- /Category: Recovery Options

        do -- Category: Zooming Options

            local categoryZoomingOptions = pageGeneralSettings:createCategory{
                label = "Опции зума камеры"
            }

            activeComponent = categoryZoomingOptions:createYesNoButton{
                label = "Включить зум камеры при спринте",
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
                label = "Множитель зума по умолчанию",
                variable = mwse.mcm.createTableVariable{
                    id = "defaultZoomAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryZoomingOptions:createTextField{
                label = "Значение зума при спринте",
                variable = mwse.mcm.createTableVariable{
                    id = "sprintingZoomMaxAmount",
                    table = config,
                    converter = tonumber
                },
                numbersOnly = true
            }

            categoryZoomingOptions:createTextField{
                label = "Множитель зума",
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