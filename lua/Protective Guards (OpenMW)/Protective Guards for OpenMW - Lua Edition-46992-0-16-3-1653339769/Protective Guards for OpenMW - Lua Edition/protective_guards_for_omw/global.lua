local core = require("openmw.core")
local world = require("openmw.world")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local searchedCells = {}
local pursuit_for_omw = false
local npc_return_omw = false
local player

if core.API_REVISION < 21 then
    error("This mod requires a newer version of OpenMW, please update.")
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

    local adjacentCellActors = types.Door.destCell(door):getAll()

    adjacentCellActors =
        aux_util.mapFilter(
        adjacentCellActors,
        function(actor)
            return actor.type == types.NPC
        end
    )

    for _, actor in pairs(adjacentCellActors) do
        if types.NPC.record(actor).class == "Guard" then
            if npc_return_omw then
                actor:sendEvent("NPC_returns_savePos_eqnx")
            end
            actor:addScript("pursuit_for_omw/pursuer.lua")
            actor:addScript("protective_guards_for_omw/protect.lua")
            core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {actor, agg})
            actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", agg)
        end
    end
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor.type == types.NPC and types.NPC.record(actor).class == "Guard" then
                actor:addScript("protective_guards_for_omw/protect.lua")
            end
        end,
        onPlayerAdded = function(PLAYER)
            player = PLAYER
        end
    },
    eventHandlers = {
        ProtectiveGuards_searchGuards_eqnx = searchGuards,
        Pursuit_installed_eqnx = function()
            pursuit_for_omw = true
            print("Pursuit and Protective Guards interaction established")
        end,
        NPCReturn_installed_eqnx = function()
            npc_return_omw = true
            print("NPC Return and Protective Guards interaction established")
        end,
    }
}
