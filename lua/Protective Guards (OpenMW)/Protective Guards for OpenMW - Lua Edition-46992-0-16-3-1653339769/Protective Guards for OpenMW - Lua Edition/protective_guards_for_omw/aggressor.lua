local self = require("openmw.self")
local nearby = require("openmw.nearby")
local time = require("openmw_aux.time")
local ai = require("openmw.interfaces").AI
local core = require("openmw.core")
local bL = require("protective_guards_for_omw.blacklistedareas")
local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local firstRun = false
local previousCell
local distCheck = 8192
local rTimer

local function searchGuardsAdjacentCells()
    if not firstRun then
        return
    end

    local nearbyDoors =
        aux_util.mapFilter(
        nearby.doors,
        function(door)
            return types.Door.isTeleport(door) and (door.position - self.position):length() < 2000
        end
    )

    for _, door in pairs(nearbyDoors) do
        core.sendGlobalEvent("ProtectiveGuards_searchGuards_eqnx", {door, self})
    end
end

rTimer = time.runRepeatedly(
    function()
        if bL[self.cell.name] then
            return
        end
        if not ai.getActiveTarget("Combat") or not types.Actor.canMove(self) then
            firstRun = true
            return
        end

        local playerRef

        if ai.getActiveTarget("Combat").type == types.Player then
            playerRef = ai.getActiveTarget("Combat")
            if types.Actor.inventory(playerRef):countOf("PG_TrigCrime") > 0 then
                return
            end
            local guards =
                aux_util.mapFilter(
                nearby.actors,
                function(actor)
                    return actor ~= self.object and actor.type == types.NPC and types.NPC.record(actor).class == "Guard"
                end
            )

            for _, actor in pairs(guards) do
                if (actor.position - self.position):length() < distCheck then
                    if math.random(5) < 3 then
                        actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", self)
                    end
                end
            end
            searchGuardsAdjacentCells()
            firstRun = false
        end
    end,
    0.5 * time.second
)


local rTimer2 = time.runRepeatedly(
    function()
        firstRun = true
    end,
    math.random(2,4) * time.second
)

return {
    engineHandlers = {
        onInactive = function()
            if types.Actor.stats.dynamic.health(self).current <= 0 then
                rTimer()
                rTimer2()
                return
            end
            firstRun = true
            previousCell = self.cell
        end,
        onActive = function()
            distCheck = self.cell.isExterior and 8192 / 5 or 8192
        end
    }
}
