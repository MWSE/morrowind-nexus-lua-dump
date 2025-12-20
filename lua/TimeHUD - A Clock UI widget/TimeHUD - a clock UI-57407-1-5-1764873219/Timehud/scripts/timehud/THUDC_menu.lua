local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local colorPicker = require('scripts.timehud.colorPicker')
local input = require('openmw.input')
local async = require('openmw.async')

local whiteTexture = ui.texture { path = 'white' }
local defaultArgument = {
    disabled = false,
}

local function applyDefaults(argument, defaults)
    if not argument then return defaults end
    if pairs(defaults) and pairs(argument) then
        local result = {}
        for k, v in pairs(defaults) do
            result[k] = v
        end
        for k, v in pairs(argument) do
            result[k] = v
        end
        return result
    end
    return argument
end

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

local function disable(disabled, layout)
    if disabled then
        return {
            template = I.MWUI.templates.disabled,
            content = ui.content {
                layout,
            },
        }
    else
        return layout
    end
end

I.Settings.registerRenderer('TH_color2', function(value, set, argument)
    argument = applyDefaults(argument, defaultArgument)
    local keyPressDetect = {
        type = ui.TYPE.Text,
        props = {
            autoSize = false,
            size = util.vector2(20, 20),
        },
        events = {
            keyPress = async:callback(function(e) if e.code == input.KEY.Escape then colorPicker.close() end end),
        },
    }
    local colorDisplay = {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = whiteTexture,
                    color = value,
                    -- TODO: remove hardcoded size when possible
                    size = util.vector2(20, 20),
                },
                content = ui.content{keyPressDetect},
            }
        },
        events = {
            mousePress = async:callback(function(e)
                colorPicker.open(set, value)
            end),
        },
    }
    local lastInput = nil
    local hexInput = paddedBox {
        template = I.MWUI.templates.textEditLine,
        props = {
            text = value:asHex(),
        },
        events = {
            textChanged = async:callback(function(text)
                lastInput = text
            end),
            focusLoss = async:callback(function()
                if not lastInput then return end
                if not pcall(function() set(util.color.hex(lastInput)) end)
                then
                    set(value)
                end
            end),
        },
    }
    return disable(argument.disabled, {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            colorDisplay,
            { template = I.MWUI.templates.interval },
            hexInput,
        }
    })
end)