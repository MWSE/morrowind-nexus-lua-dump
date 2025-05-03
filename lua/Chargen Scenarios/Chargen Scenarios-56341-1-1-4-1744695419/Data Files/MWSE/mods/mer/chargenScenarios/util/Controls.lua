
---@class ChargenScenarios.Controls
local Controls = {}

Controls.isKeyPressed = function(pressed, expected)
    return (
        pressed.keyCode == expected.keyCode
         and not not pressed.isShiftDown == not not expected.isShiftDown
         and not not pressed.isControlDown == not not expected.isControlDown
         and not not pressed.isAltDown == not not expected.isAltDown
         and not not pressed.isSuperDown == not not expected.isSuperDown
    )
end

local function setControlsDisabled(state)
    tes3.mobilePlayer.controlsDisabled = state
    tes3.mobilePlayer.jumpingDisabled = state
    tes3.mobilePlayer.attackDisabled = state
    tes3.mobilePlayer.magicDisabled = state
    tes3.mobilePlayer.mouseLookDisabled = state
end

---Disable all player controls
function Controls.disableControls()
    setControlsDisabled(true)
end

---Enable all player controls
function Controls.enableControls()
    ---@diagnostic disable
    tes3.runLegacyScript{command = "EnableInventoryMenu"}
    tes3.runLegacyScript{ command = "EnablePlayerControls" }
    tes3.runLegacyScript{ command = "EnablePlayerJumping" }
    tes3.runLegacyScript{ command = "EnablePlayerViewSwitch" }
    tes3.runLegacyScript{ command = "EnableVanityMode" }
    tes3.runLegacyScript{ command = "EnablePlayerFighting" }
    tes3.runLegacyScript{ command = "EnablePlayerMagic" }
    tes3.runLegacyScript{ command = "EnableStatsMenu" }
    tes3.runLegacyScript{ command = "EnableMagicMenu" }
    tes3.runLegacyScript{ command = "EnableMapMenu" }
    tes3.runLegacyScript{ command = "EnablePlayerLooking" }
    ---@diagnostic enable
end

return Controls