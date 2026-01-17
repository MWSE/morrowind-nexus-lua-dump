--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Time Control - Global Script                                        │
│  Handles world time manipulation (GameTimeScale, SimulationTimeScale,│
│  GameHour global variable)                                           │
╰──────────────────────────────────────────────────────────────────────╯
]]

local world = require('openmw.world')

local M = {}

-- Get MWScript global variables (GameHour, etc.)
local function getGlobals()
	return world.mwscript.getGlobalVariables()
end

return {
	eventHandlers = {
		-- Set GameHour (0-24 float)
		TimeControl_setGameHour = function(data)
			local globals = getGlobals()
			if globals then
				globals.gamehour = math.max(0, math.min(24, data.hour))
			end
		end,
		
		-- Set GameTimeScale (ratio of day time to simulation time)
		TimeControl_setDayTimeScale = function(data)
			world.setGameTimeScale(math.max(0, data.scale))
		end,
		
		-- Set SimulationTimeScale (ratio of simulation time to real time)
		TimeControl_setSimulationTimeScale = function(data)
			world.setSimulationTimeScale(math.max(0, data.scale))
		end,
	},
	
	engineHandlers = {}
}
