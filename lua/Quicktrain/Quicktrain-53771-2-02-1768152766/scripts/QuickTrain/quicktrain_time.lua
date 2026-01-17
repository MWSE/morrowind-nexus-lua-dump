local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local  time = require('openmw_aux.time')
local desiredTime = 0
local waiting = false
local useSimTime = false
local timeScale = 35000
local fakeTimeScale = 35000
local ogScale = 1
local function waitHours(num,simTime)
    if waiting then
        return
    end
    waiting = true
    desiredTime = core.getGameTime() +  (time.hour * num)
   -- --print(desiredTime)
    if simTime then
        ogScale = world.getSimulationTimeScale()
        useSimTime = true
        world.setSimulationTimeScale(timeScale)
    else
        ogScale = world.getGameTimeScale()
        useSimTime = false
        world.setGameTimeScale(fakeTimeScale)
    end
end
local function stopWaiting()
    waiting = false
    desiredTime = 0
    realTimeWaited = 0
    if useSimTime then
        
    world.setSimulationTimeScale(ogScale)
    else

        world.setGameTimeScale(ogScale)
    end
end
local realTimeWaited = 0
local function onUpdate(dt)
    realTimeWaited = realTimeWaited + dt
    if waiting then
        
    local gt = core.getGameTime()
    if gt > desiredTime then
        --print("Waited",realTimeWaited)
        stopWaiting()
    end
    end
end

return {
    interfaceName = "QT_Time",
    interface = {
        waitHours = waitHours,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = function ()
            if waiting then
                
            stopWaiting()
            end
        end
    },
    eventHandlers = {
        QT_waitHours = waitHours
    }
}