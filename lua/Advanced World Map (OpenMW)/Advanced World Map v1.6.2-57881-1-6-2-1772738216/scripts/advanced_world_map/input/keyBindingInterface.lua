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
        version = 4,
        rendererName = "DijectKeyBindings:inputBinding",
        registerKey = function (id, keyStr)
            bindingSection:set(id, keyStr)
        end,
        -- available in version 2 and higher
        getActionKey = function (id)
            return bindingSection:get(id)
        end,
        -- available in version 3 and higher
        getKeyActions = function (keyCombination)
            local res = {}
            for id, bind in pairs(bindingSection:asTable()) do
                if bind == keyCombination then
                    table.insert(res, id)
                end
            end
            return next(res) and res or nil
        end,
        keybind = {
            register = keyBinding.register,
            unregister = keyBinding.unregister,
            isContainsHandler = keyBinding.isContainsHandler,
            -- available in version 4 and higher
            isPressed = keyBinding.isPressed,
        },
        action = {
            register = keyAction.registerAction,
            unregister = keyAction.unregisterAction,
            -- available in version 4 and higher
            isPressed = keyAction.isPressed,
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