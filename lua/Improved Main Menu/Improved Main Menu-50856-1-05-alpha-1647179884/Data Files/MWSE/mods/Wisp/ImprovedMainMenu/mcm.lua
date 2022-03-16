local constants = require("Wisp.ImprovedMainMenu.common.constants")
local log       = require("Wisp.ImprovedMainMenu.common.debug").log
local config    = require("Wisp.ImprovedMainMenu.config").config

local function registerMCM()

    local template = mwse.mcm.createTemplate{ name = "Improved Main Menu" }
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
                label = "General Options"
            }

            -- Enable/Disable the Mod --

            categoryGeneralOptions:createYesNoButton{
                label = "Enable Mod",
                variable = mwse.mcm.createTableVariable{
                    id = "isModEnabled",
                    table = config
                }
            }

        end -- </Category: General Options> --

        do -- <Category: Continue Options> --

            local categoryContinueOptions = pageGeneralSettings:createCategory{
                label = "Continue Options"
            }

            -- Enable/Disable the Continue Button Addon --

            categoryContinueOptions:createYesNoButton{
                label = "Add a Continue Button",
                description = "Adds a Continue button to the main menu, which will load the most recent save game.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_continueButton_isEnabled",
                    table = config
                }
            }

            categoryContinueOptions:createDropdown{
                label = "Continue Button Visibility",
                description = "Determines when the Continue button should show up. It can be set to either <Always> or <Not In-Game>, where the later option limits it to show up only before loading a game and upon the player's death.",
                options = {
                    { value = constants.visibilityTypes.always, label = "Always" },
                    { value = constants.visibilityTypes.notInGame, label = "Not In-Game" }
                },
                variable = mwse.mcm.createTableVariable{
                    id = "addon_continueButton_visibility",
                    table = config
                }
            }

            -- Enable/Disable the Continue Confirmation Addon --

            categoryContinueOptions:createYesNoButton{
                label = "Ask for Continue Confirmation",
                description = "Prompt for user confirmation when pressing the Continue button.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_continueConfirmation_isEnabled",
                    table = config
                }
            }

            categoryContinueOptions:createDropdown{
                label = "Continue Prompt Visibility",
                description = "Determines when the Continue prompt should show up. It can be set to either <Always> or <In-Game>, where the later option limits it to show up only after loading a game and before the player's death.",
                options = {
                    { value = constants.visibilityTypes.always, label = "Always" },
                    { value = constants.visibilityTypes.inGame, label = "In-Game" }
                },
                variable = mwse.mcm.createTableVariable{
                    id = "addon_continueConfirmation_visibility",
                    table = config
                }
            }


        end -- </Category: Continue Options> --

        do -- <Category: New Game Options> --

            local categoryNewGameOptions = pageGeneralSettings:createCategory{
                label = "New Game Options"
            }

            -- Enable/Disable the New Game Confirmation Addon --

            categoryNewGameOptions:createYesNoButton{
                label = "Ask for New Game Confirmation",
                description = "Prompt for user confirmation when pressing the New Game button.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_newGameConfirmation_isEnabled",
                    table = config
                }
            }

            -- Show/Hide the New Game Button In-Game --

            categoryNewGameOptions:createYesNoButton{
                label = "Hide the New Game Button (In-Game)",
                description = "Hides the New Game button while the player is alive to prevent the Main Menu from bloating.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_hideNewGameButtonInGame_isEnabled",
                    table = config
                }
            }

        end -- </Category: New Game Options> --

        do -- <Category: Other Options> --

            local categoryOtherOptions = pageGeneralSettings:createCategory{
                label = "Other Options"
            }

            -- Show/Hide the Credits Button --

            categoryOtherOptions:createYesNoButton{
                label = "Hide the Credits Button",
                description = "Hides the Credits button to prevent the Main Menu from bloating.",
                variable = mwse.mcm.createTableVariable{
                    id = "addon_hideCreditsButton_isEnabled",
                    table = config
                }
            }

            -- Show/Hide the Return Button --

            categoryOtherOptions:createYesNoButton{
                label = "Hide the Return Button",
                description = "Hides the Return button to prevent the Main Menu from bloating.",
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