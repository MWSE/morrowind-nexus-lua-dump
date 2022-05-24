local utils = {}

function utils.getKeyPressRaw(keycode)
    return tes3.worldController.inputController:isKeyReleasedThisFrame(keycode)
end

return utils