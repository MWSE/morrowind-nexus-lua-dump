--[[
    Mod: Perfect Placement OpenMW
    Author: Hrnchamd
    Version: 2.2beta
]]--

local async = require('openmw.async')

return {
    eventHandlers = {
        ["PerfectPlacement:Move"] = function (e)
			e.active:teleport(e.active.cell, e.newPosition, e.newRotation)
		end,
        ["PerfectPlacement:Drop"] = function (e)
			-- Use timer to avoid sending a second conflicting teleport in the same frame.
			async:newUnsavableSimulationTimer(0.05, function()
				e.active:teleport(e.active.cell, e.newPosition, e.newRotation)
			end)
		end,
    }
}