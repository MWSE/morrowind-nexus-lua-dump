local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local skipNext = false
local delay1 = 0.2
local delay2 = 0.5
local function UiModeChanged(data)
    local newMode = data.newMode
    local arg = data.arg
    if newMode == "Training" then
        async:newUnsavableSimulationTimer(delay1, function()
            local soundPlaying = ambient.isSoundPlaying("skillraise")
            if soundPlaying then
                async:newUnsavableSimulationTimer(delay2, function()
                    if skipNext then
                        skipNext = false
                        return
                    end
                    local soundPlaying = ambient.isSoundPlaying("skillraise")
                    if not I.UI.getMode() and soundPlaying then
                        I.UI.setMode("Training", { target = arg })
                    end
                end)
            end
        end)
    end
end
return {--
    interfaceName = "Quicktrain_Main",
    interface = {
        skipNext = function ()
            skipNext = true
        end
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged
    }
}
