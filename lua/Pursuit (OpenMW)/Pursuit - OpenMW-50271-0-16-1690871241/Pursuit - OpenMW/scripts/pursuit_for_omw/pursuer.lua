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
local getHealth = types.Actor.stats.dynamic.health
local pursueTarget
local nearestPursuitDoor
local lastAIPackages = {}
local masa = math.huge
local canPursue = not require("scripts.pursuit_for_omw.blacklist")[self.recordId]

local canPathTarget = true
local agentBounds
local iMaxActivateDist = core.getGMST("iMaxActivateDist")

local pathList = {}
local okPaths = {
    [nearby.FIND_PATH_STATUS.Success] = true
}

local function updatePursuit()
    if not (ai.getActiveTarget("Combat") or ai.getActiveTarget("Pursue")) then
        pursueTarget = nil
        return
    end

    pursueTarget = ai.getActivePackage().target

    if getHealth(pursueTarget).current < 1 then
        return
    end
    pursueTarget:sendEvent("Pursuit_pursuerData_eqnx", self)
end

local function updatePursuitDoor()
    local function updatePursuitDoor_RESET()
        masa = math.huge
        nearestPursuitDoor = nil
        lastAIPackages = {}
    end

    if nearestPursuitDoor then
        if not nearestPursuitDoor.cell:isInSameSpace(self) or core.getSimulationTime() - masa > math.abs(SettingsPursuitMain:get("Pursue Time")) then
            updatePursuitDoor_RESET()
            return
        end

        local doorPos = vector2(nearestPursuitDoor.position.x, nearestPursuitDoor.position.y)
        local selfPos = vector2(self.position.x, self.position.y)

        -- (192 is default morrowind value, not including telekinesis)
        -- iMaxActivateDist += maybe telekinesis in the future?
        if (doorPos - selfPos):length2() < iMaxActivateDist * iMaxActivateDist then
            ai.filterPackages(function(package)
                if package.type == "Travel" then
                    return package.destPosition ~= nearestPursuitDoor.position
                end
            end)

            -- see door.lua
            nearestPursuitDoor:activateBy(self)

            core.sendGlobalEvent("Pursuit_teleportToDoorDest_eqnx", {
                nearestPursuitDoor,
                self
            })

            for _, package in pairs(lastAIPackages) do
                -- protected call because startPackage doesn't support some package types yet
                pcall(ai.startPackage, {
                    type = package.type,
                    target = package.target,
                    destPosition = package.destPosition,
                    cancelOther = false
                })
            end

            updatePursuitDoor_RESET()
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
    return okPaths[pathStatus] or (self.position - pursueTarget.position):length() < 192
end

local function repeatTask()
    if getHealth(self).current < 1 or not self:isActive() then
        return
    end
    async:newUnsavableSimulationTimer(0.1 + math.random() * 0.2, repeatTask)
    if not canPursue then
        pursueTarget = nil
        return
    end
    if pursueTarget and pursueTarget.cell == self.cell then
        pathList = {}
        canPathTarget = not SettingsPursuitMain:get("Navmesh Check") or updatePath()

    end
    updatePursuitDoor()
    updatePursuit()
end

local function initAIPackage(door)
    -- need to save aipackages in v0.48 before startPackage
    -- no need to do that in v0.49 because cancelOther is available
    ai.forEachPackage(function(package)
        lastAIPackages[#lastAIPackages + 1] = {
            type = package.type,
            target = package.target,
            destPosition = package.destPosition
        }
    end)
    ai.startPackage {
        type = "Travel",
        destPosition = door.position,
        cancelOther = false
    }
end

async:newUnsavableSimulationTimer(0, repeatTask)

return {
    interfaceName = "PURSUIT_PURSUER",
    interface = {
        version = require("scripts.pursuit_for_omw.modInfo").MOD_VERSION,
        canPursue = function(bool)
            if bool == nil then
                return canPursue
            end
            canPursue = bool
            return canPursue
        end
    },
    engineHandlers = {
        onUpdate = function()
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
        -- sent from door.lua
        Pursuit_goToNearestPursuitDoor_eqnx = function(e)
            if (pursueTarget == e.activatingActor) and e.activatedDoor.cell:isInSameSpace(self) then
                lastAIPackages = {}
                nearestPursuitDoor = e.activatedDoor
                initAIPackage(nearestPursuitDoor)
                masa = core.getSimulationTime()
            end
        end,
        Pursuit_chaseCombatTarget_eqnx = function(data)
            local pathDist = 0
            local ipos = pathList[#pathList]
            for i = #pathList, 1, -1 do
                pathDist = (ipos - pathList[i]):length() + pathDist
                ipos = pathList[i]
            end
            if canPursue then
                core.sendGlobalEvent("Pursuit_chaseCombatTarget_eqnx", {
                    self,
                    data.target,
                    data.masa,
                    canPathTarget,
                    pathDist
                })
            end
        end,
        Pursuit_Debug_Pursuer_Details_eqnx = function(e)
            -- dummy event
        end
    }
}
