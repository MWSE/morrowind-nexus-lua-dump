local config = require("mer.theGuarWhisperer.config")

---This class provides functions for disabling and enabling controls.
---@class GuarWhisperer.services.Controls
local Controls = {}

function Controls.setControlsDisabled(state)
    tes3.mobilePlayer.controlsDisabled = state
    tes3.mobilePlayer.jumpingDisabled = state
    tes3.mobilePlayer.viewSwitchDisabled = state
    tes3.mobilePlayer.vanityDisabled = state
    tes3.mobilePlayer.attackDisabled = state
    tes3.mobilePlayer.magicDisabled = state
end

function Controls.disableControls()
    Controls.setControlsDisabled(true)
end

function Controls.enableControls()
    Controls.setControlsDisabled(false)
    ---@diagnostic disable-next-line: missing-fields
    tes3.runLegacyScript{command = "EnableInventoryMenu"}
end

---Disables controls, fades out, passes time, fades back in, re-enables controls
function Controls.fadeTimeOut( hoursPassed, secondsTaken, callback )
    local function fadeTimeIn()
        Controls.enableControls()
        config.isFading = false
    end
    config.isFading  = true
    tes3.fadeOut({ duration = 0.5 })
    Controls.disableControls()
    --Halfway through, advance gamehour
    local iterations = 10
    timer.start({
        type = timer.simulate,
        iterations = iterations,
        duration = ( secondsTaken / iterations ),
        callback = (
            function()
                local gameHour = tes3.findGlobal("gameHour")
                gameHour.value = gameHour.value + (hoursPassed/iterations)
            end
        )
    })
    --All the way through, fade back in
    timer.start({
        type = timer.simulate,
        iterations = 1,
        duration = secondsTaken,
        callback = (
            function()
                local fadeBackTime = 1
                tes3.fadeIn({ duration = fadeBackTime })
                callback()
                timer.start({
                    type = timer.simulate,
                    iterations = 1,
                    duration = fadeBackTime,
                    callback = fadeTimeIn
                })
            end
        )
    })
end

return Controls