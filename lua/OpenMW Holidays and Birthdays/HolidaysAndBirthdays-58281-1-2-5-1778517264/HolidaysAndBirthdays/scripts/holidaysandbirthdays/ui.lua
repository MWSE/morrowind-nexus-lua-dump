local self = require('openmw.self')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local constants = require('scripts.holidaysandbirthdays.constants')
local Helpers = require('scripts.holidaysandbirthdays.helpers')
local modinfo = require('scripts.holidaysandbirthdays.modinfo')
local l10n = core.l10n(modinfo.name)

PlayerAge = nil
PlayerBirthday = nil

local function acceptAgeUI(sourceUIElement, ageValue, bdValue, eventName)
    if ageValue == nil or bdValue == nil or ageValue == "" or bdValue == "" then
        ui.showMessage("Value can not be empty")
        return
    end
    if sourceUIElement then
        self:sendEvent(
            eventName,
            { age = ageValue, bd = bdValue })
        auxUi.deepDestroy(sourceUIElement)
        I.UI.setMode()
    end
end

local function sanitizeAndProcessNumericInput(text, preValidationMinimumValue, validationMinimumValue, maximumValue)
    -- validating positive numbers under max. Value will be brought up to minimum in actual processing later
    local as_str = Helpers.validateNumericInput(text, preValidationMinimumValue, maximumValue)
    local as_int = tonumber(as_str) or 0
    if as_str ~= "" then
        -- preventing values < minimum
        as_int = math.max(as_int, validationMinimumValue)
    end
    return { as_str = as_str, as_int = as_int }
end

local function displayAgeInputWindow()
    W = ui.create {
        layer = "Popup",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5)
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    { props = { size = util.vector2(0, 10) } }, {
                    template = I.MWUI.templates.textNormal,
                    props = { text = "  " .. l10n("ui_ask_for_age") .. "  " }
                }, {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = string.format("  Min: %d, Max: %d  ",
                            constants.minStartingCharacterAge,
                            constants.maxStartingCharacterAge)
                    }
                }, { props = { size = util.vector2(0, 10) } }, {
                    template = I.MWUI.templates.box,
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textEditLine,
                            props = {
                                text = "",
                                textSize = 14,
                                relativeSize = util.vector2(1, 1),
                            },
                            events = {
                                textChanged = async:callback(function(text, layout)
                                    local sanitizedInput = sanitizeAndProcessNumericInput(text, 1,
                                        constants.minStartingCharacterAge, constants.maxStartingCharacterAge)
                                    PlayerAge = sanitizedInput.as_int
                                    layout.props.text = sanitizedInput.as_str
                                    auxUi.deepUpdate(W)
                                end)
                            }
                        }

                    }
                }, { props = { size = util.vector2(0, 10) } }, {
                    template = I.MWUI.templates.textNormal,
                    props = { text = "  " .. l10n("ui_ask_for_birthday") .. "  " }
                }, {
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = string.format("  Min: %d for random, Max: %d  ",
                            0,
                            constants.maxBirthdayDay)
                    }
                }, { props = { size = util.vector2(0, 10) } },
                    {
                        template = I.MWUI.templates.box,
                        content = ui.content {
                            {
                                template = I.MWUI.templates.textEditLine,
                                props = {
                                    text = "",
                                    textSize = 14,
                                    relativeSize = util.vector2(1, 1),
                                },
                                events = {
                                    textChanged = async:callback(function(text, layout)
                                        local sanitizedInput = sanitizeAndProcessNumericInput(text, 0, 0,
                                            constants.maxBirthdayDay)
                                        PlayerBirthday = sanitizedInput.as_int
                                        layout.props.text = sanitizedInput.as_str
                                        auxUi.deepUpdate(W)
                                    end)
                                }
                            }

                        }
                    }, { props = { size = util.vector2(0, 10) } },
                    {
                        type = ui.TYPE.Flex,
                        content = ui.content {
                            {
                                template = I.MWUI.templates.box,
                                content = ui.content {
                                    {
                                        template = I.MWUI.templates.textNormal,
                                        props = { text = "OK" },
                                        events = {
                                            mouseClick = async:callback(function()
                                                acceptAgeUI(W, PlayerAge, PlayerBirthday,
                                                    "holidays_internal_uiChargenAgeStatsChanged")
                                            end)
                                        }
                                    }

                                }
                            }
                        }
                    }, { props = { size = util.vector2(0, 10) } }
                }
            }
        }
    }
    I.UI.setMode('Interface', { windows = {} })
end



return {
    displayAgeInputWindow = displayAgeInputWindow,
}
