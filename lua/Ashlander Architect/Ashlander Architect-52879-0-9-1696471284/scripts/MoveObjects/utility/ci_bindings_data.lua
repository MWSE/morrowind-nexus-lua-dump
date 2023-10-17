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
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")
local bindings = {}
local keyBindings = storage.playerSection("KeyBindings")
local keyBindingSettings = storage.playerSection("SettingsKeyBindings")
local controllerModifers = { longPress = "longPress", doublePress = "doublePress" }
local function registerBinding(bindingName, shortDesc, keyId, controllerButton, controllerModifer,isHidden)
    local mouseButton = nil
    local keyX = keyId
    if keyBindings:get(bindingName) ~= nil and true == false then
        keyX = keyBindings:get(bindingName).id
    end
    if (keyId == "left" or keyId == "right") then
        mouseButton = keyId
        keyX = -1
        keyId = -1
    end

    bindings[bindingName] = {
        key = keyX,
        controllerButton = controllerButton,
        shortDesc = shortDesc,
        pressed = false,
        mouseButton = mouseButton,
        controllerModifer = controllerModifer,
        defaultKey = keyId,
        isHidden = isHidden
    }
    return bindings[bindingName]
end
keyBindings:subscribe(async:callback(function(section, key)
    if key then
        if bindings[key] ~= nil then
            bindings[key].key = keyBindings:get(key).id
        end
    elseif not key then
        print("full reset")
    end
end))

keyBindingSettings:subscribe(async:callback(function(section, key)
    if not key then
       I.MoveObjects.registerDefaultBindings()
       print("full reset")
    else
        print(key)
    end
end))
local function updateBindingKey(bindingId, keyId)
    local binding = bindings[bindingId]
    if (binding) then
        if keyId == "left" or keyId == "right" then
            binding.mouseButton = keyId
            binding.key = -1
            return
        end
        binding.mouseButton = nil
        binding.key = keyId
    end
end
local passedKey, passedCtrl = nil, nil
local longPressTime = 15
local function passInput(ctrl, key, release)
    passedKey = key
    passedCtrl = ctrl
    local valid = false
    for bindingName, binding in pairs(bindings) do
        -- print(key, binding.key, bindingName, binding.pressed)
        if (key and key == binding.key and not release) then
            binding.pressed = true
        elseif (ctrl and ctrl == binding.controllerButton and not binding.controllerModifer and not release) then
            binding.pressed = true
        elseif (ctrl and ctrl == binding.controllerButton and binding.controllerModifer == controllerModifers.longPress) then
            if (release and core.getGameTime() - binding.pressStart > 15) then
                binding.pressed = true
            else
                binding.pressStart = core.getGameTime()
                binding.pressed = false
            end
        elseif binding.mouseButton and binding.mouseButton == "left" and not release then
            binding.pressed = input.isMouseButtonPressed(1)
        elseif binding.mouseButton and binding.mouseButton == "right" and not release then
            binding.pressed = input.isMouseButtonPressed(3)
        elseif binding.key and input.isKeyPressed(binding.key) then
            binding.pressed = true
        else
            binding.pressed = false
        end
        valid = true
    end
    if not valid then return nil end
    return bindings
end
local function clearInput()
    passedKey = nil
    passedCtrl = nil
end
local function checkBinding(bindingName, controllerButton, keyId)
    local binding = bindings[bindingName]

    if controllerButton and binding.controllerButton == controllerButton then
        return true
    elseif keyId and binding.key == keyId then
        return true
    elseif passedCtrl and binding.controllerButton == passedCtrl then
        clearInput()
        return true
    elseif passedKey and binding.key == passedKey then
        clearInput()
        return true
    end
    if (controllerButton or keyId or passedKey or passedCtrl) then return false end
    if (input.isControllerButtonPressed(binding.controllerButton)) then
        return true
    elseif input.isKeyPressed(binding.key) then
        return true
    end
    return false
end
local function UpdateButtonLabel(bindingName, controllerMode)
    for bindingName, binding in pairs(bindings) do
        for key, value in pairs(input.KEY) do
            if value == binding.key then
                binding.keyLabel = key
            end
        end

        for key, value in pairs(input.CONTROLLER_BUTTON) do
            if value == binding.key then
                binding.controllerLabel = key
            end
        end
    end
end
local function getButtonLabel(bindingName, controllerMode)
    local binding = bindings[bindingName]
    if not controllerMode then
        if binding.mouseButton then
            if binding.mouseButton == "left" then
                return "Left Mouse Button"
            elseif binding.mouseButton == "right" then
                return "Right Mouse Button"
            end
        end
        for key, value in pairs(input.KEY) do
            if value == binding.key then
                return key
            end
        end
    else
        for key, value in pairs(input.CONTROLLER_BUTTON) do
            if value == binding.key then
                return key
            end
        end
    end
end
local function getBindingDesc(bindingName, withKey)
    local binding = bindings[bindingName]

    if (binding and not withKey) then
        return binding.shortDesc
    elseif binding and withKey then
        return binding.shortDesc .. ": " .. getButtonLabel(bindingName)
    end
end

local function loopKeys()
    for key, value in pairs(input.CONTROLLER_BUTTON) do
        print(key)
    end
end
local function loadSettings()
    I.ZackUtils_Bindings_AA.registerSettings(bindings)
end
return {
    interfaceName = "AA_Bindings",
    interface = {
        version = 1,
        registerBinding = registerBinding,
        checkBinding = checkBinding,
        getBindingDesc = getBindingDesc,
        getButtonLabel = getButtonLabel,
        loopKeys = loopKeys,
        passInput = passInput,
        updateBindingKey = updateBindingKey,
        controllerModifers = controllerModifers,
        loadSettings = loadSettings,
    },
    eventHandlers = {

    },
    engineHandlers = {
    }
}
