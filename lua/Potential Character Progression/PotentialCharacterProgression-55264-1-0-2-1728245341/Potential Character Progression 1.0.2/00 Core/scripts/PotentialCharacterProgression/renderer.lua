local async = require('openmw.async')local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')

local info = require('scripts.PotentialCharacterProgression.info')
local L = core.l10n(info.name)

if core.API_REVISION < info.minApiVersion then
    return
end

local myui = require('scripts.' .. info.name .. '.myui')

local v2 = util.vector2

local gameSettings = {
    strengthName = core.getGMST('sAttributeStrength'),
    intelligenceName = core.getGMST('sAttributeIntelligence'),
    willpowerName = core.getGMST('sAttributeWillpower'),
    agilityName = core.getGMST('sAttributeAgility'),
    speedName = core.getGMST('sAttributeSpeed'),
    enduranceName = core.getGMST('sAttributeEndurance'),
    personalityName = core.getGMST('sAttributePersonality'),
    luckName = core.getGMST('sAttributeLuck')
}

local function disable(disabled, layout)
    if disabled then
        return {
            template = I.MWUI.templates.disabled,
            content = ui.content {
                layout
            }
        }
    else
        return layout
    end
end

I.Settings.registerRenderer(info.name .. 'KeyBind', function(value, set)
    local rendererLayout
    rendererLayout = {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                type = ui.TYPE.Container,
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        type = ui.TYPE.Container,
                        template = I.MWUI.templates.padding,
                        content = ui.content {
                            {
                                type = ui.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {autoSize = true, textAlignH = ui.ALIGNMENT.End, text = value and input.getKeyName(value) or 'Not Bound'},
                                events = {
                                    keyPress = async:callback(function(event)
                                        if event.code == input.KEY.Escape then
                                            return
                                        elseif event.code == input.KEY.Delete or event.code == input.KEY.Backspace then
                                            set(nil)
                                        else
                                            set(event.code)
                                        end
                                    end)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return rendererLayout
end)

-- Unused selection renderer
I.Settings.registerRenderer(info.name .. 'Select', function(value, set, argument)
    local optionsContent = ui.content {}
    for _, item in pairs(argument.items) do
        local itemColor = nil
        if tostring(item) == tostring(value) then
            itemColor = myui.interactiveTextColors.active.default
        end
        local itemLayout = {
            type = ui.TYPE.Container,
            template = myui.padding(0, 2),
            content = ui.content {
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {text = L(tostring(item)), textColor = itemColor, textAlignV = ui.ALIGNMENT.Center},
                    events = {
                        mouseClick = async:callback(function(mouseEvent, data)
                            set(tostring(item))
                        end)
                    }
                }
            }
        }
        optionsContent:add(itemLayout)
    end
    local rendererLayout = {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxSolid,
        props = {visible = true},
        content = ui.content {
            {
                type = ui.TYPE.Container,
                template = myui.padding(6,2),
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {},
                        content = optionsContent
                    }
                }
            }
        }
    }
    return disable(argument.disabled, rendererLayout)
end)

-- Modified version of default number renderer
local function validateNumber(text, argument)
    local number = tonumber(text)
    if not number then return end
    if argument.min and number < argument.min then return end
    if argument.max and number > argument.max then return end
    if argument.integer and math.floor(number) ~= number then return end
    return number
end

local function createAttributeField(value, set, argument, attribute, valueCopy, size)
    return {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                type = ui.TYPE.Container,
                template = myui.padding(2, 2),
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = tostring(value[attribute]),
                            size = size,
                        },
                        events = {
                            textChanged = async:callback(function(text)
                                lastInput = text
                            end),
                            focusLoss = async:callback(function()
                                if not lastInput then return end
                                local number = validateNumber(lastInput, argument)
                                if not number then
                                    set(valueCopy)
                                end
                                if number and number ~= value then
                                    valueCopy[attribute] = number
                                    set(valueCopy)
                                end
                            end),
                        }
                    }
                }
            }
        }
    }
end

-- Renderer for unique attribute caps
local function createUniqueCapField(value, set, argument, attribute)
    local lastInput = nil
    local caps = {}
    for k, v in pairs(value) do
        caps[k] = v
    end
    return {
        type = ui.TYPE.Flex,
        props = {horizontal = true, arrange = ui.ALIGNMENT.Center},
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {text = gameSettings[attribute .. 'Name'] .. ' '}
            },
            createAttributeField(value, set, argument, attribute, caps, v2(60, 0))
        }
    }
end

I.Settings.registerRenderer(info.name .. 'UniqueCaps', function(value, set, argument)
    local rendererLayout
    if argument.disabled then
        rendererLayout = {}
    else
        rendererLayout = {
            type = ui.TYPE.Flex,
            props = {arrange = ui.ALIGNMENT.End},
            content = ui.content {
                createUniqueCapField(value, set, argument, 'strength'),
                createUniqueCapField(value, set, argument, 'intelligence'),
                createUniqueCapField(value, set, argument, 'willpower'),
                createUniqueCapField(value, set, argument, 'agility'),
                createUniqueCapField(value, set, argument, 'speed'),
                createUniqueCapField(value, set, argument, 'endurance'),
                createUniqueCapField(value, set, argument, 'personality'),
                createUniqueCapField(value, set, argument, 'luck')
            }
        }
    end
    return rendererLayout
end)

-- Renderer for custom health coefficients
local function createCoefficientField(value, set, argument, attribute, first)
    local lastInput = nil
    local coeffs = {}
    for k, v in pairs(value) do
        coeffs[k] = v
    end
    local plus = {}
    if not first then
        plus = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {text = '+ '}
        }
    end
    return {
        type = ui.TYPE.Flex,
        props = {horizontal = true, arrange = ui.ALIGNMENT.Center},
        content = ui.content {
            plus,
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {text = L(attribute:gsub('^%l', string.upper) .. 'Abbreviation'), textAlignH = ui.ALIGNMENT.Center, autoSize = false, size = v2(35, 16)}
            },
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {text = ' x ', autoSize = false, size = v2(19, 18), textAlignV = ui.ALIGNMENT.Start}
            },
            createAttributeField(value, set, argument, attribute, coeffs, v2(20, 0))
        }
    }
end


I.Settings.registerRenderer(info.name .. 'Coefficients', function(value, set, argument)
    local rendererLayout = {
        type = ui.TYPE.Flex,
        props = {arrange = ui.ALIGNMENT.End},
        content = ui.content {
            createCoefficientField(value, set, argument, 'strength', true),
            createCoefficientField(value, set, argument, 'intelligence'),
            createCoefficientField(value, set, argument, 'willpower'),
            createCoefficientField(value, set, argument, 'agility'),
            createCoefficientField(value, set, argument, 'speed'),
            createCoefficientField(value, set, argument, 'endurance'),
            createCoefficientField(value, set, argument, 'personality'),
            createCoefficientField(value, set, argument, 'luck')
        }
    }
    return disable(argument.disabled, rendererLayout)
end)