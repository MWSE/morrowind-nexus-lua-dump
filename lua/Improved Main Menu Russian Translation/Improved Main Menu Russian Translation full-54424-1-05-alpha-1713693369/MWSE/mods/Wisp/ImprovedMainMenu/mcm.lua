local constants = require("Wisp.ImprovedMainMenu.common.constants")
local log       = require("Wisp.ImprovedMainMenu.common.debug").log
local config    = require("Wisp.ImprovedMainMenu.config").config

local function registerMCM()

    local template = mwse.mcm.createTemplate{ name = "Улучшенное главное меню" }
    template.onClose = function(self)
            config.save()
        end
    template:register()

    do -- <Side Bar Page: Options> --

        local pageGeneralSettings = template:createSideBarPage{
            label = "Options"
        }

        do -- <Category: General Options> --

            local categoryGeneralOptions = pageGeneralSettings:createCategory{
                label = "Общие настройки"
            }

            -- Enable/Disable the Mod --

            categoryGeneralOptions:createYesNoButton{
                label = "Включить мод",
                variable = mwse.mcm.createTableVariable{
                    id = "isModEnabled",
                    table = config
                }
            }

        end -- </Category: General Options> --

        do -- <Category: Continue Options> --

            local categoryContinueOptions = pageGeneralSettings:createCategory{
                label = "Настройки \"Продолжить\""
            }

            -- Enable/Disable the Continue Button Addon --

            categoryContinueOptions:createYesNoButton{
                label = "Добавить кнопку \"Продолжить\"",
                description = "Добавляет кнопку \"Продолжить\" в главное меню, которая загружает самое последнее сохранение игры.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_continueButton_isEnabled",
                    table = config
                }
            }

            categoryContinueOptions:createDropdown{
                label = "Отображать кнопку \"Продолжить\"",
                description = "Этот параметр определяет, когда должна отображаться кнопка \"Продолжить\". Если установлено значение \"Всегда\", кнопка доступна всегда, если \"Вне игры\", только в главном меню и после смерти персонажа",
                options = {
                    { value = constants.visibilityTypes.always, label = "Всегда" },
                    { value = constants.visibilityTypes.notInGame, label = "Вне игры" }
                },
                variable = mwse.mcm.createTableVariable{
                    id = "addon_continueButton_visibility",
                    table = config
                }
            }

            -- Enable/Disable the Continue Confirmation Addon --

            categoryContinueOptions:createYesNoButton{
                label = "Запрашивать подтверждение",
                description = "Запрашивать подтверждение пользователя при нажатии кнопки \"Продолжить\".",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_continueConfirmation_isEnabled",
                    table = config
                }
            }

            categoryContinueOptions:createDropdown{
                label = "Настройка подтверждения",
                description = "Этот параметр определяет, когда появляется запрос \"подтверждения\". Если установлено значение \"Всегда\", то при каждом нажатии, если \"В игре\", только во время игры",
                options = {
                    { value = constants.visibilityTypes.always, label = "Всегда" },
                    { value = constants.visibilityTypes.inGame, label = "В игре" }
                },
                variable = mwse.mcm.createTableVariable{
                    id = "addon_continueConfirmation_visibility",
                    table = config
                }
            }


        end -- </Category: Continue Options> --

        do -- <Category: New Game Options> --

            local categoryNewGameOptions = pageGeneralSettings:createCategory{
                label = "Настройки \"Новая игра\""
            }

            -- Enable/Disable the New Game Confirmation Addon --

            categoryNewGameOptions:createYesNoButton{
                label = "Спрашивать подтверждение новой игры",
                description = "Запрашивать подтверждение пользователя при нажатии кнопки \"Новая\".",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_newGameConfirmation_isEnabled",
                    table = config
                }
            }

            -- Show/Hide the New Game Button In-Game --

            categoryNewGameOptions:createYesNoButton{
                label = "Скрыть кнопку \"Новая\" во время игры.",
                description = "Скрывает кнопку \"Новая\" во время игры, что бы уменьшить размеры меню.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_hideNewGameButtonInGame_isEnabled",
                    table = config
                }
            }

        end -- </Category: New Game Options> --

        do -- <Category: Other Options> --

            local categoryOtherOptions = pageGeneralSettings:createCategory{
                label = "Другие настройки"
            }

            -- Show/Hide the Credits Button --

            categoryOtherOptions:createYesNoButton{
                label = "Скрыть кнопку \"Титры\"",
                description = "Скрыть кнопку \"Титры\", что бы уменьшить размеры меню.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_hideCreditsButton_isEnabled",
                    table = config
                }
            }

            -- Show/Hide the Return Button --

            categoryOtherOptions:createYesNoButton{
                label = "Скрыть кнопку \"Назад\"",
                description = "Скрывает кнопку \"Назад\", что бы уменьшить размеры меню.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_hideReturnButton_isEnabled",
                    table = config
                }
            }

            -- The Verbosity of the Debug Messages --

            categoryOtherOptions:createDropdown{
                label = "Debug Messages Verbosity",
                description = "The verbosity of the debug messages in the log file.",
                options = {
                    { value = constants.logLevels.none,  label = "No Messages" },
                    { value = constants.logLevels.error, label = "Errors" },
                    { value = constants.logLevels.warn,  label = "Errors & Warnings" },
                    { value = constants.logLevels.info,  label = "Information Messages" },
                    { value = constants.logLevels.debug, label = "All Debug Information" },
                    { value = constants.logLevels.trace, label = "Bug-Tracing Infromation" }
                },
                variable = mwse.mcm.createTableVariable{
                    id = "logLevel",
                    table = config
                },
                callback = function(self)
                    log:setLogLevel(self.variable.value)
                end
            }

        end -- </Category: Other Options> --

    end -- </Side Bar Page: Options> --

end

event.register("modConfigReady", registerMCM)