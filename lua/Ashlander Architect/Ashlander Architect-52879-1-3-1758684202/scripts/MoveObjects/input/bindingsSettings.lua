local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local core = require("openmw.core")
local input = require("openmw.input")
local self = require('openmw.self')
local types = require('openmw.types')
local async = require("openmw.async")
local storage = require("openmw.storage")
local buttonToSet = nil
local aux_util = require('openmw_aux.util')
local keyBindings = storage.playerSection("AA_KeyBindings")
local bindings = {}
local showControllerBindings = false
local config = require("scripts.MoveObjects.config")

local keyBindingsX = storage.playerSection("SettingsKeyBindings_aa")
local keyBindingsY = storage.playerSection("SettingsKeyBindings_aa2")
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
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.Back,
        startPress = 0,
        endPress = 0,
        buttonText = "Back Button",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.DPadDown,
        startPress = 0,
        endPress = 0,
        buttonText = "DPad Down",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.DPadLeft,
        startPress = 0,
        endPress = 0,
        buttonText = "DPad Left",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.DPadRight,
        startPress = 0,
        endPress = 0,
        buttonText = "DPad Right",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.DPadUp,
        startPress = 0,
        endPress = 0,
        buttonText = "DPad Up",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.Guide,
        startPress = 0,
        endPress = 0,
        buttonText = "Guide Button",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.LeftShoulder,
        startPress = 0,
        endPress = 0,
        buttonText = "Left Shoulder",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.LeftStick,
        startPress = 0,
        endPress = 0,
        buttonText = "Left Stick Press",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.RightShoulder,
        startPress = 0,
        endPress = 0,
        buttonText = "Right Shoulder",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.RightStick,
        startPress = 0,
        endPress = 0,
        buttonText = "Right Stick Press",
        wasPressed = false,
    },
    {
        buttonVal = input.CONTROLLER_BUTTON.Start,
        startPress = 0,
        endPress = 0,
        buttonText = "Start Button",
        wasPressed = false,
    }
}
local function defaultName(key)
    if key == "leftMb" then
        return "Left MB"
    elseif key == "rightMb" then
        return "Right MB"
    else
        return input.getKeyName(key) .. " Key"
    end
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
local function setDisplayValues()
    local val = keyBindingsY:get("setType")
    showControllerBindings = val == "Controller"
    for key, value in pairs(bindings) do
        if showControllerBindings then
            local ctrl = keyBindings:get(key .. "_ctrl") or value.controllerButton

            local ctrlName = tostring(value.controllerButton)
            for index, value in ipairs(controllerKeys) do
                if value.buttonVal == ctrl then
                    ctrlName = value.buttonText
                end
            end
            if not ctrlName then
                ctrlName = "Placeholder"
            end
            keyBindingsX:set(key .. "_display", ctrlName)
        else
            local ctrl = keyBindings:get(key .. "_key")
            config.print(key)
            local ctrlName = defaultName(ctrl)
            if not ctrlName then
                ctrlName = "Placeholder"
            end
            keyBindingsX:set(key .. "_display", ctrlName)
        end
    end
end
local function registerSettings(mbindings)
    config.print("Register settings")
    bindings = mbindings
    local set = {{
        key = "reset",
        renderer = "checkbox",
        name = "Reset to Default",
        default = true,
        description = "Toggle this to reset each binding to the default value"
    }}

    for key, value in pairs(bindings) do
        --config.print(value.shortDesc)
        --  config.print((value.key))
        if (value.key ~= "leftMb" and value.key ~= "rightMb" and not value.isHidden) then
            --config.print(value.key)
            local tbl = {
                key = key .. "_display",
                renderer = "textKey",
                name = string.format(value.shortDesc, "Toggle"),
                default = defaultName(value.defaultKey),
                argument = { keyName = key },
            }

            table.insert(set, tbl)
        end
    end
    setDisplayValues()
    if settingsRegistered then return end
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
    I.Settings.registerGroup {
        key = "SettingsKeyBindings_aa2",
        page = "AA_KeyBindings",
        l10n = "KeyBindings",
        name = "Binding Type Select",
        permanentStorage = true,
        settings = {
            {
                key = "setType",
                renderer = "select",
                name = "Use Controller or KB",
                default = "Keyboard/Mouse",
                argument = {    
                    items = { "Keyboard/Mouse", "Controller" },
                    l10n = "me",
                },
            }
        }
    }

    settingsRegistered = true
end
local time
keyBindingsX:subscribe(async:callback(function(section, key)
   if key == "reset" then
     I.AA_Actions.registerDefaultBindings(true)
     setDisplayValues()
    else
        config.print(key)
        print(os.time())
        print(time)
        time = os.time()
        
        print(keyBindingsX:get(key))
    end
end))
keyBindingsY:subscribe(async:callback(function(section, key)
    if key == "setType" then
        setDisplayValues()
    elseif not key then
        config.print("full reset")
    else
        config.print(key)
    end
end))

local bindings = {}
local function processCtrlButtonPress(id, pressType)
    --("Process")
            if not types.Player.isCharGenFinished(self) then return end
    if (buttonToSet ~= nil) then
        for index, value in ipairs(controllerKeys) do
            if (value.buttonVal == id) then
                --config.print("Set try")
                keyBindings:set(buttonToSet, { id = id, pressType = pressType })
                buttonToSet = nil
                ui.showMessage("Set binding to ... " .. value.buttonText)
                skipThis = true
            end
        end
    end
    for index, value in ipairs(controllerKeys) do
        if (value.buttonVal == id) then
            --  config.print(value.buttonText, pressType)
        end
    end
end
local function registerBinding(bindingName, keyId, ControllerID)

end


local longPressTime = 0.4
local doublePressTime = 0.2
local function onControllerButtonPress(id)
            if not types.Player.isCharGenFinished(self) then return end
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
            if not types.Player.isCharGenFinished(self) then return end
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



local function onFrame(dt)
            if not types.Player.isCharGenFinished(self) then return end
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
        registerSettings = registerSettings,
    },
}
