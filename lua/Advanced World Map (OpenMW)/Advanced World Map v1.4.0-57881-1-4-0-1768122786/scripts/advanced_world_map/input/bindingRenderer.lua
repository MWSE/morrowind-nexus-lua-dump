local core = require("openmw.core")
local input = require("openmw.input")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local I = require("openmw.interfaces")


local wasInitialized = I.DijectKeyBindings ~= nil
if wasInitialized then return end


local bindingSection = storage.playerSection("AdvWMap:InputBindings")
bindingSection:setLifeTime(storage.LIFE_TIME.Persistent)


local commonData = require("scripts.advanced_world_map.common")

local keyBinding = require("scripts.advanced_world_map.input.keyBinding")
local keyCodes = require("scripts.advanced_world_map.input.keyCodes")


local defaultColor = util.color.rgb(202/255, 165/255, 96/255)
local rendererName = "DijectKeyBindings:inputBinding"


---@type {func : function, id : string, comb : string?, combLen : integer, isSecondInput : boolean?}?
local recording = nil


I.Settings.registerRenderer(rendererName, function(value, set, argument)
    argument = argument or {}

    local l10n = core.l10n(argument.l10n or commonData.l10nKey)

    local actionId = argument.action

    local binding = bindingSection:get(actionId)

    local recorder
    recorder = {
        template = I.MWUI.templates.textNormal,
        props = {
            text = bindingSection:get(actionId) or l10n("Undefined"),
            textSize = 16,
            size = util.vector2(250, 32),
            autoSize = false,
            multiline = true,
            wordWrap = true,
            textAlignH = ui.ALIGNMENT.End,
            textAlignV = ui.ALIGNMENT.Center,
            textColor = recording and util.color.rgb(0.5, 1, 0.5) or nil
        },
        events = {
            mouseRelease = async:callback(function(e)
                if recording ~= nil then return end
                if e.button == 1 then
                    if binding ~= nil then bindingSection:set(actionId, nil) end
                    recording = {
                        id = actionId,
                        arg = arg,
                        func = function(val) set(val) end,
                        combLen = 0,
                    }
                    set(nil)
                elseif e.button == 3 then
                    bindingSection:set(actionId, nil)
                    set(nil)
                end
            end),
        },
    }


    return recorder
end)


local function registerBinding()
    if not recording then return end

    bindingSection:set(recording.id, recording.comb)
    local func = recording.func
    local comb = recording.comb
    recording = nil
    func(comb)

    keyBinding.resetPressed()
end


return{
    interfaceName = "DijectKeyBindings",
    interface = {
        version = 1,
        rendererName = rendererName,
        registerKey = function (id, keyStr)
            bindingSection:set(id, keyStr)
        end
    },
    engineHandlers = {
        onKeyPress = function(key)
            if not recording then return end
            keyBinding.onKeyPressRenderer(key)
        end,

        onMouseButtonPress = function(button)
            if not recording then return end
            keyBinding.onMouseButtonPressRenderer(button)
        end,

        onControllerButtonPress = function(id)
            if not recording then return end
            keyBinding.onControllerButtonPressRenderer(id)
        end,

        onKeyRelease = function (key)
            if not recording then return end
            if key.code == input.KEY.Escape then
                registerBinding()
                return
            end

            local keyCode = keyCodes.getKeyboardKeyId(key.code)
            local comb, keys = keyBinding.getKeyCombinationString(keyCode)

            if comb and #keys >= recording.combLen then
                recording.combLen = #keys
                recording.comb = comb
            end

            keyBinding.onKeyReleaseRenderer(key)

            if not keyBinding.hasPressedKeys() then
                registerBinding()
            end
        end,

        onMouseButtonRelease = function (buttonId)
            if wasInitialized or not recording then return end

            local isFirstKey = not recording.isSecondInput
            recording.isSecondInput = true

            local comb, keys = keyBinding.getKeyCombinationString()
            if comb and #keys >= recording.combLen then
                recording.combLen = #keys
                recording.comb = comb
            end

            keyBinding.onMouseButtonReleaseRenderer(buttonId)

            if not isFirstKey and not keyBinding.hasPressedKeys() then
                registerBinding()
            end
        end,

        onControllerButtonRelease = function (key)
            if wasInitialized or not recording then return end

            if key == input.CONTROLLER_BUTTON.B and recording.combLen == 0 then
                registerBinding()
                return
            end

            local isFirstKey = not recording.isSecondInput
            recording.isSecondInput = true

            keyBinding.onControllerButtonReleaseRenderer(key)

            local keyCode = keyCodes.getControllerButtonId(key)
            local comb, keys = keyBinding.getKeyCombinationString(keyCode)
            if comb and #keys >= recording.combLen then
                recording.combLen = #keys
                recording.comb = comb
            end

            if not isFirstKey and not keyBinding.hasPressedKeys() then
                registerBinding()
            end
        end
    },
}