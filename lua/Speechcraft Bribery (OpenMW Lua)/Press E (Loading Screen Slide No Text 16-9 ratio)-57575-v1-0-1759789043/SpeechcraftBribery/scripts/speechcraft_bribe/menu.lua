-- scripts/speechcraft_bribe/menu.lua
local input = require('openmw.input')
local I = require('openmw.interfaces')
local BribeUI = require('scripts.speechcraft_bribe.ui')

local GamepadControls = I.GamepadControls

local function ensureCursorOn()
    -- Keep the gamepad-driven cursor alive while our UI is visible.
    -- If controller menus are enabled and cursor is off, turn it back on.
    if GamepadControls and GamepadControls.isControllerMenusEnabled()
       and not GamepadControls.isGamepadCursorActive() then
        GamepadControls.setGamepadCursorActive(true)
    end
end

return {
    engineHandlers = {
        -- Called after input every frame (even on pause) for menu/player scripts.
        onFrame = function(dt)
            if BribeUI.isOpen() then
                ensureCursorOn()
            end
        end,

        -- Reassert the cursor on A-press so it doesn't vanish between clicks.
        onControllerButtonPress = function(id)
            if BribeUI.isOpen() and id == input.CONTROLLER_BUTTON.A then
                ensureCursorOn()
            end
        end,
    },
}
