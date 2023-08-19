local async = require("openmw.async")
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local aux = require("scripts.pursuit_for_omw.auxiliary")
local storage = require("openmw.storage")
local time = require("openmw_aux.time")
local NPC_RETURN = require("openmw.interfaces").NPC_RETURN

local isCreature = types.Creature.objectIsInstance
local fAthleticsRunBonus = core.getGMST("fAthleticsRunBonus") or 1
local fBaseRunMultiplier = core.getGMST("fBaseRunMultiplier") or 1.75
local SettingsPursuitMain = storage.globalSection("SettingsPursuitMain")

local DOOR = types.Door

local function isDead(actor)
    return types.Actor.stats.dynamic.health(actor).current < 1
end

-- todo: replace with global onactivate engine handler in v0.49
local function teleportToDoorDest(data)
    local DOOR_OBJ, actor = table.unpack(data)

    local destCellName = DOOR.destCell(DOOR_OBJ).name
    local destPos = DOOR.destPosition(DOOR_OBJ)
    local destRot = DOOR.destRotation(DOOR_OBJ)

    -- only teleport if the door is the same cell as the actor
    if actor.cell == DOOR_OBJ.cell then
        actor:teleport(destCellName, destPos - util.vector3(0, 0, 50), destRot)
    end
end

local travelToTheDoor = async:registerTimerCallback("goToTheDoor", function(data)
    local actor, target, door = data.actor, data.target, data.door
    if not (actor:isValid() and target:isValid()) then
        return
    end
    -- for future multiplayer
    if #actor.cell:getAll(types.Player) > 0 then
        -- return
    end
    if isDead(target) or isDead(actor) then
        return
    end

    if actor.cell ~= target.cell then
        teleportToDoorDest {
            door,
            actor
        }
        NPC_RETURN.update_pursuingActors(actor, DOOR.destCell(door).name)
    end
end)

-- https://gitlab.com/OpenMW/openmw/-/blob/master/apps/openmw/mwclass/creature.cpp#L929
-- actual creature runSpeed = walkSpeed * (0.01 * athleticsSkill * fAthleticsRunBonus + fBaseRunMultiplier) based on wiki
local function getCreatureActualRunSpeed(actor)
    -- some creatures have very low walkspeed like rat
    local athleticsSkill = 50 -- average combat skill of creatures, creature skills not yet exposed in v0.48
    return types.Actor.walkSpeed(actor) * (0.01 * athleticsSkill * fAthleticsRunBonus + fBaseRunMultiplier)
end

local function chaseCombatTarget(e)
    local actor, target, masa, canPathTarget, pathDist = table.unpack(e)
    local delay

    if not SettingsPursuitMain:get("Mod Status") then
        return
    end

    if not SettingsPursuitMain:get("Creature Pursuit") and isCreature(actor) then
        return
    end

    if not (actor:isValid() and target:isValid()) then
        return
    end

    if isDead(actor) then
        return
    end

    local bestDoor
    local bestDoors = aux.findNearestDoorToCell(actor.position, target.cell.name, actor.cell:getAll(DOOR), target.position)
    for _, door in pairs(bestDoors) do
        if not aux.isLocked(door) then
            bestDoor = door
            break
        end
    end

    if not bestDoor then
        return
    end

    -- vampire check
    -- replace API_REVISION later
    if core.API_REVISION > 39 and (DOOR.destCell(bestDoor).isExterior or DOOR.destCell(bestDoor):hasTag("QuasiExterior")) then
        if aux.getGameHour() > 6 and aux.getGameHour() < 20 then
            if types.Actor.activeEffects and types.Actor.activeEffects(actor):getEffect("Vampirism") then
                masa = -math.huge
            end
        end
    end

    local distance = (actor.position - bestDoor.position):length()
    if canPathTarget and pathDist ~= 0 then
        distance = pathDist
    end

    if actor.type == types.NPC then
        delay = distance / types.Actor.runSpeed(actor)
    else
        delay = distance / getCreatureActualRunSpeed(actor)
    end
    if masa and type(masa) == "number" then
        delay = delay - masa
    end

    delay = math.max(0.1, delay)

    target:sendEvent("Pursuit_Debug_Pursuer_Details_eqnx", {
        actor = actor,
        target = target,
        canReachTarget = delay <= SettingsPursuitMain:get("Pursue Time"),
        canPathTarget = canPathTarget,
        delay = delay,
        distance = distance
    })

    if delay > math.abs(SettingsPursuitMain:get("Pursue Time")) or not canPathTarget then
        return
    end

    async:newSimulationTimer(delay, travelToTheDoor, {
        actor = actor,
        target = target,
        door = bestDoor

    })

    NPC_RETURN.returnInit(actor)
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor and (actor.type == types.NPC or actor.type == types.Creature) then
                actor:addScript("scripts/pursuit_for_omw/pursued.lua")
                actor:addScript("scripts/pursuit_for_omw/pursuer.lua")
            end
        end,
        onObjectActive = function(obj)
            if obj and obj.type == DOOR then
                obj:addScript("scripts/pursuit_for_omw/door.lua")
            end
        end,
        onLoad = function(savedData)

        end,
        onSave = function()
            return {}
        end
    },
    eventHandlers = {
        -- sent from pursuer.lua / pursued.lua
        Pursuit_chaseCombatTarget_eqnx = chaseCombatTarget,

        -- sent from pursuer.lua / door.lua(unused)
        Pursuit_teleportToDoorDest_eqnx = teleportToDoorDest
    }
}
