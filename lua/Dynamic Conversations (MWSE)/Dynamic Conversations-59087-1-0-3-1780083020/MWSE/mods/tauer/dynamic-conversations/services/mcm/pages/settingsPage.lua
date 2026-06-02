local translations = require("tauer.dynamic-conversations.services.translations.translations")
local settings = require("tauer.dynamic-conversations.services.mcm.mcmSettings")

local EVENTS = require("tauer.dynamic-conversations.services.events.enums.EVENTS")
local TRANSLATION_KEY = require("tauer.dynamic-conversations.services.translations.enums.TRANSLATION_KEY")

---@class settingsPage : mcmPage
local this = {}

---@public
---@param template mwseMCMTemplate
function this.initialize(template)
    local page = template:createSideBarPage { label = translations.get(TRANSLATION_KEY.settingsLabel) }

    page:createOnOffButton {
        label = translations.get(TRANSLATION_KEY.modEnabledLabel),
        description = translations.get(TRANSLATION_KEY.modEnabledDescription),
        variable = mwse.mcm.createTableVariable { id = "enabled", table = settings.mcm },
        callback = function()
            event.trigger(EVENTS.modStateChanged, { enabled = settings.mcm.enabled })
        end,
    }

    page:createSlider {
        label = translations.get(TRANSLATION_KEY.conversationTimerLabel),
        description = translations.get(TRANSLATION_KEY.conversationTimerDescription),
        min = 1,
        max = 300,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable { id = "conversationTimer", table = settings.mcm },
        convertToLabelValue = function(_, variableValue)
            return string.format("%s %s", variableValue, translations.get(TRANSLATION_KEY.secondsLabel))
        end
    }

    page:createPercentageSlider {
        label = translations.get(TRANSLATION_KEY.conversationChanceLabel),
        description = translations.get(TRANSLATION_KEY.conversationChanceDescription),
        min = 0,
        max = 1,
        step = 0.01,
        jump = 0.05,
        variable = mwse.mcm.createTableVariable { id = "conversationChance", table = settings.mcm },
    }

    page:createSlider {
        label = translations.get(TRANSLATION_KEY.playerDistanceThresholdLabel),
        description = translations.get(TRANSLATION_KEY.playerDistanceThresholdDescription),
        min = 50,
        max = 2000,
        step = 5,
        jump = 20,
        variable = mwse.mcm.createTableVariable { id = "conversationDistance", table = settings.mcm },
    }

    page:createOnOffButton {
        label = translations.get(TRANSLATION_KEY.exteriorsOnlyLabel),
        description = translations.get(TRANSLATION_KEY.exteriorsOnlyDescription),
        variable = mwse.mcm.createTableVariable { id = "exteriorsOnly", table = settings.mcm },
    }

    page:createOnOffButton {
        label = translations.get(TRANSLATION_KEY.enableAnimationsLabel),
        description = translations.get(TRANSLATION_KEY.enableAnimationsDescription),
        variable = mwse.mcm.createTableVariable { id = "enableAnimations", table = settings.mcm },
    }

    page:createCategory {
        label = translations.get(TRANSLATION_KEY.debuggingCategoryLabel),
        description = translations.get(TRANSLATION_KEY.debuggingCategoryDescription),
    }

    page:createButton {
        label = translations.get(TRANSLATION_KEY.forceStopConversationLabel),
        buttonText = translations.get(TRANSLATION_KEY.forceStopConversationButton),
        description = translations.get(TRANSLATION_KEY.forceStopConversationDescription),
        inGameOnly = true,
        callback = function()
            tes3ui.showMessageMenu {
                message = translations.get(TRANSLATION_KEY.forceStopConversationConfirmation),
                buttons = {
                    { text = translations.get(TRANSLATION_KEY.yesButton), callback = function()
                        event.trigger(EVENTS.conversationForceStopped)
                    end },
                    { text = translations.get(TRANSLATION_KEY.noButton) }
                }
            }
        end
    }

    page:createLogLevelOptions {
        config = settings.mcm,
        configKey = "logLevel",
    }
end

return this
