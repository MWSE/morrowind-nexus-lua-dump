local core = require("openmw.core")
local world = require("openmw.world")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local returningNPC = {}
local player
local pursuit_for_omw

if core.API_REVISION < 21 then
    error("This mod requires a newer version of OpenMW, please update.")
end

local function filterOut(npc, info)
    if not npc:isValid() or types.Actor.stats.dynamic.health(npc).current <= 0 then
        returningNPC[npc] = nil
        return
    end
    if not types.Actor.canMove(npc) then
        return
    end
    if player and not player.cell:isInSameSpace(npc) then
        info.expire = info.expire - 1
        if info.expire <= 0 and player.cell.name ~= npc.cell.name then
            core.sendGlobalEvent(
                "NPC_Returns_goBackToStartingPosition_eqnx",
                {object = npc, cell = info.cell, position = info.position}
            )
            returningNPC[npc] = nil
        end
    end
end
local function return_delayed()
    for npc, info in pairs(returningNPC) do
        filterOut(npc, info)
    end
end

time.runRepeatedly(return_delayed, 1 * time.second)

return {
    engineHandlers = {
        onPlayerAdded = function(PLAYER)
            player = PLAYER
            core.sendGlobalEvent("NPCReturn_installed_eqnx")
        end,
        onLoad = function()
            core.sendGlobalEvent("NPCReturn_installed_eqnx")
        end
    },
    eventHandlers = {
        NPC_Returns_return_eqnx = function(returnthis)
            returningNPC[returnthis.actor] = {
                expire = 4,
                cell = returnthis.cell,
                position = returnthis.position
            }
            player = returnthis.player
        end,
        NPC_Returns_goBackToStartingPosition_eqnx = function(data)
            local pos = data.position
            local rot = data.rotation

            if not data.object:isValid() then
                error("Object parameter is invalid")
            end

            if type(data.cell) ~= "string" then
                error("Cell parameter must be a string")
            end

            data.object:teleport(data.cell, pos, rot)
        end,
        
    }
}
