local tpEffect = {}
local async = require('openmw.async')
local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
--local tmain = require("mundis.main")
tpEffect.destination = ""
local function getPlayer()

    if core.API_REVISION > 29 then 
        return world.players[1]
    else
        for index, value in ipairs(world.activeActors) do
            if value.type == types.Player then
                return value
            end
        end
        end
end
function tpEffect.stage1()
    for index, value in ipairs(world.getCellByName("MUNDIS script objects cell"):getAll()) do
        if value.recordId == "zhac_mundis_sobject_fadeout1" then
            value:teleport(getPlayer().cell.name,getPlayer().position)
        end
    end
    async:newSimulationTimer(1.5,async:registerTimerCallback("Stage2",tpEffect.stage2))
end

function tpEffect.stage2()
    for index, value in ipairs(world.getCellByName("MUNDIS script objects cell"):getAll()) do
        if value.recordId == "zhac_mundis_sobject_fadein" then
            value:teleport(getPlayer().cell.name,getPlayer().position)
        end
    end
    world.activeActors[1]:sendEvent("setPlayerControlState",true)

    core.sendGlobalEvent("teleportMundis")
end

function tpEffect.startTeleport(destination, parent)
    --disable player controls
    async:newSimulationTimer(1,async:registerTimerCallback("stage1",tpEffect.stage1))
   -- tes3.playSound({ sound = "howl8" })
   -- timer.start({ duration = 1, callback = tpEffect.stage1 })
end

return tpEffect
