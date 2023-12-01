local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local async = require("openmw.async")
local shortPressTime = 0
local buttonToSet = nil
local aux_util = require('openmw_aux.util')
local controllerSettings = storage.playerSection("SettingsKeyBindings_aa")
local keyBindings = storage.playerSection("AA_KeyBindings")
local skipThis = false
local prevVal = {}
local function defaultName(key)
    if key == "leftMb" then
        return "Left MB"
    elseif key == "rightMb" then
        return "Right MB"
    else
        return input.getKeyName(key) .. " Key"
    end
end
local function clickItem(x, y)
    if (skipThis == true) then
        --   skipThis = false
        --    return
    end
    buttonToSet = y.props.keyName
    if controllerSettings:get(y.props.keyName) == "Press Button..." then
        local mousePress = nil
        if input.isMouseButtonPressed(1) then     --left
            mousePress = "leftMb"
        elseif input.isMouseButtonPressed(3) then --right
            mousePress = "rightMb"
        end
        if mousePress then
            keyBindings:set(buttonToSet, { id = mousePress })
            I.AA_Bindings.updateBindingKey(y.props.keyName, mousePress)
            controllerSettings:set(buttonToSet, defaultName(mousePress))
            buttonToSet = nil
            skipThis = true
        end

        return
    end
    -- print(aux_util.deepToString(y, 234))
   -- print(y.props.keyName)
    --print( controllerSettings:get(y.props.keyName))
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
        local mousePress = nil
        if input.isMouseButtonPressed(1) then     --left
            mousePress = "leftMb"
        elseif input.isMouseButtonPressed(3) then --right
            mousePress = "rightMb"
        end
        if mousePress then
            keyBindings:set(buttonToSet, { id = mousePress })
            I.AA_Bindings.updateBindingKey(y.props.keyName, mousePress)
            controllerSettings:set(buttonToSet, defaultName(mousePress))
            buttonToSet = nil
            skipThis = true
        end

        return
    end
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

local defaultArgument = {
    disabled = false,
    l10n = nil,
    items = {},
}
local leftArrow = ui.texture {
    path = 'textures/omw_menu_scroll_left.dds',
}
local rightArrow = ui.texture {
    path = 'textures/omw_menu_scroll_right.dds',
}
local settingsRegistered = false
local function registerSettings(bindings)
    local set = {}
    if settingsRegistered then return end
    for key, value in pairs(bindings) do
        --print(value.shortDesc)
        --  print((value.key))
        if (value.key ~= "leftMb" and value.key ~= "rightMb" and not value.isHidden) then
            --print(value.key)
            local tbl = {
                key = key,
                renderer = "textKey",
                name = string.format(value.shortDesc, "Toggle"),
                default = defaultName(value.defaultKey),
                argument = { keyName = key },
            }

            table.insert(set, tbl)
        end
    end
    I.Settings.registerPage {
        key = "AA_KeyBindings",
        l10n = "KeyBindings",
        name = "Ashlander Architect KeyBindings",
        description = "KeyBindings"
    }
    I.Settings.registerGroup {
        key = "SettingsKeyBindings_aa",
        page = "AA_KeyBindings",
        l10n = "KeyBindings",
        name = "KeyBindings",
        description = "KeyBindings",
        permanentStorage = true,
        settings = set
    }
    settingsRegistered = true
end


local bindings = {}
local controllerKeys = {
    {
        buttonVal = input.CONTROLLER_BUTTON.X,
        startPress = 0,
        endPress = 0,
        buttonText = "X Button",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.A,
        startPress = 0,
        endPress = 0,
        buttonText = "A Button",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.B,
        startPress = 0,
        endPress = 0,
        buttonText = "B Button",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.Y,
        startPress = 0,
        endPress = 0,
        buttonText = "Y Button",
        wasPressed = false,
    }
}
local function processCtrlButtonPress(id, pressType)
    --("Process")
    if (buttonToSet ~= nil) then
        for index, value in ipairs(controllerKeys) do
            if (value.buttonVal == id) then
                --print("Set try")
                controllerSettings:set(buttonToSet, value.buttonText .. pressType)
                keyBindings:set(buttonToSet, { id = id, pressType = pressType })
                buttonToSet = nil
                ui.showMessage("Set binding to ... " .. value.buttonText)
                skipThis = true
            end
        end
    end
    for index, value in ipairs(controllerKeys) do
        if (value.buttonVal == id) then
          --  print(value.buttonText, pressType)
        end
    end
end
local function registerBinding(bindingName, keyId, ControllerID)

end


local longPressTime = 0.4
local doublePressTime = 0.2
local function onControllerButtonPress(id)
    for index, value in ipairs(controllerKeys) do
        if value.buttonVal == id then
            if value.endPress > 0 and core.getRealTime() < value.endPress then
                processCtrlButtonPress(id, "Double")
                -- Reset the endPress time to prevent a normal press from being triggered
                controllerKeys[index].endPress = -1
                controllerKeys[index].startPress = 0
            else
                controllerKeys[index].startPress = core.getRealTime()
            end
        end
    end
end

local function onControllerButtonRelease(id)
    for index, value in ipairs(controllerKeys) do
        if value.buttonVal == id then
            if (value.endPress == -1) then
                controllerKeys[index].endPress = 0
                return
            end
            if core.getRealTime() - value.startPress > longPressTime then
                processCtrlButtonPress(id, "Long")
                --                ui.showMessage("Long pressed: " .. value.buttonText .. tostring(core.getRealTime() - value.startPress))
                controllerKeys[index].endPress = 0
                controllerKeys[index].startPress = 0
            elseif controllerKeys[index].endPress == 0 then
                controllerKeys[index].endPress = core.getRealTime() + doublePressTime
            end
        end
    end
end


local function onKeyPress(key)
    for index, value in ipairs(controllerKeys) do
        if value.buttonVal == key and value.endPress > 0 and core.getRealTime() < value.endPress then
            -- A double press occurred, so don't process the normal press
            return
        end
    end
    -- Process the normal press here
end

local function onFrame(dt)
    for index, value in ipairs(controllerKeys) do
        if (input.isControllerButtonPressed(value.buttonVal) and value.wasPressed == false) then
            onControllerButtonPress(value.buttonVal)
            controllerKeys[index].wasPressed = true
        elseif (input.isControllerButtonPressed(value.buttonVal) == false and value.wasPressed == true) then
            onControllerButtonRelease(value.buttonVal)
            controllerKeys[index].wasPressed = false
        end
        if value.endPress > 0 and core.getRealTime() > value.endPress then
            processCtrlButtonPress(value.buttonVal, "Single")
            controllerKeys[index].endPress = 0
        end
    end
end

local function onSave()
    return { bindings = bindings }
end
local function onLoad(data)
    if (data) then
        bindings = data.bindings
    end
end

return {
    interfaceName = "ZackUtils_Bindings_AA",
    interface = {
        version = 1,
        registerBinding = registerBinding,
        registerSettings = registerSettings,
    },
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease,
        onFrame = onFrame,
    },
    eventHandlers = {
        createItemReturn = createItemReturn,
        printToConsoleEvent = printToConsoleEvent,
        addItemEquipReturn = addItemEquipReturn,
    },
}
