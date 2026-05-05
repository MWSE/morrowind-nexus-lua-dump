local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local async = require('openmw.async')

local function paddedBox(layout)
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content { layout },
            },
        }
    }
end

local function validateDimension(text)
    local num = tonumber(text)
    if not num then return end
    num = util.clamp(num, 0, 1)
    return num
end

local function validatedTextInput(value, set, validate)
    local innerLayout = {
        template = I.MWUI.templates.textEditLine,
        props = {
            text = tostring(value),
            size = util.vector2(60, 0),
        },
        userData = {
            lastInput = nil,
        }
    }
    innerLayout.events = {
        textChanged = async:callback(function(text)
            innerLayout.userData.lastInput = text
        end),
        focusLoss = async:callback(function()
            if not innerLayout.userData.lastInput then return end
            local number = validate(innerLayout.userData.lastInput)
            if not number then
                set(value)
            end
            if number and number ~= value then
                set(number)
            end
        end),
    }
    local layout = paddedBox(innerLayout)
    return layout
end

local function windowDimensionsRenderer(value, set, arg)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = "Position",
                        }
                    },
                    {
                        template = I.MWUI.templates.interval,
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                            {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = " X ",
                                }
                            },
                            validatedTextInput(value.x, function(newX)
                                set {
                                    x = newX,
                                    y = value.y,
                                    w = value.w,
                                    h = value.h,
                                }
                            end, validateDimension),
                            {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = " Y ",
                                }
                            },
                            validatedTextInput(value.y, function(newY)
                                set {
                                    x = value.x,
                                    y = newY,
                                    w = value.w,
                                    h = value.h,
                                }
                            end, validateDimension),
                        }
                    }
                }
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = "Size",
                        }
                    },
                    {
                        template = I.MWUI.templates.interval,
                    },
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                            {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = " W ",
                                }
                            },
                            validatedTextInput(value.w, function(newW)
                                set {
                                    x = value.x,
                                    y = value.y,
                                    w = newW,
                                    h = value.h,
                                }
                            end, validateDimension),
                            {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = " H ",
                                }
                            },
                            validatedTextInput(value.h, function(newH)
                                set {
                                    x = value.x,
                                    y = value.y,
                                    w = value.w,
                                    h = newH,
                                }
                            end, validateDimension),
                        }
                    }
                }
            }
        }
    }
end

return {
    windowDimensions = windowDimensionsRenderer,
}