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
local controllerSettings = storage.playerSection("SettingsKeyBindings")
local keyBindings = storage.playerSection("KeyBindings")
local skipThis = false
local function clickItem(x, y)
    if (skipThis == true) then
        skipThis = false
        return
    end
    print(aux_util.deepToString(y, 234))
    print(y.props.text)
    buttonToSet = y.props.keyName
    controllerSettings:set(y.props.keyName, "Press Button...")
    print("Clicked")
end
local function textChanged(x, y)

end
I.Settings.registerRenderer('textKey', function(value, set, arg)
    return {
        type = ui.TYPE.TextEdit,
        props = {
            size = util.vector2(arg and arg.size or 150, 30),
            text = value,
            keyName = arg.keyName,
            textColor = util.color.rgb(1, 1, 1),
            textSize = 15,
            textAlignV = ui.ALIGNMENT.End,
        },
        events = {
            focusGain = async:callback(clickItem),
            textChanged = async:callback(textChanged),
        },
    }
end)

I.Settings.registerPage {
    key = "KeyBindings",
    l10n = "KeyBindings",
    name = "KeyBindings",
    description = "KeyBindings"
}
I.Settings.registerGroup {
    key = "SettingsKeyBindings",
    page = "KeyBindings",
    l10n = "KeyBindings",
    name = "KeyBindings",
    description = "KeyBindings",
    permanentStorage = false,
    settings = {
        {
            key = "DisableJumping",
            renderer = "textKey",
            name = "Disable Jumping in Build Mode",
            description =
            "If set to true, then jumping will be disabled while in build mode. This allows for more buttons to be reused.",
            default = "A Button",
            argument = { keyName = "DisableJumping" },
        },
        {
            key = "EnableButtonBox",
            renderer = "checkbox",
            name = "Display Button Info Window",
            description =
            "If set to true, then while in build mode, you will see a box with infomration on what keys/buttons you can press.",
            default = "true"
        },
        {
            key = "KeepOffset",
            renderer = "checkbox",
            name = "Keep objects offset from where you grabbed it",
            description =
            "If set to true, this will prevent objects from jumping to where your cursor is when you grab it.",
            default = true
        },
        {
            key = "AllowGrabAll",
            renderer = "checkbox",
            name = "Allow grabbing any object",
            default = false,
            description =
            "By default, you may only grab items, objects you can place, and natural objects like plants and rocks. This allows you to grab any object in your crosshairs.",

        }
    }
}


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
    print("Process")
    if (buttonToSet ~= nil) then
        for index, value in ipairs(controllerKeys) do
            if (value.buttonVal == id) then
                print("Set try")
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
            print(value.buttonText, pressType)
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
    interfaceName = "ZackUtils_Bindings",
    interface = {
        version = 1,
        registerBinding = registerBinding,
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
