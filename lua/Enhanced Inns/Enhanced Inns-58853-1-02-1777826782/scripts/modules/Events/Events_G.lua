
local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local util = require("openmw.util")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local core = require("openmw.core")
local calendar = require('openmw_aux.calendar')

local activatedObj = false
local activatedBed
local pendingSleep = false
local finishedSleep = false
local isWait = false
local once = true
local function UiModeChanged(data)
    local newMode = data.newMode
    local arg = data.arg

    local NoSleep = data.player.cell:hasTag("NoSleep")
    if not newMode then pendingSleep = false 

        once = true
        return 
    end
    if newMode == "Rest" and not pendingSleep  and data.oldMode ~= newMode and once then
        if not once then return end
        pendingSleep = true
        isWait = activatedObj == false and NoSleep == true
        local startTime = core.getGameTime()
        async:newUnsavableSimulationTimer(0.5, function()
            local elapsedTime = core.getGameTime() - startTime
            if elapsedTime > 10 then

                core.sendGlobalEvent("RestEnd",{Bed = activatedObj, isWait = isWait, duration = elapsedTime})
                data.player:sendEvent("RestEnd",{Bed = activatedObj, isWait = isWait, duration = elapsedTime})
                finishedSleep = false
            end
            pendingSleep = false
            activatedObj = false
        end)
        once = false
    elseif pendingSleep and finishedSleep == false then

        core.sendGlobalEvent("RestStart",{bed = activatedBed, isWait = isWait})
        data.player:sendEvent("RestStart",{bed = activatedBed, isWait = isWait})
        pendingSleep = false
        finishedSleep = true
    end



end
local function activatorActivation(activator, actor)

    local record = types.Activator.record(activator)
    activatedObj = true
    activatedBed = activator
    async:newUnsavableSimulationTimer(1, function()
        activatedObj = false
        activatedBed = nil
    end)
end
I.Activation.addHandlerForType(types.Activator, activatorActivation)


return {
    interfaceName = "ZS_Events",
    interface = {
    },
    engineHandlers = {
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    }
}
