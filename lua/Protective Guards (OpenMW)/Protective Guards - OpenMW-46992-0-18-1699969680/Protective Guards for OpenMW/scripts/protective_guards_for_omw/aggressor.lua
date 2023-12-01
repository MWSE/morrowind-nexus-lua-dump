local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local async = require("openmw.async")
local modInfo = require("scripts.protective_guards_for_omw.modInfo")
local immuneToGuards = false

-- todo: guards protect against criminal players
-- note: engine already automatically protect against hostile creatures
local function cTScan()
    if types.Actor.stats.dynamic.health(self).current < 1 then
        return
    end
    async:newUnsavableSimulationTimer(math.random() + math.random() * 2, cTScan)

    local cT = ai.getActiveTarget("Combat")
    if cT and cT.type == types.Player then
        cT:sendEvent("ProtectiveGuards_thisActorIsAttackedBy_eqnx", {
            actor = self,
            isImmune = immuneToGuards
        })
    end
end

async:newUnsavableSimulationTimer(math.random(), cTScan)

return {
    interfaceName = "ProtectiveGuards_eqnx",
    interface = setmetatable({}, {
        __index = function(tbl, key)
            if key == "version" then return modInfo.MOD_VERSION end
            if key == "getImmuneToGuards" then return immuneToGuards end
            if key == "setImmuneToGuards" then return function(arg) immuneToGuards = arg end end
        end
    }),
    eventHandlers = {
        ProtectiveGuards_isImmune_eqnx = function(ignore)
            immuneToGuards = ignore
        end
    }
}
