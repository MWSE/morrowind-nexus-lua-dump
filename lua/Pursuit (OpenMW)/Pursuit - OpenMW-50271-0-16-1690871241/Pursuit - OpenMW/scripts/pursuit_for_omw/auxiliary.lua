local types = require("openmw.types")
local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local time = require("openmw_aux.time")

local this = {}
this.include = function(moduleName)
    local status, result = pcall(require, moduleName)
    if (status) then
        return result
    end
end

this.getDaysPassed = function()
    -- same as mw global dayspassed
    return core.getGameTime() / time.day -- 86400 seconds
end

this.getGameHour = function()
    -- same as mw global gamehour
    return core.getGameTime() / time.hour % 24
end

-- remove and replace in v0.49
this.isLocked = function(door)
    if not types.Lockable then
        return nil
    end
    local suc, res = pcall(types.Lockable.isLocked, door)
    if suc then
        return res
    elseif door.type == types.ESM4Door and types.ESM4Door.record(door).isAutomatic then
        return false
    else
        return nil
    end
end

-- targetPosition is optional
this.findNearestDoorToCell = function(pos, cell, nearbyDoors, targetPosition)
    local DOOR = types.Door
    local possibleDoors, scores = aux_util.mapFilterSort(nearbyDoors, function(door)
        if targetPosition == nil then
            targetPosition = DOOR.destPosition(door)
        end
        return (DOOR.isTeleport(door) and DOOR.destCell(door).name == cell and (pos - door.position):length() +
               (targetPosition - DOOR.destPosition(door)):length())
    end)
    return possibleDoors, scores, aux_util.findMinScore(possibleDoors, function(door)
        return (pos - door.position):length()
    end)
end

return this
