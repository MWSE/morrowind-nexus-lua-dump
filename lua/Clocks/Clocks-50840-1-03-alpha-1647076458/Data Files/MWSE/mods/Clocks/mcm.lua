local constants = require("Clocks.common.constants")
local config = require("Clocks.config").config

local relativePositions = constants.enumRelativePositions

local function registerModConfig()

    local template = mwse.mcm.createTemplate{ name = "Clocks" }
    template.onClose = function()
            config.save(true)
        end
    template:register()


    do -- Page: General Settings

        local pageGeneralSettings = template:createPage{
            label = "General Settings"
        }

        pageGeneralSettings:createYesNoButton{
            label = "Enable Clocks",
            variable = mwse.mcm.createTableVariable{
                id = "enableMod",
                table = config
            }
        }

        do -- Category: Clock Options

            local categoryClockOptions = pageGeneralSettings:createCategory{
                label = "Clock Options"
            }

            categoryClockOptions:createOnOffButton{
                label = "Game Clock",
                variable = mwse.mcm.createTableVariable{
                    id = "showGameTime",
                    table = config
                }
            }

            categoryClockOptions:createOnOffButton{
                label = "Real-Time Clock",
                variable = mwse.mcm.createTableVariable{
                    id = "showRealTime",
                    table = config
                }
            }

        end -- /Category: Clock Options

        do -- Category: Other Options

            local categoryOtherOptions = pageGeneralSettings:createCategory{
                label = "Other Options"
            }

            --[[
                TODO A more elegant approach would be to create a new EasyMCM component to handle
                the following button variations.
            ]]--
            local timeFormatLabels = {
                [true]  = "12-Hour",
                [false] = "24-Hour"
            }
            categoryOtherOptions:createButton{
                label = "Time Format",
                buttonText = timeFormatLabels[config.useTwelveHourTime],
                callback = function(self)
                        config.useTwelveHourTime = not config.useTwelveHourTime
                        
                        --[[
                            Info: The self.buttonText assignment ensures that the button's text
                            won't reset on the next button's press.
                        ]]--
                        self.buttonText = timeFormatLabels[config.useTwelveHourTime]
                        self:setText(self.buttonText)
                    end
            }

            --[[
                Warning: We assume that the table relativePositionLabels contains all the indices
                from 1 to some constant number. If this is not the case the following code won't
                function properly. By default, relativePositionLabels is indexed by an enumeration.
            ]]--
            local relativePositionLabels = {
                [relativePositions.above]  = "Above",
                [relativePositions.below] = "Below"
            }
            categoryOtherOptions:createButton{
                label = "Relative Position",
                buttonText = relativePositionLabels[config.clocksRelativePosition],
                callback = function(self)

                        local newSetting = config.clocksRelativePosition + 1
                        if not relativePositionLabels[newSetting] then
                            newSetting = 1
                        end
                        config.clocksRelativePosition = newSetting

                        --[[
                            Info: The self.buttonText assignment ensures that the button's text
                            won't reset on the next button's press.
                        ]]--
                        self.buttonText = relativePositionLabels[newSetting]
                        self:setText(self.buttonText)
                    end
            }

        end -- /Category: Other Options

    end -- /Page: General Settings

    do -- Page: UI Setups Cycling

        local pageUISetupsCycling = template:createPage{
            label = "UI Setups Cycling"
        }

        pageUISetupsCycling:createYesNoButton{
            label = "Enable UI Setups Cycling",
            variable = mwse.mcm.createTableVariable{
                id = "enableUISetupsCycling",
                table = config
            }
        }

        do -- Category: Options

            local categoryOptions = pageUISetupsCycling:createCategory{
                label = "Options"
            }

            categoryOptions:createKeyBinder{
                label = "Key Combination",
                allowCombinations = true,
                variable = mwse.mcm.createTableVariable{
                    id = "keyUISetupsCycling",
                    table = config
                }
            }

        end -- /Category: Options

    end -- /Page: UI Setups Cycling

    mwse.log("[Clocks] MCM Registered")

end

event.register("modConfigReady", registerModConfig)