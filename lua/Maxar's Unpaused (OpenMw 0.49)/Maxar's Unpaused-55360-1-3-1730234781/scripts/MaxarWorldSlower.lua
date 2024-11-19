local world = require('openmw.world')

local function initialize()
    world.setSimulationTimeScale(0.5)
end

local function changeTimeScale(data)
    local timeScale = data.timeScale
    world.setSimulationTimeScale(timeScale)
end

return {
    engineHandlers = {
        onLoad = initialize,
    },
    eventHandlers = {
        ChangeTimeScale = changeTimeScale
    }
  }