local util = require('openmw.util')
local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local v2 = util.vector2

local DEFAULT_VALUE = 24 -- Default scaling value
local MIN_VALUE = 1    -- Minimum allowable value
local MAX_VALUE = 100     -- Maximum allowable value

local function validateInput(input, defaultValue)
    local numValue = tonumber(input)  -- Try converting the input to a number
    if not numValue then
        ui.showMessage("Invalid input! Resetting to default value.")
        return defaultValue or DEFAULT_VALUE
    end

    -- Clamp the number within the specified bounds
    if numValue < MIN_VALUE or numValue > MAX_VALUE then
        ui.showMessage("Value out of bounds! Clamping to allowed range.")
        return util.clamp(numValue, MIN_VALUE, MAX_VALUE)
    end

    return numValue  -- Return the valid number
end

I.Settings.registerRenderer(
    'inputText',
    function(value, set, arg)
        local defaultValue = arg.defaultValue or DEFAULT_VALUE  -- Default to 24 if no default is provided
        return {
            template = I.MWUI.templates.box,
            content = ui.content({
            {
                props = {
                    size = v2(arg and arg.size or 50, 15),
                },
                content = ui.content({
                    {
                        type = ui.TYPE.TextEdit,
                        props = {
                            size = v2(arg and arg.size or 50, 15),  -- Set size, defaulting to 150x30
                            text = tostring(value),  -- Initial text set to current value
                            textColor = util.color.rgb(202 / 255, 165 / 255, 96 / 255),  -- White text color
                            textSize = 15,  -- Text size
                            textAlignV = ui.ALIGNMENT.Start,  -- Vertical alignment
                            textAlignH = ui.ALIGNMENT.End,
                        },
                        events = {
                            textChanged = async:callback(function(newText)
                                local validatedValue = validateInput(newText, defaultValue)  -- Validate the new input
                                set(validatedValue)  -- Update the setting with the validated value
                            end),
                        },
                    }
                }),
            }
            })
        }
    end
)

I.Settings.registerRenderer(
    'myToggle',
    function(value, set, arg)
        -- Determine the initial state
        local selectedOption = value or "Unshade"  -- Default to "Shade"

        -- Function to toggle between "Shade" and "Unshade"
        local function toggle()
            if selectedOption == "Shade" then
                selectedOption = "Unshade"
            else
                selectedOption = "Shade"
            end
            set(selectedOption)  -- Update the setting value
        end

        -- Return the renderer with toggleable text
        return {
            template = I.MWUI.templates.box,  -- Use the provided template for box styling
            content = ui.content({
                {
                    template = I.MWUI.templates.padding,
                    content = ui.content({
                        {
                            type = ui.TYPE.Text,  -- Use text type for clickable option
                            props = {
                                text = selectedOption,  -- Display current state
                                textColor = util.color.rgb(202 / 255, 165 / 255, 96 / 255),  -- Custom text color
                                textSize = 15,  -- Text size
                                textAlignH = ui.ALIGNMENT.Center,  -- Center align the text horizontally
                                textAlignV = ui.ALIGNMENT.Center,
                                size = v2(60,20),
                                autoSize = false
                            },
                            events = {
                                mousePress = async:callback(function(e)
                                    if e.button ~= 1 then return end
                                    toggle()  -- Toggle the option when clicked
                                end),
                            },
                        },
                    })
                },
            })
        }
    end
)