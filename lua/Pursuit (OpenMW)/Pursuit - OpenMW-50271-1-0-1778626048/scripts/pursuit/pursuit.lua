local types = require("openmw.types")
local async = require("openmw.async")
local I = require("openmw.interfaces")

local blacklist = require "scripts.pursuit.blacklist"

local pursuit = { __data__ = {} }

local function targetDoorIsValidAndInPursuerCell(data)
    -- after save-reload, door object is not guaranteed to be available
    -- try validate by getting all doors in the cell and force re-registration
    -- if that doesnt work then this returns false
    -- needs more investigation. use gameObject.saveState later?
    local door = data.doorToTargetCell
    if not door:isValid() then
        data.pursuer.cell:getAll(types.Door)
        if not door:isValid() then -- try again
            return false
        end
    end
    return door.cell == data.pursuer.cell
end

local function validateObjects(data)
    if not data.pursuer:isValid() or not data.target:isValid() then return end
    if not targetDoorIsValidAndInPursuerCell(data) then return end
    if not data.pursuer.enabled then return end
    if not data.doorToTargetCell.enabled then return end
    return true
end

local function runHandlers(data)
    local handlers = I.Pursuit.getHandlers()
    for i = #handlers, 1, -1 do
        local success = handlers[i]:fn(data)
        if success == false then
            log(string.format("%s returned false for %s", handlers[i].name, data.pursuer))
            return false
        end
    end
    return true
end

local pursuitCallback = async:registerTimerCallback("Pursuit_Pursue_Target", function(data)
    if not validateObjects(data) then return end
    if not runHandlers(data) then return end
    --if not types.Door.destCell(data.doorToTargetCell):isInSameSpace(data.target) then return end  -- targetIsInTargetCell?

    local targetComesBack, pursuerArrived = false, false
    local destPosition = types.Door.destPosition(data.doorToTargetCell)
    local targetToDestDist = (destPosition - data.target.position):length()
    local targetToDoorDist = (data.doorToTargetCell.position - data.target.position):length()
    if targetToDoorDist <= targetToDestDist then targetComesBack = true end
    local pursuerToDestDist = (destPosition - data.pursuer.position):length()
    local pursuerToDoorDist = (data.doorToTargetCell.position - data.pursuer.position):length()
    if pursuerToDestDist <= pursuerToDoorDist then pursuerArrived = true end

    -- edge case prevention; the doorway race
    if targetComesBack or pursuerArrived then return end

    pursuit:moveToTargetCell(data)
end)


-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

function pursuit:execute(data)
    async:newSimulationTimer(math.max(0, data.timeUntilTeleport), pursuitCallback, data)
end

function pursuit:update(data)
    if not getDoorToCell(data) then return false end

    local targetData = self.__data__[data.target.id]
    local target_timeUntilTeleport = targetData and targetData.timeUntilTeleport or 0
    data.timeUntilTeleport = assert(data.distanceToDoor) / getActorSpeed(data.pursuer) - target_timeUntilTeleport

    if data.timeUntilTeleport > getGlobalStore("Settings!_Pursuit_!"):get("maxPursueTime") then
        log(("%s gave up pursuing"):format(data.pursuer))
        return false
    end

    self.__data__[data.pursuer.id] = data -- update data

    return true
end

function pursuit.pursueTarget(data)
    if not getGlobalStore("Settings!_Pursuit_!"):get("isActive") then return end
    if blacklist:get()[data.pursuer.recordId] then return end
    if pursuit:update(data) then pursuit:execute(data) end
end

function pursuit:moveToTargetCell(data)
    local door = assert(data.doorToTargetCell) -- required data
    local pursuer = assert(data.pursuer)       -- required data
    assert(types.Door.isTeleport(door))

    door:activateBy(pursuer) -- activate traps? and other activation events. note: this plays activate sound

    local destCellName, destPosition, destRotation = getDoorDestination(door)
    local ok, err = safeTeleport { data.pursuer, destCellName, destPosition, destRotation }
    if ok then
        self.__data__[data.pursuer.id] = data -- update data
        I.Pursuit_Return.update_returnList(data)
    else
        log(err)
    end
end

function pursuit.updatePursuer(e)
    local inPursue = e.inPursue
    if not inPursue then
        pursuit.__data__[e.pursuer.id] = nil
    end
end

return pursuit
