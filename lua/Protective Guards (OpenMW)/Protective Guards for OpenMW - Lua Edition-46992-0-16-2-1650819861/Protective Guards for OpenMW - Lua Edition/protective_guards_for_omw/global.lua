local core = require("openmw.core")
local world = require("openmw.world")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local searchedCells = {}
local pursuit_for_omw = false

if core.API_REVISION < 21 then
	error('This mod requires a newer version of OpenMW, please update.')
end

time.runRepeatedly(
    function()
        searchedCells = {}
    end,
    10 * time.second
)

local function searchGuards(data)
    if not pursuit_for_omw then
        return
    end

    local door, agg = unpack(data)
    if searchedCells[door] then
        return
    end

    searchedCells[door] = true
    local adjacentCellActors = types.Door.destCell(door):getAll(types.NPC)
    for _, actor in ipairs(adjacentCellActors) do

        if
            types.Actor.canMove(actor) and actor.recordId:match("guard") or actor.recordId:match("ordinator") or
                (types.Actor.equipment(actor,1) and types.Actor.equipment(actor,1).recordId:match("imperial") and
                    agg.cell.name:match("Gnisis"))
         then
            actor:addScript("pursuit_for_omw/pursuer.lua")
            actor:addScript("protective_guards_for_omw/protect.lua")
            actor:sendEvent("Pursuit_savePos_eqnx")
            core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {actor, agg})
            actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", agg)
        end
    end
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if
                actor.type == types.NPC and
                    (string.match(actor.recordId, "guard") or string.match(actor.recordId, "ordinator") or
                        (types.Actor.equipment(actor,1) and types.Actor.equipment(actor,1).recordId:match("imperial") and
                            actor.cell.name:match("Gnisis")))
             then
                actor:addScript("protective_guards_for_omw/protect.lua")
            else
                if actor:hasScript("protective_guards_for_omw/protect.lua") then
                    actor:removeScript("protective_guards_for_omw/protect.lua")
                end
            end
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
