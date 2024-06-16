do return end

local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require("openmw.interfaces")
local util = require('openmw.util')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local async = require('openmw.async')
local KEY = require('openmw.input').KEY
local input = require('openmw.input')
local v2 = util.vector2
local v3 = util.vector3
local menu = require('openmw.menu')
local function keyPress(x, y)
    if (x.code == nil) then
        return
    end
    --keyBindings:set(buttonToSet, { id = x.code })
    --I.AA_Bindings.updateBindingKey(y.props.keyName, x.code)
    --controllerSettings:set(buttonToSet, input.getKeyName(x.code) .. " Key")
    --buttonToSet = nil
    --skipThis = true
	print(x.code)
end
local function clickItem(x, y)
    if (skipThis == true) then
        --   skipThis = false
        --    return
    end

    -- print(aux_util.deepToString(y, 234))
    -- print(y.props.text)
    buttonToSet = y.props.keyName
    prevVal[y.props.keyName] = controllerSettings:get(y.props.keyName)
    controllerSettings:set(y.props.keyName, "Press Button...")
    ui.showMessage(core.getGMST("sControlsMenu3"))
    --print("Clicked")
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
local function textChanged(x, y)

end
local function focusLoss(x, y)
    buttonToSet = y.props.keyName
    if controllerSettings:get(y.props.keyName) == "Press Button..." then
        controllerSettings:set(y.props.keyName, prevVal[y.props.keyName])
    end
end
local function keyPress(x, y)
    if (x.code == nil) then
        return
    end
    keyBindings:set(buttonToSet, { id = x.code })
    I.AA_Bindings.updateBindingKey(y.props.keyName, x.code)
    controllerSettings:set(buttonToSet, input.getKeyName(x.code) .. " Key")
    buttonToSet = nil
    skipThis = true
end


I.Settings.registerRenderer('textKey', function(value, set, arg)
    return {
        type = ui.TYPE.Text,
        props = {
            size = util.vector2(arg and arg.size or 150, 30),
            text = value,
            keyName = arg.keyName,
            textColor = util.color.rgb(1, 1, 1),
            textSize = 15,
            textAlignV = ui.ALIGNMENT.End,
        },
        events = {
            mouseClick = async:callback(clickItem),
            textChanged = async:callback(textChanged),
            keyPress = async:callback(keyPress),
            focusLoss = async:callback(focusLoss),
        },
    }
end)
