local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local function LMM_SetTimeScale(val)
    if core.API_REVISION > 30 then
        return
    end
    world.setSimulationTimeScale(val)
end

local function getPlayer()
    for index, value in ipairs(world.activeActors) do
        if value.recordId == "player" then
            return value
        end
    end
    return nil
end
local function paralyzePlayer(state,cell)
    
   -- local desiredActor = "zhac_creature_paralyze_start"
--if state == "end" then
--    desiredActor = "zhac_creature_paralyze_end"
--elseif state == "endtp" then
--        desiredActor = "zhac_creature_paralyze_endtp"
--end
--for index, value in ipairs(world.getCellByName("ZHAC_Multimark_holdingcell"):getAll()) do
--    if value.recordId == desiredActor then
--        local player = getPlayer()
--        if not cell then
--            cell = player.cell.name
---        end
--        value:teleport(cell,player.position)
--        return
--    end
--end

end
local function LMM_TeleportToCell(data)
    --Simple function to teleport an object to any cell.

    if (data.cellname.name ~= nil) then
        data.cellname = data.cellname.name
    end
    if data.item.type == types.Player then
        paralyzePlayer("endtp",data.cellname)
    end
    data.item:teleport(data.cellname, data.position, data.rotation)
end
local function onActorActive(actor)
    if actor.recordId:lower() == "teleport_summonmark" then

    elseif actor.recordId:lower() == "teleport_summonrecall" then

    end
end
local function fixTime()
    if core.API_REVISION > 30 then
        return
    end
    if world.getSimulationTimeScale() == 0 then

        world.setSimulationTimeScale(1)
    end
end
return {
    eventHandlers = {
        LMM_SetTimeScale = LMM_SetTimeScale,
        LMM_TeleportToCell = LMM_TeleportToCell,
        LMM_paralyzePlayer = paralyzePlayer,
    },
    engineHandlers = {
        onActorActive = onActorActive,
        onSave = fixTime,
        onLoad = fixTime,
    }
}
