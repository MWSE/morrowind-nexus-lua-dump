local world = require('openmw.world')

return {
  eventHandlers = {
    toggleSimulation = function(timeScale)
      world.setSimulationTimeScale(timeScale)
    end,
  }
}