local storage = require("openmw.storage")
local I = require("openmw.interfaces")

local alreadyInitialized = I.DijectKeyBindings ~= nil
if alreadyInitialized then return end

local keyBinding = require("scripts.advanced_world_map.input.keyBinding")
local keyAction = require("scripts.advanced_world_map.input.keyAction")

local bindingSection = storage.playerSection("AdvWMap:InputBindings")
bindingSection:setLifeTime(storage.LIFE_TIME.Persistent)

return{
    interfaceName = "DijectKeyBindings",
    interface = {
        version = 1,
        rendererName = "DijectKeyBindings:inputBinding",
        registerKey = function (id, keyStr)
            bindingSection:set(id, keyStr)
        end,
        keybind = {
            register = keyBinding.register,
            unregister = keyBinding.unregister,
            isContainsHandler = keyBinding.isContainsHandler,
        },
        action = {
            register = keyAction.registerAction,
            unregister = keyAction.unregisterAction,
        }
    },
    engineHandlers = {
        onKeyPress = keyBinding.onKeyPress,
        onMouseButtonPress = keyBinding.onMouseButtonPress,
        onControllerButtonPress = keyBinding.onControllerButtonPress,
        onKeyRelease = keyBinding.onKeyRelease,
        onMouseButtonRelease = keyBinding.onMouseButtonRelease,
        onControllerButtonRelease = keyBinding.onControllerButtonRelease,
    },
}