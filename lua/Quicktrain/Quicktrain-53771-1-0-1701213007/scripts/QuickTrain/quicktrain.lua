local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")

local delay1 = 0.1
local delay2 = 0.5
local function UiModeChanged(data)
    local newMode = data.newMode
    local arg = data.arg
    if newMode == "Training" then
        async:newUnsavableSimulationTimer(delay1, function()
            local soundPlaying = ambient.isSoundPlaying("skillraise")
            if soundPlaying then
                async:newUnsavableSimulationTimer(delay2, function()
                    local soundPlaying = ambient.isSoundPlaying("skillraise")
                    if not I.UI.getMode() and soundPlaying then
                        I.UI.setMode("Training", { target = arg })
                    end
                end)
            end
        end)
    end
end
return {

    eventHandlers = {
        UiModeChanged = UiModeChanged
    }
}
