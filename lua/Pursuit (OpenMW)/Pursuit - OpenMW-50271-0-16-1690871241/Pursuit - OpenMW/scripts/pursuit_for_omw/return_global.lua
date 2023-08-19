local core = require("openmw.core")
local util = require("openmw.util")
local async = require("openmw.async")
local types = require("openmw.types")
local time = require("openmw_aux.time")
local storage = require("openmw.storage")
local SettingsPursuitMain = storage.globalSection("SettingsPursuitMain")
local pursuingActors = {}

time.runRepeatedly(function()
    if SettingsPursuitMain:get("Actor Return") then
        for _, actor in pairs(pursuingActors) do
            actor:sendEvent("NPC_RETURN_returnToOricellInstant_eqnx")
        end
        pursuingActors = {}
    end
end, time.day - time.hour, {
    initialDelay = time.day + time.hour,
    type = time.GameTime
})

local function returnToOriCellInstantly(e)
    if e[1]:isValid() then
        if types.Actor.canMove(e[1]) then
            e[1]:teleport(e[2], e[3], e[4])
        end
    end
end

local function Inactive_Return(data)
    local actor, door = data.actor, data.door
    local delay = (actor.position - door.position):length() / types.Actor.walkSpeed(actor)

    async:newSimulationTimer(delay, async:registerTimerCallback("Inactive_Return", function(arg)
        core.sendGlobalEvent("Pursuit_teleportToDoorDest_eqnx", arg)
    end), {
        door,
        actor
    })
end

return {
    interfaceName = "NPC_RETURN",
    interface = {
        version = require("scripts.pursuit_for_omw.modInfo").MOD_VERSION,
        update_pursuingActors = function(actor, destCellName)
            pursuingActors[#pursuingActors + 1] = actor
            actor:sendEvent("NPC_RETURN_updateCell_eqnx", {
                prevCell = actor.cell.name,
                cellName = destCellName
            })
        end,
        returnInit = function(actor)
            actor:sendEvent("NPC_RETURN_returnInit_eqnx", {
                position = actor.position,
                cellName = actor.cell.name
            })
        end
    },
    engineHandlers = {
        onSave = function()
            return {
                pursuingActors = pursuingActors
            }
        end,
        onLoad = function(savedData)
            pursuingActors = savedData and savedData.pursuingActors or {}
        end
    },
    eventHandlers = {
        -- sent from return.lua
        NPC_RETURN_returnToOriCellInstantly_eqnx = returnToOriCellInstantly,
        NPC_RETURN_Inactive_Return_eqnx = Inactive_Return
    }
}
