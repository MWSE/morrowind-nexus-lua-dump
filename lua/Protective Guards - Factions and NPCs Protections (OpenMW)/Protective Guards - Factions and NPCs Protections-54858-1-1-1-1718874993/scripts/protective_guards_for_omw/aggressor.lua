local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local async = require("openmw.async")
local immuneToGuards = false

local core = require("openmw.core")
local nearby = require("openmw.nearby")


--local util = require("openmw.util")
--local nearby = require("openmw.nearby")
--local aux_util = require("openmw_aux.util")

-- todo: guards protect against criminal players
-- note: engine already automatically protect against hostile creatures

--local function nearbyGuards()
--    local classes = section:get("Search Guard of Class"):lower()
--    return aux_util.mapFilter(nearby.actors, function(actor)
--        local actorClass = actor.type.record(actor).class
--        return actorClass and classes:find(actorClass:lower())
--    end)
--end

local function cTScan()
    if types.Actor.stats.dynamic.health(self).current < 1 then
        return
    end
--for _, actor in pairs(nearbyGuards()) do
--                if (actor.position - self.position):length() > (self.cell.isExterior and extDist or intDist) then
--                    return
--                end
--end
    async:newUnsavableSimulationTimer(math.random() + math.random() * 2, cTScan)

    local cT = ai.getActiveTarget("Combat")

    if cT and (cT.type == types.Player or cT.type == types.NPC) then -- ll: i add the NPC part
		for _, player in pairs(nearby.players) do
			player:sendEvent("ProtectiveGuards_thisActorIsAttackedBy_eqnx", {
				actor = self, -- the "aggressor"
				vict = cT, -- ll: i add this "defensor" variable
				isImmune = immuneToGuards
			})
		end
    end
end

async:newUnsavableSimulationTimer(math.random(), cTScan)

return {
    interfaceName = "PROTECTIVE_GUARDS_AGGRESSOR",
    interface = {
        version = require("scripts.protective_guards_for_omw.modInfo").MOD_VERSION,
        immuneToGuards = function(isImmune)
            if isImmune == nil then
                return immuneToGuards
            end
            immuneToGuards = isImmune
            return immuneToGuards
        end
    }
}
