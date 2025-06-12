local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local async = require("openmw.async")

local nearby = require("openmw.nearby")

local activeTarget

local function combatDetect()

    async:newUnsavableSimulationTimer(1, combatDetect)

	if not types.Actor.canMove(self) then -- if aggressor can't move, there is no pb
        return
    end

	activeTarget = ai.getActiveTarget("Combat")

    if activeTarget then
		for _, actor in pairs(nearby.actors) do
			actor:sendEvent("combat_detected", {
				aggr = self, -- the "aggressor"
				vict = activeTarget, -- the "victim"
			})
		end
    end
    
end

async:newUnsavableSimulationTimer(1, combatDetect)
