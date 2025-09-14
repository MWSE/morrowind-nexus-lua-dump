local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local async = require("openmw.async")
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
local function paralyzePlayer(state, cell)
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
local function isRecalling(player)
    local eff = types.Actor.activeEffects(player):getEffect("recall")
    return eff and eff.magnitude > 0
end
local function LMM_TeleportToCell(data)
    --Simple function to teleport an object to any cell.
    local cell
    if (data.cellname.name ~= nil) then
        data.cellname = data.cellname.id
        cell = world.getCellById(data.cellname)
    else
        cell = world.getCellById(data.cellname)
    end
    if data.item.type == types.Player then
        paralyzePlayer("endtp", data.cellname)
    end
    data.item:teleport(cell, data.position, data.rotation)
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
local prevCell = nil
local prevPos = nil
local prevRot = nil
local wasRecalling = false
local plr
local function onUpdate()

if core.isWorldPaused() then return end
    if not plr then
        plr = world.players[1]
    end
    local player = plr or world.players[1]
    if isRecalling(player) and not wasRecalling then
       -- types.Actor.activeEffects(player):remove("recall")
        print("RECALL")
        LMM_TeleportToCell(
            {
                item = player,
                cellname = prevCell.id,
                position = prevPos,
                rotation = prevRot
            })
              async:newUnsavableSimulationTimer(0.00001, function()
        plr:sendEvent("openMarkMenu")
            end)
        wasRecalling = true
    elseif not isRecalling(player) and wasRecalling then
        wasRecalling = false
    elseif not isRecalling(player) then
        prevCell = player.cell
        prevPos = player.position
        prevRot = player.rotation
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
        --onUpdate = onUpdate
    }
}
