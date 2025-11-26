local self = require("openmw.self")
local core = require("openmw.core")
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local async = require("openmw.async")
local storage = require("openmw.storage")
local SettingsPursuitMain = storage.globalSection("SettingsPursuitMain")

local vector2 = util.vector2
local pursueTarget
local nearestPursuitDoor
local masa = math.huge

local canPathTarget = true
local agentBounds
local iMaxActivateDist = core.getGMST("iMaxActivateDist")

local pathList = {}
local okPaths = {
    [nearby.FIND_PATH_STATUS.Success] = true
}

local function aiTravelTo(door)
    ai.startPackage {
        type = "Travel",
        destPosition = door.position,
        cancelOther = false
    }
end
local function updatePursuit()
    if not (ai.getActiveTarget("Combat") or ai.getActiveTarget("Pursue")) then
        pursueTarget = nil
        return
    end

    pursueTarget = ai.getActivePackage().target

    if types.Actor.isDead(pursueTarget) then
        return
    end

    pursueTarget:sendEvent("Pursuit_pursuerData_eqnx", self)
end

local function updatePursuitDoor()
    if nearestPursuitDoor then
        local pursuitDuration = core.getSimulationTime() - masa
        if not nearestPursuitDoor.cell:isInSameSpace(self) or pursuitDuration > SettingsPursuitMain:get("Pursue Time") then
            masa = math.huge
            nearestPursuitDoor = nil
            return
        end

        local doorPos = vector2(nearestPursuitDoor.position.x, nearestPursuitDoor.position.y)
        local selfPos = vector2(self.position.x, self.position.y)

        -- iMaxActivateDist += maybe telekinesis in the future?
        if (doorPos - selfPos):length2() < iMaxActivateDist * iMaxActivateDist then -- if pursuit door is within reach..
            ai.filterPackages(function(package)
                if package.type == "Travel" then
                    return package.destPosition ~= nearestPursuitDoor.position
                end
            end)

            -- NPCs cannot activate doors like the player
            -- need to manually teleport them to the door destination
            core.sendGlobalEvent("Pursuit_teleportToDoorDest_eqnx", {nearestPursuitDoor, self})

            masa = math.huge
            nearestPursuitDoor = nil
        end
    end
end

local function updatePath()
    -- cache canPathTarget, findPath() doesn't work while inactive
    local pathStatus, pL = nearby.findPath(self.position, pursueTarget.position, {
        agentBounds = agentBounds or types.Actor.getPathfindingAgentBounds(self),
        includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.OpenDoor + nearby.NAVIGATOR_FLAGS.Swim
    })
    pathList = pL
    return okPaths[pathStatus] or (self.position - pursueTarget.position):length() < iMaxActivateDist
end

local function repeatTask()
    async:newUnsavableSimulationTimer(0.1 + math.random() * 0.2, repeatTask)

    if types.Actor.isDead(self) or not self:isActive() then
        return
    end

    if pursueTarget and pursueTarget.cell == self.cell then
        pathList = {}
        canPathTarget = not SettingsPursuitMain:get("Navmesh Check") or updatePath()
    end

    updatePursuitDoor()
    updatePursuit()
end

async:newUnsavableSimulationTimer(0, repeatTask)

return {
    engineHandlers = {
        onUpdate = function()
            -- force this bastard to run towards the pursuit door
            if nearestPursuitDoor then
                self.controls.movement = 1
                self.controls.run = true
            end
        end,
        onInactive = function()
            if pursueTarget and (pursueTarget.type == types.Player) then
                pursueTarget:sendEvent("Pursuit_getPursued_eqnx")
            end
        end,
        onActive = function()
            -- cache agentBounds
            agentBounds = types.Actor.getPathfindingAgentBounds(self)
        end,
        onLoad = function(savedData)
            nearestPursuitDoor = savedData and savedData.nearestPursuitDoor
        end,
        onSave = function()
            return {
                nearestPursuitDoor = nearestPursuitDoor
            }
        end
    },
    eventHandlers = {
        -- for doors that teleports within the same cell
        Pursuit_goToNearestPursuitDoor_eqnx = function(e)
            if (pursueTarget == e.activatingActor) and e.activatedDoor.cell:isInSameSpace(self) then
                nearestPursuitDoor = e.activatedDoor
                aiTravelTo(nearestPursuitDoor)
                masa = core.getSimulationTime()
            end
        end,
        Pursuit_chaseCombatTarget_eqnx = function(data)
            local pathDist = 0
            local targetpos = pathList[#pathList]
            for i = #pathList, 1, -1 do
                pathDist = (targetpos - pathList[i]):length() + pathDist
                targetpos = pathList[i]
            end
            if not SettingsPursuitMain:get("Creature Pursuit") and self.type == types.Creature then
                return
            --begin my edit. ShulShagana
            else
                if self.type == types.Creature then
                    if not (types.Creature.record(self).isBiped or types.Creature.record(self).canUseWeapons) then
                        return
                    end
                end
            end
            --end my edit. ShulShagana
            core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx",
                {self, data.target, data.masa, canPathTarget, pathDist})
        end,
        Pursuit_Debug_Pursuer_Details_eqnx = function(e)
            -- dummy event
        end
    }
}
