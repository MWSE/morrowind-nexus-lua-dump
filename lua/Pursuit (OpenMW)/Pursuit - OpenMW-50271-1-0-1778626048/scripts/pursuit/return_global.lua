require "scripts.pursuit.defs"
local async = require("openmw.async")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local world = require("openmw.world")

local returnList = {} -- map key:id value:actor

local proxy_returnList = setmetatable({}, {
    __newindex = function(t, k, v)
        if returnList[k] then
            -- already exists, do nothing
        else
            returnList[k] = v
        end
    end
})

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

local function updateActorReturns()
    if not getGlobalStore("Settings!_Pursuit_!"):get("actorReturn") then return end

    for id, returnData in pairs(returnList) do
        local actor, startCellName = returnData.actor, returnData.startCellName

        -- remove invalid actors
        if not actor:isValid() then
            returnList[id] = nil
            goto continue
        end

        -- remove actors already in their starting cell
        if startCellName == actor.cell.name then
            returnList[id] = nil
            -- goto continue
        end

        if types.Actor.canMove(actor) then
            local localscript = world.mwscript.getLocalScript(actor)
            local isCompanion = localscript and localscript.companion and localscript.companion ~= 0

            -- companions are followers that can be ordered to wait or follow
            if not isCompanion then
                actor:sendEvent("Pursuit_Return_startingCellReturn")
            end
        end

        ::continue::
    end
end

time.runRepeatedly(updateActorReturns, time.day - time.hour, { type = time.GameTime })

local function startingCellReturn(e)
    local actor = e.actor
    local ok, err = safeTeleport { actor, e.startingCellName, e.startingPosition, e.actor.startingRotation }
    if ok then
        getGlobalStore("@Pursuit@"):set("returnStartingCell")
        returnList[actor.id] = nil
    else
        log(err)
    end
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

local inactive_return = async:registerTimerCallback("inactive_return", function(e)
    local actor, door = e.actor, e.door
    if world.players[1].cell == actor.cell then return end -- another way for self:isActive();
    local destCellName, destPosition, destRotation = getDoorDestination(door)
    safeTeleport { actor, destCellName, destPosition, destRotation }
end)

local function inactiveReturn(e)
    local moveSpeed = getActorSpeed(e.actor, not e.isRunning)
    local delay = (e.actor.position - e.door.position):length() / moveSpeed
    async:newSimulationTimer(delay, inactive_return, e)
end

local function update_returnList(data)
    proxy_returnList[data.pursuer.id] = { startCellName = data.pursuerCell, actor = data.pursuer }
    data.pursuer:sendEvent("Pursuit_Return_updateCell", {
        pursuerCell = data.pursuerCell,
        pursuerPos = data.pursuerPos,
        new_pursuerCell = types.Door.destCell(data.doorToTargetCell).name,
        new_pursuerPos = types.Door.destPosition(data.doorToTargetCell)
    })
end

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

return {
    interfaceName = "Pursuit_Return",
    interface = setmetatable({
        version = require("scripts.pursuit.modInfo").MOD_VERSION,
    }, {
        __index = {
            returnList = function() return returnList end,
            update_returnList = update_returnList,
        }
    }),
    engineHandlers = {
        onSave = function() return { returnList = returnList } end,
        onLoad = function(savedData) returnList = savedData and savedData.returnList or {} end
    },
    eventHandlers = {
        Pursuit_Return_startingCellReturn = startingCellReturn,
        Pursuit_Return_InactiveReturn = inactiveReturn,
    }
}
