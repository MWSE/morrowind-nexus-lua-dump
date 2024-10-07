
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local v2 = util.vector2

local function myFunction(value, set)
    local name = "No Key Set"
    -- Retrieve existing keybindings
    if value then
        name = input.getKeyName(value)
    end

    -- Debug print to check values
    --print("myFunction called with value:", value)
    --print("Computed name:", name)

    return {
        template = I.MWUI.templates.box,

        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                props = {
                    anchor = v2(0.3, 0),
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        events = {
                            keyPress = async:callback(function(e)
                                if e.code == input.KEY.Escape then return end

                                set(e.code)  -- Update the setting with the new key code
                            end),
                        },
                        props = {
                            text = name,
							--textColor = util.color.rgb(50, 0, 0),
							textAlignH = ui.ALIGNMENT.End,
                        },
                    },
                },
            },
        },
    }
end


I.Settings.registerRenderer("nitroInputKeySelection", myFunction)



--[[
I.Settings.registerRenderer("nitroInputKeySelection", function(value, set)
    -- Debug print to check if this function is called
    --print("Renderer function called with value:", value)

    return myFunction(value, set)
end)
]]--