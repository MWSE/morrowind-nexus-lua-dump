local async = require("openmw.async")
local util = require("openmw.util")
local core = require("openmw.core")
local world = require("openmw.world")
local types = require("openmw.types")
local playerRef

if core.API_REVISION < 21 then
	error('This mod requires a newer version of OpenMW, please update.')
end



local function getBestDoor(actor, cell, target)
    if not target then
        target = playerRef
    end

    local doors = actor.cell:getAll(types.Door)
    local bestDoor
    local bestPathLength
    for _, door in ipairs(doors) do

		if types.Door.destCell(door) == target.cell then
        local pathLength = (actor.position - door.position):length() + (target.position - types.Door.destPosition(door)):length()
        if not bestDoor or pathLength < bestPathLength then
            bestDoor, bestPathLength = door, pathLength
        end
		end
    end
    return bestDoor
end

local function returnToCell(data)
    local actor, cell, target, position = unpack(data)
    local bestDoor = getBestDoor(actor, cell, target)
	if not actor:hasScript("protective_guards_for_omw/protect.lua") then
		return
	end
	 --if this is a guard with "protect" script we return him to his original spot
    if not bestDoor then
        actor:teleport(cell, position)
        return
    end
    --advanced AI part (future)
    --aipackage to order guards back to cell by making them walk to door
    actor:teleport(cell, position) --temporary
    --actor:teleport(cell, bestDoor.destPosition - util.vector3(math.random(-100, 100), math.random(-100, 100), 50))
end

local travelToTheDoor =
    async:registerTimerCallback(
    "goToTheDoor",
    function(data)
        local actor, target = data.actor, data.target
        if actor.cell ~= target.cell then
            actor:teleport(data.destCellName, data.destPos - util.vector3(0, 0, 50), data.destRot)
        end
    end
)

--the parameter is a table with 3 values
--[1] the pursuing actor object
--[2] the target actor object of [1]
--[3] number in seconds to deduct to the time it takes to teleport (optional)
local function chaseCombatTarget(data)
    local actor, target, masa = unpack(data)
    local delay

	actor:sendEvent("Pursuit_savePos_eqnx")

    if not target or not actor then
        return
    end
    if not actor:isValid() or not target:isValid() then
        return
    end
    if actor.cell:isInSameSpace(target) or not types.Actor.canMove(target) then
        return
    end
    local bestDoor = getBestDoor(actor, target.cell.name, target)

    if not bestDoor then
        return
    end


    if actor.type == types.NPC then
        delay = (actor.position - bestDoor.position):length() / types.Actor.runSpeed(actor)
    else
        delay = (actor.position - bestDoor.position):length() / (types.Actor.runSpeed(actor) * 1.8)
    end
    if masa and type(masa) == "number" then
        delay = delay - masa
    end
    if delay > 15 then
        print(string.format("%s will not pursue further", actor))
        return
    end
    if delay < 0 then
        delay = 0.1
    end
    --print(string.format("%s : delay = %f", actor.recordId, delay))
    async:newSimulationTimer(
        delay,
        travelToTheDoor,
        {
            actor = actor,
            target = target,
            destCellName = types.Door.destCell(bestDoor).name,
            destPos = types.Door.destPosition(bestDoor),
            destRot = types.Door.destRotation(bestDoor)
        }
    )
end

return {
    engineHandlers = {
        onPlayerAdded = function(player)
            playerRef = player
			core.sendGlobalEvent("Pursuit_installed_eqnx")
        end,
        onActorActive = function(actor)
            if not actor:isValid() then
                return
            end

            if actor and (actor.type == "NPC" or actor.type == "Creature") then
                actor:addScript("pursuit_for_omw/pursued.lua")
                actor:addScript("pursuit_for_omw/pursuer.lua")
            end
        end,
        onUpdate = function()
            if not playerRef then
				for _, v in ipairs(world.activeActors) do
					if v.type == types.Player then
						playerRef = v
					end
				end
            end
        end,
        onLoad = function()
            core.sendGlobalEvent("Pursuit_installed_eqnx")
        end
    },
    eventHandlers = {
        Pursuit_chaseCombatTarget_eqnx = chaseCombatTarget,
        Pursuit_returnToCell_eqnx = returnToCell
    }
}
