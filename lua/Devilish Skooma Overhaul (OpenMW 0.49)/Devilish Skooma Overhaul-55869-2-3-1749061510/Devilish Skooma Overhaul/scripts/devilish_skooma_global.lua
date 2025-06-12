-- server / global context
local world = require('openmw.world')

local function skoomaSetTimeScale(scale)
  world.setSimulationTimeScale(scale)
end

return { eventHandlers = { skoomaSetTimeScale = skoomaSetTimeScale } }