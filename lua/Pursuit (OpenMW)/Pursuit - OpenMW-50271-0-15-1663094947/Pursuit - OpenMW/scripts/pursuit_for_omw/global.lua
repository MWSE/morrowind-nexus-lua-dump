local async = require("openmw.async")
local util = require("openmw.util")
local core = require("openmw.core")
local world = require("openmw.world")
local types = require("openmw.types")
local aux_util = require('openmw_aux.util')
local auxiliary = require('scripts.pursuit_for_omw.auxiliary')
local storage = require('openmw.storage')
local globalSettings = storage.globalSection('Settings_Pursuit_Options_Key_KINDI')

require('scripts/pursuit_for_omw.settings_G')

if core.API_REVISION < 29 then
	error('Pursuit mod requires a newer version of OpenMW, please update.')
end

local travelToTheDoor =
    async:registerTimerCallback(
    "goToTheDoor",
    function(data)
        local actor, target = data.actor, data.target
		if types.Actor.stats.dynamic.health(target).current <= 0 then
			return
		end
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

    if not globalSettings:get('Mod Status') then
        return
    end

    if require("scripts.pursuit_for_omw.blacklistOptional")[actor.recordId] then
        return
    end

    if not target or not actor then
        return
    end
    if not actor:isValid() or not target:isValid() then
        return
    end
    if actor.cell:isInSameSpace(target) or not types.Actor.canMove(target) then
        return
    end
    local bestDoor = auxiliary.getBestDoor(actor, target.cell.name, target, nil, actor.cell:getAll(types.Door))

    if not bestDoor then
        return
    end

    if storage.globalSection('Settings_Pursuit_ZDebug_Key_KINDI'):get('Debug') then
        target:sendEvent("Pursuit_Debug_Pursuer_Details_eqnx", {actor = actor, target = target})
    end

    if actor.type == types.NPC then
        delay = (actor.position - bestDoor.position):length() / types.Actor.runSpeed(actor)
    else
        delay = (actor.position - bestDoor.position):length() / (types.Actor.runSpeed(actor) * 1.8)
    end
    if masa and type(masa) == "number" then
        delay = delay - masa
    end
    if delay > globalSettings:get('Pursue Time') then
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
			core.sendGlobalEvent("Pursuit_installed_eqnx")
        end,
        onActorActive = function(actor)
            if actor and (actor.type == types.NPC or actor.type == types.Creature) then
                actor:addScript("scripts/pursuit_for_omw/pursued.lua")
                actor:addScript("scripts/pursuit_for_omw/pursuer.lua")
            end
        end,
        onLoad = function()
            core.sendGlobalEvent("Pursuit_installed_eqnx")
        end
    },
    eventHandlers = {
        Pursuit_chaseCombatTarget_eqnx = chaseCombatTarget,
    }
}
