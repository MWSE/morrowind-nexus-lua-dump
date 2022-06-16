local utils = {}

function utils.getKeyHold(keybind)
        return tes3.worldController.inputController:isKeyDown(tes3.worldController.inputController.inputMaps[keybind + 1].code)
end

function utils.getKeyPress(keybind)
    return tes3.worldController.inputController:isKeyReleasedThisFrame(tes3.worldController.inputController.inputMaps[keybind + 1].code)
end

function utils.getKeyHoldRaw(keycode)
        return tes3.worldController.inputController:isKeyDown(keycode)
end

function utils.getKeyPressRaw(keycode)
    return tes3.worldController.inputController:isKeyReleasedThisFrame(keycode)
end

return utils