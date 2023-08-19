local time = require("openmw_aux.time")
local types = require("openmw.types")
local searchedCells = {}

time.runRepeatedly(function()
    searchedCells = {}
end, 1 * time.second)

local function searchGuards(data)
    local door, agg, classes = table.unpack(data)

    local C = tostring(types.Door.destCell(door))
    if searchedCells[C] then
        return
    end

    searchedCells[C] = true
    local adjacentCellActors = types.Door.destCell(door):getAll(types.NPC)
    for _, actor in pairs(adjacentCellActors) do
        if classes:find(types.NPC.record(actor).class:lower()) then -- string.find
            actor:addScript("scripts/pursuit_for_omw/pursuer.lua")
            actor:addScript("scripts/pursuit_for_omw/return.lua")
            actor:addScript("scripts/protective_guards_for_omw/protect.lua")
            actor:sendEvent("Pursuit_chaseCombatTarget_eqnx", {
                target = agg
            })
            actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {
                attacker = agg
            })
        end
    end
end

local function oldVersionCleanup(data)
    local oldObjs = types.Actor.inventory(data.actor):findAll("PG_TrigCrime")
    if #oldObjs > 0 then
        for _, oldObj in pairs(oldObjs) do
            if oldObj:isValid() then
                oldObj:remove()
            end
        end
    end
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor.type == types.NPC then
                actor:addScript("scripts/protective_guards_for_omw/protect.lua")
            end
        end
    },
    eventHandlers = {
        ProtectiveGuards_searchGuards_eqnx = searchGuards,
        ProtectiveGuards_oldVersionCleanup_eqnx = oldVersionCleanup
    }
}
