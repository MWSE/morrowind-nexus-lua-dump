local core = require("openmw.core")
local world = require("openmw.world")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local util = require('openmw.util')
local searchedCells = {}
local pursuit_for_omw = false
local npc_return_omw = false

if core.API_REVISION < 29 then
    error("Protective Guards mod requires a newer version of OpenMW, please update.")
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

    local door, agg, classes = unpack(data)

    if searchedCells[door] then
        return
    end

    searchedCells[door] = true

    local adjacentCellActors = types.Door.destCell(door):getAll(types.NPC)

    for _, actor in pairs(adjacentCellActors) do
        if classes:find(types.NPC.record(actor).class) then
            if npc_return_omw then
                actor:sendEvent("NPC_returns_savePos_eqnx")
            end
            actor:addScript("scripts/pursuit_for_omw/pursuer.lua")
            actor:addScript("scripts/protective_guards_for_omw/protect.lua")
            core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {actor, agg})
            actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", agg)
        end
    end
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor.type == types.NPC then
                actor:addScript("scripts/protective_guards_for_omw/protect.lua")
            end
        end,
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
