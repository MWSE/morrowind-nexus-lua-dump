local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local async = require("openmw.async")

local nearby = require("openmw.nearby")

-- Blacklist to exclude some Cells from the scope of this mod.
-- By default i put the arena pits.
-- You can modify this list as you want (you must use the name of the cell in lowercase).
local blacklistedCells = {
	["vivec, arena pit"] = true,
	["anvil, the abecette: fight pit"] = true,
}

-- Blacklist to exclude some "attackers":
-- all actors in this list will be ignored by the other actors (from my mod point of view).
-- (In my mod, player is already ignored by the other actors)
-- You can fill this list as you want (you must use the actor ID in lowercase).
local blacklistedAggressors = {
	--["fargoth"] = true, -- example
}

local activeTarget

local function combatDetect()

    async:newUnsavableSimulationTimer(1, combatDetect)

	if not types.Actor.canMove(self) -- if "attacker" can't move,
	   or blacklistedCells[string.lower(self.cell.name)] -- or is in a blacklisted Cell,
	   or blacklistedAggressors[self.recordId] then -- or is a blacklisted attacker,
        return -- don't do anything
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
