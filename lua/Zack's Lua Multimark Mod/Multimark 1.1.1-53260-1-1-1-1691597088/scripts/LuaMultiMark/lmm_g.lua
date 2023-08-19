local world = require("openmw.world")
local types = require("openmw.types")
local function LMM_SetTimeScale(val)
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
    
    local desiredActor = "zhac_creature_paralyze_start"
if state == "end" then
    desiredActor = "zhac_creature_paralyze_end"
elseif state == "endtp" then
        desiredActor = "zhac_creature_paralyze_endtp"
end
for index, value in ipairs(world.getCellByName("ZHAC_Multimark_holdingcell"):getAll()) do
    if value.recordId == desiredActor then
        local player = getPlayer()
        if not cell then
            cell = player.cell.name
        end
        value:teleport(cell,player.position)
        return
    end
end

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
        local player = getPlayer()
        player:sendEvent("saveMarkLoc")
    elseif actor.recordId:lower() == "teleport_summonrecall" then
        local player = getPlayer()
        player:sendEvent("openMarkMenu")
    end
end
return {
    eventHandlers = {
        LMM_SetTimeScale = LMM_SetTimeScale,
        LMM_TeleportToCell = LMM_TeleportToCell,
        LMM_paralyzePlayer = paralyzePlayer,
    },
    engineHandlers = {
    }
}
