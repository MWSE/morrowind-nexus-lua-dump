local core = require("openmw.core")
local query = require("openmw.query")
local aux = require("openmw_aux.util")
local searchedCells = {}
local pursuit_for_omw = false

local function searchGuards(data)
    if not pursuit_for_omw then
        return
    end
    local door, agg = unpack(data)
    if searchedCells[tostring(door)] then
        return
    end
    searchedCells[tostring(door)] = true
    local adjacentCellActors = door.destCell:selectObjects(query.actors)
    for _, actor in adjacentCellActors:ipairs() do
        if
            actor:canMove() and actor.recordId:match("guard") or actor.recordId:match("ordinator") or
                (actor:getEquipment()[1] and actor:getEquipment()[1].recordId:match("imperial") and agg.cell.name:match("Gnisis"))
         then
            actor:addScript("pursuit_for_omw/pursuer.lua")
            actor:addScript("protective_guards_for_omw/protect.lua")
            actor:sendEvent("Pursuit_savePos_eqnx")
            core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {actor, agg})
            actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", agg)
        end
    end
end

aux.runEveryNSeconds(
    10,
    function()
        searchedCells = {}
    end
)

return {
    engineHandlers = {
        onActorActive = function(actor)
            if not actor or not actor:isValid() then
                return
            end
            actor:addScript("protective_guards_for_omw/aggressor.lua")
            if actor.type == "NPC" then
                actor:addScript("protective_guards_for_omw/protect.lua")
            end
        end,
        onLoad = function()
            aux.runEveryNSeconds(
                10,
                function()
                    searchedCells = {}
                end
            )
        end
    },
    eventHandlers = {
        ProtectiveGuards_searchGuards_eqnx = searchGuards,
        Pursuit_installed_eqnx = function()
            pursuit_for_omw = true
            print("Pursuit and Protective Guards interaction established")
        end
    }
}
