local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')


local function setSimulationTimeScale(scale)
	world.setSimulationTimeScale(scale)
end



return{
	eventHandlers = {
		speedyStartSetSimulationTimeScale = setSimulationTimeScale,
    }
}