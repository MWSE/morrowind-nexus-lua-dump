local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local world = require("openmw.world")

local scriptPath = "scripts/ImpactEffects/npc.lua"

local function removeLocal(o)
	if types.Actor.isDead(o) or not types.Actor.isInActorsProcessingRange(o) then
		if o:hasScript(scriptPath) then
			o:removeScript(scriptPath)
--			print(o.recordId.." PurgeScript")
		end
	end
end

return {
	eventHandlers = {
		impactActorUpdate = function(o)
			if not o:hasScript(scriptPath) then o:addScript(scriptPath)	end
		end,
		impactRunMwscript = function(e)
--			print("MWSCRIPT check")
			local mw = world.mwscript.getLocalScript(e[1], e[2]).variables
			if not mw.impactHit then return	end
			mw.impactHit = 1	-- e[1]:activateBy(e[2])
		end,
		impactPurgeLocal = function(o)
			async:newUnsavableSimulationTimer(3, function() removeLocal(o) end)
		end
	}
}
