local ui = require("openmw.ui")
local input = require("openmw.input")
local storage = require("openmw.storage")
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")

local config = require("scripts.MoveObjects.config")
local buttonToSet = nil
local controllerSettings = storage.playerSection("SettingsKeyBindings_aa")
local keyBindingsY = storage.playerSection("SettingsKeyBindings_aa2")
local keyBindings = storage.playerSection("AA_KeyBindings")
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

    if controllerSettings:get(y.props.keyName .. "_display") == "Press Button..." then
        local mousePress = nil
        if input.isMouseButtonPressed(1) then
            mousePress = "leftMb"
        elseif input.isMouseButtonPressed(3) then
            mousePress = "rightMb"
        end
        if mousePress then
            controllerSettings:set(buttonToSet .. "_display", defaultName(mousePress))
            buttonToSet = nil
        end
        return
    end
    buttonToSet = y.props.keyName
    prevVal[y.props.keyName] = controllerSettings:get(y.props.keyName .. "_display")
    controllerSettings:set(y.props.keyName.. "_display", "Press Button...")
    ui.showMessage(core.getGMST("sControlsMenu3"))
end

local function focusLoss(x, y)
    if controllerSettings:get(y.props.keyName) == "Press Button..." then
        print("focus lost",y.props.keyName )
        local mousePress = nil
        if input.isMouseButtonPressed(1) then
            mousePress = "leftMb"
        elseif input.isMouseButtonPressed(3) then
            mousePress = "rightMb"
        end
        if mousePress then
            controllerSettings:set(buttonToSet, defaultName(mousePress))
            buttonToSet = nil
        end
        if  prevVal[y.props.keyName] then
            
        controllerSettings:set(y.props.keyName .. "_display", prevVal[y.props.keyName])
        end
        return
    end
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
            mouseClick = async:callback(clickItem,set),
            --keyPress = async:callback(keyPress,set),
            focusLoss = async:callback(focusLoss,set),
        },
    }
end)
local function onKeyPress(key)
    if not buttonToSet or not key.code then return end
    if keyBindingsY:get("setType") == "Controller" then
        return
    end
    controllerSettings:set(buttonToSet .. "_display", input.getKeyName(key.code) .. " Key")
    keyBindings:set(buttonToSet .. "_key",key.code)
    buttonToSet = nil
end
local function onControllerButtonPress(ctrl)
    if not buttonToSet  then return end

    if keyBindingsY:get("setType") ~= "Controller" then
        return
    end
    local name = "Placeholder"
    for key, value in pairs(input.CONTROLLER_BUTTON) do
        if value == ctrl then
            name = key
        end
    end
    controllerSettings:set(buttonToSet .. "_display", name .. " Button")
    keyBindings:set(buttonToSet .. "_key",ctrl)
    buttonToSet = nil
end
return{
    engineHandlers = {
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress
    }
}